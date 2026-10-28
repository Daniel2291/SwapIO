package swapio_pkg;

 ////////////////////////////////////////////////
 //    ___         ____          _             //
 //   / _ \ _ __  / ___|___   __| | ___  ___   //
 //  | | | | '_ \| |   / _ \ / _` |/ _ \/ __|  //
 //  | |_| | |_) | |__| (_) | (_| |  __/\__ \  //
 //   \___/| .__/ \____\___/ \__,_|\___||___/  //
 //        |_|                                 //
 ////////////////////////////////////////////////

    localparam logic [3:0] OPCODE_SYS = 4'b0000;
    localparam logic [3:0] OPCODE_BRANCH = 4'b0001;
    localparam logic [3:0] OPCODE_SET = 4'b0010;
    localparam logic [3:0] OPCODE_MOV = 4'b0011;
    localparam logic [3:0] OPCODE_SHIFT_REG = 4'b0100;
    localparam logic [3:0] OPCODE_FIFO = 4'b0101;
    localparam logic [3:0] OPCODE_WAIT = 4'b0110;
    localparam logic [3:0] OPCODE_PIN = 4'b0111;
    localparam logic [3:0] OPCODE_WAIT_CYCLES = 4'b1000;
    localparam logic [3:0] OPCODE_ALU = 4'b1001;
    localparam logic [3:0] OPCODE_ALU_IMM = 4'b1010;
    localparam logic [3:0] OPCODE_CSR_RW = 4'b1011;
    localparam logic [3:0] OPCODE_LDST = 4'b1100;

    // Function codes
    typedef enum logic [1:0] {
        SYS_NOP = 2'b00,
        SYS_IRQ = 2'b01
    } sys_func_t;

    typedef enum logic [1:0] {
        BRANCH_JMP = 2'b00,
        BRANCH_JZ = 2'b01,
        BRANCH_JNZ = 2'b10
    } branch_func_t;

    typedef enum logic {
        SHIFT_REG_IN = 1'b0,
        SHIFT_REG_OUT = 1'b1
    } shift_reg_func_t;

    typedef enum logic {
        FIFO_PUSH = 1'b0,
        FIFO_PULL = 1'b1
    } fifo_func_t;

    typedef enum logic {
        WAIT_LOW = 1'b0,
        WAIT_HIGH = 1'b1
    } wait_func_t;

    typedef enum logic [2:0] {
        PIN_SET = 3'b000,
        PIN_CLEAR = 3'b001,
        PIN_DIR = 3'b010,
        PIN_READ = 3'b011,
        PIN_WRITE = 3'b100
    } pin_func_t;

    typedef enum logic [3:0] {
        ALU_DEC = 4'b0000,
        ALU_INC = 4'b0001,
        ALU_XOR = 4'b0010,
        ALU_AND = 4'b0011,
        ALU_OR = 4'b0100,
        ALU_SHL = 4'b0101,
        ALU_SHR = 4'b0110,
        ALU_CMP = 4'b0111,
        ALU_BTST = 4'b1000
    } alu_func_t;

    typedef enum logic [2:0] {
        ALU_IMM_XORI = 3'b000,
        ALU_IMM_ANDI = 3'b001,
        ALU_IMM_ORI = 3'b010,
        ALU_IMM_SHLI = 3'b011,
        ALU_IMM_SHRI = 3'b100,
        ALU_IMM_CMPI = 3'b101,
        ALU_IMM_BTSTI = 3'b110
    } alu_imm_func_t;

    typedef enum logic [1:0] {
        CSR_RW_CSRR = 2'b00,
        CSR_RW_CSRW = 2'b01
    } csr_rw_func_t;

    typedef enum logic [1:0] {
        LDST_LOAD = 2'b00,
        LDST_STORE = 2'b01
    } ldst_func_t;

    //NOTE: we might not use this depending on how we implement execute
    // Unique instruction IDs (independent of raw opcode/function)
    typedef enum logic [5:0] {
        INSTR_NOP = 6'd0,
        INSTR_IRQ = 6'd1,
        INSTR_JMP = 6'd2,
        INSTR_JZ = 6'd3,
        INSTR_JNZ = 6'd4,
        INSTR_SET = 6'd5,
        INSTR_MOV = 6'd6,
        INSTR_IN = 6'd7,
        INSTR_OUT = 6'd8,
        INSTR_PUSH = 6'd9,
        INSTR_PULL = 6'd10,
        INSTR_WAIT_LOW = 6'd11,
        INSTR_WAIT_HIGH = 6'd12,
        INSTR_PIN_SET = 6'd13,
        INSTR_PIN_CLEAR = 6'd14,
        INSTR_PIN_DIR = 6'd15,
        INSTR_PIN_READ = 6'd16,
        INSTR_PIN_WRITE = 6'd17,
        INSTR_WAIT_CYCLES = 6'd18,
        INSTR_DEC = 6'd19,
        INSTR_INC = 6'd20,
        INSTR_XOR = 6'd21,
        INSTR_AND = 6'd22,
        INSTR_OR = 6'd23,
        INSTR_SHL = 6'd24,
        INSTR_SHR = 6'd25,
        INSTR_CMP = 6'd26,
        INSTR_BTST = 6'd27,
        INSTR_XORI = 6'd28,
        INSTR_ANDI = 6'd29,
        INSTR_ORI = 6'd30,
        INSTR_SHLI = 6'd31,
        INSTR_SHRI = 6'd32,
        INSTR_CMPI = 6'd33,
        INSTR_BTSTI = 6'd34,
        INSTR_CSRR = 6'd35,
        INSTR_CSRW = 6'd36,
        INSTR_LOAD = 6'd37,
        INSTR_STORE = 6'd38
    } operation_t;

/////////////////////////////////////////////////////////
//    ____ ____    ____            _     _             //
//   / ___/ ___|  |  _ \ ___  __ _(_)___| |_ ___ _ __  //
//  | |   \___ \  | |_) / _ \/ _` | / __| __/ _ \ '__| //
//  | |___ ___) | |  _ <  __/ (_| | \__ \ ||  __/ |    //
//   \____|____/  |_| \_\___|\__, |_|___/\__\___|_|    //
//                           |___/                     //
/////////////////////////////////////////////////////////


    // CSR addresses
    typedef enum logic [4:0] {
        CSR_SYS_CTRL = 5'h00,
        CSR_SYS_STATUS = 5'h01,
        CSR_OSR = 5'h02,
        CSR_ISR = 5'h03,
        CSR_PC = 5'h04,
        CSR_GPIO_OUT = 5'h05,
        CSR_GPIO_OE = 5'h06,
        CSR_GPIO_IN = 5'h07,
        CSR_OD_MASK = 5'h08,
        CSR_CYCLE_COUNT = 5'h09,
        CSR_FLAGS = 5'h0A,
        CSR_FIFO_STATUS = 5'h0B,
        CSR_CLK_DIV = 5'h0C,
        CSR_CLK_CFG = 5'h0D
    } csr_addr_t;

endpackage
