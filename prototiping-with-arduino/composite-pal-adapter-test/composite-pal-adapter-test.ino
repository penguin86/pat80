/**
 * This file is part of Pat80 IO Devices.
 *
 * Pat80 IO Devices is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Pat80 IO Devices is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY * without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Pat80 IO Devices.  If not, see <http://www.gnu.org/licenses/>.
 *
 *
 * Composite pal adapter test.
 * This sketch makes an Arduino send test data to tha Pat80 composite video pal adapter.
 * Connect the video adapter directly to Arduino
 */

const byte CLK = 11;   // output active low
const byte RS = 12;   // output low = DATA register, high = COMMAND register
const byte BUSY = 13;   // Input, Active low
// DATA BUS (Output, active high): 3, 4, 5, 6, 7, 8, 9, 10;

void setup() {
  DDRD = DDRD | B11111000; // Port D (arduino pins 3 to 7) is output. In or to preserve serial pins and interrupt pin
  DDRB = B00000111; // Port B (0,1,2) = pins 8,9,10 output
  pinMode(CLK, OUTPUT);
  pinMode(RS, OUTPUT);
  pinMode(BUSY, INPUT);

  digitalWrite(CLK, HIGH);  // Inactive clock
}

void loop() {
  delay(1000);
  send();
}

void send() {
    // Random char
    char c = random(32, 126);
    // Wait for BUSY to become inactive (HIGH)
    //while(digitalRead(BUSY) == LOW) {}

    // Split byte to two parts and write to ports
    PORTD = c << 3;
    PORTB = c >> 5;

    // Clock pulse
    digitalWrite(CLK, LOW);
    delay(100);
    digitalWrite(CLK, HIGH);
}
