`timescale 1ns/1ps
`default_nettype none
module tb_swapio_core;
  reg clk = 1'b0;
  always #5 clk = ~clk;
  reg rst_n = 1'b0;
  reg bus_valid = 0, bus_write = 0;
  reg [7:0] bus_addr = 0, gpio_in = 0;
  reg [31:0] bus_wdata = 0;
  wire bus_ready;
  wire [31:0] bus_rdata;
  wire [7:0] gpio_out, gpio_oe;
  integer errors = 0;
  swapio_core dut (
    .clk(clk), .rst_n(rst_n), .bus_valid(bus_valid), .bus_write(bus_write),
    .bus_addr(bus_addr), .bus_wdata(bus_wdata), .bus_ready(bus_ready),
    .bus_rdata(bus_rdata), .gpio_in(gpio_in), .gpio_out(gpio_out), .gpio_oe(gpio_oe)
  );

  task write_reg(input [7:0] addr, input [31:0] data);
    begin
      @(negedge clk);
      bus_valid = 1'b1; bus_write = 1'b1;
      bus_addr = addr; bus_wdata = data;
      @(negedge clk);
      bus_valid = 1'b0; bus_write = 1'b0;
    end
  endtask
  task check_pin(input [7:0] expected);
    begin
      #1;
      if (gpio_out !== expected) begin
        $display("ERROR time=%0t gpio=%h expected=%h", $time, gpio_out, expected);
        errors = errors + 1;
      end
    end
  endtask
  initial begin
    $dumpfile("build/swapio.vcd");
    $dumpvars(0, tb_swapio_core);
    repeat (3) @(negedge clk);
    rst_n = 1;
    write_reg(8'h08, 32'd2); // instruction every 2 clocks
    write_reg(8'h10, 32'hff);
    write_reg(8'h80, 32'he001); // SET PINS,1
    write_reg(8'h84, 32'he200); // SET X,0  (non-GPIO)
    write_reg(8'h88, 32'he000); // SET PINS,0
    write_reg(8'h8c, 32'h0000); // JMP 0
    write_reg(8'h00, 32'h3);   // enable + restart
    wait (dut.pc == 5'd1); check_pin(8'h01);
    wait (dut.pc == 5'd2); check_pin(8'h01);
    wait (dut.pc == 5'd3); check_pin(8'h00);
    wait (dut.pc == 5'd0);
    wait (dut.pc == 5'd1); check_pin(8'h01);
    write_reg(8'h00, 32'h0);
    if (errors == 0) $display("PASS: SwapIO GPIO sequence and branch");
    else $fatal(1,"FAIL: %0d errors", errors);
    $finish;
  end
  initial begin #5000; $fatal(1,"TIMEOUT"); end
endmodule
`default_nettype wire
