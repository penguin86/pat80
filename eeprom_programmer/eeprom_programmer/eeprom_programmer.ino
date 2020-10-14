/* ************** EEPROM PROGRAMMER ******************

HARDWARE:

    CORRISPONDENZA PIN EEPROM Atmel AT28C64B  -> ARDUINO MEGA 2560
    (Compatibile con eeprom fino a 16 bit di address bus. In caso di altre eeprom collegare secondo datasheet)
    NB: Nel caso della eeprom da 8k, ci sono solo 12 address bus, quindi gli altri 4 pin provenienti dall'Arduino
    vengono lasciati disconnessi

      Arduino   VCC  11        38   40   44   10   42   12    9    8    7    6    5
      Eeprom    28   27   26   25   24   23   22   21   20   19   18   17   16   15
                ____________________________________________________________________
               |                                                                    |
               |                                                                    |
               |_                                                                   |
               |_)                         Atmel AT28C64B                           |
               |                                                                    |
               |                                                                    |
               |____________________________________________________________________|
               
      Eeprom    1    2    3    4    5    6    7    8    9    10   11   12   13   14
      Arduino       46    36  34   32   30   28   26   24    22    2    3    4   GND




    CORRISPONDENZA FUNZIONALE:
    
      Address bus (A0...A15):     22, 24, 26, 28, 30, 32, 34, 36, 38, 40, 42, 44, 46, 48, 50, 52
      
      Data bus (D0...D7):         2, 3, 4, 5, 6, 7, 8, 9
  
      Control bus:
        /OE     10
        /WE     11
        /CE     12

*/

const byte ROM_DATA[] = {0x76, 0x00, 0x00, 0x00, 0x76, 0x00, 0x00};


const byte ADDR_BUS[] = {52, 50, 48, 46, 44, 42, 40, 38, 36, 34, 32, 30, 28, 26, 24, 22};
const byte DATA_BUS[] = {9, 8, 7, 6, 5, 4, 3, 2};
const byte CTRL_BUS_OE = 10;
const byte CTRL_BUS_WE = 11;
const byte CTRL_BUS_CE = 12;

void setup() {
  Serial.begin(57600);
  for(int pin=0; pin < 16; pin++) {
    pinMode(ADDR_BUS[pin], OUTPUT);
  }
  setDataBusAs(INPUT);
  pinMode(CTRL_BUS_OE, OUTPUT);
  pinMode(CTRL_BUS_WE, OUTPUT);
  pinMode(CTRL_BUS_CE, OUTPUT);
  digitalWrite(CTRL_BUS_OE, HIGH);  //Active low
  digitalWrite(CTRL_BUS_WE, HIGH);  //Active low
  digitalWrite(CTRL_BUS_CE, HIGH);  //Active low

  delay(1000);
  
  //readRom(8192);
  writeRom();
  verifyRom();
}

void writeRom() {
  digitalWrite(CTRL_BUS_OE, HIGH);
  setDataBusAs(OUTPUT);
  Serial.print("Starting to write ROM... ");
  for (int i=0; i<sizeof(ROM_DATA); i++) {
    writeIntToAddressBus(i);
    delayMicroseconds(5); // Address hold time (tAH)
    digitalWrite(CTRL_BUS_CE, LOW);
    digitalWrite(CTRL_BUS_WE, LOW);
    writeByteToDataBus(ROM_DATA[i]);
    delayMicroseconds(5); // Data setup time (tDS)
    digitalWrite(CTRL_BUS_WE, HIGH);
    digitalWrite(CTRL_BUS_CE, HIGH);  //Active low
    delayMicroseconds(5); // Data hold time (tDH)
  }
  setDataBusAs(INPUT);
  Serial.println("Done.");
}

void verifyRom() {
  Serial.print("Starting to verify ROM... ");
  digitalWrite(CTRL_BUS_WE, HIGH);  //Active low
  char output[50] = {};
  for (int i=0; i<sizeof(ROM_DATA); i++) {
    writeIntToAddressBus(i);
    delayMicroseconds(5);
    digitalWrite(CTRL_BUS_OE, LOW);  //Active low
    digitalWrite(CTRL_BUS_CE, LOW);  //Active low
    delayMicroseconds(5);
    byte readData = getData();
    if(readData != ROM_DATA[i]) {
      sprintf(output, "Error at addr %04x: expected %02x, found %02x", i, ROM_DATA[i], readData);
      Serial.println(output);
    }
    
    while(true){}
    digitalWrite(CTRL_BUS_OE, HIGH);  //Active low
    digitalWrite(CTRL_BUS_CE, HIGH);  //Active low
    delayMicroseconds(5);
  }
  Serial.println("Done.");
}

void readRom(int bytes) {
  digitalWrite(CTRL_BUS_WE, HIGH);  //Active low
  char output[50] = {};
  for (int i=0; i<bytes; i++) {
    writeIntToAddressBus(i);
    delayMicroseconds(5);
    digitalWrite(CTRL_BUS_OE, LOW);  //Active low
    digitalWrite(CTRL_BUS_CE, LOW);  //Active low
    delayMicroseconds(5);
    byte readData = getData();
    sprintf(output, "0x%02x ", readData);
    Serial.print(output);
    digitalWrite(CTRL_BUS_OE, HIGH);  //Active low
    digitalWrite(CTRL_BUS_CE, HIGH);  //Active low
    delayMicroseconds(5);
  }
  Serial.println("Done.");
}

unsigned int getData() {
  setDataBusAs(INPUT);
  unsigned int data = 0;
    for(int pin=0; pin < 8; pin++) {
      byte b = digitalRead(DATA_BUS[pin]) ? 1 : 0;
      data = (data << 1) + b;   // Shifta di 1 e aggiunge il bit corrente. Serve per ricostruire il numero da binario
    }
    return data;
}

void setDataBusAs(byte mode){
  for(int pin=0; pin < 8; pin++) {
    pinMode(DATA_BUS[pin], mode);
  }  
}

void writeByteToDataBus(byte j) {
  setDataBusAs(OUTPUT);
  for (int n=0; n<8; n++)
  {
    if((0x01&j) < 0x01)
    {
      digitalWrite(DATA_BUS[n],LOW);
    } else {
      digitalWrite(DATA_BUS[n],HIGH);
    }
    j>>=1;
  }
}


void writeIntToAddressBus(int j) {
  for (int n=0; n<16; n++)
  {
    if((0x01&j) < 0x01)
    {
      digitalWrite(ADDR_BUS[n],LOW);
    } else {
      digitalWrite(ADDR_BUS[n],HIGH);
    }
    j>>=1;
  }
}

void loop() {}
