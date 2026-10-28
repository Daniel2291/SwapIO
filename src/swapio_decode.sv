module swapio_decode import swapio_pkg::*; (
    input logic [15:0] instr_i,
    output logic [2:0] src_o,
    output logic [2:0] dst_o,
    output logic [2:0] pin_o,
    output logic [15:0] imm_o,
    output logic [15:0] addr_o,
    output logic [7:0] mask_o,
    output logic clr_o,
    output logic wait_o,
    output logic block_o,
    output logic [5:0] operation_o,
    output logic valid_o
);

    logic [3:0] opcode;
    assign opcode = instr_i[15:12];

    logic func1;
    assign func1 = instr_i[11];

    logic [1:0] func2;
    assign func2 = instr_i[11:10];

    logic [2:0] func3;
    assign func3 = instr_i[11:9];

    logic [3:0] func4;
    assign func4 = instr_i[11:8];

    always_comb begin
        src_o = '0;
        dst_o = '0;
        pin_o = '0;
        imm_o = '0;
        addr_o = '0;
        mask_o = '0;
        clr_o = '0;
        wait_o = '0;
        block_o = '0;
        operation_o = '0; // Only meaningful when valid_o is high
        valid_o = '0;

        case (opcode)
            OPCODE_SYS: begin
                case (func2)
                    SYS_NOP: begin
                        valid_o = 1'b1;
                        operation_o = INSTR_NOP;
                    end

                    SYS_IRQ: begin
                        valid_o = 1'b1;
                        operation_o = INSTR_IRQ;
                        clr_o = instr_i[9 -: 1];
                        wait_o = instr_i[8 -: 1];
                        imm_o = {11'b0, instr_i[7 -: 5]};
                    end
                    default: ;
                endcase
            end

            OPCODE_BRANCH: begin
                case (func2)
                    BRANCH_JMP: begin
                        valid_o = 1'b1;
                        operation_o = INSTR_JMP;
                        addr_o = {7'b0, instr_i[9 -: 9]};
                    end

                    BRANCH_JZ: begin
                        valid_o = 1'b1;
                        operation_o = INSTR_JZ;
                        addr_o = {7'b0, instr_i[9 -: 9]};
                    end

                    BRANCH_JNZ: begin
                        valid_o = 1'b1;
                        operation_o = INSTR_JNZ;
                        addr_o = {7'b0, instr_i[9 -: 9]};
                    end
                    default: ;
                endcase
            end

            OPCODE_SET: begin
                valid_o = 1'b1;
                operation_o = INSTR_SET;
                dst_o = instr_i[11 -: 3];
                imm_o = {8'b0, instr_i[8 -: 8]};
            end

            OPCODE_MOV: begin
                valid_o = 1'b1;
                operation_o = INSTR_MOV;
                dst_o = instr_i[11 -: 3];
                src_o = instr_i[8 -: 3];
            end

            OPCODE_SHIFT_REG: begin
                case (func1)
                    SHIFT_REG_IN: begin
                        valid_o = 1'b1;
                        operation_o = INSTR_IN;
                        pin_o = instr_i[10 -: 3];
                        imm_o = {11'b0, instr_i[7 -: 5]};
                    end

                    SHIFT_REG_OUT: begin
                        valid_o = 1'b1;
                        operation_o = INSTR_OUT;
                        pin_o = instr_i[10 -: 3];
                        imm_o = {11'b0, instr_i[7 -: 5]};
                    end
                    default: ;
                endcase
            end

            OPCODE_FIFO: begin
                case (func1)
                    FIFO_PUSH: begin
                        valid_o = 1'b1;
                        operation_o = INSTR_PUSH;
                        wait_o = instr_i[10 -: 1];
                    end

                    FIFO_PULL: begin
                        valid_o = 1'b1;
                        operation_o = INSTR_PULL;
                        wait_o = instr_i[10 -: 1];
                    end
                    default: ;
                endcase
            end

            OPCODE_WAIT: begin
                case (func1)
                    WAIT_LOW: begin
                        valid_o = 1'b1;
                        operation_o = INSTR_WAIT_LOW;
                        pin_o = instr_i[5 -: 3];
                    end

                    WAIT_HIGH: begin
                        valid_o = 1'b1;
                        operation_o = INSTR_WAIT_HIGH;
                        pin_o = instr_i[5 -: 3];
                    end
                    default: ;
                endcase
            end

            OPCODE_PIN: begin
                case (func3)
                    PIN_SET: begin
                        valid_o = 1'b1;
                        operation_o = INSTR_PIN_SET;
                        mask_o = instr_i[8 -: 8];
                    end

                    PIN_CLEAR: begin
                        valid_o = 1'b1;
                        operation_o = INSTR_PIN_CLEAR;
                        mask_o = instr_i[8 -: 8];
                    end

                    PIN_DIR: begin
                        valid_o = 1'b1;
                        operation_o = INSTR_PIN_DIR;
                        mask_o = instr_i[8 -: 8];
                    end

                    PIN_READ: begin
                        valid_o = 1'b1;
                        operation_o = INSTR_PIN_READ;
                        dst_o = instr_i[8 -: 3];
                        pin_o = instr_i[5 -: 3];
                    end

                    PIN_WRITE: begin
                        valid_o = 1'b1;
                        operation_o = INSTR_PIN_WRITE;
                        src_o = instr_i[8 -: 3];
                        pin_o = instr_i[5 -: 3];
                    end
                    default: ;
                endcase
            end

            OPCODE_WAIT_CYCLES: begin
                valid_o = 1'b1;
                operation_o = INSTR_WAIT_CYCLES;
                imm_o = {4'b0, instr_i[11 -: 12]};
            end

            OPCODE_ALU: begin
                case (func4)
                    ALU_DEC: begin
                        valid_o = 1'b1;
                        operation_o = INSTR_DEC;
                        dst_o = instr_i[7 -: 3];
                        src_o = instr_i[4 -: 3];
                    end

                    ALU_INC: begin
                        valid_o = 1'b1;
                        operation_o = INSTR_INC;
                        dst_o = instr_i[7 -: 3];
                        src_o = instr_i[4 -: 3];
                    end

                    ALU_XOR: begin
                        valid_o = 1'b1;
                        operation_o = INSTR_XOR;
                        dst_o = instr_i[7 -: 3];
                        src_o = instr_i[4 -: 3];
                    end

                    ALU_AND: begin
                        valid_o = 1'b1;
                        operation_o = INSTR_AND;
                        dst_o = instr_i[7 -: 3];
                        src_o = instr_i[4 -: 3];
                    end

                    ALU_OR: begin
                        valid_o = 1'b1;
                        operation_o = INSTR_OR;
                        dst_o = instr_i[7 -: 3];
                        src_o = instr_i[4 -: 3];
                    end

                    ALU_SHL: begin
                        valid_o = 1'b1;
                        operation_o = INSTR_SHL;
                        dst_o = instr_i[7 -: 3];
                        src_o = instr_i[4 -: 3];
                    end

                    ALU_SHR: begin
                        valid_o = 1'b1;
                        operation_o = INSTR_SHR;
                        dst_o = instr_i[7 -: 3];
                        src_o = instr_i[4 -: 3];
                    end

                    ALU_CMP: begin
                        valid_o = 1'b1;
                        operation_o = INSTR_CMP;
                        dst_o = instr_i[7 -: 3];
                        src_o = instr_i[4 -: 3];
                    end

                    ALU_BTST: begin
                        valid_o = 1'b1;
                        operation_o = INSTR_BTST;
                        dst_o = instr_i[7 -: 3];
                        src_o = instr_i[4 -: 3];
                    end
                    default: ;
                endcase
            end

            OPCODE_ALU_IMM: begin
                case (func3)
                    ALU_IMM_XORI: begin
                        valid_o = 1'b1;
                        operation_o = INSTR_XORI;
                        dst_o = instr_i[8 -: 3];
                        imm_o = {10'b0, instr_i[5 -: 6]};
                    end

                    ALU_IMM_ANDI: begin
                        valid_o = 1'b1;
                        operation_o = INSTR_ANDI;
                        dst_o = instr_i[8 -: 3];
                        imm_o = {10'b0, instr_i[5 -: 6]};
                    end

                    ALU_IMM_ORI: begin
                        valid_o = 1'b1;
                        operation_o = INSTR_ORI;
                        dst_o = instr_i[8 -: 3];
                        imm_o = {10'b0, instr_i[5 -: 6]};
                    end

                    ALU_IMM_SHLI: begin
                        valid_o = 1'b1;
                        operation_o = INSTR_SHLI;
                        dst_o = instr_i[8 -: 3];
                        imm_o = {10'b0, instr_i[5 -: 6]};
                    end

                    ALU_IMM_SHRI: begin
                        valid_o = 1'b1;
                        operation_o = INSTR_SHRI;
                        dst_o = instr_i[8 -: 3];
                        imm_o = {10'b0, instr_i[5 -: 6]};
                    end

                    ALU_IMM_CMPI: begin
                        valid_o = 1'b1;
                        operation_o = INSTR_CMPI;
                        dst_o = instr_i[8 -: 3];
                        imm_o = {10'b0, instr_i[5 -: 6]};
                    end

                    ALU_IMM_BTSTI: begin
                        valid_o = 1'b1;
                        operation_o = INSTR_BTSTI;
                        dst_o = instr_i[8 -: 3];
                        imm_o = {10'b0, instr_i[5 -: 6]};
                    end
                    default: ;
                endcase
            end

            OPCODE_CSR_RW: begin
                case (func2)
                    CSR_RW_CSRR: begin
                        valid_o = 1'b1;
                        operation_o = INSTR_CSRR;
                        dst_o = instr_i[9 -: 3];
                        addr_o = {9'b0, instr_i[6 -: 7]};
                    end

                    CSR_RW_CSRW: begin
                        valid_o = 1'b1;
                        operation_o = INSTR_CSRW;
                        src_o = instr_i[9 -: 3];
                        addr_o = {9'b0, instr_i[6 -: 7]};
                    end
                    default: ;
                endcase
            end

            OPCODE_LDST: begin
                case (func2)
                    LDST_LOAD: begin
                        valid_o = 1'b1;
                        operation_o = INSTR_LOAD;
                        dst_o = instr_i[9 -: 3];
                        addr_o = {9'b0, instr_i[6 -: 7]};
                    end

                    LDST_STORE: begin
                        valid_o = 1'b1;
                        operation_o = INSTR_STORE;
                        src_o = instr_i[9 -: 3];
                        addr_o = {9'b0, instr_i[6 -: 7]};
                    end
                    default: ;
                endcase
            end
            default: ;
        endcase
    end
endmodule
