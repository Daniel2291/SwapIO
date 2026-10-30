`timescale 1ns/1ps
module tb_afifo;
  localparam integer DSIZE = 8;
  localparam integer ASIZE = 4;
  localparam integer DEPTH = (1 << ASIZE);

  reg wclk = 0;
  reg rclk = 0;
  always #10 wclk = ~wclk;   // 50 MHz write clock, SPI-side example
  always #7  rclk = ~rclk;   // ~71.4 MHz read clock, unrelated phase/rate

  reg wrst_n = 0, rrst_n = 0;
  reg wr = 0, rd = 0;
  reg [DSIZE-1:0] wdata = 0;
  wire [DSIZE-1:0] rdata;
  wire full, empty;
  integer sent = 0, received = 0;
  integer i;

  afifo #(.DSIZE(DSIZE), .ASIZE(ASIZE)) dut (
      .i_wclk(wclk), .i_wrst_n(wrst_n), .i_wr(wr), .i_wdata(wdata), .o_wfull(full),
      .i_rclk(rclk), .i_rrst_n(rrst_n), .i_rd(rd), .o_rdata(rdata), .o_rempty(empty)
  );

  // Hold valid and data across a rising write edge.
  task automatic push(input [7:0] value);
    begin
      @(negedge wclk);
      while (full) @(negedge wclk);
      wr = 1;
      wdata = value;
      @(negedge wclk);
      wr = 0;
      sent = sent + 1;
    end
  endtask

  // FWFT: the current head word is already visible before asserting rd.
  task automatic pop_check(input [7:0] expected);
    reg [7:0] observed;
    begin
      @(negedge rclk);
      while (empty) @(negedge rclk);
      observed = rdata;
      if (observed !== expected)
        $fatal(1, "Mismatch at read %0d: expected %02x, got %02x", received, expected, observed);
      rd = 1;
      @(negedge rclk);
      rd = 0;
      received = received + 1;
    end
  endtask

  initial begin
    $dumpfile("build/afifo.vcd");
    $dumpvars(0, tb_afifo);

    // Independent, synchronous-to-local-clock reset deassertion.
    repeat (4) @(negedge wclk);
    wrst_n = 1;
    repeat (4) @(negedge rclk);
    rrst_n = 1;
    repeat (4) @(negedge rclk);
    if (full !== 1'b0 || empty !== 1'b1)
      $fatal(1, "Incorrect FIFO state after reset");

    $display("TEST 1: Fill FIFO to capacity");
    for (i = 0; i < DEPTH; i = i + 1)
      push(i[7:0]);
    @(negedge wclk);
    if (full !== 1'b1) $fatal(1, "FIFO did not assert full");

    $display("TEST 2: Drain and verify ordering");
    for (i = 0; i < DEPTH; i = i + 1)
      pop_check(i[7:0]);
    repeat (4) @(negedge rclk);
    if (empty !== 1'b1) $fatal(1, "FIFO did not assert empty");

    $display("TEST 3: Concurrent reads/writes and pointer wraparound");
    fork
      begin : producer
        integer j;
        for (j = 0; j < 128; j = j + 1)
          push((j ^ 8'hA5) & 8'hFF);
      end
      begin : consumer
        integer j;
        // Deliberately allow FIFO to fill before consumer starts.
        repeat (16) @(negedge rclk);
        for (j = 0; j < 128; j = j + 1)
          pop_check((j ^ 8'hA5) & 8'hFF);
      end
    join
    repeat (4) @(negedge rclk);
    if (!empty) $fatal(1, "FIFO not empty at end of test");
    if (sent != received) $fatal(1, "Counters differ: %0d != %0d", sent, received);
    $display("PASS: %0d bytes written and read correctly", received);
    $finish;
  end

  initial begin
    #100000;
    $fatal(1, "Timeout / deadlock");
  end
endmodule
