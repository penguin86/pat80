/* HD44780 Character display debugger */

#define EN 2
const byte DATA_BUS[] = {10, 9, 8, 7, 6, 5, 4, 3};

void setup() {
  pinMode(EN, INPUT_PULLUP);
  for(int pin=0; pin < 8; pin++) {
    pinMode(DATA_BUS[pin], INPUT);
  }

  Serial.begin(57600);
  Serial.println("HD44780 debugger");
  Serial.println("DATA BUS    HEX     EN");

  attachInterrupt(digitalPinToInterrupt(EN), onClk, FALLING);
}

void loop() {}

void onClk() {
  unsigned int data = 0;
    for(int pin=0; pin < 8; pin++) {
      byte b = digitalRead(DATA_BUS[pin]) ? 1 : 0;
      Serial.print(b);
      data = (data << 1) + b;   // Shifta di 1 e aggiunge il bit corrente. Serve per ricostruire il numero da binario
    }
    
    char output[50] = {};
    sprintf(output, "    0x%02x    %c", 
      data, 
      digitalRead(EN) ? 'D' : 'I'
    );
    Serial.println(output);
}