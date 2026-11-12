`default_nettype none
module swapio_gpio_sync #(
  parameter int unsigned WIDTH = 8
)(
  input logic clk_i,

  input  logic [WIDTH-1:0] gpio_async_i,
  output logic [WIDTH-1:0] gpio_sync_o
);
  // WARNING: Before tapeout, check the ASIC flow's synchronizer identification
  // and CDC timing constraints. Preserve both stages and allow sufficient
  // settling time between them; do not assume FPGA ASYNC_REG attributes apply.
  logic [WIDTH-1:0] synchronizer[1:0];

  always_ff @(posedge clk_i) begin
    synchronizer[0] <= gpio_async_i;
    synchronizer[1] <= synchronizer[0];
  end

  assign gpio_sync_o = synchronizer[1];

endmodule
