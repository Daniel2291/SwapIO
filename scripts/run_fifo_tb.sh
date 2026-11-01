#!/bin/bash
set -e

mkdir -p build

iverilog -g2012 \
    -s tb_afifo \
    -o build/fifo_sim \
    afifo_prj/async_fifo.v \
    afifo_prj/fifo_memory.v \
    afifo_prj/rptr_empty.v \
    afifo_prj/wptr_full.v \
    afifo_prj/sync_r2w.v \
    afifo_prj/sync_w2r.v \
    test/bus/tb_afifo.sv

vvp build/fifo_sim

gtkwave async_fifo.vcd