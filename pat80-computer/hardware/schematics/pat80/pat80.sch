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
Text Notes 7400 7500 0    50   ~ 0
Pat80 Z80 home computer
Text Notes 8150 7650 0    50   ~ 0
2021-03-15
$Comp
L CPU:Z80CPU U1
U 1 1 604F040E
P 3150 2650
F 0 "U1" H 3150 4331 50  0000 C CNN
F 1 "Z80CPU" H 3150 4240 50  0000 C CNN
F 2 "" H 3150 3050 50  0001 C CNN
F 3 "www.zilog.com/manage_directlink.php?filepath=docs/z80/um0080" H 3150 3050 50  0001 C CNN
	1    3150 2650
	1    0    0    -1  
$EndComp
$Comp
L Memory_EEPROM:28C256 U3
U 1 1 604F6B81
P 6850 1700
F 0 "U3" V 6896 556 50  0000 R CNN
F 1 "256k (32k x 8) EEPROM" V 6805 556 50  0000 R CNN
F 2 "" H 6850 1700 50  0001 C CNN
F 3 "http://ww1.microchip.com/downloads/en/DeviceDoc/doc0006.pdf" H 6850 1700 50  0001 C CNN
	1    6850 1700
	0    -1   -1   0   
$EndComp
Entry Wire Line
	4150 1550 4250 1650
Entry Wire Line
	4150 1650 4250 1750
Entry Wire Line
	4150 1750 4250 1850
Entry Wire Line
	4150 1850 4250 1950
Entry Wire Line
	4150 1950 4250 2050
Entry Wire Line
	4150 2050 4250 2150
Entry Wire Line
	4150 2150 4250 2250
Entry Wire Line
	4150 2250 4250 2350
Entry Wire Line
	4150 2350 4250 2450
Entry Wire Line
	4150 2450 4250 2550
Entry Wire Line
	4150 2550 4250 2650
Entry Wire Line
	4150 2650 4250 2750
Entry Wire Line
	4150 2750 4250 2850
Entry Wire Line
	4150 2850 4250 2950
Entry Wire Line
	4150 2950 4250 3050
Wire Bus Line
	4250 3050 5100 3050
Wire Wire Line
	3850 1450 4150 1450
Wire Wire Line
	3850 1550 4150 1550
Wire Wire Line
	3850 1650 4150 1650
Wire Wire Line
	3850 1750 4150 1750
Wire Wire Line
	3850 1850 4150 1850
Wire Wire Line
	3850 1950 4150 1950
Wire Wire Line
	3850 2050 4150 2050
Wire Wire Line
	3850 2150 4150 2150
Wire Wire Line
	3850 2250 4150 2250
Wire Wire Line
	3850 2350 4150 2350
Wire Wire Line
	3850 2450 4150 2450
Wire Wire Line
	3850 2550 4150 2550
Wire Wire Line
	3850 2650 4150 2650
Wire Wire Line
	3850 2750 4150 2750
Wire Wire Line
	3850 2850 4150 2850
Wire Wire Line
	3850 2950 4150 2950
Entry Wire Line
	5950 2200 5850 2300
Entry Wire Line
	6050 2200 5950 2300
Entry Wire Line
	6150 2200 6050 2300
Entry Wire Line
	6250 2200 6150 2300
Entry Wire Line
	6350 2200 6250 2300
Entry Wire Line
	6450 2200 6350 2300
Entry Wire Line
	6550 2200 6450 2300
Entry Wire Line
	6650 2200 6550 2300
Entry Wire Line
	6750 2200 6650 2300
Entry Wire Line
	6850 2200 6750 2300
Entry Wire Line
	6950 2200 6850 2300
Entry Wire Line
	7050 2200 6950 2300
Entry Wire Line
	7150 2200 7050 2300
Entry Wire Line
	7250 2200 7150 2300
Entry Wire Line
	7350 2200 7250 2300
Wire Wire Line
	5950 2100 5950 2200
Wire Wire Line
	6050 2100 6050 2200
Wire Wire Line
	6150 2100 6150 2200
Wire Wire Line
	6250 2100 6250 2200
Wire Wire Line
	6350 2100 6350 2200
Wire Wire Line
	6450 2100 6450 2200
Wire Wire Line
	6550 2100 6550 2200
Wire Wire Line
	6650 2100 6650 2200
Wire Wire Line
	6750 2100 6750 2200
Wire Wire Line
	6850 2100 6850 2200
Wire Wire Line
	6950 2100 6950 2200
Wire Wire Line
	7050 2100 7050 2200
Wire Wire Line
	7150 2100 7150 2200
Wire Wire Line
	7250 2100 7250 2200
Wire Wire Line
	7350 2100 7350 2200
Wire Bus Line
	5100 3050 5100 2300
Text Label 3950 1450 0    50   ~ 0
A0
Text Label 3950 1550 0    50   ~ 0
A1
Text Label 3950 1650 0    50   ~ 0
A2
Text Label 3950 1750 0    50   ~ 0
A3
Text Label 3950 1850 0    50   ~ 0
A4
Text Label 3950 1950 0    50   ~ 0
A5
Text Label 3950 2050 0    50   ~ 0
A6
Text Label 3950 2150 0    50   ~ 0
A7
Text Label 3950 2250 0    50   ~ 0
A8
Text Label 3950 2350 0    50   ~ 0
A9
Text Label 3950 2450 0    50   ~ 0
A10
Text Label 3950 2550 0    50   ~ 0
A11
Text Label 3950 2650 0    50   ~ 0
A12
Text Label 3950 2750 0    50   ~ 0
A13
Text Label 3950 2850 0    50   ~ 0
A14
Text Label 3950 2950 0    50   ~ 0
A15
Text Label 5950 2150 3    50   ~ 0
A0
Text Label 6050 2150 3    50   ~ 0
A1
Text Label 6150 2150 3    50   ~ 0
A2
Text Label 6250 2150 3    50   ~ 0
A3
Text Label 6350 2150 3    50   ~ 0
A4
Text Label 6450 2150 3    50   ~ 0
A5
Text Label 6550 2150 3    50   ~ 0
A6
Text Label 6650 2150 3    50   ~ 0
A7
Text Label 6750 2150 3    50   ~ 0
A8
Text Label 6850 2150 3    50   ~ 0
A9
Text Label 6950 2150 3    50   ~ 0
A10
Text Label 7050 2150 3    50   ~ 0
A11
Text Label 7150 2150 3    50   ~ 0
A12
Text Label 7250 2150 3    50   ~ 0
A13
Text Label 7350 2150 3    50   ~ 0
A14
Entry Wire Line
	5950 3950 5850 4050
Entry Wire Line
	6050 3950 5950 4050
Entry Wire Line
	6150 3950 6050 4050
Entry Wire Line
	6250 3950 6150 4050
Entry Wire Line
	6350 3950 6250 4050
Entry Wire Line
	6450 3950 6350 4050
Entry Wire Line
	6550 3950 6450 4050
Entry Wire Line
	6650 3950 6550 4050
Entry Wire Line
	6750 3950 6650 4050
Entry Wire Line
	6850 3950 6750 4050
Entry Wire Line
	6950 3950 6850 4050
Entry Wire Line
	7050 3950 6950 4050
Entry Wire Line
	7150 3950 7050 4050
Entry Wire Line
	7250 3950 7150 4050
Entry Wire Line
	7350 3950 7250 4050
Wire Wire Line
	5950 3950 5950 3850
Wire Wire Line
	6050 3950 6050 3850
Wire Wire Line
	6150 3950 6150 3850
Wire Wire Line
	6250 3950 6250 3850
Wire Wire Line
	6350 3950 6350 3850
Wire Wire Line
	6450 3950 6450 3850
Wire Wire Line
	6550 3950 6550 3850
Wire Wire Line
	6650 3950 6650 3850
Wire Wire Line
	6750 3950 6750 3850
Wire Wire Line
	6850 3950 6850 3850
Wire Wire Line
	6950 3950 6950 3850
Wire Wire Line
	7050 3950 7050 3850
Wire Wire Line
	7150 3950 7150 3850
Wire Wire Line
	7250 3950 7250 3850
Wire Wire Line
	7350 3950 7350 3850
Wire Bus Line
	5100 4050 5100 3050
Connection ~ 5100 3050
Text Label 5950 3900 3    50   ~ 0
A0
Text Label 6050 3900 3    50   ~ 0
A1
Text Label 6150 3900 3    50   ~ 0
A2
Text Label 6250 3900 3    50   ~ 0
A3
Text Label 6350 3900 3    50   ~ 0
A4
Text Label 6450 3900 3    50   ~ 0
A5
Text Label 6550 3900 3    50   ~ 0
A6
Text Label 6650 3900 3    50   ~ 0
A7
Text Label 6750 3900 3    50   ~ 0
A8
Text Label 6850 3900 3    50   ~ 0
A9
Text Label 6950 3900 3    50   ~ 0
A10
Text Label 7050 3900 3    50   ~ 0
A11
Text Label 7150 3900 3    50   ~ 0
A12
Text Label 7250 3900 3    50   ~ 0
A13
Text Label 7350 3900 3    50   ~ 0
A14
Entry Wire Line
	4150 3150 4250 3250
Entry Wire Line
	4150 3150 4250 3250
Entry Wire Line
	4150 3250 4250 3350
Entry Wire Line
	4150 3350 4250 3450
Entry Wire Line
	4150 3450 4250 3550
Entry Wire Line
	4150 3550 4250 3650
Entry Wire Line
	4150 3650 4250 3750
Entry Wire Line
	4150 3750 4250 3850
Entry Wire Line
	4150 3850 4250 3950
Wire Wire Line
	3850 3150 4150 3150
Wire Wire Line
	3850 3250 4150 3250
Wire Wire Line
	3850 3350 4150 3350
Wire Wire Line
	3850 3450 4150 3450
Wire Wire Line
	3850 3550 4150 3550
Wire Wire Line
	3850 3650 4150 3650
Wire Wire Line
	3850 3750 4150 3750
Wire Wire Line
	3850 3850 4150 3850
Wire Bus Line
	4250 4350 8600 4350
Entry Wire Line
	5950 2750 6050 2650
Entry Wire Line
	6150 2650 6050 2750
Entry Wire Line
	6250 2650 6150 2750
Entry Wire Line
	6350 2650 6250 2750
Entry Wire Line
	6450 2650 6350 2750
Entry Wire Line
	6550 2650 6450 2750
Entry Wire Line
	6650 2650 6550 2750
Entry Wire Line
	6750 2650 6650 2750
Wire Wire Line
	5950 2850 5950 2750
Wire Wire Line
	6050 2850 6050 2750
Wire Wire Line
	6150 2850 6150 2750
Wire Wire Line
	6250 2850 6250 2750
Wire Wire Line
	6350 2850 6350 2750
Wire Wire Line
	6450 2850 6450 2750
Wire Wire Line
	6550 2850 6550 2750
Wire Wire Line
	6650 2850 6650 2750
Wire Bus Line
	8600 2650 8600 4350
Entry Wire Line
	6050 1100 5950 1200
Entry Wire Line
	6150 1100 6050 1200
Entry Wire Line
	6250 1100 6150 1200
Entry Wire Line
	6350 1100 6250 1200
Entry Wire Line
	6450 1100 6350 1200
Entry Wire Line
	6550 1100 6450 1200
Entry Wire Line
	6650 1100 6550 1200
Entry Wire Line
	6750 1100 6650 1200
Wire Wire Line
	5950 1300 5950 1200
Wire Wire Line
	6050 1300 6050 1200
Wire Wire Line
	6150 1300 6150 1200
Wire Wire Line
	6250 1300 6250 1200
Wire Wire Line
	6350 1300 6350 1200
Wire Wire Line
	6450 1300 6450 1200
Wire Wire Line
	6550 1300 6550 1200
Wire Wire Line
	6650 1300 6650 1200
Wire Bus Line
	8600 1100 8600 2650
Connection ~ 8600 2650
Text Label 5950 1200 3    50   ~ 0
D0
Text Label 6050 1200 3    50   ~ 0
D1
Text Label 6150 1200 3    50   ~ 0
D2
Text Label 6250 1200 3    50   ~ 0
D3
Text Label 6350 1200 3    50   ~ 0
D4
Text Label 6450 1200 3    50   ~ 0
D5
Text Label 6550 1200 3    50   ~ 0
D6
Text Label 6650 1200 3    50   ~ 0
D7
Text Label 5950 2750 3    50   ~ 0
D0
Text Label 6050 2750 3    50   ~ 0
D1
Text Label 6150 2750 3    50   ~ 0
D2
Text Label 6250 2750 3    50   ~ 0
D3
Text Label 6350 2750 3    50   ~ 0
D4
Text Label 6450 2750 3    50   ~ 0
D5
Text Label 6550 2750 3    50   ~ 0
D6
Text Label 6650 2750 3    50   ~ 0
D7
Text Label 3950 3150 0    50   ~ 0
D0
Text Label 3950 3250 0    50   ~ 0
D1
Text Label 3950 3350 0    50   ~ 0
D2
Text Label 3950 3450 0    50   ~ 0
D3
Text Label 3950 3550 0    50   ~ 0
D4
Text Label 3950 3650 0    50   ~ 0
D5
Text Label 3950 3750 0    50   ~ 0
D6
Text Label 3950 3850 0    50   ~ 0
D7
Entry Wire Line
	4150 1450 4250 1550
Wire Bus Line
	6050 1100 8600 1100
Wire Bus Line
	6050 2650 8600 2650
Wire Bus Line
	4250 3250 4250 4350
Wire Bus Line
	4250 1550 4250 3050
Wire Bus Line
	5100 2300 7250 2300
Wire Bus Line
	5100 4050 7250 4050
$EndSCHEMATC
