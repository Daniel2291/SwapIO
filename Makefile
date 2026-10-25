IVERILOG ?= iverilog
VVP ?= vvp
VERILATOR ?= verilator
VIVADO ?= vivado
YOSYS ?= yosys
.PHONY: sim sim-tt lint fpga-synth asic-generic clean
sim:
	mkdir -p build
	$(IVERILOG) -g2005 -Wall -s tb_swapio_core -o build/tb_core.vvp src/swapio_core.v sim/tb_swapio_core.v
	$(VVP) build/tb_core.vvp
sim-tt:
	mkdir -p build
	$(IVERILOG) -g2005 -Wall -s tb_swapio_tt -o build/tb_tt.vvp src/swapio_core.v src/project.v sim/tb_swapio_tt.v
	$(VVP) build/tb_tt.vvp
lint:
	$(VERILATOR) --lint-only -Wall -Wno-fatal --top-module tt_um_swapio src/swapio_core.v src/project.v
fpga-synth:
	$(VIVADO) -mode batch -source fpga/synth.tcl
asic-generic:
	mkdir -p build
	$(YOSYS) -s asic/generic_synth.ys
clean:
	rm -rf build .Xil vivado*.log vivado*.jou
