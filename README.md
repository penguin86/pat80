# Software utilizzato
Compilatore assembly: z80asm (da repo debian)
Compilatore c: sdcc (da repo debian)
Eeprom flash: minipro (da https://gitlab.com/DavidGriffith/minipro/)
Disegnatore schemi logici: logisim (jar da sourceforge)
    Per usarlo su hdpi: `java -Dsun.java2d.uiScale=2 -jar logisim-generic-2.7.1.jar`
Disegnatore circuiti: fritzing (da repo debian)

# Assembly
## Deploy
### Compilare assembly:
`z80asm -i hd44780_lcd_test_procedure.asm -o rom.bin`
### Portare binario alla dimensione dell eeprom:
`dd if=/dev/zero of=rom.bin bs=1 count=0 seek=8192`
### Scrivere su EEPROM:
`minipro -w rom.bin -p "AT28C64B"`
### Leggere EEPROM:
`minipro -r rom_read.bin -p "AT28C64B"`
## Istruzioni
### Dichiarare una variabile:
Usare EQU per assegnare una posizione di memoria nota (nella RAM) al nome variabile.
```
myVar: EQU 0x800F   ; init variable
ld hl, "A"          ; load value into register
ld (myVar), hl      ; copy value into variable
```
NB: Se il programma si blocca, verificare che la variabile non sia stata dichiarata in una parte non scrivibile della memoria (ROM)
### Accedere ad una variabile
Modificarne il valore (nell'esempio: incrementarla di 1)
```
ld a, (myVar)
inc a
ld (myVar), a
```
Passarne il puntatore ad una funzione:
```
ld bc, myVar
call lcd_print
```
### Segmentation fault
Controllare che non si stia puntando ad un registro con le parentesi:
`ld (ix), a`

# C
## Deploy
### Compilare c:
`sdcc -mz80 test.c`
