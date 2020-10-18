/* HD44780 Character display debugger */

#define EN 2
#define RS 11
const byte DATA_BUS[] = {10, 9, 8, 7, 6, 5, 4, 3};

void setup() {
  pinMode(RS, INPUT);
  pinMode(EN, INPUT);
  for(int pin=0; pin < 8; pin++) {
    pinMode(DATA_BUS[pin], INPUT);
  }

  Serial.begin(57600);
  Serial.println("HD44780 debugger");
  Serial.println("DATA BUS    HEX     RS   EN");

  attachInterrupt(digitalPinToInterrupt(EN), onClk, CHANGE);
}

void loop() {}

void onClk() {
  unsigned int data = 0;
    for(int pin=0; pin < 8; pin++) {
      byte b = digitalRead(DATA_BUS[pin]) ? 1 : 0;
      Serial.print(b);
      data = (data << 1) + b;   // Shifta di 1 e aggiunge il bit corrente. Serve per ricostruire il numero da binario
    }
    
    char output[30] = {};
    sprintf(output, "    0x%02x    %c    %c", data, digitalRead(RS) ? 'D' : 'I', digitalRead(EN) ? 'H' : 'L');
    Serial.println(output);
}
