`default_nettype none

module swapio_fetch (
  input  logic        clk_i,
  input  logic        rst_n,
  input  logic        run_i,
  input  logic [8:0]  pc_i,
  input  logic        instruction_retire_i,

  output logic        fetch_en_o,
  output logic [8:0]  fetch_addr_o,
  input  logic [15:0] instr_data_i,

  output logic [15:0] insn_o,
  output logic        execute_en_o
);
endmodule

`default_nettype wire
