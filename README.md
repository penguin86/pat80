# Software utilizzato
Compilatore assembly: z80asm (da repo debian)
Compilatore c: sdcc (da repo debian)
Eeprom flash: minipro (da https://gitlab.com/DavidGriffith/minipro/)

# Assembly
## Compilare assembly:
`z80asm -i hd44780_lcd_test_procedure.asm -o rom.bin`
## Portare binario alla dimensione dell eeprom:
`dd if=/dev/zero of=rom.bin bs=1 count=0 seek=8192`
## Scrivere su EEPROM:
`minipro -w rom.bin -p "AT28C64B"`
## Leggere EEPROM:
`minipro -r rom_read.bin -p "AT28C64B"`

# C
## Compilare c:
`sdcc -mz80 test.c`
