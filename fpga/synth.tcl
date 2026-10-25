# From repository root: vivado -mode batch -source fpga/synth.tcl
set part xc7z020clg400-1
set top swapio_fpga_demo
if {[info exists ::env(TARGET_TOP)]} {set top $::env(TARGET_TOP)}
file mkdir build/fpga
read_verilog src/swapio_core.v fpga/swapio_fpga_demo.v
if {$top eq "swapio_fpga_demo"} {read_xdc fpga/pynq_z2_demo.xdc}
synth_design -top $top -part $part
report_utilization -file build/fpga/utilization.rpt
report_timing_summary -file build/fpga/timing_synth.rpt
write_checkpoint -force build/fpga/synth.dcp
if {$top eq "swapio_fpga_demo"} {
  opt_design
  place_design
  route_design
  report_timing_summary -file build/fpga/timing_route.rpt
  write_bitstream -force build/fpga/swapio_demo.bit
}
