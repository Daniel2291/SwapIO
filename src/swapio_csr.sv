module swapio_csr import swapio_kg::*; #()(
  input logic         clk_i,
  input logic         rst_n,

  input logic  [5:0]  addr_i,
  input logic         w_enable_i,

  input logic  [31:0] w_data_i,
  output logic [31:0] r_data_o,

  input logic  [8:0]  pc_i,

  input logic  [1:0]  sys_ctrl_i,
  input logic  [8:0]  sys_status_i,
  input logic  [31:0] osr_i,
  input logic  [31:0] isr_i,
   
  // GPIO registers
  input logic  [7:0]  gpio_out_i,
  input logic  [7:0]  gpio_oe_i,
  input logic  [7:0]  gpio_in_i,
  output logic [7:0]  gpio_od_mask_o,
   
  input logic [31:0] cycle_count_i,
  input logic [3:0] flags_i,
  input logic [9:0] fifo_status_i,
   
  output logic [15:0] clk_div_o,
  output logic [31:0] clk_cfg_o
);

  logic [15:0] clk_div_reg;
  logic [31:0] clk_cfg_reg;
  logic [7:0] gpio_od_mask_reg;

  assign clk_div_o = clk_div_reg;
  assign clk_cfg_o = clk_cfg_reg;
  assign gpio_od_mask_o = gpio_od_mask_reg;

  // writing is clock gated, reading is combinational
  always_ff @(posedge clk_i or negedge rst_n) begin
    if (!rst_n) begin
      clk_div_reg          <=  'd0;
      clk_cfg_reg          <=  'd0;
      gpio_od_mask_reg     <=  'd0;
    end else if (w_enable_i) begin
      case (addr_i)
        CSR_OD_MASK: begin
          gpio_od_mask_reg <= w_data_i[7:0];
        end
        CSR_CLK_DIV: begin
          clk_div_reg <= w_data_i[15:0];
        end
        CSR_CLK_CFG: begin
          clk_cfg_reg <= w_data_i[31:0];
        end
        default: begin
          // maybe raise an exception
        end
      endcase
    end
  end
  always_comb begin
    case (arr_i)
      CSR_SYS_CTRL: begin
        r_data_o = sys_ctrl_i;
      end
      CSR_SYS_STATUS: begin
        r_data_o = sys_status_i;
      end
      CSR_OSR: begin
        r_data_o = osr_i;
      end
      CSR_ISR: begin
        r_data_o = isr_i;
      end
      CSR_PC: begin
        r_data_o = pc_i;
      end
      CSR_GPIO_OUT: begin
        r_data_o = gpio_out_i;
      end
      CSR_GPIO_OE: begin
        r_data_o = gpio_oe_i;
      end
      CSR_GPIO_IN: begin
        r_data_o = gpio_in_i;
      end
      CSR_OD_MASK: begin
        r_data_o = gpio_od_mask_reg;
      end
      CSR_CYCLE_COUNT: begin
        r_data_o = cycle_count_i;
      end
      CSR_FLAGS: begin
        r_data_o = flags_i;
      end
      CSR_FIFO_STATUS: begin
        r_data_o = fifo_status_i;
      end
      CSR_CLK_DIV: begin
        r_data_o = clk_div_reg;
      end
      CSR_CLK_CFG: begin
        r_data_o = clk_cfg_reg;
      end
      default: begin
        // maybe raise an exception
      end
    endcase
  end
endmodule
