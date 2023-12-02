# PAT80 Emulator
This folder contains a submodule (you should fetch it if you need to run the os in an emulator).

Uses cburbridge's Z80 emulator written in python. It opens some windows showing the emulated computer's memory map, the cpu registers state and parallel terminal to interact with the os.

## Usage
To run the os in the emulator, head to `pat80-computer/software/z80-assembly/os/Makefile` and run `make run` to build the rom from assembly and start the emulator.
