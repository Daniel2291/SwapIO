`timescale 1ns/1ps
module tb_spi_controller;
    parameter MODE = 0;
    localparam CPOL = (MODE == 2 || MODE == 3);
    localparam CPHA = (MODE == 1 || MODE == 3);
    reg rst_n = 0;
    reg sys_clk = 0;
    always #10 sys_clk = ~sys_clk; // 50 MHz
    reg sclk = CPOL;
    reg cs_n = 1;
    reg mosi = 0;
    wire miso, miso_oe;
    wire rx_dv, rx_start;
    wire [7:0] rx_byte;
    reg [7:0] tx_byte = 0;
    reg tx_dv = 0;
    wire tx_ready, rx_overflow, tx_underflow;
    integer n_rx = 0;
    reg [7:0] expected_rx [0:2];
    reg [7:0] expected_tx [0:2];
    reg [7:0] observed_tx;
    integer k;

    spi_controller_slave #(.SPI_MODE(MODE)) dut (
        .i_Rst_L(rst_n),
        .i_Clk(sys_clk),
        .i_SPI_Clk(sclk), 
        .i_SPI_CS_n(cs_n), 
        .i_SPI_MOSI(mosi),
        .o_SPI_MISO(miso), 
        .o_SPI_MISO_OE(miso_oe),
        .o_RX_DV(rx_dv), 
        .o_RX_Byte(rx_byte), 
        .o_RX_Start(rx_start),
        .i_RX_Ready(1'b1), 
        .i_TX_Byte(tx_byte),
        .i_TX_DV(tx_dv), 
        .o_TX_Ready(tx_ready),
        .o_RX_Overflow(rx_overflow), 
        .o_TX_Underflow(tx_underflow)
    );

    always @(posedge sys_clk) begin
        #1;
        if (rx_dv) begin
            if (n_rx >= 3) $fatal(1, "Extra RX byte %02x", rx_byte);
            if (rx_byte !== expected_rx[n_rx])
                $fatal(1, "RX mismatch idx=%0d got=%02x expected=%02x", n_rx, rx_byte, expected_rx[n_rx]);
            if (rx_start !== (n_rx == 0))
                $fatal(1, "START mismatch idx=%0d got=%b", n_rx, rx_start);
            n_rx = n_rx + 1;
        end
    end

    task push_tx(input [7:0] value);
    begin
        @(negedge sys_clk);
        if (!tx_ready) $fatal(1, "TX FIFO full");
        tx_byte = value;
        tx_dv = 1;
        @(negedge sys_clk);
        tx_dv = 0;
    end
    endtask

    // Drive one SPI bit. Keep each half-period 10ns = 50MHz SCLK.
    task spi_bit(input bit in_bit, output bit out_bit);
    begin
        if (!CPHA) begin
            mosi = in_bit;
            #10;
            out_bit = miso; // sample immediately BEFORE sample edge in TB
            sclk = ~CPOL;  // leading = sampling for CPHA=0
            #10;
            sclk = CPOL;   // trailing = launch next bit
        end else begin
            sclk = ~CPOL;  // leading = launch for CPHA=1
            mosi = in_bit;
            #10;
            out_bit = miso; // sample just BEFORE trailing sampling edge
            sclk = CPOL;
            #10;
        end
    end
    endtask

    task spi_byte(input [7:0] value, output [7:0] captured);
        integer bit_index;
        reg sampled;
    begin
        captured = 0;
        for (bit_index=7; bit_index>=0; bit_index=bit_index-1) begin
            spi_bit(value[bit_index], sampled);
            captured[bit_index] = sampled;
        end
    end
    endtask

    task clock_idle_sclk;
    begin
        #10; sclk = ~CPOL;
        #10; sclk = CPOL;
    end
    endtask

    initial begin
        rst_n   = 1'b1;

        // Generate an explicit asynchronous reset edge
        #2;
        rst_n = 1'b0;

        repeat (3) @(negedge sys_clk);

        rst_n = 1'b1;

        repeat (3) @(posedge sys_clk);

        $display("TX FIFO after reset:");
        $display("  rptr    = %b", dut.u_tx_fifo.rptr);
        $display("  wptr    = %b", dut.u_tx_fifo.wptr);
        $display("  wrptr2  = %b", dut.u_tx_fifo.wrptr2);
        $display("  tx_full = %b", dut.tx_full);
        $display("  tx_empty= %b", dut.tx_empty);
    end
    initial begin
        $dumpfile("build/spi_mode.vcd");
        $dumpvars(0,tb_spi_controller);
        expected_rx[0] = 8'h11;
        expected_rx[1] = 8'h22;
        expected_rx[2] = 8'h33;
        expected_tx[0] = 8'hA5;
        expected_tx[1] = 8'h3C;
        expected_tx[2] = 8'hF0;
        repeat(5) @(negedge sys_clk);
        repeat(5) @(negedge sys_clk);
        push_tx(expected_tx[0]);
        push_tx(expected_tx[1]);
        push_tx(expected_tx[2]);
        // SPI read-domain pointer synchronizer only advances on SCLK edges.
        // This is a testbench priming sequence, not a final host protocol.
        repeat(6) clock_idle_sclk();
        if (dut.tx_empty) $fatal(1, "TX FIFO not visible after priming");
        #10; cs_n = 0;
        #10;
        for (k=0; k<3; k=k+1) begin
            spi_byte(expected_rx[k], observed_tx);
            if (observed_tx !== expected_tx[k])
                $fatal(1, "MISO mismatch mode=%0d idx=%0d got=%02x expected=%02x",
                       MODE,k,observed_tx,expected_tx[k]);
        end
        cs_n = 1;
        // No more SPI edges: final RX byte must still reach system domain.
        repeat(20) @(negedge sys_clk);
        if (n_rx != 3) $fatal(1,"Expected 3 RX bytes, got %0d",n_rx);
        if (rx_overflow || tx_underflow) $fatal(1,"FIFO error: RX=%b TX=%b",rx_overflow,tx_underflow);
        $display("PASS mode %0d",MODE);
        $finish;
    end
endmodule
