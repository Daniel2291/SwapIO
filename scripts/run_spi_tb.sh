#!/usr/bin/env bash
set -euo pipefail
mkdir -p build
# Run from the SwapIO repository root; adjust FIFO path if necessary.
FIFO_DIR=${FIFO_DIR:-afifo_prj}
RTL_DIR=${RTL_DIR:-src/bus}
for mode in 0 1 2 3; do
  iverilog -g2012 -Wall -s tb_spi_controller -Ptb_spi_controller.MODE="$mode" \
    -o build/spi_mode${mode}.vvp \
    "$RTL_DIR/spi_controller_slave.v" \
    "$FIFO_DIR"/*.v \
    test/bus/tb_spi_controller.sv
  vvp build/spi_mode${mode}.vvp
done
