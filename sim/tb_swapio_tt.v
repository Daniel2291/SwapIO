`timescale 1ns/1ps
`default_nettype none
module tb_swapio_tt;
  reg clk=0, rst_n=0;
  reg [7:0] ui_in=0, uio_in=0;
  wire [7:0] uo_out, uio_out, uio_oe;
  integer errors=0;
  always #10 clk=~clk;
  tt_um_swapio dut(.ui_in(ui_in),.uo_out(uo_out),.uio_in(uio_in),
    .uio_out(uio_out),.uio_oe(uio_oe),.ena(1'b1),.clk(clk),.rst_n(rst_n));
  initial begin
    $dumpfile("build/swapio_tt.vcd"); $dumpvars(0,tb_swapio_tt);
    repeat(3) @(negedge clk); rst_n=1;
    repeat(10) @(posedge clk);
    if (uio_oe !== 8'd0 || uio_out !== 8'd0) begin
      $display("FAIL: undriven IO outputs"); errors=errors+1;
    end
    if (dut.u_core.running !== 1'b1) begin
      $display("FAIL: boot program did not start"); errors=errors+1;
    end
    // Avoid waiting 0.05 sec per instruction in smoke test.
    if (errors==0) $display("PASS: SwapIO Tiny Tapeout wrapper boot");
    else $fatal(1,"SwapIO TT wrapper errors=%0d",errors);
    $finish;
  end
  initial begin #10000; $fatal(1,"TIMEOUT"); end
endmodule
`default_nettype wire
