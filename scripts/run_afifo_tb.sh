#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
if [[ ! -s src/bus/afifo.v ]]; then
  echo 'Missing src/bus/afifo.v; download the original ZipCPU source first.' >&2
  exit 1
fi
iverilog -g2012 -s tb_afifo -Wall -o build/afifo_tb \
  src/bus/afifo.v test/bus/tb_afifo.sv
vvp build/afifo_tb
echo 'Waveform: build/afifo.vcd'
