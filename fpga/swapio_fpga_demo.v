`default_nettype none
// PYNQ-Z2 hardware demo: self-load GSwapIO toggle program, drive LED0.
module swapio_fpga_demo (input wire clk125, input wire btn0, output wire led0);
  wire rst_n = ~btn0; // Press BTN0 to reset and load program.
  reg [2:0] init_step;
  reg bus_valid;
  reg [7:0] bus_addr;
  reg [31:0] bus_wdata;
  wire [7:0] gpio_out, gpio_oe;
  wire [31:0] unused_rdata;
  wire unused_ready;
  always @* begin
    bus_valid = (init_step < 3'd5);
    bus_addr = 8'h00;
    bus_wdata = 32'd0;
    case (init_step)
      3'd0: begin bus_addr=8'h08; bus_wdata=32'd12500000; end // 0.1 s / instruction
      3'd1: begin bus_addr=8'h10; bus_wdata=32'h01; end // GSwapIO0 output
      3'd2: begin bus_addr=8'h80; bus_wdata=32'h0000e001; end // SET PINS,1
      3'd3: begin bus_addr=8'h84; bus_wdata=32'h0000e000; end // SET PINS,0
      3'd4: begin bus_addr=8'h88; bus_wdata=32'h00000000; end // JMP 0
      default: begin bus_addr=8'h00; bus_wdata=32'h3; end // enable + restart
    endcase
    if (init_step == 3'd5) bus_valid=1'b1;
    if (init_step >= 3'd6) bus_valid=1'b0;
  end
  always @(posedge clk125 or negedge rst_n) begin
    if (!rst_n) init_step <= 0;
    else if (init_step < 3'd6) init_step <= init_step + 3'd1;
  end
  swapio_core core (
    .clk(clk125), .rst_n(rst_n), .bus_valid(bus_valid), .bus_write(1'b1),
    .bus_addr(bus_addr), .bus_wdata(bus_wdata), .bus_ready(unused_ready),
    .bus_rdata(unused_rdata), .gpio_in(8'd0), .gpio_out(gpio_out), .gpio_oe(gpio_oe)
  );
  assign led0 = gpio_out[0] & gpio_oe[0];
endmodule
`default_nettype wire
