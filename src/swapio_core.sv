`default_nettype none
// SwapIO milestone 0: compact, synthesizable GPIO sequencer.
// Implemented ISA: JMP (unconditional), WAIT GPIO, SET GPIO/X/Y/OE.
// All other opcodes deliberately raise sticky fault and stop execution.
module swapio_core (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        bus_valid,
  input  logic        bus_write,
  input  logic [7:0]  bus_addr,
  input  logic [31:0] bus_wdata,
  output logic        bus_ready,
  output logic [31:0] bus_rdata,

  input  logic [7:0]  gpio_in,
  output logic [7:0]  gpio_out,
  output logic [7:0]  gpio_oe
);
  // reg [15:0] imem [0:31];

  // Program Counter
  // 9 bits
  logic [8:0] pc, pc_next;

  logic execute_en; // is the execute enabled
  logic instruction_retire; // shall we retire the instruction

  logic [15:0] insn; // TODO update to use the SRAM memory

  // TODO
  // implement
  swapio_fetch swapio_fetch(
    .clk_i(clk),
    .rst_n(rst_n),

    .insn_o(insn),
    .execute_en_o(execute_en)
  );

  swapio_execute exec_m(
    .clk_i(clk),
    .rst_n(rst_n),
    .insn_i(insn),
    .pc_i(pc),

    .execute_en_i(execute_en),
    .pc_next_o(pc_next),

    .instruction_retire_o(instruction_retire),

    .gpio_in(gpio_in),
    .gpio_out(gpio_out),
    .gpio_oe(gpio_oe)
  );

  always @* begin

  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pc      <= 9'd0;
      pc_next <= 9'd0;
    end else if (instruction_retire) begin
      pc      <= pc_next;
    end
  end
endmodule
`default_nettype wire
