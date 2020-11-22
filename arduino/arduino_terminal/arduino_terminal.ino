/**
 * Terminal interface.
 * This sketch allow an Arduino to be used as a terminal to log into Pat80.
 * The Arduino is connected to the Pat80 I/O bus and to the terminal computer via USB.
 * The Arduino IDE serial monitor is used to send and receive commands to the Z80.
 */

#define EN 2   // Active low
#define WR 11   // Active low
// DATA BUS IS: 3, 4, 5, 6, 7, 8, 9, 10;

void setup() {
  Serial.begin(115200);
  Serial.println("Pat80 terminal");
  
  pinMode(EN, INPUT);
  pinMode(WR, INPUT);
  DDRD = B00000010; // Port D (used arduino pins 2 to 7) is input. Avoid changing serial pins.
  DDRB = B00000000; // Port B (used arduino pins 8 and 9) is input
  attachInterrupt(digitalPinToInterrupt(EN), onClk, CHANGE);
}

void loop() {}

void onClk() {
  if (digitalRead(EN)) {
    // Clock pulse finished, return to high impedance state
    DDRD = B00000010;
    DDRB = B00000000;
  } else {
    // Clock pulse started
    if (digitalRead(WR)) {      
      // Pat80 wants to Read (we send data)
      DDRD = DDRD | B11111000; // Port D (arduino pins 3 to 7) is output. In or to preserve serial pins and interrupt pin
      DDRB = B00000111; // Port B (0,1,2) = pins 8,9,10 output
      byte incomingByte = 0;  // Defaults to NULL
      // Check if serial data available
      if (Serial.available() > 0) {
        incomingByte = Serial.read();
      }
      // Split byte to two parts
      byte wbPortD = incomingByte << 3;
      byte wbPortB = incomingByte >> 5;
      PORTD = wbPortD;
      PORTB = wbPortB;
    } else {
      // Pat80 wants to Write (we receive data)
      byte rb = (PIND >> 3) | (PINB << 5); // Compose the final byte from the two parts
      if (rb == 0)
        return; // NULL
      if ((rb >= 8 && rb <= 13) || (rb >= 32 && rb <= 127)) {
        // Printable character
        Serial.print((char)rb);
      } else {
        // Non-printable character
        Serial.print("[0x");
        Serial.print(rb, HEX);
        Serial.print("]");
      }
    }
  }
}
