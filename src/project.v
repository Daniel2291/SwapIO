`default_nettype none
// SwapIO Tiny Tapeout demonstrator: autonomous program loaded after reset.
// This initial wrapper is NOT a host-programmable chip interface yet.
module tt_um_swapio (
    input wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input wire ena,
    input wire clk,
    input wire rst_n
);
  reg [2:0] init_step;
  reg bus_valid;
  reg [7:0] bus_addr;
  reg [31:0] bus_wdata;
  wire [31:0] bus_rdata;
  wire bus_ready;
  wire [7:0] gpio_out;
  wire [7:0] gpio_oe;
  always @* begin
    bus_valid = (init_step < 3'd6);
    bus_addr = 8'h00;
    bus_wdata = 32'd0;
    case (init_step)
      3'd0: begin bus_addr=8'h08; bus_wdata=32'd2500000; end // 0.05 s / instruction @ 50 MHz
      3'd1: begin bus_addr=8'h10; bus_wdata=32'h00000001; end
      3'd2: begin bus_addr=8'h80; bus_wdata=32'h0000e001; end // SET PINS,1
      3'd3: begin bus_addr=8'h84; bus_wdata=32'h0000e000; end // SET PINS,0
      3'd4: begin bus_addr=8'h88; bus_wdata=32'h00000000; end // JMP 0
      3'd5: begin bus_addr=8'h00; bus_wdata=32'h00000003; end // enable + restart
      default: begin bus_valid=1'b0; bus_addr=8'h00; bus_wdata=32'd0; end
    endcase
  end
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) init_step <= 3'd0;
    else if (ena && init_step < 3'd6) init_step <= init_step + 3'd1;
  end
  swapio_core u_core (
    .clk(clk), .rst_n(rst_n),
    .bus_valid(bus_valid && ena), .bus_write(1'b1),
    .bus_addr(bus_addr), .bus_wdata(bus_wdata),
    .bus_ready(bus_ready), .bus_rdata(bus_rdata),
    .gpio_in(ui_in), .gpio_out(gpio_out), .gpio_oe(gpio_oe)
  );
  assign uo_out = gpio_out;
  assign uio_out = 8'b0;
  assign uio_oe = 8'b0;
  wire unused_inputs = &{uio_in, bus_rdata[0], bus_ready, gpio_oe[0], 1'b0};
endmodule
`default_nettype wire
