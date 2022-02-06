/*
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
 *
 *
 * HD44780 Character display debugger
 * Used to intercept data sent from Pat80 to character display
 */

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
