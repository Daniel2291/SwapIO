module swapio_register_file#()(
  input logic         clk_i,
  input logic         rst_n,

  input logic         w_en_i,

  input logic  [2:0 ] r_addr1_i,
  input logic  [2:0 ] r_addr2_i,

  input logic  [2:0 ] w_addr_i,

  input logic  [31:0] data_i,
  output logic [31:0] data1_o,
  output logic [31:0] data2_o
);

//WARN: synthesize as FF
logic [31:0]  gpr_m[0:7];

always_ff @(posedge clk_i, negedge rst_n) begin 
  if (!rst_n) begin
    //NOTE: Consider removing the reset, 
    //      since it might be taking too many FF
    for (integer i = 0; i < 8; i = i + 1) begin
      gpr_m[i] <= 32'b0;
    end
  end else if (w_en_i) begin
    gpr_m[w_addr_i] <= data_i;
  end
end

assign data1_o = gpr_m[r_addr1_i];
assign data2_o = gpr_m[r_addr2_i];

endmodule
