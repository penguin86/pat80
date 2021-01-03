# Atmega Microcontroller
## Build ASM code
`avra filename.asm` (generates *filename.hex*)

## Flash
### Rom
`minipro -w filename.hex -p ATMEGA1284`

### Fuses
Read fuses: `minipro -r -c config -p ATMEGA1284` (`-r -c config` means read configuration (fuses))
Fuses must be written all together, so read the current values, edit the generated file and write it.
The meaning of every bis is in the conf file.
Write fuses: `minipro -w fuses.conf -c config -p ATMEGA1284`