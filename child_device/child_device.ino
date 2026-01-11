/*******************************************************************************
 * Código para o Dispositivo Final (ESP32 LoRa) - v_OLED_T9_Input
 *
 * Placa Alvo: Heltec WiFi LoRa 32 (V3)
 *
 * FUNCIONALIDADES DESTA VERSÃO:
 * 1. [FEEDBACK OLED] Mostra a composição T9, status e mensagens no ecrã.
 * 2. [ENTRADA T9] Permite ao utilizador compor mensagens de texto livre com 4 botões.
 * 3. [LOOP INTERATIVO] Loop ativo para permitir a composição da mensagem.
 * 4. [BIBLIOTECA SIMPLIFICADA] Usa a biblioteca LoRa (P2P) para eficiência.
 * 5. [DOWNLINK BINÁRIO] Recebe e exibe comandos e broadcasts do gateway.
 *
 *******************************************************************************/

#include <SPI.h>
#include <LoRa.h>
#include <ArduinoJson.h>
#include <WiFi.h>
#include <U8g2lib.h> // NOVO: Biblioteca para o ecrã OLED

// --- PINAGEM OLED (Integrado na Heltec V3) ---
#define OLED_SDA 21
#define OLED_SCL 22
#define OLED_RST -1 // -1 se não estiver a ser usado
U8G2_SSD1306_128X64_NONAME_F_HW_I2C u8g2(U8G2_R0, /* reset=*/ OLED_RST, /* clock=*/ OLED_SCL, /* data=*/ OLED_SDA);

// --- PINAGEM LORA ---
#define LORA_SCK 9
#define LORA_MISO 11
#define LORA_MOSI 10
#define LORA_CS 8
#define LORA_RST 12
#define LORA_DIO0 14

// --- PINAGEM DE INTERAÇÃO ---
#define VIBRATION_MOTOR_PIN 13 // Pino movido para evitar conflito com OLED
#define LED_PIN 35
#define BTN_CYCLE_KEY     27
#define BTN_CYCLE_CHAR    26
#define BTN_APPEND        25
#define BTN_SEND_BACK     33

// --- CONFIGURAÇÕES DE INTERAÇÃO ---
#define DEBOUNCE_DELAY 50
#define LONG_PRESS_DELAY 1000
#define RECEIVE_WINDOW_MS 3000

// --- ESTADO T9 E MENSAGEM ---
const char* T9_KEYS[] = {" ", ".,?!", "ABC", "DEF", "GHI", "JKL", "MNO", "PQRS", "TUV", "WXYZ"};
String currentMessage = "";
int currentKeyIndex = 0;
int currentCharInKeyIndex = 0;

// Variáveis de controlo dos botões
unsigned long btn_last_debounce_time[4] = {0};
byte btn_last_state[4] = {HIGH, HIGH, HIGH, HIGH};
unsigned long btn_press_start_time[4] = {0};

// --- ESTADO DO DISPOSITIVO ---
String myMacAddress = "";

// Enum de comandos de downlink
enum DownlinkCommand : uint8_t { CMD_NONE=0x00, CMD_VIBRATE=0x01, CMD_LED_ON=0x02, CMD_LED_OFF=0x03, CMD_BROADCAST=0x10 };

// --- DECLARAÇÃO DE FUNÇÕES ---
void updateDisplay(String line1, String line2, bool clear=false);
void handleInput();
void sendUplinkMessage(String message);
void checkForDownlink();
void handleDownlink(uint8_t* payload, int size);
void macStringToBytes(String macStr, uint8_t* macBytes);
void setupLoRa();

void setup() {
  Serial.begin(115200);
  while (!Serial);
  Serial.println("\nLoRa Device Starting... (v_OLED_T9_Input)");

  // Inicializar o ecrã OLED
  u8g2.begin();
  u8g2.enableUTF8Print();
  u8g2.setFont(u8g2_font_profont12_tr);
  updateDisplay("Booting...", "v_OLED_T9", true);
  delay(1000);

  WiFi.mode(WIFI_STA);
  myMacAddress = WiFi.macAddress();
  myMacAddress.replace(":", "");
  Serial.println("My MAC: " + myMacAddress);
  updateDisplay("MAC:", myMacAddress, true);
  delay(1500);

  pinMode(VIBRATION_MOTOR_PIN, OUTPUT); digitalWrite(VIBRATION_MOTOR_PIN, LOW);
  pinMode(LED_PIN, OUTPUT); digitalWrite(LED_PIN, LOW);
  pinMode(BTN_CYCLE_KEY, INPUT_PULLUP);
  pinMode(BTN_CYCLE_CHAR, INPUT_PULLUP);
  pinMode(BTN_APPEND, INPUT_PULLUP);
  pinMode(BTN_SEND_BACK, INPUT_PULLUP);

  setupLoRa();
  
  sendUplinkMessage("Device booted");
  checkForDownlink();

  // Pronto para compor
  updateDisplay("", ">", true);
}

void loop() {
  handleInput();
}

// NOVO: Função centralizada para atualizar o ecrã
void updateDisplay(String line1, String line2, bool clear) {
  u8g2.clearBuffer();
  u8g2.setCursor(0, 12); // Linha 1
  u8g2.print(line1);
  u8g2.setCursor(0, 30); // Linha 2
  u8g2.print(line2);
  if (clear) { // Para mensagens de status, mostra por um tempo
     u8g2.sendBuffer();
     delay(1000);
  } else { // Para UI interativa, só envia
     u8g2.sendBuffer();
  }
}

// MODIFICADO: Atualiza o ecrã em vez do Serial
void showCurrentSelection() {
  char selectedChar = T9_KEYS[currentKeyIndex][currentCharInKeyIndex];
  String line2_feedback = "[" + String(T9_KEYS[currentKeyIndex]) + "] > " + selectedChar;
  u8g2.clearBuffer();
  u8g2.setFont(u8g2_font_profont12_tr);
  u8g2.setCursor(0, 12);
  u8g2.print("> " + currentMessage);
  u8g2.setCursor(0, 60); // Posição inferior para feedback
  u8g2.print(line2_feedback);
  u8g2.sendBuffer();
  
  // Mantém o output serial para depuração
  Serial.printf("%s | Mensagem: %s\n", line2_feedback.c_str(), currentMessage.c_str());
}

void handleInput() {
  // ... (a lógica interna dos botões permanece a mesma da versão v_T9_Input)
  int btn_pins[4] = {BTN_CYCLE_KEY, BTN_CYCLE_CHAR, BTN_APPEND, BTN_SEND_BACK};
  for (int i = 0; i < 4; i++) {
    int reading = digitalRead(btn_pins[i]);
    if (reading != btn_last_state[i]) { btn_last_debounce_time[i] = millis(); }
    if ((millis() - btn_last_debounce_time[i]) > DEBOUNCE_DELAY) {
      bool is_pressed = (reading == LOW);
      bool was_pressed = (btn_last_state[i] == LOW);
      if (is_pressed && !was_pressed) { 
        btn_press_start_time[i] = millis();
        digitalWrite(LED_PIN, HIGH);
      } else if (!is_pressed && was_pressed) {
        digitalWrite(LED_PIN, LOW);
        unsigned long pressDuration = millis() - btn_press_start_time[i];
        if (pressDuration < LONG_PRESS_DELAY) {
          switch(i) {
            case 0: currentKeyIndex=(currentKeyIndex + 1) % (sizeof(T9_KEYS)/sizeof(T9_KEYS[0]));currentCharInKeyIndex=0; break;
            case 1: currentCharInKeyIndex=(currentCharInKeyIndex + 1) % strlen(T9_KEYS[currentKeyIndex]); break;
            case 2: currentMessage += T9_KEYS[currentKeyIndex][currentCharInKeyIndex]; break;
            case 3: if (currentMessage.length() > 0) { currentMessage.remove(currentMessage.length() - 1); } break;
          }
        } else {
           switch(i) {
            case 2: currentMessage += ' '; break;
            case 3:
              updateDisplay("Enviando...", "", true);
              sendUplinkMessage(currentMessage);
              checkForDownlink();
              currentMessage = "";
              break;
          }
        }
        showCurrentSelection(); // Atualiza o ecrã após cada ação
      }
    }
    btn_last_state[i] = reading;
  }
}

void sendUplinkMessage(String message) {
  StaticJsonDocument<256> doc;
  doc["from_mac"] = myMacAddress;
  doc["msg"] = message;
  doc["ts"] = millis();
  String jsonString; serializeJson(doc, jsonString);
  Serial.println("Sending uplink: " + jsonString);
  digitalWrite(VIBRATION_MOTOR_PIN, HIGH); delay(100); digitalWrite(VIBRATION_MOTOR_PIN, LOW);
  LoRa.beginPacket(); LoRa.print(jsonString); LoRa.endPacket();
  Serial.println("Uplink sent.");
  updateDisplay("Enviado!", "", true);
}

// MODIFICADO: Exibe comandos e broadcasts no ecrã
void handleDownlink(uint8_t* payload, int size) {
  if (size < 7) { Serial.println("Error: Downlink payload too small."); return; }
  uint8_t targetMacBytes[6]; memcpy(targetMacBytes, payload, 6);
  uint8_t myMacBytes[6]; macStringToBytes(myMacAddress, myMacBytes);
  uint8_t broadcastMacBytes[] = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};
  if (memcmp(targetMacBytes, myMacBytes, 6) != 0 && memcmp(targetMacBytes, broadcastMacBytes, 6) != 0) {
    Serial.println("Downlink is not for me."); return;
  }
  DownlinkCommand command = (DownlinkCommand)payload[6];
  String cmdText = "";
  switch (command) {
    case CMD_VIBRATE: 
      cmdText = "CMD: Vibrar";
      digitalWrite(VIBRATION_MOTOR_PIN, HIGH); delay(1000); digitalWrite(VIBRATION_MOTOR_PIN, LOW);
      break;
    case CMD_LED_ON: cmdText = "CMD: LED ON"; digitalWrite(LED_PIN, HIGH); break;
    case CMD_LED_OFF: cmdText = "CMD: LED OFF"; digitalWrite(LED_PIN, LOW); break;
    case CMD_BROADCAST:
      if (size > 7) {
        char message[size - 6]; memcpy(message, payload + 7, size - 7); message[size - 7] = '\0';
        cmdText = "BCast: " + String(message);
      } else {
        cmdText = "BCast Recebido";
      }
      break;
    default: cmdText = "Comando Desconhecido"; break;
  }
  Serial.println("### " + cmdText + " ###");
  updateDisplay(cmdText, "", true);
  showCurrentSelection(); // Volta para a tela de composição
}


void checkForDownlink() {
  Serial.printf("Listening for downlinks for %d ms...\n", RECEIVE_WINDOW_MS);
  LoRa.receive(); 
  long startTime = millis();
  while (millis() - startTime < RECEIVE_WINDOW_MS) {
    int packetSize = LoRa.parsePacket();
    if (packetSize > 0) {
      Serial.printf("Downlink received with RSSI %d\n", LoRa.packetRssi());
      uint8_t receivedPayload[packetSize];
      for (int i = 0; i < packetSize; i++) { receivedPayload[i] = LoRa.read(); }
      handleDownlink(receivedPayload, packetSize);
      return; 
    }
  }
  Serial.println("Receive window closed.");
  showCurrentSelection(); // Garante que a UI de escrita é restaurada
}

void setupLoRa() {
  SPI.begin(LORA_SCK, LORA_MISO, LORA_MOSI, LORA_CS);
  LoRa.setPins(LORA_CS, LORA_RST, LORA_DIO0);
  if (!LoRa.begin(915E6)) { Serial.println("Starting LoRa failed!"); while (1); }
  Serial.println("LoRa Initialized!");
}

void macStringToBytes(String macStr, uint8_t* macBytes) {
    for (int i = 0; i < 6; i++) {
        char hex[3] = {macStr.charAt(i*2), macStr.charAt(i*2 + 1), 0};
        macBytes[i] = strtol(hex, NULL, 16);
    }
}
