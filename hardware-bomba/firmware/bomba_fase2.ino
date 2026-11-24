#include <LiquidCrystal.h>

// Pines LCD: RS=21(a14), E=22(a17), D4=15(a4), D5=5(a10), D6=23(a18), D7=4(a7)
LiquidCrystal lcd(21, 22, 15, 5, 23, 4);

// Pines de controles
const int btnPins[4]  = {13, 14, 27, 26}; // j5(Rojo), j8(Azul), j9(Verde), j10(Amarillo)
const int wirePins[4] = {19, 18, 17, 16}; // a12, a11, a9, a8
const int ledPins[3]  = {32, 33, 2};      // j13, j12, a5
const int buzzerPin   = 25;               // j11

unsigned long totalTime = 180; // 3 minutos
unsigned long lastTick = 0;
int strikes = 0;
bool gameOver = false;
bool defused = false;

int targetWire = 0;
bool wireCut[4] = {false, false, false, false};
bool modWiresSolved = false;

int btnSequence[4];
int btnStep = 0;
bool modButtonsSolved = false;
String serialCode = "";

// Función para hacer sonar el buzzer activo sin trabar el reloj
void beep(int ms) {
  digitalWrite(buzzerPin, HIGH);
  delay(ms);
  digitalWrite(buzzerPin, LOW);
}

// Función para reproducir el ritmo de "La Bombachita"
void playBombachita() {
  // Patrón rítmico aproximado de la cumbia clásica
  int melody[] = { 
    200, 200, 200, 400, // Ti-ti-ti-Taa
    200, 200, 200, 400, // Ti-ti-ti-Taa
    200, 200, 400,      // Ti-ti-Taa
    200, 200, 400       // Ti-ti-Taa
  };
  
  int pauses[] = { 
    100, 100, 100, 300, 
    100, 100, 100, 300, 
    100, 100, 200, 
    100, 100, 500
  };

  for (int i = 0; i < 14; i++) {
    beep(melody[i]);
    delay(pauses[i]);
  }
}

void explode() {
  gameOver = true;
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("*** BOOOM! ***");
  lcd.setCursor(0, 1);
  lcd.print("BOMBA DETONADA");
  
  // En lugar de un solo pitido largo, suena la melodía
  playBombachita();
}

void addStrike() {
  strikes++;
  beep(400);
  if (strikes <= 3) {
    digitalWrite(ledPins[strikes - 1], HIGH);
  }
  if (strikes >= 3) {
    explode();
  }
}

void winGame() {
  defused = true;
  gameOver = true;
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("DESACTIVADA!");
  lcd.setCursor(0, 1);
  lcd.print("EQUIPO A SALVO");
  beep(150);
  delay(100);
  beep(150);
  delay(100);
  beep(400);
}

void setup() {
  Serial.begin(115200);
  pinMode(buzzerPin, OUTPUT);
  digitalWrite(buzzerPin, LOW);

  for (int i = 0; i < 4; i++) pinMode(btnPins[i], INPUT_PULLUP);
  for (int i = 0; i < 4; i++) pinMode(wirePins[i], INPUT_PULLUP);
  for (int i = 0; i < 3; i++) {
    pinMode(ledPins[i], OUTPUT);
    digitalWrite(ledPins[i], LOW);
  }

  lcd.begin(16, 2);
  randomSeed(esp_random());

  targetWire = random(0, 4);
  for (int i = 0; i < 4; i++) {
    btnSequence[i] = random(0, 4);
  }
serialCode = "W" + String(targetWire + 1) + "-B" + String(btnSequence[0] + 1) + String(btnSequence[1] + 1) + String(btnSequence[2] + 1) + String(btnSequence[3] + 1);
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("BOMBA ARMADA!");
  lcd.setCursor(0, 1);
  lcd.print("COD: " + serialCode);
  
  Serial.println("BOMBA INICIADA - CODIGO: " + serialCode);
  beep(300);
  delay(2000);
  lcd.clear();
}

void loop() {
  if (gameOver) return;

  // 1. Reloj cada 1 segundo
  if (millis() - lastTick >= 1000) {
    lastTick = millis();
    if (totalTime > 0) {
      totalTime--;
      beep(50); // Bip corto cada segundo
      
      int mins = totalTime / 60;
      int secs = totalTime % 60;
      lcd.setCursor(0, 0);
      lcd.print("TIEMPO: 0");
      lcd.print(mins);
      lcd.print(":");
      if (secs < 10) lcd.print("0");
      lcd.print(secs);
      lcd.print("   ");

      lcd.setCursor(0, 1);
      lcd.print("ID:");
      lcd.print(serialCode);
      lcd.print(" ");
      lcd.print(modWiresSolved ? "OK" : "--");
      lcd.print("/");
      lcd.print(modButtonsSolved ? "OK" : "--");
    } else {
      explode();
      return;
    }
  }

  // 2. Revisar 4 Cables Cortables
  if (!modWiresSolved) {
    for (int i = 0; i < 4; i++) {
      if (!wireCut[i] && digitalRead(wirePins[i]) == HIGH) {
        delay(50);
        if (digitalRead(wirePins[i]) == HIGH) {
          wireCut[i] = true;
          Serial.println("Cable cortado: " + String(i + 1));
          if (i == targetWire) {
            modWiresSolved = true;
            beep(250);
          } else {
            addStrike();
          }
        }
      }
    }
  }

  // 3. Revisar 4 Botones Arcade
  if (!modButtonsSolved) {
    for (int i = 0; i < 4; i++) {
      if (digitalRead(btnPins[i]) == LOW) {
        delay(150);
        while (digitalRead(btnPins[i]) == LOW);
        Serial.println("Boton presionado: " + String(i + 1));
        if (i == btnSequence[btnStep]) {
          btnStep++;
          beep(100);
          if (btnStep >= 4) {
            modButtonsSolved = true;
          }
        } else {
          btnStep = 0;
          addStrike();
        }
      }
    }
  }

  // 4. Ganar partida
  if (modWiresSolved && modButtonsSolved && !defused) {
    winGame();
  }
}
