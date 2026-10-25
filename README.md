# SwapIO

**Verilog-2001 only for RTL**, common PIO core for PYNQ-Z2 (Vivado) and Jane Street / Tiny Tapeout IHP CMOS5L (eventual ASIC). No SystemVerilog source files.

## First commands

```sh
sudo apt install iverilog verilator yosys make gtkwave
make sim
make sim-tt
make lint
make asic-generic
make fpga-synth  # Requires Vivado installed
```

`make sim` is the core instruction-sequence test; `make sim-tt` tests the Tiny Tapeout demonstrator boot. VCD files appear in `build/`.

## Layout

- `src/swapio_core.v`: portable synthesizable Verilog PIO milestone-0 core.
- `src/project.v`: TT-compatible pin interface; **autonomous demo**, not host-programmable yet.
- `src/config.json`: **draft placeholder**, replace with official `cmos5l` branch configuration.
- `info.yaml`: metadata with Jane Street `6x4` target. Author is intentionally blank.
- `sim/`: plain Verilog self-checking testbenches.
- `test/`: compatibility placeholders; use official Tiny Tapeout cocotb tests and CI when merging.
- `fpga/`: PYNQ-Z2 top-level, XDC, and scripted Vivado flow.
- `asic/`: generic Yosys sanity synthesis only; **not** IHP physical signoff.

## Integrating the official ASIC flow

Use the competition-linked `cmos5l` branch of https://github.com/TinyTapeout/ttihp-verilog-template as the authoritative starting point. It differs from the public default branch; `6x4` is competition-specific. Copy `src/swapio_core.v` and `src/project.v` into its `src/`, merge `info.yaml` metadata/source_files, retain the template's `src/config.json`, `test/` cocotb files, and `.github/workflows/` as appropriate. Do not claim physical compatibility until template hardening and timing pass.

## Status & limitations

The archive is a portable *starter*, not a completed protocol emulator, and **has not been validated on FPGA or ASIC**. It currently has no external program-loading pins, TX/RX FIFOs, ISR/OSR, SERDES, or complete ISA. `uo_out` is driven by core GPIO output; bidirectional IO is parked in input mode. A demo boot program runs after reset.

The FPGA demo uses a 125 MHz board reference and toggles LED0. Recheck board XDC mapping before programming. Maintain all RTL in `.v` files.
