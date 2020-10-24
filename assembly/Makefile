bios:
	z80asm -i pat80_bios_0.1.asm -o rom.bin
	dd if=/dev/zero of=rom.bin bs=1 count=0 seek=8192
	minipro -w rom.bin -p "AT28C64B"
	