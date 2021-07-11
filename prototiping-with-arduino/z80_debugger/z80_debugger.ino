/* ************** DEBUGGER Zilog Z80 ******************
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


HARDWARE:

    CORRISPONDENZA PIN CPU -> ARDUINO MEGA 2560

      Arduino   A12  A15  A14  53   51   49   47   45   43   41   39   37   35   33   31   29   27   25   23   20
      Cpu       40   39   38   37   36   35   34   33   32   31   30   29   28   27   26   25   24   23   22   21
                __________________________________________________________________________________________________
               |                                                                                                  |
               |                                                                                                  |
               |_                                                                                                 |
               |_)                                      Zilog Z80                                                 |
               |                                                                                                  |
               |                                                                                                  |
               |__________________________________________________________________________________________________|

      Cpu       1    2    3    4    5    6    7    8    9    10   11   12   13   14   15   16   17   18   19   20
      Arduino   A8   A9   A11  52   50   21   46   44   42   40   38   36   34   32   30   28   26   24   22   A13




    CORRISPONDENZA FUNZIONALE:
      Address bus (A0...A15):     39, 41, 43, 45, 47, 49, 51, 53, A14, A15, A12, A8, A9, A11, 52, 50
      Data bus (D0...D7):         32, 30, 36, 44, 46, 42, 40, 34
      Control bus:
        CLK     21
        INT     28
        NMI     26
        HALT    24
        MREQ    22
        IORQ    A13
        RFSH    35
        RD      20
        WR      23
        BUSACK  25
        WAIT    27
        BUSREQ  29
        RESET   31
        M1      33
      Other
        GND     37, GND
        Vcc     38

*/


const byte MODE_DEBUGGER = 0;
const byte MODE_ROM_EMULATOR = 1;
const byte MODE_ROM_RAM_EMULATOR = 2;

const byte ADDR_BUS[] = {50, 52, A11, A9, A8, A12, A15, A14, 53, 51, 49, 47, 45, 43, 41, 39};
//const byte DATA_BUS[] = {34, 40, 42, 44, 46, 36, 30, 32};
const byte DATA_BUS[] = {3, 4, 5, 6, 7, 8, 9,10};
//const byte CTRL_BUS_RD = 20;
const byte CTRL_BUS_RD = 3;
const byte CTRL_BUS_WR = 23;
const byte CTRL_BUS_BUSACK = 25;
const byte CTRL_BUS_WAIT = 27;
const byte CTRL_BUS_BUSREQ = 29;
const byte CTRL_BUS_RESET = 31;
const byte CTRL_BUS_M1 = 33;
const byte CTRL_BUS_REFRESH = 35;
const byte CTRL_BUS_IORQ = A13;
const byte CTRL_BUS_MREQ = 22;
const byte CTRL_BUS_HALT = 24;
const byte CTRL_BUS_NMI = 26;
//const byte CTRL_BUS_CLK= 21;
const byte CTRL_BUS_CLK= 2;
const byte CTRL_BUS_INT = 28;
const byte PWR_GND = 37;
const byte PWR_VCC = 38;







/* 
 *  SETUP
 *    Mode:
 *      MODE_DEBUGGER = Debugger (stays in high impedance mode listening to inputs/outputs on data, address and control buses)
 *      MODE_ROM_EMULATOR = Emulates rom with the contents of ROM_DATA
 *      MODE_ROM_RAM_EMULATOR = Emulates ram
*/
const byte MODE = MODE_DEBUGGER;

const byte ROM_DATA[] = {0x00, 0x00, 0x00, 0x00, 0xC3, 0x00, 0x00};
//const byte ROM_DATA[] = {0x00, 0x00, 0x00, 0x00, 0x76, 0x00, 0x00};





void setup() {
  Serial.begin(57600);
  Serial.print("Started in mode ");
  switch(MODE) {
    case MODE_DEBUGGER:
    Serial.println("debugger");
    break;    
    case MODE_ROM_EMULATOR:
    Serial.println("rom emulator");
    break;
    case MODE_ROM_RAM_EMULATOR:
    Serial.println("rom/ram emulator");
    break;
  }
  for(int pin=0; pin < 16; pin++) {
    pinMode(ADDR_BUS[pin], INPUT);
  }  
  setDataBusAs(INPUT);
  pinMode(CTRL_BUS_RD, INPUT);
  pinMode(CTRL_BUS_WR, INPUT);
  pinMode(CTRL_BUS_BUSACK, INPUT);
  pinMode(CTRL_BUS_WAIT, INPUT);
  pinMode(CTRL_BUS_BUSREQ, INPUT);
  pinMode(CTRL_BUS_RESET, INPUT);
  pinMode(CTRL_BUS_M1, INPUT);
  pinMode(CTRL_BUS_REFRESH, INPUT);
  pinMode(CTRL_BUS_IORQ, INPUT);
  pinMode(CTRL_BUS_MREQ, INPUT);
  pinMode(CTRL_BUS_HALT, INPUT);
  pinMode(CTRL_BUS_NMI, INPUT);
  pinMode(CTRL_BUS_CLK, INPUT);
  pinMode(CTRL_BUS_INT, INPUT);

  // Set power pins to high impedance, even if we aren't going to read them, to avoid shorts
  pinMode(PWR_GND, INPUT);
  pinMode(PWR_VCC, INPUT);

  attachInterrupt(digitalPinToInterrupt(CTRL_BUS_CLK), onClk, RISING);
  
}

void onClk() {
  setDataBusAs(INPUT);
  
  switch (MODE) {
    case MODE_DEBUGGER:
      debugCycle();
      break;
    case MODE_ROM_EMULATOR:
      emulateRomCycle();
      break;
    default:
      Serial.println("Unimplemented mode");
  }
}

void loop() {}

void debugCycle() {
  if (!digitalRead(CTRL_BUS_RD) || !digitalRead(CTRL_BUS_WR)) { //RD e WR are active-low
    unsigned int address = getAddress();  
    unsigned int data = getData();    
  
    char output[30] = {};
    sprintf(output, "%04x  %c%c  %02x  %s", address, digitalRead(CTRL_BUS_RD) ? '-' : 'r', digitalRead(CTRL_BUS_WR) ? '-' : 'w', data, digitalRead(CTRL_BUS_RESET) ? "" : "reset");
    Serial.println(output);
  }
}

void emulateRomCycle() {
  if (!digitalRead(CTRL_BUS_RD)) {  //RD e WR are active-low
    unsigned int addr = getAddress();
    if (addr < sizeof(ROM_DATA)) {
      unsigned int data = ROM_DATA[addr];
      writeByteToDataBus(data);
      
      char output[30] = {};
      sprintf(output, "%04x  r-  %02x Emu ROM read", addr, data);
      Serial.println(output);
    }
  }
  if (!digitalRead(CTRL_BUS_WR)) {
    debugCycle();    
  }
}

unsigned int getAddress() {
  unsigned int address = 0;
    for(int pin=0; pin < 16; pin++) {
      byte b = digitalRead(ADDR_BUS[pin]) ? 1 : 0;
      //Serial.print(b);
      address = (address << 1) + b;   // Shifta di 1 e aggiunge il bit corrente. Serve per ricostruire il numero da binario
    }  
    return address;
}

unsigned int getData() {
  unsigned int data = 0;
    for(int pin=0; pin < 8; pin++) {
      byte b = digitalRead(DATA_BUS[pin]) ? 1 : 0;
      //Serial.print(b);
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
