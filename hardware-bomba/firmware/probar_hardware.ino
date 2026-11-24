#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <ESP32Servo.h>

// ==========================================
// 1. LCD I2C (A14 = SDA, A17 = SCL)
// ==========================================
#define SDA_PIN 21
#define SCL_PIN 22
LiquidCrystal_I2C lcd(0x27, 16, 2);

// ==========================================
// 2. TECLADO MATRICIAL 4x4 (Lectura directa)
// ==========================================
byte filas[4]    = {15, 2, 0, 5};     // A4, A5, A6, A10
byte columnas[4] = {35, 34, 39, 36};  // J14, J15, J16, J17

char teclas[4][4] = {
  {'1', '2', '3', 'A'},
  {'4', '5', '6', 'B'},
  {'7', '8', '9', 'C'},
  {'*', '0', '#', 'D'}
};

unsigned long ultimaTeclaMs = 0;

// ==========================================
// 3. BOTONES ARCADE (COM a GND -> INPUT_PULLUP)
// ==========================================
#define BTN_ROJO     13  // J5
#define BTN_AZUL     14  // J8
#define BTN_VERDE    27  // J9
#define BTN_AMARILLO 26  // J10

unsigned long ultimoBotonMs = 0;

// ==========================================
// 4. CABLES CORTABLES (Extremo a GND -> INPUT_PULLUP)
// ==========================================
const int pinesCables[5] = {16, 17, 18, 19, 12}; // A8, A9, A11, A12, J7
bool estadoCableAnterior[5];

// ==========================================
// 5. LEDs STRIKE, BUZZER Y SERVOMOTOR
// ==========================================
#define LED_STRIKE_1 4   // A7
#define LED_STRIKE_2 32  // J13
#define LED_STRIKE_3 33  // J12
#define BUZZER_PIN   25  // J11
#define SERVO_PIN    23  // A18 (señal directa o con resistencia baja)

Servo servoGlobo;
bool servoActivo = false;
unsigned long tiempoInicioServo = 0;

void setup() {
  Serial.begin(115200);

  // LCD
  Wire.begin(SDA_PIN, SCL_PIN);
  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print("TEST COMPLETO B1");
  lcd.setCursor(0, 1);
  lcd.print("Todo listo...");

  // Teclado Matricial (Sin INPUT_PULLUP en columnas por resistencias externas)
  for (int i = 0; i < 4; i++) {
    pinMode(filas[i], OUTPUT);
    digitalWrite(filas[i], HIGH);
    pinMode(columnas[i], INPUT);
  }

  // Botones Arcade
  pinMode(BTN_ROJO, INPUT_PULLUP);
  pinMode(BTN_AZUL, INPUT_PULLUP);
  pinMode(BTN_VERDE, INPUT_PULLUP);
  pinMode(BTN_AMARILLO, INPUT_PULLUP);

  // Cables Cortables
  for (int i = 0; i < 5; i++) {
    pinMode(pinesCables[i], INPUT_PULLUP);
    estadoCableAnterior[i] = digitalRead(pinesCables[i]);
  }

  // LEDs y Buzzer
  pinMode(LED_STRIKE_1, OUTPUT);
  pinMode(LED_STRIKE_2, OUTPUT);
  pinMode(LED_STRIKE_3, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);

  // Servomotor en reposo (15° evita tope mecánico interno del SG90)
  servoGlobo.attach(SERVO_PIN, 500, 2400);
  servoGlobo.write(15);

  // Barrido inicial de LEDs y Buzzer
  digitalWrite(LED_STRIKE_1, HIGH);
  beepCorto(80);
  digitalWrite(LED_STRIKE_2, HIGH);
  beepCorto(80);
  digitalWrite(LED_STRIKE_3, HIGH);
  beepCorto(80);
  delay(200);
  digitalWrite(LED_STRIKE_1, LOW);
  digitalWrite(LED_STRIKE_2, LOW);
  digitalWrite(LED_STRIKE_3, LOW);
}

void loop() {
  // 0. Actualizar retorno del servomotor sin bloquear el loop
  actualizarServo();

  // 1. Lectura del Teclado Matricial 4x4
  char tecla = leerTecladoDirecto();
  if (tecla != '\0') {
    Serial.printf("[KEYPAD] Tecla: %c\n", tecla);
    mostrarEnLCD("Keypad oprimido:", "Tecla -> " + String(tecla));
    beepCorto(50);

    // '#' o '*' disparan el servomotor al instante
    if (tecla == '#' || tecla == '*') {
      activarServoInstantaneo();
    }
  }

  // 2. Lectura de Botones Arcade (con antirrebote no bloqueante)
  if (millis() - ultimoBotonMs > 250) {
    if (digitalRead(BTN_ROJO) == LOW) {
      ultimoBotonMs = millis();
      probarBoton("Boton ROJO", HIGH, LOW, LOW);
    } 
    else if (digitalRead(BTN_AZUL) == LOW) {
      ultimoBotonMs = millis();
      probarBoton("Boton AZUL", LOW, HIGH, LOW);
    } 
    else if (digitalRead(BTN_VERDE) == LOW) {
      ultimoBotonMs = millis();
      probarBoton("Boton VERDE", LOW, LOW, HIGH);
    } 
    else if (digitalRead(BTN_AMARILLO) == LOW) {
      ultimoBotonMs = millis();
      Serial.println("[ARCADE] Boton AMARILLO -> Servo");
      mostrarEnLCD("Boton AMARILLO", "Activando Servo!");
      activarServoInstantaneo();
    }
  }

  // 3. Lectura de Cables Cortables (1 al 5)
  for (int i = 0; i < 5; i++) {
    bool estadoActual = digitalRead(pinesCables[i]);
    if (estadoActual != estadoCableAnterior[i]) {
      estadoCableAnterior[i] = estadoActual;
      String estado = (estadoActual == HIGH) ? "CORTADO (Abierto)" : "CONECTADO (GND)";
      Serial.printf("[CABLE %d] %s\n", i + 1, estado.c_str());
      mostrarEnLCD("Cable " + String(i + 1) + ":", estado);
      beepCorto(60);
    }
  }
}

// ==========================================
// FUNCIONES AUXILIARES
// ==========================================
char leerTecladoDirecto() {
  if (millis() - ultimaTeclaMs < 220) return '\0';

  for (int f = 0; f < 4; f++) {
    digitalWrite(filas[f], LOW);
    delayMicroseconds(100);
    for (int c = 0; c < 4; c++) {
      if (digitalRead(columnas[c]) == LOW) {
        digitalWrite(filas[f], HIGH);
        ultimaTeclaMs = millis();
        return teclas[f][c];
      }
    }
    digitalWrite(filas[f], HIGH);
  }
  return '\0';
}

void mostrarEnLCD(String l1, String l2) {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print(l1);
  lcd.setCursor(0, 1);
  lcd.print(l2);
}

void beepCorto(int ms) {
  digitalWrite(BUZZER_PIN, HIGH);
  delay(ms);
  digitalWrite(BUZZER_PIN, LOW);
}

void probarBoton(String nombre, int l1, int l2, int l3) {
  Serial.println("[ARCADE] " + nombre);
  mostrarEnLCD("Arcade:", nombre);
  digitalWrite(LED_STRIKE_1, l1);
  digitalWrite(LED_STRIKE_2, l2);
  digitalWrite(LED_STRIKE_3, l3);
  beepCorto(60);
}

void activarServoInstantaneo() {
  Serial.println("[SERVO] Golpe inmediato a 105 grados...");
  servoGlobo.write(105);
  digitalWrite(BUZZER_PIN, HIGH);
  servoActivo = true;
  tiempoInicioServo = millis();
}

void actualizarServo() {
  if (servoActivo && (millis() - tiempoInicioServo >= 450)) {
    servoGlobo.write(15);
    digitalWrite(BUZZER_PIN, LOW);
    servoActivo = false;
    Serial.println("[SERVO] Regreso a 15 grados.");
  }
}