#! /usr/bin/env python3
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
import textwrap
import os


class TerminalEmulator:
    SYNC_SLEEP = 0.001

    def __init__(self, w, ser):
        w.clear()
        w.move(0,0)
        while True:

            # read serial port and write to curses
            if ser.inWaiting():
                b = ser.read(1)
                if ord(b) > 31 or ord(b) == 10:
                    w.addch(b)

            # read key and write to serial port
            key = w.getch()
            if key == 10 or (key > 31 and key < 256):
                # Is a character
                time.sleep(self.SYNC_SLEEP)
                ser.write(bytes([key]))
            elif int(key) == 1:     # CTRL+A, enter ADB mode
                # Save cursor position
                (xPos, yPos) = w.getyx()
                self.adbMode(w, ser)
                # Restore cursor position
                w.move(xPos, yPos)


            w.refresh()

    def adbMode(self, w, ser):
        stdscr.nodelay(False)
        curses.echo()

        # Clear first line
        w.move(0,0)
        w.clrtoeol()
        # Ask for file path
        w.addstr(0, 0, '[ADB MODE] file to load:', curses.A_REVERSE)
        path = w.getstr()
        try:
            header = bytearray(2)
            size = os.path.getsize(path)
            # Compute the two header bytes needed to declare the length of the stream
            header[1] = size & 255 # get lower 8 bits
            size >>= 8 # shift by 8 bits
            header[0] = size & 255 # get second lower 8 bits
            # Log size for debug
            w.addstr("Header bytes: {}".format(header.hex()))
            w.refresh()

            # Send the two heading bytes (most significant first)
            ser.write(header[0:1])
            time.sleep(self.SYNC_SLEEP)
            ser.write(header[1:2])
            time.sleep(self.SYNC_SLEEP)

            # Send the actual binary stream
            with open(path, "rb") as f:
                byte = f.read(1)
                while byte:
                    # Check if terminal interface (Arduino) is busy
                    ser.write(b'\x01')  # COMMAND_BUFFER
                    ser.read()
                    ser.write(byte)
                    byte = f.read(1)
        except IOError as e:
            w.move(0,0)
            w.clrtoeol()
            w.addstr(" {}".format(str(e)), curses.A_REVERSE)
            w.refresh()

        curses.noecho()
        stdscr.nodelay(True)
        

if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawTextHelpFormatter,
        epilog=textwrap.dedent('''\
            Pat80 Terminal Emulator with ADB (Assembly Deploy Bridge) support.
            CTRL+C Exits
            CTRL+A ADB mode: sends binary file
        ''')
    )
    parser.add_argument('port', help="arduino parallel monitor USB port")
    parser.add_argument('baudrate', help="arduino parallel monitor USB baudrate")
    args = parser.parse_args()

    # Init curses
    stdscr = curses.initscr()
    curses.noecho()
    curses.cbreak()
    stdscr.idlok(True)
    stdscr.scrollok(True)
    stdscr.nodelay(True)

    exitMessage = None
    exitSuccess = True
    try:
        ser = serial.Serial(args.port, args.baudrate, timeout=0)
        td = TerminalEmulator(stdscr, ser)
    except KeyboardInterrupt:
        exitMessage = 'Bye!'
        exitSuccess = True
    except Exception as e:
        exitMessage = str(e)
        exitSuccess = False
    finally:
        # Close serial
        ser.close()
        # Stop curses
        curses.nocbreak()
        curses.echo()
        curses.endwin()
        # Print exit message
        print(exitMessage)
        exit(0 if exitSuccess else 1)

