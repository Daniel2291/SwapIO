`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.03.2026 08:16:01
// Design Name: 
// Module Name: async_fifo_axis
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


module async_fifo_axis#(
  parameter DATA_WIDTH = 8,
  parameter ADDRSIZE   = 4
)(
  //AXI Slave (write side)
  input                  s_axis_clk,
  input                  s_axis_areset_n,
  input [DATA_WIDTH-1:0] s_axis_tdata,
  input                  s_axis_tvalid,
  output                 s_axis_tready,
  
  //AXI Master (read side)
  input                   m_axis_clk,
  input                   m_axis_areset_n,
  output [DATA_WIDTH-1:0] m_axis_tdata,
  output                  m_axis_tvalid,
  input                   m_axis_tready
 
);

  (* mark_debug = "true" *) wire wfull, rempty;
  wire winc,  rinc;
  
  //AXI FIFO map
  assign s_axis_tready = ~wfull;
  assign winc          = s_axis_tvalid & s_axis_tready;
  
  assign m_axis_tvalid = ~rempty;
  assign rinc          = m_axis_tvalid & m_axis_tready;
  
  async_fifo #(
    .DATAWIDTH(DATA_WIDTH),
    .ADDRSIZE(ADDRSIZE)
  ) fifo (
    .wdata(s_axis_tdata),
    .winc(winc),
    .wclk(s_axis_clk),
    .wrst_n(s_axis_areset_n),

    .rinc(rinc),
    .rclk(m_axis_clk),
    .rrst_n(m_axis_areset_n),

    .rdata(m_axis_tdata),
    .wfull(wfull),
    .rempty(rempty)
  );
  
endmodule
