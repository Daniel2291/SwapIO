`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.03.2026 16:32:19
// Design Name: 
// Module Name: async_fifo
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


module async_fifo #(
  parameter DATAWIDTH = 8,
  parameter ADDRSIZE  = 4
 )(
  input  [DATAWIDTH-1:0] wdata,
  input                  winc, wclk, wrst_n,
  input                  rinc, rclk, rrst_n,
  
  output [DATAWIDTH-1:0] rdata,
  output                 wfull,
  output                 rempty

 );
  wire [ADDRSIZE-1:0] waddr, raddr;
  wire [ADDRSIZE:0]   wptr, rptr, wrptr2, rwptr2;
  
  sync_r2w sync_r2w(
    .wrptr2(wrptr2),
    .rptr(rptr),
    .wclk(wclk),
    .wrst_n(wrst_n)
  );
  
  sync_w2r sync_w2r(
    .rwptr2(rwptr2),
    .wptr(wptr),
    .rclk(rclk),
    .rrst_n(rrst_n)
  );
  
  fifo_memory #(
    .DATAWIDTH(DATAWIDTH),
    .ADDRSIZE(ADDRSIZE)
   )fifo_memory(
    .rd_data(rdata),
    .wr_data(wdata),
    .rd_addr(raddr),
    .wr_addr(waddr),
    .wclk_en(winc),
    .wclk(wclk)
  );
  
  rptr_empty #(
    .ADDRSIZE(ADDRSIZE)
   ) rptr_empty(
    .rempty(rempty),
    .raddr(raddr),
    .rptr(rptr),
    .rwptr2(rwptr2),
    .rinc(rinc),
    .rclk(rclk),
    .rrst_n(rrst_n)
  );
  
  wptr_full #(
    .ADDRSIZE(ADDRSIZE)
   ) wptr_full(
    .wfull(wfull),
    .waddr(waddr),
    .wptr(wptr),
    .wrptr2(wrptr2),
    .winc(winc),
    .wclk(wclk),
    .wrst_n(wrst_n)
  );
    
endmodule
