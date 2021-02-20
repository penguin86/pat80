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

# Generate test images
Using GIMP, Image -> Mode -> Indexed, select 2 colors and Posterize.
Invert the image colors.
Save as .xbm file. Oper with a *text editor*, you will find an array of byte-packed pixels (every byte represents 8 pixels).
Copy and paste on an ASM file.