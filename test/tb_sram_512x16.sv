`timescale 1ns/1ps
`default_nettype none

module tb_sram_512x16;
  reg clk = 1'b0;
  always #5 clk = ~clk;

  reg rst_n = 1'b0;
  reg fetch_en = 1'b0;
  reg [8:0] fetch_addr = 9'd0;
  wire [15:0] instr_data;
  reg wr_en = 1'b0;
  reg [8:0] wr_addr = 9'd0;
  reg [15:0] wr_data = 16'd0;
  integer checks = 0;
  integer i;
  reg [15:0] random_word;

  swio_instr_mem dut (
    .clk(clk), 
    .rst_n(rst_n),
    .fetch_en(fetch_en), 
    .fetch_addr(fetch_addr), 
    .instr_data(instr_data),
    .wr_en(wr_en), 
    .wr_addr(wr_addr), 
    .wr_data(wr_data)
  );

  task automatic write_word(input reg [8:0] addr, input reg [15:0] data);
    begin
      @(negedge clk);
      wr_en = 1'b1;
      wr_addr = addr;
      wr_data = data;
      fetch_en = 1'b0;
      @(posedge clk); // write accepted
      @(negedge clk);
      wr_en = 1'b0;
    end
  endtask

  task automatic read_check(input reg [8:0] addr, input reg [15:0] expected);
    begin
      @(negedge clk);
      wr_en = 1'b0;
      fetch_en = 1'b1;
      fetch_addr = addr;
      @(posedge clk);
      #1; // allow NBA update of registered SRAM output
      if (instr_data !== expected)
        $fatal(1, "READ FAIL addr=%0d expected=%04h actual=%04h", addr, expected, instr_data);
      checks = checks + 1;
      $display("PASS read[%0d] = %04h", addr, instr_data);
    end
  endtask

  task automatic check_hold(input reg [15:0] expected);
    begin
      @(negedge clk);
      wr_en = 1'b0;
      fetch_en = 1'b0;
      @(posedge clk);
      #1;
      if (instr_data !== expected)
        $fatal(1, "HOLD FAIL expected=%04h actual=%04h", expected, instr_data);
      checks = checks + 1;
    end
  endtask

  task automatic check_write_priority(
    input reg [8:0] addr,
    input reg [15:0] value,
    input reg [15:0] expected_held
  );
    begin
      @(negedge clk);
      fetch_en = 1'b1;
      fetch_addr = 9'd0;
      wr_en = 1'b1;
      wr_addr = addr;
      wr_data = value;
      @(posedge clk);
      #1;
      if (instr_data !== expected_held)
        $fatal(1, "WRITE PRIORITY FAIL: read output changed to %04h", instr_data);
      checks = checks + 1;
      @(negedge clk);
      wr_en = 1'b0;
      fetch_en = 1'b0;
    end
  endtask

  initial begin
    $dumpfile("build/sram_512x16.vcd");
    $dumpvars(0, tb_sram_512x16);
    // SRAM contents undefined at power-up; do not assert on uninitialized reads.
    repeat (3) @(negedge clk);
    rst_n = 1'b1;

    $display("TEST: basic storage and boundary addresses");
    write_word(9'd0,   16'hA123);
    write_word(9'd1,   16'hB456);
    write_word(9'd511, 16'hCAFE);
    read_check(9'd0,   16'hA123);
    read_check(9'd1,   16'hB456);
    read_check(9'd511, 16'hCAFE);

    $display("TEST: disabled read holds output");
    check_hold(16'hCAFE);

    $display("TEST: simultaneous fetch and write - write priority");
    check_write_priority(9'd7, 16'hD00D, 16'hCAFE);
    read_check(9'd7, 16'hD00D);

    $display("TEST: reset suppresses writes, memory retains contents");
    @(negedge clk);
    rst_n = 1'b0;
    wr_en = 1'b1;
    wr_addr = 9'd7;
    wr_data = 16'hDEAD;
    fetch_en = 1'b0;
    @(posedge clk);
    #1;
    if (instr_data !== 16'hD00D)
      $fatal(1, "RESET HOLD FAIL");
    @(negedge clk);
    wr_en = 1'b0;
    rst_n = 1'b1;
    read_check(9'd7, 16'hD00D);

    $display("TEST: randomized content at distinct addresses");
    for (i = 0; i < 20; i = i + 1) begin
      random_word = $random;
      write_word((32+i), random_word);
      read_check((32+i), random_word);
    end

    $display("ALL TESTS PASSED (%0d checks)", checks);
    $finish;
  end
endmodule
`default_nettype wire