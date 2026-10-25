# SwapIO architecture (Milestone 0)

- Single 16-bit-instruction state machine; 32 x 16 instruction memory.
- PC 5-bit; 32-bit X/Y scratch registers; ISR/OSR and FIFOs **not implemented yet**.
- Implemented instructions: unconditional JMP, WAIT GPIO, SET GPIO/X/Y/output-enable.
- 8 GPIO inputs / 8 GPIO outputs; optional 2-bit side-set controls output bits 7:6.
- Divider uses clock enable, not an internally generated clock.
- CSR bus is a development-only parallel interface; TT wrapper currently bootloads a demo.
- Target eventual serial programming, RX/TX FIFOs, serializer, and RMII experiments.

Important: unsigned 32-bit divider is intentionally a placeholder; optimize after timing/area study.

## Core bus
- 0x00 control: bit0 running, bit1 restart
- 0x04 status
- 0x08 clock divider (minimum 1)
- 0x0c GPIO output
- 0x10 GPIO output-enable
- 0x14 GPIO input
- 0x18 side-set enable
- 0x80..0xfc instruction memory (word aligned)

Only write program/configuration while stopped. Contents of imem are undefined after reset until loaded.
