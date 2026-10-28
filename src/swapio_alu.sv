module swapio_alu
    import swapio_pkg::*;
(
    input  logic [31:0] src1_i,
    input  logic [31:0] src2_i,
    input  alu_func_t   alu_op_i,

    output logic [31:0] result_o,
    output logic [3:0]  flags_o
);

    logic [32:0] diff;
    logic [31:0] test_result;

    always_comb begin
        result_o    = '0;
        flags_o     = '0;

        diff = {1'b0, src1_i} - {1'b0, src2_i};
        test_result = src1_i & src2_i;

        case (alu_op_i)
            ALU_DEC: begin
                result_o = src1_i - 32'd1;
            end

            ALU_INC: begin
                result_o = src1_i + 32'd1;
            end

            ALU_XOR: begin
                result_o = src1_i ^ src2_i;
            end

            ALU_AND: begin
                result_o = src1_i & src2_i;
            end

            ALU_OR: begin
                result_o = src1_i | src2_i;
            end

            ALU_SHL: begin
                result_o = src1_i << src2_i[4:0];
            end

            ALU_SHR: begin
                result_o = src1_i >> src2_i[4:0];
            end

            ALU_CMP: begin
                flags_o[FLAGS_Z_LSB] = (diff[31:0] == 32'd0);
                flags_o[FLAGS_N_LSB] = diff[31];
                flags_o[FLAGS_C_LSB] = ~diff[32];
                flags_o[FLAGS_V_LSB] =
                    (src1_i[31] ^ src2_i[31]) &
                    (src1_i[31] ^ diff[31]);
            end

            ALU_BTST: begin
                flags_o[FLAGS_Z_LSB] = (test_result == 32'd0);
                flags_o[FLAGS_N_LSB] = test_result[31];
            end

            default: begin
            end
        endcase
    end

endmodule
