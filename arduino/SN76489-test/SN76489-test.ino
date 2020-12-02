/**
 * SN76489 sound chip test
 * 
 * DATA BUS IS: 3, 4, 5, 6, 7, 8, 9, 10 (NOTE: 3 is D0, but D0 is the MSB)
 * WE 11   (Active low)
 */

void setup() {
    DDRD = DDRD | B11111000; // Port D (arduino pins 3 to 7) is output. In or to preserve serial pins and interrupt pin
    DDRB = B00001111; // Port B (0,1,2,3) = pins 8,9,10,11 output (11 is WE)
}

void loop() {
}



void writeByte(byte b) {
    // Split byte to two parts and write to data bus
    PORTD = b << 3;
    PORTB = b >> 5;
    // Pulse WE
    b
}
