#! /usr/bin/env python
# -*- coding: utf-8 -*-

""" @package docstring
ARDUINO PARALLEL TERMINAL DEPLOYER
This software sends a compiled Z80 binary files to Pat80 monitor via an arduino
with flashed arduino_terminal firmware.

USAGE:
Connect the arduino to a Pat80 I/O port.
Flash /arduino/arduino_terminal firmware into the Arduino.
Connect the Arduino to a PC via USB and power on Pat80
In the Pat80 Memory Monitor select I for IMMEDIATE LOAD
Run this program providing the Arduino USB port and a Z80 binary file
The code contained will be copied in Pat80's memory and executed immediately.

DISCLAIMER:
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
"""

import serial
import time

class TerminalDeployer:
    def __init__(self, port, baudRate, fileName):
        ser = serial.Serial(port, baudRate)
        print "Serial port {} opened with baudrate {}".format(port, str(baudRate))

        ser.write(73)
        while True:
            x = ser.read()
            print(x)
        time.sleep(1)
        ser.write(b'v')

        # Open z80 bin file
        '''
        with open(fileName, "rb") as f:
            print "Sending command IMMEDIATE"
            ser.write(b'I')
            time.sleep(1)
            print "Sending file {}".format(fileName)
            byte = f.read(1)
            while byte:
                print(byte)
                ser.write(byte)
                byte = f.read(1)
            f.close()

        ser.close()
        print "Completed"
        '''

if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument('port', help="arduino parallel monitor USB port")
    parser.add_argument('baudrate', help="arduino parallel monitor USB baudrate")
    parser.add_argument('file', help="asm binary file to send")
    args = parser.parse_args()

    td = TerminalDeployer(args.port, args.baudrate, args.file)
