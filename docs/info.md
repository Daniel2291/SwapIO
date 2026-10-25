# SwapIO

A programmable I/O sequencer demonstrator for the Jane Street protocol emulator challenge.

Current demo loads a three-instruction toggle program after reset. GPIO inputs are mapped from `ui_in`, GPIO outputs to `uo_out`. `uio` pins are held in input mode.

**This is not the final programmable host interface.** The instruction-loader and full ISA remain future work. The chip must gain a runtime host programming path before it is a complete protocol emulator.
