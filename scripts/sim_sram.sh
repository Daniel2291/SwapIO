#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
MODEL_DIR="macro/sram/verilog"
iverilog -g2012 -DFUNCTIONAL -s tb_sram_512x16 -o build/tb_sram_512x16.vvp \
  src/swio_instr_mem.v \
  "$MODEL_DIR/RM_IHPSG13_1P_512x16_c2_bm_bist.v" \
  "$MODEL_DIR/RM_IHPSG13_1P_core_behavioral_bm_bist.v" \
  test/tb_sram_512x16.sv
vvp build/tb_sram_512x16.vvp