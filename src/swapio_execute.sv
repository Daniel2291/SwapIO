module swapio_execute import swapio_pkg::*; #()(
  input logic        clk_i,
  input logic        rst_n,

  input logic [15:0] insn_i,
  input logic        pc_i
);

  logic [2:0]        src_operand;
  logic [2:0]        dst_operand;
  logic [2:0]        pin_operand;
  logic [15:0]       imm_operand;
  logic [15:0]       addr_operand;
  logic [7:0]        mask_operand;
  logic              clr_operand;
  logic              wait_operand;
  logic              block_operand;
  logic [5:0]        operation_operand;
  logic              valid_operand;

  logic              csr_w_en;

  /////////////////////////////////////////////////////////
  //    ____ ____    ____            _     _             //
  //   / ___/ ___|  |  _ \ ___  __ _(_)___| |_ ___ _ __  //
  //  | |   \___ \  | |_) / _ \/ _` | / __| __/ _ \ '__| //
  //  | |___ ___) | |  _ <  __/ (_| | \__ \ ||  __/ |    //
  //   \____|____/  |_| \_\___|\__, |_|___/\__\___|_|    //
  //                           |___/                     //
  /////////////////////////////////////////////////////////

  logic [1:0]       sys_ctrl_reg;
  logic [8:0]       sys_status_reg;
  logic [31:0]      osr;
  logic [31:0]      isr;

  //NOTE: PC is defined in swapio_core

  // GPIO registers
  logic [7:0]       gpio_out_reg;     // RO
  logic [7:0]       gpio_oe_reg;      // RO
  logic [7:0]       gpio_in_reg;      // RO

  logic [31:0]      cycle_count_reg;
  logic [3:0]       flags_reg;
  logic [9:0]       fifo_status_reg;

  /////////////////////////////////////////////
  //   ____                     _            //
  //  |  _ \  ___  ___ ___   __| | ___ _ __  //
  //  | | | |/ _ \/ __/ _ \ / _` |/ _ \ '__| //
  //  | |_| |  __/ (_| (_) | (_| |  __/ |    //
  //  |____/ \___|\___\___/ \__,_|\___|_|    //
  //                                         //
  /////////////////////////////////////////////

  swapio_decode decoder_m(
    insn_i, 
    src_operand, 
    dst_operand, 
    pin_operand, 
    imm_operand, 
    addr_operand, 
    mask_operand, 
    clr_operand, 
    wait_operand, 
    block_operand, 
    operation_operand, 
    valid_operand
  );

  /////////////////////////////////////////////////////
  //   _______  __  ____ _____  _    ____ _____      //
  //  | ____\ \/ / / ___|_   _|/ \  / ___| ____|     //
  //  |  _|  \  /  \___ \ | | / _ \| |  _|  _|       //
  //  | |___ /  \   ___) || |/ ___ \ |_| | |___      //
  //  |_____/_/\_\ |____/ |_/_/   \_\____|_____|     //
  //                                                 //
  /////////////////////////////////////////////////////

  always_comb begin : blockName
    case (operation_operand)
      INSTR_NOP: begin

      end

      INSTR_IRQ: begin

      end

      INSTR_JMP: begin

      end

      INSTR_JZ: begin

      end

      INSTR_JNZ: begin

      end

      INSTR_SET: begin

      end

      INSTR_MOV: begin

      end

      INSTR_IN: begin

      end

      INSTR_OUT: begin

      end

      INSTR_PUSH: begin

      end

      INSTR_PULL: begin

      end

      INSTR_WAIT_LOW: begin

      end

      INSTR_WAIT_HIGH: begin

      end

      INSTR_PIN_SET: begin

      end

      INSTR_PIN_CLEAR: begin

      end

      INSTR_PIN_DIR: begin

      end

      INSTR_PIN_READ: begin

      end

      INSTR_PIN_WRITE: begin

      end

      INSTR_WAIT_CYCLES: begin

      end

      INSTR_DEC: begin

      end

      INSTR_INC: begin

      end

      INSTR_XOR: begin

      end

      INSTR_AND: begin

      end

      INSTR_SHL: begin

      end

      INSTR_SHR: begin

      end

      INSTR_CMP: begin

      end

      INSTR_BTST: begin

      end

      INSTR_XORI: begin

      end

      INSTR_ANDI: begin

      end

      INSTR_SHLI: begin

      end

      INSTR_SHRI: begin

      end

      INSTR_CMPI: begin

      end

      INSTR_BTSTI: begin

      end

      INSTR_CSRR: begin

      end

      INSTR_CSRW: begin

      end

      INSTR_LOAD: begin

      end

      INSTR_STORE: begin

      end
      default: begin
      end
    endcase
  end

  // Handles R/W to the CSR registers
  swapio_csr csr_m(
    .clk_i(clk_i),
    .rst_n(rst_n),

    .addr_i(addr_operand),
    .w_enable_i(csr_w_en),

    .w_data_i(),
    .r_data_o(),
    .pc_i(pc_i)
  );

  // handles R/W to the GPR (general purpose registers)
  swapio_register_file   reg_file_m(
    .clk_i(clk_i),
    .rst_n(rst_n),

    .w_en_i(),
    .r_addr1_i(),
    .r_addr2_i(),

    .w_addr_i(),

    .data_i(),
    .data1_o(),
    .data2_o()
  );

endmodule
