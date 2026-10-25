`timescale 1ns/1ps
`default_nettype none
module tb;
  reg clk=0;
  reg rst_n=0;
  reg ena=1;
  reg [7:0] ui_in=0;
  reg [7:0] uio_in=0;
  wire [7:0] uo_out,uio_out,uio_oe;
  always #10 clk=~clk;
  tt_um_swapio dut(.ui_in(ui_in),.uo_out(uo_out),.uio_in(uio_in),
      .uio_out(uio_out),.uio_oe(uio_oe),.ena(ena),.clk(clk),.rst_n(rst_n));
endmodule
`default_nettype wire
