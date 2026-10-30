`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.03.2026 21:13:06
// Design Name: 
// Module Name: fifo_memory
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


module fifo_memory#(
  parameter DATAWIDTH = 8,       //memory data word width
  parameter ADDRSIZE  = 4,       //number of mem addr bits 
  parameter DEPTH = 1<<ADDRSIZE  //2^ADDRSIZE
)(
  input  wclk, wclk_en,
  input [DATAWIDTH-1:0] wr_data,
  input [ADDRSIZE-1:0]  wr_addr, rd_addr,
  
  output [DATAWIDTH-1:0] rd_data
 );
 
  reg [DATAWIDTH-1:0] mem [0:DEPTH-1];
  assign rd_data = mem[rd_addr];
  
  always @(posedge wclk) begin
     if (wclk_en)   mem[wr_addr] <= wr_data;
  end
  
endmodule
