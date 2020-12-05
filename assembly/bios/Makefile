bios:
	@echo "Building PAT80 rom..."
	@z80asm -i main.asm -o rom.bin
	@echo "PAT80 Rom size:"
	@du -h rom.bin
	@echo "Stretching rom to EEPROM size..."
	@dd if=/dev/zero of=rom.bin bs=1 count=0 seek=8192
	@echo "Writing to EEPROM..."
	@minipro -w rom.bin -p "AT28C64B"
