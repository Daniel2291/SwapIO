`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.03.2026 14:30:34
// Design Name: 
// Module Name: sync_w2r
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


module sync_w2r #(
 parameter ADDRSIZE = 4
 )(
  input      [ADDRSIZE:0] wptr,
  input                   rclk, rrst_n,
  output reg [ADDRSIZE:0] rwptr2
 );
  reg [ADDRSIZE:0] rwptr1;
  
  always @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n)  {rwptr2, rwptr1}  <= 0;
    else          {rwptr2, rwptr1}  <= {rwptr1, wptr};
  end  
  

endmodule
