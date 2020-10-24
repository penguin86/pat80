Compilare assembly:
    z80asm -i hd44780_lcd_test_procedure.asm -o rom.bin
Portare binario alla dimensione dell eeprom:
    dd if=/dev/zero of=rom.bin bs=1 count=0 seek=8192
Scrivere su EEPROM:
    minipro -w rom.bin -p "AT28C64B"
Leggere EEPROM:
    minipro -r rom_read.bin -p "AT28C64B"
