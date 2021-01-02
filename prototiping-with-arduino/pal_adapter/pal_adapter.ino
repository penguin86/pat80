#include <TVout.h>
#include <TVoutfonts/fontALL.h>
TVout TV;

// Pins
#define RS 5
#define EN 4
const byte DATA [] = {A5, A4, A3, A2, 13, 12, 11, 10};


bool clkState = false;

void setup() {
  Serial.begin(57600);
  Serial.println("PAL debugger");
  
  // Init comm pins
  pinMode(EN, INPUT);
  pinMode(RS, INPUT);
  for(int pin = 0; pin < 8; pin++) {
    pinMode(DATA[pin], INPUT);
  }

  // Init VGA
  TV.begin(PAL,120,96);
  TV.select_font(font4x6);

  TV.println("TV init");
}

void loop() {
  bool newClkState = digitalRead(EN);
  if (newClkState == false && clkState == true) {
    // Falling edge: read data from bus
    onClk();
  }
  clkState = newClkState;
}

void onClk() {
  bool isCommand = digitalRead(RS);
  if (isCommand) {
    //onCommandReceived();
    onDataReceived();
  } else {
    onDataReceived();
  }
}

void onCommandReceived() {
  
}

void onDataReceived() {
  char ch = readByte();
  TV.print(ch);
  Serial.println(ch);
}

byte readByte() {
  unsigned int data = 0;
  for(int pin=0; pin < 8; pin++) {
    byte b = digitalRead(DATA[pin]) ? 1 : 0;
    data = (data << 1) + b;   // Shifta di 1 e aggiunge il bit corrente. Serve per ricostruire il numero da binario
  }
  return data;
}
