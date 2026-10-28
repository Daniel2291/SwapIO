module swapio_decode import swapio_pkg::*; (
    input logic [15:0] instr_i,

    output logic  [2:0]  src_o,
    output logic  [2:0]  dst_o,
    output logic  [2:0]  pin_o,
    output logic  [15:0] imm_o,
    output logic  [15:0] addr_o,
    output logic  [7:0]  mask_o,
    output logic  [5:0]  operation_o
);

    logic [3:0] opcode;
    assign opcode = instr_i[15:12];

    logic       func1;
    assign func1 = instr_i[11];

    logic [1:0] func2;
    assign func2 = instr_i[11:10];

    logic [2:0] func3;
    assign func3 = instr_i[11:9];

    logic [3:0] func4;
    assign func4 = instr_i[11:8];

    logic [2:0]  src_d;
    logic [2:0]  dst_d;
    logic [2:0]  pin_d;
    logic [15:0] imm_d;
    logic [15:0] addr_d;
    logic [7:0]  mask_d;
    logic        clr_d;
    logic        wait_d;
    logic        block_d;

    // Combinational instruction decoder
    always_comb begin
        src_d   = 3'd0;
        dst_d   = 3'd0;
        pin_d   = 3'd0;
        imm_d   = 16'd0;
        addr_d  = 16'd0;
        mask_d  = 8'd0;
        clr_d   = 1'b0;
        wait_d  = 1'b0;
        block_d = 1'b0;

        case (opcode)
            OPCODE_SYS: begin
                case (func2)
                    // NOP
                    2'b00: begin
                        // No operand fields
                    end

                    // IRQ
                    2'b01: begin
                        clr_d = instr_i[9 -: 1];
                        wait_d = instr_i[8 -: 1];
                        imm_d = instr_i[7 -: 5];
                    end
                    default: begin
                        // Unsupported function
                    end
                endcase
            end

            OPCODE_BRANCH: begin
                case (func2)
                    // JMP
                    2'b00: begin
                        addr_d = instr_i[9 -: 9];
                    end

                    // JZ
                    2'b01: begin
                        addr_d = instr_i[9 -: 9];
                    end

                    // JNZ
                    2'b10: begin
                        addr_d = instr_i[9 -: 9];
                    end
                    default: begin
                        // Unsupported function
                    end
                endcase
            end

            OPCODE_SET: begin
                // SET
                dst_d = instr_i[11 -: 3];
                imm_d = instr_i[8 -: 8];
            end

            OPCODE_MOV: begin
                // MOV
                dst_d = instr_i[11 -: 3];
                src_d = instr_i[8 -: 3];
            end

            OPCODE_SHIFT_REG: begin
                case (func1)
                    // IN
                    1'b0: begin
                        pin_d = instr_i[10 -: 3];
                        imm_d = instr_i[7 -: 5];
                    end

                    // OUT
                    1'b1: begin
                        pin_d = instr_i[10 -: 3];
                        imm_d = instr_i[7 -: 5];
                    end
                    default: begin
                        // Unsupported function
                    end
                endcase
            end

            OPCODE_FIFO: begin
                case (func1)
                    // PUSH
                    1'b0: begin
                        wait_d = instr_i[10 -: 1];
                    end

                    // PULL
                    1'b1: begin
                        wait_d = instr_i[10 -: 1];
                    end
                    default: begin
                        // Unsupported function
                    end
                endcase
            end

            OPCODE_WAIT: begin
                case (func1)
                    // WAIT_LOW
                    1'b0: begin
                        pin_d = instr_i[5 -: 3];
                    end

                    // WAIT_HIGH
                    1'b1: begin
                        pin_d = instr_i[5 -: 3];
                    end
                    default: begin
                        // Unsupported function
                    end
                endcase
            end

            OPCODE_PIN: begin
                case (func3)
                    // PIN_SET
                    3'b000: begin
                        mask_d = instr_i[8 -: 9];
                    end

                    // PIN_CLEAR
                    3'b001: begin
                        mask_d = instr_i[8 -: 9];
                    end

                    // PIN_DIR
                    3'b010: begin
                        mask_d = instr_i[8 -: 9];
                    end

                    // PIN_READ
                    3'b011: begin
                        dst_d = instr_i[8 -: 3];
                        pin_d = instr_i[5 -: 3];
                    end

                    // PIN_WRITE
                    3'b100: begin
                        src_d = instr_i[8 -: 3];
                        pin_d = instr_i[5 -: 3];
                    end
                    default: begin
                        // Unsupported function
                    end
                endcase
            end

            OPCODE_WAIT_CYCLES: begin
                // WAIT_CYCLES
                imm_d = instr_i[11 -: 12];
            end

            OPCODE_ALU: begin
                case (func4)
                    // DEC
                    4'b0000: begin
                        dst_d = instr_i[7 -: 3];
                        src_d = instr_i[4 -: 3];
                    end

                    // INC
                    4'b0001: begin
                        dst_d = instr_i[7 -: 3];
                        src_d = instr_i[4 -: 3];
                    end

                    // XOR
                    4'b0010: begin
                        dst_d = instr_i[7 -: 3];
                        src_d = instr_i[4 -: 3];
                    end

                    // AND
                    4'b0011: begin
                        dst_d = instr_i[7 -: 3];
                        src_d = instr_i[4 -: 3];
                    end

                    // OR
                    4'b0100: begin
                        dst_d = instr_i[7 -: 3];
                        src_d = instr_i[4 -: 3];
                    end

                    // SHL
                    4'b0101: begin
                        dst_d = instr_i[7 -: 3];
                        src_d = instr_i[4 -: 3];
                    end

                    // SHR
                    4'b0110: begin
                        dst_d = instr_i[7 -: 3];
                        src_d = instr_i[4 -: 3];
                    end

                    // CMP
                    4'b0111: begin
                        dst_d = instr_i[7 -: 3];
                        src_d = instr_i[4 -: 3];
                    end

                    // BTST
                    4'b1000: begin
                        dst_d = instr_i[7 -: 3];
                        src_d = instr_i[4 -: 3];
                    end
                    default: begin
                        // Unsupported function
                    end
                endcase
            end

            OPCODE_ALU_IMM: begin
                case (func3)
                    // XORI
                    3'b000: begin
                        dst_d = instr_i[8 -: 3];
                        imm_d = instr_i[5 -: 6];
                    end

                    // ANDI
                    3'b001: begin
                        dst_d = instr_i[8 -: 3];
                        imm_d = instr_i[5 -: 6];
                    end

                    // ORI
                    3'b010: begin
                        dst_d = instr_i[8 -: 3];
                        imm_d = instr_i[5 -: 6];
                    end

                    // SHLI
                    3'b011: begin
                        dst_d = instr_i[8 -: 3];
                        imm_d = instr_i[5 -: 6];
                    end

                    // SHRI
                    3'b100: begin
                        dst_d = instr_i[8 -: 3];
                        imm_d = instr_i[5 -: 6];
                    end

                    // CMPI
                    3'b101: begin
                        dst_d = instr_i[8 -: 3];
                        imm_d = instr_i[5 -: 6];
                    end

                    // BTSTI
                    3'b110: begin
                        dst_d = instr_i[8 -: 3];
                        imm_d = instr_i[5 -: 6];
                    end
                    default: begin
                        // Unsupported function
                    end
                endcase
            end

            OPCODE_CSR_RW: begin
                case (func2)
                    // CSRR
                    2'b00: begin
                        dst_d = instr_i[9 -: 3];
                        addr_d = instr_i[6 -: 7];
                    end

                    // CSRW
                    2'b01: begin
                        src_d = instr_i[9 -: 3];
                        addr_d = instr_i[6 -: 7];
                    end
                    default: begin
                        // Unsupported function
                    end
                endcase
            end

            OPCODE_LDST: begin
                case (func2)
                    // LOAD
                    2'b00: begin
                        dst_d = instr_i[9 -: 3];
                        addr_d = instr_i[6 -: 7];
                    end

                    // STORE
                    2'b01: begin
                        src_d = instr_i[9 -: 3];
                        addr_d = instr_i[6 -: 7];
                    end
                    default: begin
                        // Unsupported function
                    end
                endcase
            end

            default: begin
                // Unsupported opcode
            end
        endcase
    end

endmodule
