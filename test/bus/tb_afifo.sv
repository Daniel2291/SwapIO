
`timescale 1ns/1ps

module tb_afifo;

  localparam DATAWIDTH = 8;
  localparam ADDRSIZE  = 4;
  localparam DEPTH     = (1 << ADDRSIZE);

  reg wclk = 0;
  reg rclk = 0;
  reg wrst_n = 0;
  reg rrst_n = 0;

  reg  [DATAWIDTH-1:0] wdata = 0;
  reg  winc = 0;
  reg  rinc = 0;

  wire [DATAWIDTH-1:0] rdata;
  wire wfull, rempty;

  // Independent clock domains
  always #5 wclk = ~wclk;  // 100 MHz
  always #7 rclk = ~rclk;  // ~71.4 MHz

  async_fifo #(
    .DATAWIDTH(DATAWIDTH),
    .ADDRSIZE(ADDRSIZE)
  ) dut (
    .wdata(wdata),
    .winc(winc),
    .wclk(wclk),
    .wrst_n(wrst_n),
    .rinc(rinc),
    .rclk(rclk),
    .rrst_n(rrst_n),
    .rdata(rdata),
    .wfull(wfull),
    .rempty(rempty)
  );

  // Reference FIFO
  reg [DATAWIDTH-1:0] expected[$];
  reg [DATAWIDTH-1:0] item;

  integer writes = 0;
  integer reads  = 0;
  integer errors = 0;

  // Write scoreboard:
  // Sample acceptance at the write clock edge.
  always @(posedge wclk) begin
    if (wrst_n && winc && !wfull) begin
      expected.push_back(wdata);
      writes = writes + 1;
    end
  end

  // Read scoreboard:
  // Async-read memory: sample data before
  // the read pointer changes at this edge.
  always @(posedge rclk) begin
    if (rrst_n && rinc && !rempty) begin
      if (expected.size() == 0) begin
        $error("Unexpected read: scoreboard empty");
        errors = errors + 1;
      end else begin
        item = expected.pop_front();

        if (rdata !== item) begin
          $error("Read mismatch: got=%02h expected=%02h",
                 rdata, item);
          errors = errors + 1;
        end
        reads = reads + 1;
      end
    end
  end

  // Drive signals on falling edges to avoid races.
  task write_byte(input [DATAWIDTH-1:0] data);
    begin
      @(negedge wclk);
      wdata = data;
      winc = 1;
      @(negedge wclk);
      winc = 0;
    end
  endtask

  task read_byte;
    begin
      @(negedge rclk);
      rinc = 1;
      @(negedge rclk);
      rinc = 0;
    end
  endtask

  task wait_full;
    integer t;
    begin
      t = 0;
      while (!wfull && t < 100) begin
        @(negedge wclk);
        t = t + 1;
      end
      if (!wfull)
        $fatal(1, "Timeout waiting for FULL");
    end
  endtask

  task wait_empty;
    integer t;
    begin
      t = 0;
      while (!rempty && t < 100) begin
        @(negedge rclk);
        t = t + 1;
      end
      if (!rempty)
        $fatal(1, "Timeout waiting for EMPTY");
    end
  endtask

  integer i;

  initial begin
    $dumpfile("async_fifo.vcd");
    $dumpvars(0, tb_afifo);

    // Reset both clock domains
    repeat (5) @(negedge wclk);
    wrst_n = 1;
    rrst_n = 1;

    repeat (5) @(negedge rclk);

    if (!rempty || wfull)
      $fatal(1, "Incorrect reset flags");

    // TEST 1: Fill FIFO
    $display("[TEST 1] Fill FIFO");

    for (i = 0; i < DEPTH; i = i + 1)
      write_byte(i + 8'h20);

    wait_full();

    if (expected.size() != DEPTH)
      $fatal(1, "Incorrect FIFO occupancy");

    // TEST 2: Overflow attempt
    $display("[TEST 2] Overflow protection");

    repeat (4)
      write_byte(8'hFF);

    if (expected.size() != DEPTH)
      $fatal(1, "Overflow changed occupancy");

    // TEST 3: Drain FIFO
    $display("[TEST 3] Drain FIFO");

    for (i = 0; i < DEPTH; i = i + 1)
      read_byte();

    wait_empty();

    if (expected.size() != 0)
      $fatal(1, "FIFO not completely drained");

    // TEST 4: Underflow attempt
    $display("[TEST 4] Underflow protection");

    repeat (4)
      read_byte();

    if (expected.size() != 0)
      $fatal(1, "Underflow changed occupancy");

    // TEST 5: Concurrent randomized traffic
    $display("[TEST 5] Concurrent random traffic");

    fork
      begin : writer
        repeat (500) begin
          @(negedge wclk);
          winc  = ($urandom_range(0, 3) != 0);
          wdata = $urandom;
        end
        @(negedge wclk);
        winc = 0;
      end

      begin : reader
        repeat (500) begin
          @(negedge rclk);
          rinc = ($urandom_range(0, 3) != 0);
        end
        @(negedge rclk);
        rinc = 0;
      end
    join

    // Drain remaining data
    // Wait for pointer synchronization.
    repeat (5) @(negedge rclk);

    while (!rempty)
      read_byte();

    wait_empty();

    if (expected.size() != 0)
      $fatal(1, "Scoreboard contains unread data");

    if (errors == 0)
      $display("PASS: writes=%0d reads=%0d",
               writes, reads);
    else
      $fatal(1, "FAIL: %0d errors", errors);

    $finish;
  end

  initial begin
    #200000;
    $fatal(1, "Global simulation timeout");
  end

endmodule
