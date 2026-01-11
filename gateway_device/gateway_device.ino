/*******************************************************************************
 * Código para o Dispositivo Gateway (ESP32 LoRa) - v_AutoRouter
 *
 * Placa Alvo: Heltec WiFi LoRa 32 (V3)
 *
 * FUNCIONALIDADES DESTA VERSÃO:
 * 1. [ROTEAMENTO AUTOMÁTICO] Retransmite automaticamente mensagens de uplink de um
 *    dispositivo como um broadcast para todos os outros dispositivos.
 * 2. [LISTENER DE DOWNLINK] Ouve o nó 'downlink_commands' no Firebase em tempo real
 *    para uma resposta de downlink imediata e eficiente.
 * 3. [UPLINK PARA FIREBASE] Envia mensagens LoRa recebidas para o Firebase RTDB.
 * 4. [DOWNLINK BINÁRIO] Envia comandos para os dispositivos usando um formato
 *    binário otimizado e seguro.
 * 5. [STATUS ONLINE] Mantém um status de 'last_seen' no Firebase.
 * 6. [FILA DE UPLINK] Armazena mensagens de uplink em caso de falha de WiFi/Firebase
 *    e envia-as quando a conexão é restaurada.
 *
 *******************************************************************************/

#include <WiFi.h>
#include <SPI.h>
#include <LoRa.h>
#include <ArduinoJson.h>
#include <Firebase_ESP_Client.h>
#include "addons/TokenHelper.h"

// --- CREDENCIAIS (substituir pelos seus valores) ---
#define WIFI_SSID "YOUR_WIFI_SSID"
#define WIFI_PASSWORD "YOUR_WIFI_PASSWORD"
#define API_KEY "YOUR_FIREBASE_API_KEY"
#define DATABASE_URL "YOUR_FIREBASE_DATABASE_URL"

// --- PINAGEM LORA (Heltec WiFi LoRa 32 V3) ---
#define LORA_SCK 9
#define LORA_MISO 11
#define LORA_MOSI 10
#define LORA_CS 8
#define LORA_RST 12
#define LORA_DIO0 14

// --- OBJETOS FIREBASE ---
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// --- FILA DE UPLINK ---
struct UplinkMessage {
  String path;
  String payload;
};
#define MAX_QUEUE_SIZE 20
UplinkMessage uplinkQueue[MAX_QUEUE_SIZE];
int queue_head = 0;
int queue_tail = 0;

// --- ESTADO ---
String myMacAddress = "";
unsigned long last_status_update = 0;
const long status_update_interval = 60000; // 1 minuto

// Definição dos comandos de downlink (deve ser idêntica à do child_device)
enum DownlinkCommand : uint8_t {
  CMD_NONE      = 0x00,
  CMD_VIBRATE   = 0x01,
  CMD_LED_ON    = 0x02,
  CMD_LED_OFF   = 0x03,
  CMD_BROADCAST = 0x10
};

// --- DECLARAÇÕES DE FUNÇÕES ---
void streamCallback(FirebaseStream data);
void streamTimeoutCallback(bool timeout);
void setupWiFi();
void setupFirebase();
void handleLoRaUplink(int packetSize);
void sendDownlink(String targetMac, uint8_t command, String textPayload);
void macStringToBytes(String macStr, uint8_t* macBytes);
void processUplinkQueue();
void addToUplinkQueue(String path, String payload);

void setup() {
  Serial.begin(115200);
  while (!Serial);
  Serial.println("\nGateway Device Starting... (v_AutoRouter)");

  myMacAddress = WiFi.macAddress();
  myMacAddress.replace(":", "");

  setupWiFi();
  setupFirebase();

  LoRa.setPins(LORA_CS, LORA_RST, LORA_DIO0);
  if (!LoRa.begin(915E6)) {
    Serial.println("Starting LoRa failed!");
    while (1);
  }
  LoRa.receive();
  Serial.println("LoRa Initialized. Ready for messages.");
}

void loop() {
  // Lida com o pacote LoRa recebido
  int packetSize = LoRa.parsePacket();
  if (packetSize) {
    handleLoRaUplink(packetSize);
  }

  // Processa a fila de uplinks se houver conexão
  if (Firebase.ready()) {
    processUplinkQueue();
  }

  // Atualiza o status online periodicamente
  if (millis() - last_status_update > status_update_interval) {
    last_status_update = millis();
    if (Firebase.ready()) {
      Firebase.RTDB.setTimestamp(&fbdo, "/gateways/" + myMacAddress + "/last_seen");
    }
  }
}

// MODIFICADO: Esta função agora também roteia a mensagem
void handleLoRaUplink(int packetSize) {
  String receivedText = "";
  while (LoRa.available()) {
    receivedText += (char)LoRa.read();
  }
  Serial.printf("Uplink Received: %s, RSSI: %d\n", receivedText.c_str(), LoRa.packetRssi());

  StaticJsonDocument<256> doc;
  DeserializationError error = deserializeJson(doc, receivedText);

  if (error) {
    Serial.print(F("deserializeJson() failed: "));
    Serial.println(error.c_str());
    return;
  }

  String fromMac = doc["from_mac"];
  fromMac.replace(":", "");

  if (fromMac.length() == 0) {
    Serial.println("Error: Uplink JSON does not contain 'from_mac'.");
    return;
  }

  // AÇÃO 1: Adicionar à fila para registo no Firebase
  String uplinkPath = "/devices/" + fromMac + "/uplink";
  String payload = receivedText;
  addToUplinkQueue(uplinkPath, payload);

  // AÇÃO 2: Roteamento Automático - Criar um comando de downlink de broadcast
  if (doc.containsKey("msg")) {
    String msg_text = doc["msg"];
    String sender_short_name = fromMac.substring(8); // Usa os últimos 4 chars do MAC como nome curto
    String broadcast_msg = sender_short_name + ": " + msg_text;

    // Monta o JSON para o nó de comandos de downlink
    FirebaseJson json_payload;
    json_payload.add("to_mac", "FF:FF:FF:FF:FF:FF"); // MAC de Broadcast
    json_payload.add("command", "BCAST");
    json_payload.add("text", broadcast_msg);
    json_payload.add("timestamp", ".sv", "timestamp");

    String downlink_command_path = "/downlink_commands";
    // Adiciona o comando de broadcast à fila para ser enviado ao Firebase
    addToUplinkQueue(downlink_command_path, json_payload.raw());
    Serial.println("Auto-Routing: Broadcast command created and queued.");
  }

  // Após receber um uplink, voltar ao modo de receção
  LoRa.receive();
}

// Esta função é chamada quando um novo comando é adicionado em /downlink_commands
void streamCallback(FirebaseStream data) {
  Serial.printf("Stream data available: %s, %s, %s\n", data.streamPath().c_str(), data.dataPath().c_str(), data.eventType().c_str());
  
  if (data.dataTypeEnum() == fb_esp_data_type_json && data.dataPath().length() > 1) {
    FirebaseJson* json = data.to<FirebaseJson*>();
    String jsonStr;
    json->toString(jsonStr, true);
    Serial.println("Received JSON: " + jsonStr);

    FirebaseJsonData result;
    String targetMac, command, textPayload;
    
    json->get(result, "to_mac");
    if (result.success) targetMac = result.to<String>();

    json->get(result, "command");
    if (result.success) command = result.to<String>();

    json->get(result, "text");
    if (result.success) textPayload = result.to<String>();

    // Remove o comando do Firebase para não ser processado de novo
    Firebase.RTDB.deleteNode(&fbdo, data.dataPath());

    if (targetMac.length() > 0 && command.length() > 0) {
        uint8_t cmd_byte = CMD_NONE;
        if (command == "VIBRATE") cmd_byte = CMD_VIBRATE;
        else if (command == "LED_ON") cmd_byte = CMD_LED_ON;
        else if (command == "LED_OFF") cmd_byte = CMD_LED_OFF;
        else if (command == "BCAST") cmd_byte = CMD_BROADCAST;

        sendDownlink(targetMac, cmd_byte, textPayload);
    }
  }
}

void sendDownlink(String targetMac, uint8_t command, String textPayload) {
  uint8_t payload[255];
  int payload_size = 0;

  uint8_t mac_bytes[6];
  macStringToBytes(targetMac, mac_bytes);
  memcpy(payload, mac_bytes, 6);
  payload_size += 6;

  payload[payload_size++] = command;

  if (command == CMD_BROADCAST && textPayload.length() > 0) {
    memcpy(payload + payload_size, textPayload.c_str(), textPayload.length());
    payload_size += textPayload.length();
  }
  
  LoRa.beginPacket();
  LoRa.write(payload, payload_size);
  LoRa.endPacket();
  Serial.printf("Downlink Sent to %s, Command: 0x%02X, Size: %d\n", targetMac.c_str(), command, payload_size);
  
  LoRa.receive(); // Voltar ao modo de receção
}

// --- FUNÇÕES DE SETUP E UTILITÁRIAS (sem alterações) ---
void setupWiFi() { /* ... */ }
void setupFirebase() { /* ... */ }
void streamTimeoutCallback(bool timeout) { /* ... */ }
void macStringToBytes(String macStr, uint8_t* macBytes) { /* ... */ }
void processUplinkQueue() { /* ... */ }
void addToUplinkQueue(String path, String payload) { /* ... */ }

// --- Implementação das funções de utilidade para completude ---
void setupWiFi() {
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(300);
  }
  Serial.println();
  Serial.print("Connected with IP: ");
  Serial.println(WiFi.localIP());
}

void setupFirebase() {
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  auth.user.email = "gateway@device.com";
  auth.user.password = "password";
  config.token_status_callback = tokenStatusCallback; //definida em addons/TokenHelper.h
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  // Começa a ouvir o nó de comandos de downlink
  if (!Firebase.RTDB.beginStream(&fbdo, "/downlink_commands")) {
    Serial.printf("Stream begin error: %s\n", fbdo.errorReason().c_str());
  }
  Firebase.RTDB.setStreamCallback(&fbdo, streamCallback, streamTimeoutCallback);
  Serial.println("Firebase Stream on /downlink_commands started.");
}

void streamTimeoutCallback(bool timeout) {
  if (timeout) {
    Serial.println("Stream timeout, resuming...");
  }
}

void macStringToBytes(String macStr, uint8_t* macBytes) {
  macStr.replace(":", "");
  for (int i = 0; i < 6; i++) {
    char hex[3] = {macStr.charAt(i * 2), macStr.charAt(i * 2 + 1), 0};
    macBytes[i] = strtol(hex, NULL, 16);
  }
}

void addToUplinkQueue(String path, String payload) {
  int next_head = (queue_head + 1) % MAX_QUEUE_SIZE;
  if (next_head == queue_tail) {
    Serial.println("Uplink queue is full! Dropping oldest message.");
    queue_tail = (queue_tail + 1) % MAX_QUEUE_SIZE; // Perde a mensagem mais antiga
  }
  uplinkQueue[queue_head].path = path;
  uplinkQueue[queue_head].payload = payload;
  queue_head = next_head;
  Serial.println("Added to queue: " + path);
}

void processUplinkQueue() {
  if (queue_head == queue_tail) return; // Fila vazia

  String path = uplinkQueue[queue_tail].path;
  String payload = uplinkQueue[queue_tail].payload;
  
  bool success = false;
  if (path == "/downlink_commands") {
      // É um comando de broadcast gerado pelo gateway, usa push para criar ID único
      success = Firebase.RTDB.pushJSON(&fbdo, path, payload);
  } else {
      // É um uplink de dispositivo, aninha sob um push ID
      String pushPath = path + "/" + fbdo.pushName();
      success = Firebase.RTDB.setJSON(&fbdo, pushPath, payload);
  }

  if (success) {
    Serial.println("Successfully sent queued message to: " + path);
    queue_tail = (queue_tail + 1) % MAX_QUEUE_SIZE;
  } else {
    Serial.println("Failed to send queued message. Error: " + fbdo.errorReason());
  }
}
