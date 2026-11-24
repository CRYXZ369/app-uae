#include <Wire.h>
#include <LiquidCrystal_I2C.h>

// =========================================================
// 1. MAPEO EXACTO DE PINES SEGÚN TU PROTOBOARD (FILAS 1-19)
// =========================================================
// Pantalla LCD 16x2 I2C (Mover SDA a a14 [21] y SCL a a17 [22])
#define PIN_I2C_SDA 21       // a14
#define PIN_I2C_SCL 22       // a17
LiquidCrystal_I2C lcd(0x27, 16, 2); // Si no se ven letras, cambiar 0x27 por 0x3F

// LEDs de Strike
#define PIN_LED_STRIKE_1 4   // a7  (puente desde e25 hacia a7)
#define PIN_LED_STRIKE_2 32  // j13 (puente desde j27 hacia j13)
#define PIN_LED_STRIKE_3 33  // j12 (puente desde j29 hacia j12)

// Buzzer
#define PIN_BUZZER 25        // j11

// Botones Arcade (conectados a GND -> presionado = LOW)
#define BTN_ROJO     13      // j5
#define BTN_AZUL     14      // j8
#define BTN_VERDE    27      // j9
#define BTN_AMARILLO 26      // j10

// Cables para cortar (conectados a GND -> conectado = LOW, cortado = HIGH)
// Nota: Cable 1 (negro en a20) es cable trampa sin pin en ESP32
#define CABLE_2_ROJO     19  // a12
#define CABLE_3_BLANCO   18  // a11
#define CABLE_4_AZUL     17  // a9
#define CABLE_5_AMARILLO 16  // a8

// Pines libres reservados para el siguiente paso (Teclado 4x4 o Botón Timbre):
// Lado izquierdo libres: a10 (GPIO 5), a18 (GPIO 23), a4 (GPIO 15), a5 (GPIO 2)
// Lado derecho libres (solo entrada, ideales para columnas del teclado o timbre):
// j14 (GPIO 35), j15 (GPIO 34), j16 (GPIO 39), j17 (GPIO 36)

// =========================================================
// 2. VARIABLES DE ESTADO DEL JUEGO
// =========================================================
int strikes = 0;
const int MAX_STRIKES = 3;
bool bombaExplotada = false;
bool bombaDesactivada = false;

unsigned long tiempoRestanteSeg = 300; // 5:00 minutos
unsigned long ultimoTick = 0;

const int pinesCables[4] = {
  CABLE_2_ROJO,
  CABLE_3_BLANCO,
  CABLE_4_AZUL,
  CABLE_5_AMARILLO
};
bool estadoCableAnterior[4];

// Índice del cable correcto a cortar (0=Rojo/a12, 1=Blanco/a11, 2=Azul/a9, 3=Amarillo/a8)
const int CABLE_CORRECTO = 1;

void pitido(int frecuencia, int duracionMs) {
  tone(PIN_BUZZER, frecuencia, duracionMs);
}

void actualizarLedsStrike() {
  digitalWrite(PIN_LED_STRIKE_1, strikes >= 1 ? HIGH : LOW);
  digitalWrite(PIN_LED_STRIKE_2, strikes >= 2 ? HIGH : LOW);
  digitalWrite(PIN_LED_STRIKE_3, strikes >= 3 ? HIGH : LOW);
}

void registrarStrike(const char* motivo) {
  strikes++;
  actualizarLedsStrike();
  pitido(180, 500);

  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("!! STRIKE ");
  lcd.print(strikes);
  lcd.print("/3 !!");
  lcd.setCursor(0, 1);
  lcd.print(motivo);
  delay(1200);
  lcd.clear();

  if (strikes >= MAX_STRIKES) {
    bombaExplotada = true;
  }
}

void setup() {
  Serial.begin(115200);

  Wire.begin(PIN_I2C_SDA, PIN_I2C_SCL);
  lcd.init();
  lcd.backlight();

  pinMode(PIN_LED_STRIKE_1, OUTPUT);
  pinMode(PIN_LED_STRIKE_2, OUTPUT);
  pinMode(PIN_LED_STRIKE_3, OUTPUT);
  pinMode(PIN_BUZZER, OUTPUT);
  actualizarLedsStrike();

  pinMode(BTN_ROJO, INPUT_PULLUP);
  pinMode(BTN_AZUL, INPUT_PULLUP);
  pinMode(BTN_VERDE, INPUT_PULLUP);
  pinMode(BTN_AMARILLO, INPUT_PULLUP);

  for (int i = 0; i < 4; i++) {
    pinMode(pinesCables[i], INPUT_PULLUP);
    estadoCableAnterior[i] = digitalRead(pinesCables[i]);
  }

  lcd.setCursor(0, 0);
  lcd.print("BOMBA ACTIVADA");
  lcd.setCursor(0, 1);
  lcd.print("INICIANDO...");
  pitido(1200, 150);
  delay(1500);
  lcd.clear();
}

void loop() {
  if (bombaExplotada) {
    lcd.setCursor(0, 0);
    lcd.print("  *** BOOM ***  ");
    lcd.setCursor(0, 1);
    lcd.print("BOMBA DETONADA  ");
    pitido(110, 400);
    delay(600);
    return;
  }

  if (bombaDesactivada) {
    lcd.setCursor(0, 0);
    lcd.print("DESACTIVADA :)  ");
    lcd.setCursor(0, 1);
    lcd.print("SOBRO: ");
    lcd.print(tiempoRestanteSeg);
    lcd.print("s     ");
    delay(500);
    return;
  }

  // 1. Reloj regresivo (1 segundo)
  if (millis() - ultimoTick >= 1000) {
    ultimoTick = millis();
    if (tiempoRestanteSeg > 0) {
      tiempoRestanteSeg--;
      pitido(2000, 35);
    } else {
      bombaExplotada = true;
      return;
    }

    int min = tiempoRestanteSeg / 60;
    int seg = tiempoRestanteSeg % 60;
    lcd.setCursor(0, 0);
    lcd.print("TIEMPO: ");
    if (min < 10) lcd.print("0");
    lcd.print(min);
    lcd.print(":");
    if (seg < 10) lcd.print("0");
    lcd.print(seg);
    lcd.print("   ");

    lcd.setCursor(0, 1);
    lcd.print("STRIKES: ");
    lcd.print(strikes);
    lcd.print("/3     ");
  }

  // 2. Detección de cables cortados
  for (int i = 0; i < 4; i++) {
    bool lectura = digitalRead(pinesCables[i]);
    if (estadoCableAnterior[i] == LOW && lectura == HIGH) {
      delay(30); // Antirrebote
      if (digitalRead(pinesCables[i]) == HIGH) {
        estadoCableAnterior[i] = HIGH;
        if (i == CABLE_CORRECTO) {
          bombaDesactivada = true;
          pitido(1600, 300);
          lcd.clear();
        } else {
          registrarStrike("CABLE EQUIVOCADO");
        }
      }
    }
  }

  // 3. Prueba de los 4 botones arcade
  if (digitalRead(BTN_ROJO) == LOW)     { pitido(523, 80); delay(180); }
  if (digitalRead(BTN_AZUL) == LOW)     { pitido(659, 80); delay(180); }
  if (digitalRead(BTN_VERDE) == LOW)    { pitido(784, 80); delay(180); }
  if (digitalRead(BTN_AMARILLO) == LOW) { pitido(988, 80); delay(180); }
}