# PAT80 Emulator
Uses algodesigner's Z80 emulator (see submodule in z80 folder).
Instances the Z80 object (representing the CPU) and:
- intercepts all memory access and returns the corresponding rom value (read from rom file) if PC is in first 32k of memory (TODO)
- intercepts all memory access and stops execution returning error if trying to write to first 32k of memory (TODO)

## Usage
Build with `make all`
Run with `./pat80emu`
