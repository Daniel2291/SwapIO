//
//
//

module swapio_gpio #(
    parameter int WIDTH = 8
)(
    input logic           clk_i,
    input logic           rst_n,

    input logic   [WIDTH-1:0]  pad_in_i, //physical input pads
    output logic  [WIDTH-1:0]  pad_out_o,
    output logic  [WIDTH-1:0]  pad_oe_o,
    output logic  [WIDTH-1:0]  pad_in_o, 

    input logic                out_we_i,
    input logic  [WIDTH-1:0]  out_mask_i,
    input logic  [WIDTH-1:0]  out_data_i,

    input logic               dir_we_i,
    input logic  [WIDTH-1:0]  dir_mask_i,
    input logic  [WIDTH-1:0]  dir_data_i

);

    logic [WIDTH-1:0] in_meta_q, in_sync_q; // 2FF 
    logic [WIDTH-1:0] out_q, dir_q;

    always_ff @(posedge clk_i or negedge rst_n) begin
        if (!rst_n) begin
            in_meta_q <= '0;
            in_sync_q <= '0;
            out_q <= '0;
            dir_q <= '0;
        end else begin
            in_meta_q <= pad_in_i;   //FF meta
            in_sync_q <= in_meta_q;  //FF synced
            out_q <= (out_we_i) ? ((out_q & ~out_mask_i) | (out_data_i & out_mask_i)) : out_q;
            dir_q <= (dir_we_i) ? ((dir_q & ~dir_mask_i) | (dir_data_i & dir_mask_i)) : dir_q;
        end
    end

    assign pad_in_o = in_sync_q;
    assign pad_out_o = out_q;
    assign pad_oe_o = dir_q;

endmodule