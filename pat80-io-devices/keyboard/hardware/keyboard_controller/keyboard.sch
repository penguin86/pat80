EESchema Schematic File Version 4
EELAYER 30 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 1
Title ""
Date ""
Rev ""
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
Wire Wire Line
	4350 3800 5800 3800
Connection ~ 4350 3800
Text Label 4900 4800 0    50   ~ 0
ROW7
Text Label 4900 4700 0    50   ~ 0
ROW6
Text Label 4900 4600 0    50   ~ 0
ROW5
Text Label 4900 4500 0    50   ~ 0
ROW4
Text Label 4900 4400 0    50   ~ 0
ROW3
Text Label 4900 4300 0    50   ~ 0
ROW2
Text Label 4900 4200 0    50   ~ 0
ROW1
Text Label 4900 4100 0    50   ~ 0
ROW0
Text Label 6850 4300 0    50   ~ 0
COL7
Text Label 6850 4200 0    50   ~ 0
COL6
Text Label 6850 4100 0    50   ~ 0
COL5
Text Label 6850 4000 0    50   ~ 0
COL4
Text Label 6850 3900 0    50   ~ 0
COL3
Text Label 6850 3800 0    50   ~ 0
COL2
Text Label 6850 3700 0    50   ~ 0
COL1
Text Label 6850 3600 0    50   ~ 0
COL0
Wire Wire Line
	4850 4800 5100 4800
Wire Wire Line
	4850 4700 5100 4700
Wire Wire Line
	4850 4600 5100 4600
Wire Wire Line
	4850 4500 5100 4500
Wire Wire Line
	4850 4400 5100 4400
Wire Wire Line
	4850 4300 5100 4300
Wire Wire Line
	4850 4200 5100 4200
Wire Wire Line
	4850 4100 5100 4100
Entry Wire Line
	5100 4800 5200 4900
Entry Wire Line
	5100 4700 5200 4800
Entry Wire Line
	5100 4600 5200 4700
Entry Wire Line
	5100 4500 5200 4600
Entry Wire Line
	5100 4400 5200 4500
Entry Wire Line
	5100 4300 5200 4400
Entry Wire Line
	5100 4200 5200 4300
Entry Wire Line
	5100 4100 5200 4200
Wire Wire Line
	6800 3600 7150 3600
Wire Wire Line
	6800 3700 7150 3700
Wire Wire Line
	6800 3800 7150 3800
Wire Wire Line
	6800 3900 7150 3900
Wire Wire Line
	6800 4000 7150 4000
Wire Wire Line
	7150 4100 6800 4100
Wire Wire Line
	6800 4200 7150 4200
Wire Wire Line
	7150 4300 6800 4300
Entry Wire Line
	7150 4300 7250 4400
Entry Wire Line
	7150 4200 7250 4300
Entry Wire Line
	7150 4100 7250 4200
Entry Wire Line
	7150 4000 7250 4100
Entry Wire Line
	7150 3900 7250 4000
Entry Wire Line
	7150 3800 7250 3900
Entry Wire Line
	7150 3700 7250 3800
Entry Wire Line
	7150 3600 7250 3700
Connection ~ 5400 4250
Wire Wire Line
	5400 3500 5400 4250
Wire Wire Line
	2150 3500 5400 3500
Wire Wire Line
	4850 5050 4850 5100
Connection ~ 4850 5050
Wire Wire Line
	5800 4250 5800 4300
Connection ~ 5800 4250
Wire Wire Line
	5400 5050 4850 5050
Wire Wire Line
	5400 4250 5400 5050
Wire Wire Line
	5800 4250 5400 4250
Wire Wire Line
	4850 5000 4850 5050
Wire Wire Line
	5800 4200 5800 4250
$Comp
L power:VCC #PWR010
U 1 1 605B5E0F
P 5800 4100
F 0 "#PWR010" H 5800 3950 50  0001 C CNN
F 1 "VCC" H 5817 4273 50  0000 C CNN
F 2 "" H 5800 4100 50  0001 C CNN
F 3 "" H 5800 4100 50  0001 C CNN
	1    5800 4100
	1    0    0    -1  
$EndComp
Wire Wire Line
	2150 3800 4350 3800
Wire Wire Line
	2150 3700 5800 3700
Wire Wire Line
	2150 3600 5800 3600
Wire Wire Line
	4350 3150 4350 3800
NoConn ~ 2650 4000
NoConn ~ 2650 3900
NoConn ~ 2650 4900
Wire Wire Line
	2150 4800 3850 4800
Wire Wire Line
	2150 4700 3850 4700
Wire Wire Line
	2150 4600 3850 4600
Wire Wire Line
	2150 4500 3850 4500
Wire Wire Line
	2150 4300 3850 4300
Wire Wire Line
	2150 4200 3850 4200
Wire Wire Line
	2150 4100 3850 4100
$Comp
L Device:C C2
U 1 1 6058BC4A
P 4700 3300
F 0 "C2" V 4448 3300 50  0000 C CNN
F 1 "56Pf" V 4539 3300 50  0000 C CNN
F 2 "Capacitor_THT:CP_Radial_Tantal_D6.0mm_P5.00mm" H 4738 3150 50  0001 C CNN
F 3 "~" H 4700 3300 50  0001 C CNN
	1    4700 3300
	0    1    1    0   
$EndComp
Wire Wire Line
	4850 3150 4850 3050
Connection ~ 4850 3150
Wire Wire Line
	4950 3150 4850 3150
$Comp
L power:GND #PWR09
U 1 1 6058E1A9
P 4950 3150
F 0 "#PWR09" H 4950 2900 50  0001 C CNN
F 1 "GND" H 4955 2977 50  0000 C CNN
F 2 "" H 4950 3150 50  0001 C CNN
F 3 "" H 4950 3150 50  0001 C CNN
	1    4950 3150
	1    0    0    -1  
$EndComp
Wire Wire Line
	4350 3150 4350 3000
Connection ~ 4350 3150
Wire Wire Line
	4550 3150 4550 3050
Connection ~ 4550 3150
Wire Wire Line
	4550 3150 4350 3150
Wire Wire Line
	4550 3300 4550 3150
Wire Wire Line
	4850 3300 4850 3150
$Comp
L Device:C C1
U 1 1 6058B545
P 4700 3050
F 0 "C1" V 4448 3050 50  0000 C CNN
F 1 "100Nf" V 4539 3050 50  0000 C CNN
F 2 "Capacitor_THT:CP_Radial_Tantal_D6.0mm_P5.00mm" H 4738 2900 50  0001 C CNN
F 3 "~" H 4700 3050 50  0001 C CNN
	1    4700 3050
	0    1    1    0   
$EndComp
$Comp
L power:GND #PWR08
U 1 1 6058B250
P 4350 5400
F 0 "#PWR08" H 4350 5150 50  0001 C CNN
F 1 "GND" H 4355 5227 50  0000 C CNN
F 2 "" H 4350 5400 50  0001 C CNN
F 3 "" H 4350 5400 50  0001 C CNN
	1    4350 5400
	1    0    0    -1  
$EndComp
$Comp
L power:VCC #PWR07
U 1 1 6058AE17
P 4350 3000
F 0 "#PWR07" H 4350 2850 50  0001 C CNN
F 1 "VCC" H 4367 3173 50  0000 C CNN
F 2 "" H 4350 3000 50  0001 C CNN
F 3 "" H 4350 3000 50  0001 C CNN
	1    4350 3000
	1    0    0    -1  
$EndComp
Wire Wire Line
	2650 5450 2900 5450
$Comp
L power:VCC #PWR05
U 1 1 60585FB5
P 2900 5450
F 0 "#PWR05" H 2900 5300 50  0001 C CNN
F 1 "VCC" H 2917 5623 50  0000 C CNN
F 2 "" H 2900 5450 50  0001 C CNN
F 3 "" H 2900 5450 50  0001 C CNN
	1    2900 5450
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR03
U 1 1 60585B88
P 2750 5200
F 0 "#PWR03" H 2750 4950 50  0001 C CNN
F 1 "GND" H 2755 5027 50  0000 C CNN
F 2 "" H 2750 5200 50  0001 C CNN
F 3 "" H 2750 5200 50  0001 C CNN
	1    2750 5200
	1    0    0    -1  
$EndComp
Wire Wire Line
	2150 5000 2750 5000
Wire Wire Line
	2750 5000 2750 5200
Wire Wire Line
	2650 5100 2650 5450
$Comp
L power:GND #PWR04
U 1 1 60584796
P 2850 3000
F 0 "#PWR04" H 2850 2750 50  0001 C CNN
F 1 "GND" H 2855 2827 50  0000 C CNN
F 2 "" H 2850 3000 50  0001 C CNN
F 3 "" H 2850 3000 50  0001 C CNN
	1    2850 3000
	1    0    0    -1  
$EndComp
$Comp
L power:VCC #PWR02
U 1 1 60584370
P 2650 3000
F 0 "#PWR02" H 2650 2850 50  0001 C CNN
F 1 "VCC" H 2667 3173 50  0000 C CNN
F 2 "" H 2650 3000 50  0001 C CNN
F 3 "" H 2650 3000 50  0001 C CNN
	1    2650 3000
	1    0    0    -1  
$EndComp
Wire Wire Line
	2150 3400 2750 3400
Wire Wire Line
	2750 3000 2850 3000
Wire Wire Line
	2750 3400 2750 3000
Wire Wire Line
	2650 3300 2650 3000
Text Label 2250 5100 0    50   ~ 0
IOVCC
Text Label 2250 5000 0    50   ~ 0
IOGND
Text Label 2250 4900 0    50   ~ 0
IOWR
Text Label 2250 4800 0    50   ~ 0
IOD7
Text Label 2250 4700 0    50   ~ 0
IOD6
Text Label 2250 4600 0    50   ~ 0
IOD5
Text Label 2250 4500 0    50   ~ 0
IOD4
Text Label 2250 4400 0    50   ~ 0
IOD3
Text Label 2250 4300 0    50   ~ 0
IOD2
Text Label 2250 4200 0    50   ~ 0
IOD1
Text Label 2250 4100 0    50   ~ 0
IOD0
Text Label 2250 4000 0    50   ~ 0
IOADDR4
Text Label 2250 3900 0    50   ~ 0
IOADDR3
Text Label 2250 3800 0    50   ~ 0
IOADDR2
Text Label 2250 3700 0    50   ~ 0
IOADDR1
Text Label 2250 3600 0    50   ~ 0
IOADDR0
Text Label 2250 3500 0    50   ~ 0
IOEN
Text Label 2250 3400 0    50   ~ 0
IOGND
Text Label 2250 3300 0    50   ~ 0
IOVCC
Wire Wire Line
	2150 5100 2650 5100
Wire Wire Line
	2150 4900 2650 4900
Wire Wire Line
	2150 4000 2650 4000
Wire Wire Line
	2150 3900 2650 3900
Wire Wire Line
	2150 3300 2650 3300
$Comp
L Connector_Generic:Conn_01x19 IOBUS1
U 1 1 6057928D
P 1950 4200
F 0 "IOBUS1" H 1868 5317 50  0000 C CNN
F 1 "IO_Bus_conn" H 1868 5226 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_1x19_P2.54mm_Horizontal" H 1950 4200 50  0001 C CNN
F 3 "~" H 1950 4200 50  0001 C CNN
	1    1950 4200
	-1   0    0    -1  
$EndComp
$Comp
L 74xx:74HC244 U1
U 1 1 605787CB
P 4350 4600
F 0 "U1" H 4350 5581 50  0000 C CNN
F 1 "74HC244" H 4350 5490 50  0000 C CNN
F 2 "Package_DIP:DIP-20_W7.62mm_LongPads" H 4350 4600 50  0001 C CNN
F 3 "http://www.nxp.com/documents/data_sheet/74HC_HCT244.pdf" H 4350 4600 50  0001 C CNN
	1    4350 4600
	-1   0    0    -1  
$EndComp
$Comp
L 74xx:74LS138 U2
U 1 1 60577A7C
P 6300 3900
F 0 "U2" H 6300 4681 50  0000 C CNN
F 1 "74HC138" H 6300 4590 50  0000 C CNN
F 2 "Package_DIP:DIP-16_W7.62mm_LongPads" H 6300 3900 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS138" H 6300 3900 50  0001 C CNN
	1    6300 3900
	1    0    0    -1  
$EndComp
Wire Wire Line
	2150 4400 3850 4400
Text Notes 4000 1300 0    197  ~ 0
PAT80 Keyboard Controller
Text Notes 4000 2000 0    47   ~ 0
The PAT80 keyboard is seen from the computer as a readonly block of 64 bytes of memory\nin the I/O space mapped to the first 3 of the 5 I/O address available for every single I/O device.\n\nThe keyboard controller is a board plugged on the I/O backplane and connected to the matrix board with a\n34-pin female-to-female flat ribbon cable (e.g. the ones used by IBM PC floppy disk drives)\n\nThe joystick port is Atari-style: partially C64 and MSX compatible (supports a single button and no analog paddle)
Text Notes 4750 6100 0    47   ~ 0
Keyboard controller
$Comp
L Connector_Generic:Conn_02x17_Odd_Even J1
U 1 1 60ECCE47
P 9100 3650
F 0 "J1" H 9150 4667 50  0000 C CNN
F 1 "Keyboard connector" H 9150 4576 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_2x17_P2.54mm_Vertical" H 9100 3650 50  0001 C CNN
F 3 "~" H 9100 3650 50  0001 C CNN
	1    9100 3650
	1    0    0    -1  
$EndComp
Wire Wire Line
	9400 2850 9400 2950
Wire Wire Line
	9400 4600 9600 4600
Connection ~ 9400 2950
Wire Wire Line
	9400 2950 9400 3050
Connection ~ 9400 3050
Wire Wire Line
	9400 3050 9400 3150
Connection ~ 9400 3150
Wire Wire Line
	9400 3150 9400 3250
Connection ~ 9400 3250
Wire Wire Line
	9400 3250 9400 3350
Connection ~ 9400 3350
Wire Wire Line
	9400 3350 9400 3450
Connection ~ 9400 3450
Wire Wire Line
	9400 3450 9400 3550
Connection ~ 9400 3550
Wire Wire Line
	9400 3550 9400 3650
Connection ~ 9400 3650
Wire Wire Line
	9400 3650 9400 3750
Connection ~ 9400 3750
Wire Wire Line
	9400 3750 9400 3850
Connection ~ 9400 3850
Wire Wire Line
	9400 3850 9400 3950
Connection ~ 9400 3950
Wire Wire Line
	9400 3950 9400 4050
Connection ~ 9400 4050
Wire Wire Line
	9400 4050 9400 4150
Connection ~ 9400 4150
Wire Wire Line
	9400 4150 9400 4250
Connection ~ 9400 4250
Wire Wire Line
	9400 4250 9400 4350
Connection ~ 9400 4350
Wire Wire Line
	9400 4350 9400 4450
Connection ~ 9400 4450
Wire Wire Line
	9400 4450 9400 4600
Entry Wire Line
	8500 2850 8400 2950
Entry Wire Line
	8500 2950 8400 3050
Entry Wire Line
	8500 3050 8400 3150
Entry Wire Line
	8500 3150 8400 3250
Entry Wire Line
	8500 3250 8400 3350
Entry Wire Line
	8500 3350 8400 3450
Entry Wire Line
	8500 3450 8400 3550
Entry Wire Line
	8500 3550 8400 3650
Entry Wire Line
	8500 3750 8400 3850
Entry Wire Line
	8500 3850 8400 3950
Entry Wire Line
	8500 3950 8400 4050
Entry Wire Line
	8500 4050 8400 4150
Entry Wire Line
	8500 4150 8400 4250
Entry Wire Line
	8500 4250 8400 4350
Entry Wire Line
	8500 4350 8400 4450
Entry Wire Line
	8500 4450 8400 4550
$Comp
L power:GND #PWR017
U 1 1 60ECCE7F
P 9600 4600
F 0 "#PWR017" H 9600 4350 50  0001 C CNN
F 1 "GND" H 9605 4427 50  0000 C CNN
F 2 "" H 9600 4600 50  0001 C CNN
F 3 "" H 9600 4600 50  0001 C CNN
	1    9600 4600
	1    0    0    -1  
$EndComp
Wire Wire Line
	8500 2850 8900 2850
Wire Wire Line
	8500 2950 8900 2950
Wire Wire Line
	8500 3050 8900 3050
Wire Wire Line
	8500 3150 8900 3150
Wire Wire Line
	8500 3250 8900 3250
Wire Wire Line
	8500 3350 8900 3350
Wire Wire Line
	8500 3450 8900 3450
Wire Wire Line
	8500 3550 8900 3550
Wire Wire Line
	8500 3750 8900 3750
Wire Wire Line
	8500 3850 8900 3850
Wire Wire Line
	8500 3950 8900 3950
Wire Wire Line
	8500 4050 8900 4050
Wire Wire Line
	8500 4150 8900 4150
Wire Wire Line
	8500 4250 8900 4250
Wire Wire Line
	8500 4350 8900 4350
Wire Wire Line
	8500 4450 8900 4450
Text Label 8600 2850 0    47   ~ 0
COL0
Text Label 8600 2950 0    47   ~ 0
COL1
Text Label 8600 3050 0    47   ~ 0
COL2
Text Label 8600 3150 0    47   ~ 0
COL3
Text Label 8600 3250 0    47   ~ 0
COL4
Text Label 8600 3350 0    47   ~ 0
COL5
Text Label 8600 3450 0    47   ~ 0
COL6
Text Label 8600 3550 0    47   ~ 0
COL7
Text Label 8600 3750 0    47   ~ 0
ROW0
Text Label 8600 3850 0    47   ~ 0
ROW1
Text Label 8600 3950 0    47   ~ 0
ROW2
Text Label 8600 4050 0    47   ~ 0
ROW3
Text Label 8600 4150 0    47   ~ 0
ROW4
Text Label 8600 4250 0    47   ~ 0
ROW5
Text Label 8600 4350 0    47   ~ 0
ROW6
Text Label 8600 4450 0    47   ~ 0
ROW7
$Comp
L power:VCC #PWR014
U 1 1 6138B5E2
P 7950 3950
F 0 "#PWR014" H 7950 3800 50  0001 C CNN
F 1 "VCC" H 7967 4123 50  0000 C CNN
F 2 "" H 7950 3950 50  0001 C CNN
F 3 "" H 7950 3950 50  0001 C CNN
	1    7950 3950
	1    0    0    -1  
$EndComp
Wire Wire Line
	8900 3650 8450 3650
Wire Wire Line
	8450 3650 8450 3750
Wire Wire Line
	8450 3750 8150 3750
Wire Wire Line
	8150 3750 8150 3950
Wire Wire Line
	8150 3950 7950 3950
Text Label 8600 3650 0    47   ~ 0
MTXVCC
$Comp
L Connector:DB9_Female_MountingHoles J2
U 1 1 60C1B7D7
P 9250 5250
F 0 "J2" H 9430 5252 50  0000 L CNN
F 1 "Joystick connector" H 9430 5161 50  0000 L CNN
F 2 "Connector_Dsub:DSUB-9_Female_Horizontal_P2.77x2.84mm_EdgePinOffset4.94mm_Housed_MountingHolesOffset7.48mm" H 9250 5250 50  0001 C CNN
F 3 " ~" H 9250 5250 50  0001 C CNN
	1    9250 5250
	1    0    0    -1  
$EndComp
Wire Bus Line
	7250 3650 8400 3650
Wire Bus Line
	7250 5600 8100 5600
Wire Bus Line
	5200 5750 8400 5750
Entry Wire Line
	8100 5450 8200 5350
Text Label 8600 5350 0    50   ~ 0
COL7
Wire Wire Line
	8950 4850 8500 4850
Entry Wire Line
	8400 4950 8500 4850
Wire Bus Line
	8100 5600 8100 5450
Wire Wire Line
	8950 5050 8500 5050
Entry Wire Line
	8400 5150 8500 5050
Wire Wire Line
	8950 5250 8500 5250
Entry Wire Line
	8400 5350 8500 5250
Wire Wire Line
	8950 5450 8500 5450
Entry Wire Line
	8400 5550 8500 5450
Text Label 8600 4850 0    50   ~ 0
ROW0
Text Label 8600 5050 0    50   ~ 0
ROW1
Text Label 8600 5250 0    50   ~ 0
ROW2
Text Label 8600 5450 0    50   ~ 0
ROW3
Wire Wire Line
	8950 4950 8500 4950
Entry Wire Line
	8400 5050 8500 4950
Text Label 8600 4950 0    50   ~ 0
ROW4
Wire Wire Line
	8950 5150 8500 5150
Wire Wire Line
	8500 5150 8500 5200
Wire Wire Line
	8500 5200 7950 5200
$Comp
L power:VCC #PWR015
U 1 1 60EC4111
P 7950 5200
F 0 "#PWR015" H 7950 5050 50  0001 C CNN
F 1 "VCC" H 7967 5373 50  0000 C CNN
F 2 "" H 7950 5200 50  0001 C CNN
F 3 "" H 7950 5200 50  0001 C CNN
	1    7950 5200
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR016
U 1 1 60EC5968
P 9250 5850
F 0 "#PWR016" H 9250 5600 50  0001 C CNN
F 1 "GND" H 9255 5677 50  0000 C CNN
F 2 "" H 9250 5850 50  0001 C CNN
F 3 "" H 9250 5850 50  0001 C CNN
	1    9250 5850
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR012
U 1 1 60F7D3B6
P 6300 4950
F 0 "#PWR012" H 6300 4700 50  0001 C CNN
F 1 "GND" H 6305 4777 50  0000 C CNN
F 2 "" H 6300 4950 50  0001 C CNN
F 3 "" H 6300 4950 50  0001 C CNN
	1    6300 4950
	1    0    0    -1  
$EndComp
Wire Wire Line
	6300 4950 6300 4600
$Comp
L Device:C C4
U 1 1 60FB4E9D
P 6650 3100
F 0 "C4" V 6398 3100 50  0000 C CNN
F 1 "56Pf" V 6489 3100 50  0000 C CNN
F 2 "Capacitor_THT:CP_Radial_Tantal_D6.0mm_P5.00mm" H 6688 2950 50  0001 C CNN
F 3 "~" H 6650 3100 50  0001 C CNN
	1    6650 3100
	0    1    1    0   
$EndComp
Wire Wire Line
	6800 2950 6800 2850
Connection ~ 6800 2950
Wire Wire Line
	6900 2950 6800 2950
$Comp
L power:GND #PWR013
U 1 1 60FB4EA6
P 6900 2950
F 0 "#PWR013" H 6900 2700 50  0001 C CNN
F 1 "GND" H 6905 2777 50  0000 C CNN
F 2 "" H 6900 2950 50  0001 C CNN
F 3 "" H 6900 2950 50  0001 C CNN
	1    6900 2950
	1    0    0    -1  
$EndComp
Wire Wire Line
	6300 2950 6300 2800
Wire Wire Line
	6500 2950 6500 2850
Connection ~ 6500 2950
Wire Wire Line
	6500 2950 6300 2950
Wire Wire Line
	6500 3100 6500 2950
Wire Wire Line
	6800 3100 6800 2950
$Comp
L Device:C C3
U 1 1 60FB4EB3
P 6650 2850
F 0 "C3" V 6398 2850 50  0000 C CNN
F 1 "100Nf" V 6489 2850 50  0000 C CNN
F 2 "Capacitor_THT:CP_Radial_Tantal_D6.0mm_P5.00mm" H 6688 2700 50  0001 C CNN
F 3 "~" H 6650 2850 50  0001 C CNN
	1    6650 2850
	0    1    1    0   
$EndComp
$Comp
L power:VCC #PWR011
U 1 1 60FB4EB9
P 6300 2800
F 0 "#PWR011" H 6300 2650 50  0001 C CNN
F 1 "VCC" H 6317 2973 50  0000 C CNN
F 2 "" H 6300 2800 50  0001 C CNN
F 3 "" H 6300 2800 50  0001 C CNN
	1    6300 2800
	1    0    0    -1  
$EndComp
Wire Wire Line
	6300 2950 6300 3300
Connection ~ 6300 2950
Wire Wire Line
	8200 5350 8950 5350
Wire Bus Line
	8400 2950 8400 3650
Wire Bus Line
	5200 4200 5200 5750
Wire Bus Line
	7250 3650 7250 5600
Wire Bus Line
	8400 3850 8400 5750
Text Notes 7350 7550 0    118  ~ 0
Pat80 Keyboard and Joystick Controller
$EndSCHEMATC
