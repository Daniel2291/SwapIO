
`default_nettype none

module swio_instr_mem (
    input  wire        clk,
    input  wire        rst_n,

    // SwapIO instruction fetch
    input  wire        fetch_en,
    input  wire [8:0]  fetch_addr,
    output wire [15:0] instr_data,

    // Host instruction memory programming, should check what bis is used
    input  wire        wr_en,
    input  wire [8:0]  wr_addr,
    input  wire [15:0] wr_data
);

    // Single-port SRAM: host writes take priority
    wire [8:0] sram_addr;

    assign sram_addr = wr_en ? wr_addr : fetch_addr;

    RM_IHPSG13_1P_512x16_c2_bm_bist u_sram (
        .A_CLK       (clk),
        .A_MEN       (rst_n && (wr_en || fetch_en)),
        .A_WEN       (wr_en),
        .A_REN       (fetch_en && !wr_en),

        .A_ADDR      (sram_addr),
        .A_DIN       (wr_data),
        .A_DOUT      (instr_data),

        .A_BM        (16'hFFFF),
        .A_DLY       (1'b1),

        // Disable built-in self-test
        .A_BIST_CLK  (1'b0),
        .A_BIST_EN   (1'b0),
        .A_BIST_MEN  (1'b0),
        .A_BIST_WEN  (1'b0),
        .A_BIST_REN  (1'b0),
        .A_BIST_ADDR (9'b0),
        .A_BIST_DIN  (16'b0),
        .A_BIST_BM   (16'b0)
    );

endmodule

`default_nettype wire
