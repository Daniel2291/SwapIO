`default_nettype none
// SwapIO milestone 0: compact, synthesizable GPIO sequencer.
// Implemented ISA: JMP (unconditional), WAIT GPIO, SET GPIO/X/Y/OE.
// All other opcodes deliberately raise sticky fault and stop execution.
module swapio_core (
  input  wire        clk,
  input  wire        rst_n,
  input  wire        bus_valid,
  input  wire        bus_write,
  input  wire [7:0]  bus_addr,
  input  wire [31:0] bus_wdata,
  output wire        bus_ready,
  output reg  [31:0] bus_rdata,
  input  wire [7:0]  gpio_in,
  output reg  [7:0]  gpio_out,
  output reg  [7:0]  gpio_oe
);
  reg [15:0] imem [0:31];

  // TODO: below will be removed
  reg [31:0] x, y;
  reg running, fault, sideset_enable;
  reg [31:0] divider, divider_count;
  reg [2:0] delay_count;
  wire [15:0] insn = imem[pc]; // combinational-read memory, LUT/mux implementation
  wire [2:0] arg = insn[7:5];
  wire [4:0] imm = insn[4:0];
  wire [1:0] sideset = insn[12:11];
  wire [2:0] delay_val = insn[10:8];
  wire tick = running && (divider_count == divider - 32'd1);
  wire wait_pin = gpio_in[imm[2:0]];
  wire wait_ok = (wait_pin == arg[0]); // WAIT operand: bit5 polarity; pin in bits2:0
  wire bus_wr = bus_valid && bus_write;
  assign bus_ready = 1'b1; // zero wait states; read data combinational

  always @* begin
    bus_rdata = 32'd0;
    case (bus_addr)
      8'h00: bus_rdata = {31'd0, running};
      8'h04: bus_rdata = {23'd0, delay_count, pc, fault};
      8'h08: bus_rdata = divider;
      8'h0c: bus_rdata = {24'd0, gpio_out};
      8'h10: bus_rdata = {24'd0, gpio_oe};
      8'h14: bus_rdata = {24'd0, gpio_in};
      8'h18: bus_rdata = {31'd0, sideset_enable};
      default: begin
        if (bus_addr[7] && (bus_addr[1:0] == 2'b00))
          bus_rdata = {16'd0, imem[bus_addr[6:2]]};
      end
    endcase
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pc <= 5'd0;
      x <= 32'd0;
      y <= 32'd0;
      running <= 1'b0;
      fault <= 1'b0;
      divider <= 32'd1;
      divider_count <= 32'd0;
      delay_count <= 3'd0;
      sideset_enable <= 1'b0;
      gpio_out <= 8'd0;
      gpio_oe <= 8'd0;
    end else begin
      if (!running) divider_count <= 32'd0;
      else if (tick) divider_count <= 32'd0;
      else divider_count <= divider_count + 32'd1;

      // Program and configure ONLY while stopped. Bus master must obey this policy.
      if (bus_wr) begin
        case (bus_addr)
          8'h00: begin
            running <= bus_wdata[0];
            if (bus_wdata[1]) begin
              pc <= 5'd0;
              x <= 32'd0;
              y <= 32'd0;
              delay_count <= 3'd0;
              divider_count <= 32'd0;
              fault <= 1'b0;
            end
          end
          8'h08: if (!running) divider <= (bus_wdata == 0) ? 32'd1 : bus_wdata;
          8'h0c: if (!running) gpio_out <= bus_wdata[7:0];
          8'h10: if (!running) gpio_oe <= bus_wdata[7:0];
          8'h18: if (!running) sideset_enable <= bus_wdata[0];
          default: begin
            if (!running && bus_addr[7] && (bus_addr[1:0] == 2'b00))
              imem[bus_addr[6:2]] <= bus_wdata[15:0];
          end
        endcase
      end
      if (tick && !fault && !(bus_wr && bus_addr == 8'h00)) begin
        if (delay_count != 0) begin
          delay_count <= delay_count - 3'd1;
        end else begin
          case (opcode)
            3'b000: begin // JMP: only unconditional condition 000
              if (arg == 3'b000) begin
                pc <= imm;
                delay_count <= delay_val;
                if (sideset_enable) gpio_out[7:6] <= sideset;
              end else begin fault <= 1'b1; running <= 1'b0; end
            end
            3'b001: begin // WAIT: pins[2:0] and polarity bit5; other operand bits reserved
              if (arg[2:1] == 2'b00 && imm[4:3] == 2'b00) begin
                if (wait_ok) begin
                  pc <= pc + 5'd1;
                  delay_count <= delay_val;
                  if (sideset_enable) gpio_out[7:6] <= sideset;
                end
              end else begin fault <= 1'b1; running <= 1'b0; end
            end
            3'b111: begin // SET dest: 000 PINS, 001 X, 010 Y, 011 PINDIRS
              case (arg)
                3'b000: gpio_out <= sideset_enable ? {sideset, 1'b0, imm} : {3'b000, imm};
                3'b001: x <= {27'd0, imm};
                3'b010: y <= {27'd0, imm};
                3'b011: gpio_oe <= {3'd0, imm};
                default: begin fault <= 1'b1; running <= 1'b0; end
              endcase
              if (arg <= 3'b011) begin
                if (sideset_enable && arg != 3'b000) gpio_out[7:6] <= sideset;
                pc <= pc + 5'd1;
                delay_count <= delay_val;
              end
            end
            default: begin fault <= 1'b1; running <= 1'b0; end
          endcase
        end
      end
    end
  end
endmodule
`default_nettype wire
