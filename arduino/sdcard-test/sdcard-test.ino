/**
 * SPI SD-Card test sketch
 * Reads the first 128 bytes from cf and prints it out as ascii characters in serial monitor at 9200 baud
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
  sendCommand(B01000000); // First two bits are always 01. Command is 0 (000000).
  byte resp = receiveResponse();
  Serial.println("Card response:");
  Serial.println(resp, HEX);
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
void sendCommand(byte index) {
  // Send command index (2+6=8 bits)
  sendByte(index);
  // Send argument (32 bit)
  for(byte i=0; i<4; i++) {
    sendByte(0);
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
    if (digitalRead(MISO)) {
      resp = resp | B00000001;
    }
    resp = resp << 1;
    clk();
  }
  
}
