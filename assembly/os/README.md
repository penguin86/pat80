# Pat80 Operating System and Memory Monitor

## Intro
This folder contains the Pat80 Operating System.
It is a System Monitor that makes available also some system API to access hardware (monitor, sound, keyboard, parallel terminal...).

## Build
### Requirements
z80asm, minipro
### Make
The os can be build issuing command `make`.
Two files will be generated:
- `rom.bin` is the rom file to be flashed on the eeprom
- `abi-generated.asm` is the file to be included in any Pat80 application to access system APIs (see README.md in ../applications/)
The build routine will then try to write the rom to a MiniPRO.
