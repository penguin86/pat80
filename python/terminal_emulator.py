#! /usr/bin/env python
# -*- coding: utf-8 -*-

""" @package docstring
ARDUINO PARALLEL TERMINAL EMULATOR

USAGE:
Connect the arduino to a Pat80 I/O port.
Flash /arduino/arduino_terminal firmware into the Arduino.
Connect the Arduino to a PC via USB and power on Pat80
Run this program providing the Arduino USB port

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
import curses
import time

class TerminalEmulator:
    def __init__(self, w, ser):
        w.clear()
        w.move(0,0)
        while True:
            try:
                # read key and write to serial port
                key = w.get_wch()   # TODO: Mettere no delay mode
                if key == 10 or (key > 31 and key < 256):
                    # Is a character
                    ser.write(key)
            except Exception as e:
                # No input   
                pass         

            # read serial port and write to curses
            if ser.inWaiting():
                b = ser.read(1)
                if ord(b) > 31 or ord(b) == 10:
                    w.addch(b)

            stdscr.refresh()

        

if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument('port', help="arduino parallel monitor USB port")
    parser.add_argument('baudrate', help="arduino parallel monitor USB baudrate")
    args = parser.parse_args()

    # Init curses
    stdscr = curses.initscr()
    curses.noecho()
    curses.cbreak()
    stdscr.idlok(True)
    stdscr.scrollok(True)

    try:
        ser = serial.Serial(args.port, args.baudrate, timeout=0)
        td = TerminalEmulator(stdscr, ser)           
    except Exception as e:
        print(e)
    finally:
        # Close serial
        ser.close()
        # Stop curses
        curses.nocbreak()
        curses.echo()
        curses.endwin()

