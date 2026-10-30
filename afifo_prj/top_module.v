`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 
// Design Name: 
// Module Name: tb_async_fifo_axis
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



module top_module#(
    parameter DATA_WIDTH = 8
)(
    input  board_clk,
    input  board_reset_n
);

wire clk_100M, clk_75M;
wire locked;

`ifdef SIMULATION
    reg clk_100M_r = 0;
    reg clk_75M_r  = 0;
    reg locked_r   = 0;

    always #5      clk_100M_r = ~clk_100M_r;
    always #6.666  clk_75M_r  = ~clk_75M_r;

    initial begin
        locked_r = 1'b0;
        #100;
        locked_r = 1'b1;
    end

    assign clk_100M = clk_100M_r;
    assign clk_75M  = clk_75M_r;
    assign locked   = locked_r;
`else
    clk_wiz_0 clkgen (
        .clk_100M(clk_100M),
        .clk_75M (clk_75M),
        .reset   (1'b0),
        .locked  (locked),
        .clk_in1 (board_clk)
    );
`endif


//Reset sync------------------------------------------------------- 

reg [1:0] rst_w_sync, rst_r_sync;


wire global_reset_n = ~board_reset_n & locked;  //board button is active high, so board reset is inverted

always @(posedge clk_100M or negedge global_reset_n) begin
    if (!global_reset_n)
        rst_w_sync <= 2'b00;
    else
        rst_w_sync <= {rst_w_sync[0], 1'b1};
end

always @(posedge clk_75M or negedge global_reset_n) begin
    if (!global_reset_n)
        rst_r_sync <= 2'b00;
    else
        rst_r_sync <= {rst_r_sync[0], 1'b1};
end

wire s_axis_areset_n = rst_w_sync[1];
wire m_axis_areset_n = rst_r_sync[1];

//AXIS connections------------------------------------------------------- 

(* mark_debug = "true" *) wire [DATA_WIDTH-1:0] s_axis_tdata;
(* mark_debug = "true" *) wire       s_axis_tvalid;
(* mark_debug = "true" *) wire       s_axis_tready;

(* mark_debug = "true" *) wire [DATA_WIDTH-1:0] m_axis_tdata;
(* mark_debug = "true" *) wire       m_axis_tvalid;
(* mark_debug = "true" *) wire       m_axis_tready;

(* mark_debug = "true" *) wire winc = s_axis_tvalid & s_axis_tready;
(* mark_debug = "true" *) wire rinc = m_axis_tvalid & m_axis_tready;


//Write data generator------------------------------------------------------- 

(* mark_debug = "true", dont_touch = "true" *) reg [DATA_WIDTH-1:0] wr_data_counter;

always @(posedge clk_100M or negedge s_axis_areset_n) begin
    if (!s_axis_areset_n)
        wr_data_counter <= {DATA_WIDTH{1'b0}};
    else if (winc)
        wr_data_counter <= wr_data_counter + 1'b1;
end

assign s_axis_tdata = wr_data_counter;


// Synchronize read handshakes into write clock domain------------------------------------------------------- 

reg rinc_toggle_r;

always @(posedge clk_75M or negedge m_axis_areset_n) begin
    if (!m_axis_areset_n)
        rinc_toggle_r <= 1'b0;
    else if (rinc)
        rinc_toggle_r <= ~rinc_toggle_r;
end

reg [2:0] rinc_sync_w;

always @(posedge clk_100M or negedge s_axis_areset_n) begin
    if (!s_axis_areset_n)
        rinc_sync_w <= 3'b000;
    else
        rinc_sync_w <= {rinc_sync_w[1:0], rinc_toggle_r};
end

wire rinc_pulse_w = rinc_sync_w[2] ^ rinc_sync_w[1];

// External occupancy counter in write domain------------------------------------------------------- 

(* mark_debug = "true", dont_touch = "true" *) reg [5:0] occ_count_w;

always @(posedge clk_100M or negedge s_axis_areset_n) begin
    if (!s_axis_areset_n) begin
        occ_count_w <= 6'd0;
    end else begin
        case ({winc, rinc_pulse_w})
            2'b10: occ_count_w <= occ_count_w + 6'd1;
            2'b01: occ_count_w <= occ_count_w - 6'd1;
            default: occ_count_w <= occ_count_w;
        endcase
    end
end


// Simple phase FSM in write clock domain------------------------------------------------------- 

localparam ST_NORMAL20 = 3'd0;
localparam ST_DRAIN1   = 3'd1;
localparam ST_FILL20   = 3'd2;
localparam ST_DRAIN2   = 3'd3;

(* mark_debug = "true", dont_touch = "true" *) reg [2:0] state_w;
(* mark_debug = "true", dont_touch = "true" *) reg [5:0] write_goal_cnt_w;
(* mark_debug = "true", dont_touch = "true" *) reg [3:0] drain_idle_cnt_w;

// number of successful writes in NORMAL20 and FILL20 phases
localparam [5:0] TARGET_WRITES = 6'd20;

// wait a few write-clock cycles after empty before switching phase
localparam [3:0] DRAIN_IDLE_THRESHOLD = 4'd8;

always @(posedge clk_100M or negedge s_axis_areset_n) begin
    if (!s_axis_areset_n) begin
        state_w          <= ST_NORMAL20;
        write_goal_cnt_w <= 6'd0;
        drain_idle_cnt_w <= 4'd0;
    end else begin
        case (state_w)

            ST_NORMAL20: begin
                drain_idle_cnt_w <= 4'd0;

                if (winc) begin
                    write_goal_cnt_w <= write_goal_cnt_w + 6'd1;
                    if (write_goal_cnt_w == TARGET_WRITES - 1) begin
                        state_w          <= ST_DRAIN1;
                        write_goal_cnt_w <= 6'd0;
                    end
                end
            end

            ST_DRAIN1: begin
                if (occ_count_w == 6'd0) begin
                    drain_idle_cnt_w <= drain_idle_cnt_w + 4'd1;
                    if (drain_idle_cnt_w == DRAIN_IDLE_THRESHOLD - 1) begin
                        state_w          <= ST_FILL20;
                        write_goal_cnt_w <= 6'd0;
                        drain_idle_cnt_w <= 4'd0;
                    end
                end else begin
                    drain_idle_cnt_w <= 4'd0;
                end
            end

            ST_FILL20: begin
                drain_idle_cnt_w <= 4'd0;

                if (winc) begin
                    write_goal_cnt_w <= write_goal_cnt_w + 6'd1;
                    if (write_goal_cnt_w == TARGET_WRITES - 1) begin
                        state_w          <= ST_DRAIN2;
                        write_goal_cnt_w <= 6'd0;
                    end
                end
            end

            ST_DRAIN2: begin
                if (occ_count_w == 6'd0) begin
                    drain_idle_cnt_w <= drain_idle_cnt_w + 4'd1;
                    if (drain_idle_cnt_w == DRAIN_IDLE_THRESHOLD - 1) begin
                        state_w          <= ST_NORMAL20;
                        write_goal_cnt_w <= 6'd0;
                        drain_idle_cnt_w <= 4'd0;
                    end
                end else begin
                    drain_idle_cnt_w <= 4'd0;
                end
            end

            default: begin
                state_w          <= ST_NORMAL20;
                write_goal_cnt_w <= 6'd0;
                drain_idle_cnt_w <= 4'd0;
            end
        endcase
    end
end

// Synchronize phase into read domain------------------------------------------------------- 

reg [2:0] state_r1, state_r2;

always @(posedge clk_75M or negedge m_axis_areset_n) begin
    if (!m_axis_areset_n) begin
        state_r1 <= ST_NORMAL20;
        state_r2 <= ST_NORMAL20;
    end else begin
        state_r1 <= state_w;
        state_r2 <= state_r1;
    end
end

// AXIS source/sink behavior per phase------------------------------------------------------- 

reg s_axis_tvalid_r;
reg m_axis_tready_r;

always @(posedge clk_100M or negedge s_axis_areset_n) begin
    if (!s_axis_areset_n) begin
        s_axis_tvalid_r <= 1'b0;
    end else begin
        case (state_w)
            ST_NORMAL20: s_axis_tvalid_r <= 1'b1; // write while reads also enabled
            ST_DRAIN1:   s_axis_tvalid_r <= 1'b0; // stop writes
            ST_FILL20:   s_axis_tvalid_r <= 1'b1; // write only
            ST_DRAIN2:   s_axis_tvalid_r <= 1'b0; // stop writes
            default:     s_axis_tvalid_r <= 1'b0;
        endcase
    end
end

always @(posedge clk_75M or negedge m_axis_areset_n) begin
    if (!m_axis_areset_n) begin
        m_axis_tready_r <= 1'b0;
    end else begin
        case (state_r2)
            ST_NORMAL20: m_axis_tready_r <= 1'b1; // normal simultaneous flow
            ST_DRAIN1:   m_axis_tready_r <= 1'b1; // drain
            ST_FILL20:   m_axis_tready_r <= 1'b0; // block reads
            ST_DRAIN2:   m_axis_tready_r <= 1'b1; // drain
            default:     m_axis_tready_r <= 1'b0;
        endcase
    end
end

assign s_axis_tvalid = s_axis_tvalid_r;
assign m_axis_tready = m_axis_tready_r;


// DUT
async_fifo_axis fifo_inst (
    .s_axis_clk      (clk_100M),
    .s_axis_areset_n (s_axis_areset_n),
    .s_axis_tdata    (s_axis_tdata),
    .s_axis_tvalid   (s_axis_tvalid),
    .s_axis_tready   (s_axis_tready),

    .m_axis_clk      (clk_75M),
    .m_axis_areset_n (m_axis_areset_n),
    .m_axis_tdata    (m_axis_tdata),
    .m_axis_tvalid   (m_axis_tvalid),
    .m_axis_tready   (m_axis_tready)
);

// Read-side capture for ILA

(* mark_debug = "true", dont_touch = "true" *) reg [DATA_WIDTH-1:0] dbg_m_axis_tdata;

always @(posedge clk_75M or negedge m_axis_areset_n) begin
    if (!m_axis_areset_n)
        dbg_m_axis_tdata <= {DATA_WIDTH{1'b0}};
    else if (rinc)
        dbg_m_axis_tdata <= m_axis_tdata;
end

endmodule