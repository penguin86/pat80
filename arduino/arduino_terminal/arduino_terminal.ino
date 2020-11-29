/**
 * Terminal interface.
 * This sketch allow an Arduino to be used as a terminal to log into Pat80.
 * The Arduino is connected to the Pat80 I/O bus and to the terminal computer via USB.
 * The Arduino IDE serial monitor is used to send and receive commands to the Z80.
 */

// EN 2   // Active low
// WR 11   // Active low
// DATA BUS IS: 3, 4, 5, 6, 7, 8, 9, 10;

byte incomingBuffer = 0;  // Incoming from computer, to the Pat80
byte outgoingBuffer = 0;  // Outgoing to computer, from the Pat80

void setup() {
  Serial.begin(2000000);
  Serial.println("Pat80 terminal");
  
  DDRD = B00000010; // Port D (used arduino pins 2 (EN) and 3 to 7 (DATA)) is input. Avoid changing serial pins.
  DDRB = B00000000; // Port B (used arduino pins 8 to 10 (DATA) and 11 (WR)) is input
  attachInterrupt(digitalPinToInterrupt(2), onClk, CHANGE);
}

void loop() {
  if (Serial.available() > 0) {
    incomingBuffer = Serial.read();
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
  }
}

void onClk() {
  if (PINB & B00000100 == B00000100) { // If EN is HIGH (clock pulse finished)
    // Clock pulse finished, return to high impedance state
    DDRD = B00000010;
    DDRB = B00000000;
  } else {
     // EN is LOW: Clock pulse started
    if (PIND & B00001000 == B00001000) {  // WR is HIGH (Pat80 wants to Read (we send data))
      DDRD = DDRD | B11111000; // Port D (arduino pins 3 to 7) is output. In or to preserve serial pins and interrupt pin
      DDRB = B00000111; // Port B (0,1,2) = pins 8,9,10 output
      // Split byte to two parts
      PORTD = incomingBuffer << 3;
      PORTB = incomingBuffer >> 5;
    } else {
      // Pat80 wants to Write (we receive data)
      outgoingBuffer = (PIND >> 3) | (PINB << 5); // Compose the final byte from the two parts
    }
  }
}
