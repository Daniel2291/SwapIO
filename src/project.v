`default_nettype none
// Tiny Tapeout wrapper for SwapIO.
module tt_um_swapio (
// GPIO signals
//
//Used for the SPI-Host communication
    input wire [7:0]  ui_in,              // Dedicated inputs
    output wire [7:0] uo_out,             // Dedicated outputs
//

//Used for communicating with other devices
    input wire [7:0]  uio_in,             // IOs: Input path
    output wire [7:0] uio_out,            // IOs: Output path
    output wire [7:0] uio_oe,             // IOs: Enable path (active high: 0=input, 1=output)
//
    input wire        ena,                // always 1 when the design is powered, so you can ignore
    input wire        clk,                // System clock
    input wire        rst_n               // reset_n - low to reset
);
  wire gpio_uio_in_synchronized;

  //synchronize the uio_in signal
  swapio_gpio_sync gpio_sync (
    .clk_i(clk),

    .uio_in_i(uio_in),
    .gpio_uio_in_synchronized_o(gpio_uio_in_synchronized)
  );

  swapio_core u_core (
    .clk(clk),
    .rst_n(rst_n),

    .gpio_uio_in(gpio_uio_in_synchronized),
    .gpio_uio_out(uio_out),
    .gpio_uio_oe(uio_oe)
  );

  wire unused_inputs = &{ena, 1'b0};
endmodule
`default_nettype wire
