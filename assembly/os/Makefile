os:
	@echo "Building PAT80 rom..."
	@z80asm -i main.asm -o rom.bin || (exit 1)
	@echo "Generating label lookup table..."
	@z80asm -i main.asm -o rom.bin -L 2>&1 | grep "Sys_" > abi-generated.asm
	@echo "PAT80 Rom size:"
	@du -h rom.bin
	@echo "Stretching rom to EEPROM size..."
	@dd if=/dev/zero of=rom.bin bs=1 count=0 seek=8192
	@echo "Writing to EEPROM..."
	@minipro -w rom.bin -p "AT28C64B"
