///////////////////////////////////////////////////////////////////////////////
// Description: SPI (Serial Peripheral Interface) Slave
//              Creates slave based on input configuration.
//              Receives a byte one bit at a time on MOSI
//              Will also push out byte data one bit at a time on MISO.  
//              Any data on input byte will be shipped out on MISO.
//              Supports multiple bytes per transaction when CS_n is kept 
//              low during the transaction.
//
// Note:        i_Clk must be at least 4x faster than i_SPI_Clk
//              MISO is tri-stated when not communicating.  Allows for multiple
//              SPI Slaves on the same interface.
//
// Parameters:  SPI_MODE, can be 0, 1, 2, or 3.  See above.
//              Can be configured in one of 4 modes:
//              Mode | Clock Polarity (CPOL/CKP) | Clock Phase (CPHA)
//               0   |             0             |        0
//               1   |             0             |        1
//               2   |             1             |        0
//               3   |             1             |        1
//              More info: https://en.wikipedia.org/wiki/Serial_Peripheral_Interface_Bus#Mode_numbers
//
//  !!! The originl code from nandland is modified, the CDC registers are removed
//       so CDC FIFOs are used instead.
///////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
module spi_controller_slave
  #(parameter SPI_MODE = 0)
  (
   // Control/Data Signals,
   input            i_Rst_L,    // Reset, active low
   input            i_Clk,      // Clock
  // RX (MOSI) Signals
   output reg       o_RX_Start,
   output reg       o_RX_DV,    // Data Valid pulse (1 clock cycle) ,system clocked, making integration with cmd_dec, driven by FIFO
   output reg [7:0] o_RX_Byte,  // Byte received on MOSI
   input wire       i_RX_Ready,
   output reg       o_RX_Overflow, // FIFO overflow flag, system clocked, driven by FIFO
  // TX (MISO) Signals
   input            i_TX_DV,    // Data Valid pulse to register i_TX_Byte
   input  [7:0]     i_TX_Byte,  // Byte to serialize to MISO.
   output wire      o_TX_Ready,
   output reg       o_TX_Underflow, // FIFO underflow flag, system clocked, driven by FIFO
   

   // SPI Interface
   input       i_SPI_Clk,
   output wire o_SPI_MISO,
   output wire o_SPI_MISO_OE, // MISO output enable, active high
   input       i_SPI_MOSI,
   input       i_SPI_CS_n        // active low
   );


  // SPI Interface (All Runs at SPI Clock Domain)
  wire CPOL;     // Clock polarity
  wire CPHA;     // Clock phase
  wire w_SPI_Clk;  // Inverted/non-inverted depending on settings
  wire w_SPI_MISO_Mux;
  
  reg [2:0] rx_count;
  reg [7:0] rx_shift;
  reg first_byte;
  wire [8:0] rx_wdata = { first_byte, rx_shift[6:0], i_SPI_MOSI };
  wire rx_full, rx_empty;
  wire [8:0] rx_rdata;
  wire rx_write = i_Rst_L && !i_SPI_CS_n && (rx_count == 3'd7) && !rx_full;
  wire rx_read = i_Rst_L && !rx_empty && i_RX_Ready;


  reg r_SPI_MISO_Bit, r_Preload_MISO;

  // CPOL: Clock Polarity
  // CPOL=0 means clock idles at 0, leading edge is rising edge.
  // CPOL=1 means clock idles at 1, leading edge is falling edge.
  assign CPOL  = (SPI_MODE == 2) | (SPI_MODE == 3);
  // CPHA: Clock Phase
  // CPHA=0 means the "out" side changes the data on trailing edge of clock
  //              the "in" side captures data on leading edge of clock
  // CPHA=1 means the "out" side changes the data on leading edge of clock
  //              the "in" side captures data on the trailing edge of clock
  assign CPHA  = (SPI_MODE == 1) | (SPI_MODE == 3);
  //assign w_SPI_Clk = w_CPHA ? ~i_SPI_Clk : i_SPI_Clk;
  assign w_SPI_Clk = (CPOL ^ CPHA)
                 ? ~i_SPI_Clk
                 :  i_SPI_Clk;


  async_fifo #(.DATAWIDTH(9), .ADDRSIZE(4)) u_rx_fifo (
        .wdata(rx_wdata), 
        .winc(rx_write), 
        .wclk(w_SPI_Clk),
        .wrst_n(i_Rst_L), 
        .wfull(rx_full),
        .rdata(rx_rdata),
        .rinc(rx_read),
        .rclk(i_Clk),
        .rrst_n(i_Rst_L),
        .rempty(rx_empty)
    );

  // Purpose: Recover SPI Byte in SPI Clock Domain RX sequence
  always @(posedge w_SPI_Clk or posedge i_SPI_CS_n or negedge i_Rst_L)
  begin
    if (!i_Rst_L || i_SPI_CS_n) begin
      rx_count <= 3'd0;
            rx_shift <= 8'd0;
            first_byte <= 1'b1;
        end else begin
            rx_count <= rx_count + 3'd1;
            rx_shift <= {rx_shift[6:0], i_SPI_MOSI};
            if (rx_count == 3'd7) first_byte <= 1'b0;
        end    
  end 

  
  always @(posedge i_Clk or negedge i_Rst_L) // Output received bytes in the system clock domain
  begin
    if (~i_Rst_L)
    begin
      o_RX_DV    <= 1'b0;
      o_RX_Byte  <= 8'h00;
      o_RX_Start <= 1'b0;
    end
    else begin
       o_RX_DV <= rx_read;

      if (rx_read) begin
          o_RX_Byte  <= rx_rdata[7:0];
          o_RX_Start <= rx_rdata[8];
      end
    end
  end 

  always @(posedge w_SPI_Clk or negedge i_Rst_L) begin
        if (!i_Rst_L) o_RX_Overflow <= 1'b0;
        else if (!i_SPI_CS_n && rx_count == 3'd7 && rx_full)
            o_RX_Overflow <= 1'b1;
  end



  // TX FIFO: system writes / SPI sampling edge reads.
  wire tx_full, tx_empty;
  wire [7:0] tx_rdata;
  wire tx_write = i_TX_DV && i_Rst_L;
  reg [7:0] tx_byte_latched;
  reg tx_byte_valid;
  reg sample_seen; // set when first sampling edge is seen, cleared on CS high
  reg miso_bit;
  wire tx_pop = i_Rst_L && !i_SPI_CS_n && (rx_count == 3'd7) && tx_byte_valid;
  assign o_TX_Ready = !tx_full;

  async_fifo 
    #(.DATAWIDTH(8), 
    .ADDRSIZE(4)) 
    u_tx_fifo (
      .wdata(i_TX_Byte), 
      .winc(tx_write), 
      .wclk(i_Clk),
      .wrst_n(i_Rst_L), 
      .wfull(tx_full),
      .rdata(tx_rdata), 
      .rinc(tx_pop), 
      .rclk(w_SPI_Clk),
      .rrst_n(i_Rst_L), 
      .rempty(tx_empty)
  );

  always @(posedge w_SPI_Clk or posedge i_SPI_CS_n or negedge i_Rst_L) begin
      if (!i_Rst_L || i_SPI_CS_n) begin
          tx_byte_latched <= 8'd0;
          tx_byte_valid <= 1'b0;
          sample_seen <= 1'b0;
      end else begin
          sample_seen <= 1'b1;
          if (rx_count == 3'd0) begin
              tx_byte_latched <= tx_empty ? 8'h00 : tx_rdata;
              tx_byte_valid <= !tx_empty;
          end
      end
  end

  // Opposite edge drives the next bit. CPHA=0 first bit is preloaded
  // combinationally from FWFT FIFO head before the first sampling edge.
  always @(negedge w_SPI_Clk or negedge i_Rst_L) begin    //special first bit preloading
      if (!i_Rst_L) miso_bit <= 1'b0;   
      else if (!i_SPI_CS_n) begin
          if (rx_count == 3'd0)          // rx because bits already received on MOSI, so can strat sending on MISO
              miso_bit <= tx_empty ? 1'b0 : tx_rdata[7];
          else
              miso_bit <= tx_byte_latched[7-rx_count];
      end
  end

  assign o_SPI_MISO_OE = !i_SPI_CS_n;
  assign o_SPI_MISO = i_SPI_CS_n ? 1'bz :
            ((!CPHA && !sample_seen) ?
                (tx_empty ? 1'b0 : tx_rdata[7]) : miso_bit);

  always @(posedge w_SPI_Clk or negedge i_Rst_L) begin
      if (!i_Rst_L) o_TX_Underflow <= 1'b0;
      else if (!i_SPI_CS_n && rx_count == 3'd0 && tx_empty)
          o_TX_Underflow <= 1'b1;
  end

endmodule


/* 
SPI_Slave #(
    .SPI_MODE(0)
) u_spi_slave (
    .i_Rst_L    (rst_n),
    .i_Clk      (sys_clk),

    .o_RX_DV    (spi_rx_valid),
    .o_RX_Byte  (spi_rx_byte),

    .i_TX_DV    (spi_tx_valid),
    .i_TX_Byte  (spi_tx_byte),

    .i_SPI_Clk  (spi_sclk),
    .i_SPI_MOSI (spi_mosi),
    .o_SPI_MISO (spi_miso),
    .i_SPI_CS_n (spi_cs_n)
);
*/