/**
 *
 * This file is part of Pat80 Utils.
 *
 * Pat80 Utils is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Pat80 Utils is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY * without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Pat80 Utils.  If not, see <http://www.gnu.org/licenses/>.
 *
 *
 * SN76489 sound chip test
 *
 * DATA BUS IS: 2, 3, 4, 5, 6, 7, 8, 9 (NOTE: 2 is D0, but D0 is the MSB)
 * WE 10   (Active low)
 */

const byte DATA_BUS[] = {9, 8, 7, 6, 5, 4, 3, 2};
const byte WE = 10;

void setup() {
  // Setup pins
  for(int pin=0; pin < 8; pin++) {
    pinMode(DATA_BUS[pin], OUTPUT);
  }
  pinMode(WE, OUTPUT);
  digitalWrite(WE, HIGH);

  /*  Init device (silence all channels)
   *  Bits meaning:
   *  1 R0 R1 R2 A0 A1 A2 A3
   *    Bit0 is 1
   *    Bit1,2,3 select the channel: 001, 011, 101, 111(noise)
   *    Bit4,5,6,7 selecy the attenuation (0000=full volume, 1111=silent)
   */
  SendByte(B10011111);    // Sil ch 1
  SendByte(B10111111);    // Sil ch 2
  SendByte(B11011111);    // Sil ch 3
  SendByte(B11111111);    // Sil noise

  delay(1000);

  // Channel 1 to max volume
  SendByte(B10010000);

  /*  Play note on channel 1
   *  Requires sending 2 bytes.
   *  Bits meaning:
   *  1 R0 R1 R2 F6 F7 F8 F9    0 0 F0 F1 F2 F3 F4 F5
   *    First bit:  1=low byte (first sent), 0=high byte (last sent)
   *    R0,1,2: select the channel: 000, 010, 100, 110(noise)
   *    F0..9: frequency value calculated as:
   *      f = REF_CLK / 32 * n
   *      Where f is the resulting frequency in HZ, REF_CLK is the reference clock on pin 14 in HZ and n is F0..9
   */
   SendByte(B10000000); SendByte(B00100000);
   delay(500);
   SendByte(B10000000); SendByte(B00010000);
   delay(500);
   SendByte(B10000000); SendByte(B00001000);
   delay(500);

   SendByte(B10011111);    // Sil ch 1

   delay(1000);

   // Play notes on channel 1,2,3
   SendByte(B10010000); // Channel 1 vol max (0000)
   SendByte(B10000000); SendByte(B00100000);  // Note on ch1
   delay(500);
   SendByte(B10110010); // Channel 2 vol 0010
   SendByte(B10100000); SendByte(B00010000);  // Note on ch2
   delay(500);
   SendByte(B11010100); // Channel 3 vol 0100
   SendByte(B11000000); SendByte(B00001000);  // Note on ch3
   delay(500);

   SendByte(B10011111);    // Sil ch 1
   SendByte(B10111111);    // Sil ch 2
   SendByte(B11011111);    // Sil ch 3

   delay(1000);
   /*
    * Play noise on channel 4
    */

}

void loop() {}

void SendByte(byte b) {
  digitalWrite(DATA_BUS[0], (b&1)?HIGH:LOW);
  digitalWrite(DATA_BUS[1], (b&2)?HIGH:LOW);
  digitalWrite(DATA_BUS[2], (b&4)?HIGH:LOW);
  digitalWrite(DATA_BUS[3], (b&8)?HIGH:LOW);
  digitalWrite(DATA_BUS[4], (b&16)?HIGH:LOW);
  digitalWrite(DATA_BUS[5], (b&32)?HIGH:LOW);
  digitalWrite(DATA_BUS[6], (b&64)?HIGH:LOW);
  digitalWrite(DATA_BUS[7], (b&128)?HIGH:LOW);
  delay(1);
  digitalWrite(WE, LOW);
  delay(1);
  digitalWrite(WE, HIGH);
}
