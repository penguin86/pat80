/**
 * Terminal interface.
 * This sketch allow an Arduino to be used as a terminal to log into Pat80.
 * The Arduino is connected to the Pat80 I/O bus and to the terminal computer via USB.
 * The Python Terminal Monitor or the Arduino IDE serial monitor is used to send 
 * and receive commands to/from the Z80.
 * 
 * Seen from the Pat80, the terminal interface has two registers:
 * DATA Register at addr 0x00 (\RS) contains the last received byte from the pc
 * DATA_AVAILABLE Register at addr 0x01 (RS) contains the number of bytes in the buffer,
 * waiting to be read from the Pat80. A READ operation on DATA register removes the
 * byte from the buffer and decrements DATA_AVAILABLE.
 */

// EN 2   // Input, Active low
// WR 11   // Input, Active low
// RS 12   // Input, low = DATA register, high = DATA_AVAILABLE register
// DATA BUS (Input/Output, active high): 3, 4, 5, 6, 7, 8, 9, 10;

byte incomingBuffer = 0;  // Incoming from computer, to the Pat80
byte outgoingBuffer = 0;  // Outgoing to computer, from the Pat80
byte availableBytes = 0;  // Available bytes in the incoming buffer (for the DATA_AVAILABLE register)

void setup() {  
  DDRD = B00000010; // Port D (used arduino pins 2 (EN) and 3 to 7 (DATA)) is input. Avoid changing serial pins.
  DDRB = B00000000; // Port B (used arduino pins 8 to 10 (DATA), 11 (WR) and 12 (RS) is input
  
  Serial.begin(2000000);
  Serial.println("Pat80 terminal");

  attachInterrupt(digitalPinToInterrupt(2), onClk, CHANGE);
}

void loop() {
  if (Serial.available() > 0) {
    incomingBuffer = Serial.read();
    availableBytes = 1;   // TODO: Implement a 256 byte buffer and store the avail bytes number in this var
  }
  if (outgoingBuffer != 0) {
    if ((outgoingBuffer >= 8 && outgoingBuffer <= 13) || (outgoingBuffer >= 32 && outgoingBuffer <= 127)) {
      // Printable character
      Serial.print((char)outgoingBuffer);
    } else {
      // Non-printable character
      Serial.print("[0x");
      Serial.print(outgoingBuffer, HEX);
      Serial.print("]");
    }
    outgoingBuffer = 0;
  }
}

void onClk() {
  // In any case, return to high impedance state
  DDRD = B00000010;
  DDRB = B00000000;
  if ((PIND & B00000100) == 0) {
     // EN is LOW: Clock pulse started
    if ((PINB & B00001000) == B00001000) {  // WR is HIGH (Pat80 wants to Read (we send data))
      DDRD = DDRD | B11111000; // Port D (arduino pins 3 to 7) is output. In or to preserve serial pins and interrupt pin
      DDRB = B00000111; // Port B (0,1,2) = pins 8,9,10 output
      if ((PINB & B00010000) == B00010000) {  // RS is HIGH: we send number of bytes available in buffer
        // Split byte to two parts
        PORTD = availableBytes << 3;
        PORTB = availableBytes >> 5;
      } else {
        // Split byte to two parts
        PORTD = incomingBuffer << 3;
        PORTB = incomingBuffer >> 5;
        incomingBuffer = 0;
        availableBytes = 0;
      }
    } else {
      // Pat80 wants to Write (we receive data)
      outgoingBuffer = (PIND >> 3) | (PINB << 5); // Compose the final byte from the two parts
    }
  }
}
