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


module wptr_full#(
  parameter ADDRSIZE = 4
 )(
  input  [ADDRSIZE:0] wrptr2,
  input               winc, wclk, wrst_n,
  output reg wfull,
  output reg [ADDRSIZE:0]   wptr,
  output     [ADDRSIZE-1:0] waddr 
 );
  reg  [ADDRSIZE:0] wgnext, wbin, wbnext;
  reg  waddrmsb;
  
  //grayscale pointer
  always @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n) begin
      waddrmsb <= 0;
      wptr     <= 0;
    end else begin
      wptr     <= wgnext;
      waddrmsb <= wgnext[ADDRSIZE]^wgnext[ADDRSIZE-1];
    end
  end
  
  always @(*) begin: gray_inc
    integer i;
    for (i=0; i<=ADDRSIZE; i=i+1)
      wbin[i] = ^(wptr>>i);               //gray to binary conversion
    if(!wfull) wbnext = wbin + winc;
    else      wbnext = wbin;
    wgnext = (wbnext>>1)^wbnext;
   end
   
   //memory write address pointer
   assign waddr = {waddrmsb, wptr[ADDRSIZE-2:0]};
   
   wire w_2ndmsb  =  wgnext[ADDRSIZE] ^ wgnext[ADDRSIZE-1];
   wire wr_2ndmsb =  wrptr2[ADDRSIZE] ^ wrptr2[ADDRSIZE-1];
   always@(posedge wclk or negedge wrst_n) begin
     if(!wrst_n) wfull <= 0;
     else        wfull <= ((wgnext[ADDRSIZE]    !=wrptr2[ADDRSIZE]) &&
                           (w_2ndmsb            ==wr_2ndmsb      ) &&
                           (wgnext[ADDRSIZE-2:0]==wrptr2[ADDRSIZE-2:0]));
   end
      

endmodule
