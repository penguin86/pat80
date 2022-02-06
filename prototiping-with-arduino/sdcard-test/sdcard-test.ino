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
 * SPI SD-Card test sketch
 * Reads the first 128 bytes from sdcard and prints it out as ascii characters in serial monitor at 9200 baud
 *
 * Implementation of the specification at http://elm-chan.org/docs/mmc/mmc_e.html
 */

#define CS 5    // aka CAT3
#define MOSI 4  // aka DI or CMD
#define SCK 3   // aka CAT3
#define MISO 2  // aka DAT0

void setup() {
  pinMode(CS, OUTPUT);
  pinMode(MOSI, OUTPUT);
  pinMode(SCK, OUTPUT);
  pinMode(MISO, INPUT);

  Serial.begin(9600);

  /***** Init sequence *******/

  // Wait 1ms
  delay(1);

  Serial.println("Init card...");


  // >= 75 clocks with CS and DI high
  digitalWrite(CS, HIGH);
  digitalWrite(MOSI, HIGH);
  for (byte i=0; i<80; i++) {
    clk();
  }

  // CMD0 with CS low (Software reset). Means "Leave native mode and enter SPI mode"
  digitalWrite(CS, LOW);
  byte arg[] = {0x00,0x00,0x00,0x00};
  sendCommand(B01000000, arg); // First two bits are always 01. Command is 0 (000000).
  byte resp = receiveResponse();
  Serial.print("    CMD0 response: ");
  Serial.println(resp, HEX);
  // Now card is in idle mode

  // Send CMD8 (check voltage) to find if sd version is 2 or previous
  byte arg2[] = {0x00,0x00,0x00,0x00};
  sendCommand(B01001000, arg2); // CMD8
  resp = receiveResponse();
  Serial.print("    CMD8 response: ");
  Serial.println(resp, HEX);

  if (resp == 5) {
    // CMD8 Illegal command: sd version 1.X

    while(true) {
      // Now send ACMD41. ACMD is a CMD55 followed by a CMDxx
      byte arg3[] = {0x00,0x00,0x00,0x00};
      sendCommand(B01110111, arg3); // CMD55
      //resp = receiveResponse();
      Serial.print("    CMD55 response: ");
      Serial.println(resp, HEX);
      byte arg4[] = {0x40,0x00,0x00,0x00};
      sendCommand(B01101001, arg4); // CMD41
      resp = receiveResponse();
      Serial.print("    CMD41 response: ");
      Serial.println(resp, HEX);
    }
  } else {
    Serial.print("Sd version 2 not supported.");
  }
  
  
  digitalWrite(CS, HIGH);

}

void loop() {}

/**
 * Sends a clock cycle
 */
void clk() {
  digitalWrite(SCK, HIGH);
  //delayMicroseconds(1);
  digitalWrite(SCK, LOW);
  //delayMicroseconds(1);
}

/**
 * Sends a command to card.
 * The sent CRC field is valid for the CMD0 message.
 * This is ok, since the CRC field will not be checked in SPI mode.
 * @param index: the command index byte. First two bytes are the sync bytes "01".
 */
void sendCommand(byte index, byte arg[]) {
  // Send command index (2+6=8 bits)
  sendByte(index);
  // Send argument (32 bit)
  for(byte i=0; i<4; i++) {
    sendByte(arg[i]);
  }
  // Send CRC with final stop bit (7+1=8 bits)
  sendByte(B10010101);  // We send always the CMD0 CRC, because is not checked in SPI mode
}

/**
 * Sends a byte to the card. The two MSB must be 01 as per specification.
 * Byte is sent MSB first.
 */
void sendByte(byte b) {
  for (byte i=0; i<8; i++) {
    // If last bit is 1 set MOSI HIGH, else LOW
    digitalWrite(MOSI, (b & B10000000) == B10000000 ? HIGH : LOW);
    //Serial.print((b & B10000000) == B10000000 ? "1" : "0");
    clk();
    // Shift byte to have, in the next cycle, the next bit in last position
    b = b << 1;
  }
}

/**
 * Receives the response from card
 * MSB first.
 */
byte receiveResponse() {
  digitalWrite(CS, LOW);
  digitalWrite(MOSI, HIGH);
  
  // continuously toggle the SD CLK signal and observe the MISO line for data:
  // message response starts with 0
  while (digitalRead(MISO)) {
    clk();
  }  // Wait for first 0

  byte resp = 0;
  // Read 8 bits
  for (byte i=0; i<8; i++) {
    resp = resp << 1;
    resp = resp | digitalRead(MISO);
    clk();
  }
  return resp;
}
