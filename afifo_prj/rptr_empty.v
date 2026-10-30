`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.03.2026 11:21:52
// Design Name: 
// Module Name: wptr_full
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

//read clk domain
module rptr_empty#(
   parameter ADDRSIZE = 4
 )(
   input      [ADDRSIZE:0] rwptr2,
   input      rinc, rclk, rrst_n,
   output     [ADDRSIZE-1:0] raddr,
   output reg [ADDRSIZE:0]   rptr,
   output reg rempty
  
 );
   reg raddrmsb;
   reg [ADDRSIZE:0]rbin, rgnext, rbnext;
   
   //greyscale pointer
   always @(posedge rclk or negedge rrst_n) begin
     if (!rrst_n) begin 
       rptr     <= 0;
       raddrmsb <= 0;
     end else begin 
       rptr     <= rgnext;
       raddrmsb <= rgnext[ADDRSIZE]^rgnext[ADDRSIZE-1];  //converts the two MSBs of gray pointer into binary MSB, as mem address must be binary
     end
   end
     
   always @(*) begin: gray_inc   // use * not only specifie signals
     integer i;
     for (i=0; i<=ADDRSIZE; i=i+1)
        rbin[i] = ^(rptr>>i);               //gray to binary conversion
     if (!rempty) rbnext = rbin + rinc;
     else         rbnext = rbin;
     rgnext = (rbnext>>1)^rbnext;           //binary to gray conversion
   end
   
   //memory read-address pointer
   assign raddr = {raddrmsb, rptr[ADDRSIZE-2:0]};  // trick to avoid a full Gray to binary conversion
   
   //FIFO empty on rst or when rptr == sync wptr
   always @(posedge rclk or negedge rrst_n) begin
     if (!rrst_n)  rempty <= 1'b1;
     else          rempty <= (rgnext == rwptr2);
   end  
    
endmodule
