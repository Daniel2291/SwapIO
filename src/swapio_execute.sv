module swapio_execute import swapio_pkg::*; #()(
  input logic         clk_i,
  input logic         rst_n,

  input logic  [15:0] insn_i,
  input logic  [8: 0] pc_i,

  input  logic        execute_en_i,
  output logic [8: 0] pc_next_o,

  output logic        instruction_retire_o,

  input  logic [7: 0] gpio_in,
  output logic [7: 0] gpio_out,
  output logic [7: 0] gpio_oe
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
  logic [31:0]       csr_data_o;

  logic [31:0]       reg_file_data_i;
  logic              reg_file_w_en;
  alu_func_t         alu_op;
  logic [3:0]        alu_flags;
  logic              alu_flags_w_en;

  logic [31:0]       alu_src1;
  logic [31:0]       alu_src2;

  logic [31:0]       alu_value;

  logic [31:0]       reg_file_o1;
  logic [31:0]       reg_file_o2;


  logic              stall;

  // set at the end of the file
  logic reg_file_write_en;
  logic csr_write_en;
  logic flags_write_en;

  assign instruction_retire_o = execute_en_i && valid_operand && !stall;

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

  swapio_alu alu_m(
    alu_src1,
    alu_src2, 
    alu_op,

    alu_value,
    alu_flags
  );

  /////////////////////////////////////////////////////
  //   _______  __  ____ _____  _    ____ _____      //
  //  | ____\ \/ / / ___|_   _|/ \  / ___| ____|     //
  //  |  _|  \  /  \___ \ | | / _ \| |  _|  _|       //
  //  | |___ /  \   ___) || |/ ___ \ |_| | |___      //
  //  |_____/_/\_\ |____/ |_/_/   \_\____|_____|     //
  //                                                 //
  /////////////////////////////////////////////////////
  
  logic [11:0] wait_cycles_remaining_d, wait_cycles_remaining_q;
  logic wait_active_d, wait_active_q;

  always_ff @(posedge clk_i or negedge rst_n) begin
    if (!rst_n) begin
      cycle_count_reg <= 'b0;
      flags_reg       <= 'b0;
      wait_cycles_remaining_q <= 'b1;
      wait_active_q           <= 'b0;
    end else begin
      if (flags_write_en) begin
        flags_reg       <= alu_flags;
      end
      wait_cycles_remaining_q <= wait_cycles_remaining_d;
      wait_active_q           <= wait_active_d;
    end
  end

  assign stall = wait_active_d;

  always_comb begin : blockName
    reg_file_data_i = 'b0;
    reg_file_w_en   = 'b0;
    csr_w_en        = 'b0;
    alu_src1        = 'b0;
    alu_src2        = 'b0;
    alu_op          = ALU_DEC;
    alu_flags_w_en  = 'b0;
    pc_next_o       = pc_i + 'd1;

    wait_cycles_remaining_d = wait_cycles_remaining_q;
    wait_active_d           = wait_active_q;

    if (execute_en_i) begin
      if (!wait_active_d) begin
        case (operation_operand)
          INSTR_NOP: begin
            // we do nothing
          end

          INSTR_IRQ: begin
            // WARN:
            // Leave it for now
            // I cant think of a reason
            // why we would need it at the beginning
          end

          INSTR_JMP: begin
            pc_next_o  = addr_operand;
          end

          INSTR_JZ: begin
            pc_next_o = flags_reg[FLAGS_Z_LSB]? addr_operand : pc_i + 'd1;
          end

          INSTR_JNZ: begin
            pc_next_o = (!flags_reg[FLAGS_Z_LSB])? addr_operand : pc_i + 'd1;
          end

          INSTR_SET: begin
            reg_file_data_i = {16'b0, imm_operand};
            reg_file_w_en   = 1'b1;
          end

          INSTR_MOV: begin
            reg_file_data_i = reg_file_o1;
            reg_file_w_en   = 'b1;
          end

          INSTR_IN: begin
            //TODO need a synchronizer
            // gpio_out_i[pin_operand] =
          end

          INSTR_OUT: begin
            //TODO
          end

          INSTR_PUSH: begin
            /*
            * Push to the TX buffer
            */
            //TODO
          end

          INSTR_PULL: begin
            /*
            * Pull from the RX buffer
            */
            //TODO
          end

          INSTR_WAIT_LOW: begin
            // need a synchronizer
            //TODO
          end

          INSTR_WAIT_HIGH: begin
            // need a synchronizer
            //TODO
          end

          INSTR_PIN_SET: begin
            //TODO
          end

          INSTR_PIN_CLEAR: begin
            //TODO
          end

          INSTR_PIN_DIR: begin
            //TODO
          end

          INSTR_PIN_READ: begin
            //TODO need a synchronizer
            // gpio_out_i[pin_operand] =
          end

          INSTR_PIN_WRITE: begin
            //TODO
          end

          INSTR_WAIT_CYCLES: begin
            wait_cycles_remaining_d = imm_operand;
            wait_active_d           = imm_operand > 'b0;
          end

          INSTR_DEC: begin
            alu_op = ALU_DEC;

            alu_src1 = reg_file_o1;
            alu_src2 = reg_file_o2;

            reg_file_data_i = alu_value;
            reg_file_w_en   = 'b1;
          end

          INSTR_INC: begin
            alu_op = ALU_INC;

            alu_src1 = reg_file_o1;
            alu_src2 = reg_file_o2;

            reg_file_data_i = alu_value;
            reg_file_w_en   = 'b1;
          end

          INSTR_XOR: begin
            alu_op = ALU_XOR;

            alu_src1 = reg_file_o1;
            alu_src2 = reg_file_o2;

            reg_file_data_i = alu_value;
            reg_file_w_en   = 'b1;
          end

          INSTR_AND: begin
            alu_op = ALU_AND;

            alu_src1 = reg_file_o1;
            alu_src2 = reg_file_o2;

            reg_file_data_i = alu_value;
            reg_file_w_en   = 'b1;
          end

          INSTR_SHL: begin
            alu_op = ALU_SHL;

            alu_src1 = reg_file_o1;
            alu_src2 = reg_file_o2;

            reg_file_data_i = alu_value;
            reg_file_w_en   = 'b1;
          end

          INSTR_SHR: begin
            alu_op = ALU_SHR;

            alu_src1 = reg_file_o1;
            alu_src2 = reg_file_o2;

            reg_file_data_i = alu_value;
            reg_file_w_en   = 'b1;
          end

          INSTR_CMP: begin
            alu_op = ALU_CMP;

            alu_src1 = reg_file_o2;
            alu_src2 = reg_file_o1;

            reg_file_data_i = alu_value;
            alu_flags_w_en  = 'b1;
          end

          INSTR_BTST: begin
            alu_op = ALU_BTST;

            alu_src1 = reg_file_o1;
            alu_src2 = reg_file_o2;

            reg_file_data_i = alu_value;
            alu_flags_w_en  = 'b1;
          end

          INSTR_XORI: begin
            alu_op = ALU_XOR;

            alu_src1 = imm_operand;
            alu_src2 = reg_file_o2;

            reg_file_data_i = alu_value;
            reg_file_w_en   = 'b1;
          end

          INSTR_ANDI: begin
            alu_op = ALU_AND;

            alu_src1 = imm_operand;
            alu_src2 = reg_file_o2;

            reg_file_data_i = alu_value;
            reg_file_w_en   = 'b1;
          end

          INSTR_SHLI: begin
            alu_op = ALU_SHL;

            alu_src1 = reg_file_o2;
            alu_src2 = {16'b0, imm_operand};

            reg_file_data_i = alu_value;
            reg_file_w_en   = 'b1;
          end

          INSTR_SHRI: begin
            alu_op = ALU_SHR;

            alu_src1 = reg_file_o2;
            alu_src2 = {16'b0, imm_operand};

            reg_file_data_i = alu_value;
            reg_file_w_en   = 'b1;
          end

          INSTR_CMPI: begin
            alu_op = ALU_CMP;

            alu_src1 = reg_file_o2;
            alu_src2 = {16'b0, imm_operand};

            reg_file_data_i = alu_value;
            alu_flags_w_en  = 'b1;
          end

          INSTR_BTSTI: begin
            alu_op = ALU_BTST;

            alu_src1 = imm_operand;
            alu_src2 = reg_file_o2;

            reg_file_data_i = alu_value;
            alu_flags_w_en  = 'b1;
          end

          INSTR_CSRR: begin
            reg_file_data_i = csr_data_o;
            reg_file_w_en   = 'b1;
          end

          INSTR_CSRW: begin
            csr_w_en          = 'b1;
          end

          INSTR_LOAD: begin
            /* WARN:
            * FOR FUTURE
            */
          end

          INSTR_STORE: begin
            /* WARN:
            * FOR FUTURE
            */
          end
          default: begin
          end
        endcase
      end else begin
          if (wait_cycles_remaining_d > 'b0) begin
            wait_cycles_remaining_d = wait_cycles_remaining_d - 'b1;
          end
          wait_active_d = wait_cycles_remaining_d > 'b0;
      end
    end
  end

  // Handles R/W to the CSR registers
  swapio_csr csr_m(
    .clk_i(clk_i),
    .rst_n(rst_n),

    .addr_i(addr_operand),
    .w_enable_i(csr_write_en),

    .w_data_i(reg_file_o1),
    .r_data_o(csr_data_o),
    .pc_i(pc_i),

    .sys_ctrl_i(sys_ctrl_reg),
    .sys_status_i(sys_status_reg),
    .osr_i(osr),
    .isr_i(isr),
    .gpio_out_i(gpio_out_reg),
    .gpio_oe_i(gpio_oe_reg),
    .gpio_in_i(gpio_in_reg),
    .gpio_od_mask_o(), //TODO: maybe expose to outside module
    .cycle_count_i(cycle_count_reg),
    .flags_i(flags_reg),
    .fifo_status_i(fifo_status_reg),
    .clk_div_o(),      //TODO: maybe expose to outside module
    .clk_cfg_o()       //TODO: maybe expose to outside module
  );

  // handles R/W to the GPR (general purpose registers)
  swapio_register_file   reg_file_m(
    .clk_i(clk_i),
    .rst_n(rst_n),

    .w_en_i(reg_file_write_en),
    .r_addr1_i(src_operand),
    .r_addr2_i(dst_operand),

    .w_addr_i(dst_operand),

    .data_i(reg_file_data_i),
    .data1_o(reg_file_o1),
    .data2_o(reg_file_o2)
  );

  assign reg_file_write_en = instruction_retire_o && reg_file_w_en;
  assign csr_write_en      = instruction_retire_o && csr_w_en;
  assign flags_write_en    = instruction_retire_o && alu_flags_w_en;

endmodule
