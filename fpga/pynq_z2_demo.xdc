# PYNQ-Z2 125 MHz board clock, LED0, pushbutton BTN0 active-high.
# Verify your specific board revision's XDC before programming.
set_property -dict { PACKAGE_PIN H16 IOSTANDARD LVCMOS33 } [get_ports clk125]
create_clock -name board_clk -period 8.000 [get_ports clk125]
set_property -dict { PACKAGE_PIN R14 IOSTANDARD LVCMOS33 } [get_ports led0]
# BTN0 is active-high: demo wrapper inverts it to active-low core reset.
set_property -dict { PACKAGE_PIN D19 IOSTANDARD LVCMOS33 } [get_ports btn0]
