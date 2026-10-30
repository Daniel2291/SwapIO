`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.03.2026 14:11:45
// Design Name: 
// Module Name: sync_r2w
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


module sync_r2w#(
  parameter ADDRSIZE = 4
 )(
  input      [ADDRSIZE:0] rptr,
  input               wclk, wrst_n,
  output reg [ADDRSIZE:0] wrptr2
 );
  reg [ADDRSIZE:0] wrptr1;
  
  always @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n)  {wrptr2, wrptr1}  <= 0;
    else          {wrptr2, wrptr1}  <= {wrptr1, rptr};
  end  
  
endmodule
