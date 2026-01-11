
/*******************************************************************************
 * CÓDIGO DO DISPOSITIVO FINAL - VERSÃO V6.0 (Híbrido WiFi + LoRa) - COMPLETO
 * 
 * Placa Alvo: Heltec WiFi LoRa 32 (V3)
 * 
 * FUNCIONALIDADES DESTA VERSÃO:
 * 1. [Comunicação Híbrida] Prioriza WiFi e usa LoRa Mesh como fallback.
 * 2. [Convite de Grupo] Implementa fluxo de convite/aceitação com botão físico.
 * 3. [Conexão Direta] Em modo WiFi, comunica diretamente com Firebase (RTDB).
 * 4. [Interface Melhorada] OLED exibe estado da conexão (WiFi/LoRa) e alertas.
 * 5. [T9 e OTA] Mantém as funcionalidades de escrita T9 e atualização OTA.
 *******************************************************************************/

// --- BIBLIOTECAS ADICIONAIS ---
#include <WiFi.h>
#include <ArduinoOTA.h>
#include <Firebase_ESP_Client.h> // Para comunicação direta com Firebase

// --- BIBLIOTECAS EXISTENTES ---
#include <SPI.h>
#include <Wire.h>
#include <RHMesh.h>
#include <RH_RF95.h>
#include <U8g2lib.h>
#include <OneButton.h>
#include <ArduinoJson.h>

// >>>>> PREENCHA AS SUAS CREDENCIAIS AQUI <<<<<
#define WIFI_SSID         "SEU_WIFI_SSID"
#define WIFI_PASSWORD     "SUA_SENHA_WIFI"
#define OTA_PASSWORD      "sua_senha_ota_segura" 

#define FIREBASE_API_KEY      "SUA_FIREBASE_API_KEY"
#define FIREBASE_DATABASE_URL "SUA_FIREBASE_DATABASE_URL" // Ex: https://seu-projeto-default-rtdb.firebaseio.com
// >>>>> FIM DAS CREDENCIAIS <<<<<

// --- PINAGEM (Heltec WiFi LoRa 32 V3) ---
#define RFM95_CS         8
#define RFM95_RST        12
#define RFM95_INT        14
#define OLED_SDA         17
#define OLED_SCL         18
#define OLED_RST         21
#define BTN_NAV_PIN      0  // Navegação T9 / Scroll
#define BTN_CONFIRM_PIN  1  // Confirmar letra / ACEITAR convite
#define BTN_ACTION_PIN   2  // Backspace / REJEITAR convite / Enviar
#define VIBRATOR_PIN     13

// --- CONFIGURAÇÃO DA REDE E ESTADO ---
#define TEMP_NODE_ADDRESS  254 
#define GATEWAY_ADDRESS    1
#define INACTIVITY_TIMEOUT 30000 

enum CommsMode {
  MODE_WIFI,
  MODE_LORA
};
CommsMode currentCommsMode;

// --- DADOS PARA T9 ---
#define T9_GROUPS 9
const char* t9_map[T9_GROUPS] = {
  "1.,?!", "2ABC", "3DEF",
  "4GHI", "5JKL", "6MNO",
  "7PQRS", "8TUV", "9WXYZ"
};

// --- OBJETOS GLOBAIS ---
RH_RF95 driver(RFM95_CS, RFM95_INT);
RHMesh manager(driver, TEMP_NODE_ADDRESS);
U8G2_SSD1306_128X64_NONAME_F_HW_I2C u8g2(U8G2_R0, OLED_RST, OLED_SCL, OLED_SDA);
OneButton btn_nav(BTN_NAV_PIN, true);
OneButton btn_confirm(BTN_CONFIRM_PIN, true);
OneButton btn_action(BTN_ACTION_PIN, true);

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// --- VARIÁVEIS DE ESTADO (MANTIDAS NO DEEP SLEEP) ---
RTC_DATA_ATTR char messageBuffer[RH_MESH_MAX_MESSAGE_LEN] = {0};
RTC_DATA_ATTR int currentGroupIndex = 0;
RTC_DATA_ATTR int currentCharIndex = 0;
RTC_DATA_ATTR bool group_invitation_pending = false;
RTC_DATA_ATTR char pending_group_id[37] = "";

// --- VARIÁVEIS DE ESTADO (VOLÁTEIS) ---
String deviceMacAddress;
unsigned long lastActivityTime;
bool sendingConfirm = false;
bool otaUpdateMode = false;

// --- PROTÓTIPOS DAS FUNÇÕES ---
void handleNavClick();
void handleNavLongPress();
void handleConfirmClick();
void handleConfirmLongPress();
void handleActionClick();
void handleActionLongPressStart();
void handleActionLongPressStop();
void drawScreen();
void showStatus(const char* status, int duration, bool smallFont = false);
void goToDeepSleep();
void setupComms();
void connectWiFi();
void initFirebase();
void commandStreamCallback(FirebaseStream data);
void tokenStatusCallback(TokenInfo info);
void handleGroupInvitation(String& groupId);
void sendResponse(bool accepted);
void sendMessage(const char* textPayload, const char* statusPayload);
void enterOtaMode();
void setupOTA();

/*******************************************************************************
 * SETUP
 *******************************************************************************/
void setup() {
  pinMode(VIBRATOR_PIN, OUTPUT);
  digitalWrite(VIBRATOR_PIN, HIGH); delay(50); digitalWrite(VIBRATOR_PIN, LOW);

  Serial.begin(115200);
  u8g2.begin();
  u8g2.setFont(u8g2_font_profont12_tr);

  WiFi.mode(WIFI_STA);
  deviceMacAddress = WiFi.macAddress();
  Serial.print("MAC Address (ID Unico): ");
  Serial.println(deviceMacAddress);

  setupComms(); // Configura WiFi ou LoRa

  // Anexa os botões às suas funções
  btn_nav.attachClick(handleNavClick);
  btn_nav.attachLongPressStart(handleNavLongPress);
  btn_confirm.attachClick(handleConfirmClick);
  btn_confirm.attachLongPressStart(handleConfirmLongPress);
  btn_action.attachClick(handleActionClick);
  btn_action.attachLongPressStart(handleActionLongPressStart);
  btn_action.attachLongPressStop(handleActionLongPressStop);

  esp_sleep_enable_ext1_wakeup((1ULL << BTN_NAV_PIN) | (1ULL << BTN_CONFIRM_PIN) | (1ULL << BTN_ACTION_PIN), ESP_EXT1_WAKEUP_ANY_LOW);

  lastActivityTime = millis();
  drawScreen();
  Serial.println("Dispositivo Hibrido Inicializado (V6.0 - COMPLETO).");
}

/*******************************************************************************
 * LOOP
 *******************************************************************************/
void loop() {
  if (otaUpdateMode) {
    ArduinoOTA.handle();
    return;
  }

  btn_nav.tick();
  btn_confirm.tick();
  btn_action.tick();

  if (currentCommsMode == MODE_LORA) {
    uint8_t buf[RH_MESH_MAX_MESSAGE_LEN];
    uint8_t len = sizeof(buf);
    uint8_t from;
    if (manager.recvfromAckTimeout(buf, &len, 250, &from)) {
      String msgStr = String((char*)buf);
      if (msgStr.startsWith("INVITE:")) {
        String groupId = msgStr.substring(7);
        handleGroupInvitation(groupId);
      }
      // Outras mensagens LoRa podem ser tratadas aqui se necessário
    }
  }

  if (!sendingConfirm && (millis() - lastActivityTime > INACTIVITY_TIMEOUT)) {
    goToDeepSleep();
  }
}
/*******************************************************************************
 * LÓGICA DE COMUNICAÇÃO HÍBRIDA
 *******************************************************************************/
void setupComms() {
  u8g2.clearBuffer();
  u8g2.drawStr(0, 12, "Conectando...");
  u8g2.sendBuffer();

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 15) {
    delay(500);
    Serial.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    currentCommsMode = MODE_WIFI;
    Serial.println("
Conectado ao WiFi!");
    initFirebase();
  } else {
    currentCommsMode = MODE_LORA;
    Serial.println("
Falha no WiFi. Ativando LoRa.");
    WiFi.disconnect(true);
    WiFi.mode(WIFI_OFF);
    if (!manager.init()) {
      Serial.println("Falha ao iniciar LoRa!");
    } else {
      driver.setTxPower(23, false);
      driver.setFrequency(915.0);
    }
  }
}

void initFirebase() {
  config.api_key = FIREBASE_API_KEY;
  config.database_url = FIREBASE_DATABASE_URL;
  auth.user.uid = deviceMacAddress; // Usa o MAC como UID para o dispositivo
  config.token_status_callback = tokenStatusCallback; 
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  // Inicia a escuta por comandos
  String commandPath = "devices/" + deviceMacAddress + "/command";
  if (!Firebase.RTDB.beginStream(&fbdo, commandPath)) {
    Serial.println("Erro ao iniciar stream de comandos: " + fbdo.errorReason());
  }
  Firebase.RTDB.setStreamCallback(&fbdo, commandStreamCallback, 1000);
}

// Callback para quando um comando é recebido via WiFi
void commandStreamCallback(FirebaseStream data) {
  if (data.dataType() == "string") {
    String msg = data.stringData();
    if (msg.startsWith("INVITE:")) {
      String groupId = msg.substring(7);
      handleGroupInvitation(groupId);
      Firebase.RTDB.setString(&fbdo, data.streamPath(), "processing"); // Confirma o processamento
    } else if (msg == "start_ota") {
        enterOtaMode();
    }
  }
}

// Callback para status de autenticação do Firebase
void tokenStatusCallback(TokenInfo info) {
  if (info.status == token_status_ready) {
    Serial.println("Firebase token pronto.");
  } else {
    Serial.printf("Firebase token status: %s
", info.status == token_status_error ? info.error.message.c_str() : "...");
  }
}
/*******************************************************************************
 * LÓGICA DE CONVITE DE GRUPO E RESPOSTA
 *******************************************************************************/
void handleGroupInvitation(String& groupId) {
  Serial.println("Convite recebido para o grupo: " + groupId);
  group_invitation_pending = true;
  strncpy(pending_group_id, groupId.c_str(), sizeof(pending_group_id) - 1);

  digitalWrite(VIBRATOR_PIN, HIGH); delay(150); digitalWrite(VIBRATOR_PIN, LOW);
  delay(150);
  digitalWrite(VIBRATOR_PIN, HIGH); delay(150); digitalWrite(VIBRATOR_PIN, LOW);

  drawScreen(); // Atualiza o ecrã para mostrar o alerta
  lastActivityTime = millis();
}

void sendResponse(bool accepted) {
  char response_msg[64];
  if (accepted) {
    sprintf(response_msg, "ACCEPT:%s", pending_group_id);
    showStatus("Convite Aceito!", 1500);
  } else {
    sprintf(response_msg, "REJECT:%s", pending_group_id);
    showStatus("Convite Rejeitado", 1500);
  }

  // Limpa o estado do convite
  group_invitation_pending = false;
  pending_group_id[0] = '\0';

  sendMessage(response_msg, nullptr); // Envia a resposta pelo canal ativo
}

/*******************************************************************************
 * LÓGICA DE BOTÕES E T9
 *******************************************************************************/
void handleNavClick() {
  if (sendingConfirm || otaUpdateMode || group_invitation_pending) return;
  currentCharIndex = (currentCharIndex + 1) % strlen(t9_map[currentGroupIndex]);
  drawScreen();
  lastActivityTime = millis();
}

void handleNavLongPress() {
  if (sendingConfirm || otaUpdateMode || group_invitation_pending) return;
  currentGroupIndex = (currentGroupIndex + 1) % T9_GROUPS;
  currentCharIndex = 0;
  drawScreen();
  lastActivityTime = millis();
}

void handleConfirmClick() {
  if (group_invitation_pending) {
    sendResponse(true); // Botão de confirmar ACEITA o convite
    return;
  }
  if (sendingConfirm || otaUpdateMode) return;
  int len = strlen(messageBuffer);
  if (len < sizeof(messageBuffer) - 2) {
    messageBuffer[len] = t9_map[currentGroupIndex][currentCharIndex];
    messageBuffer[len + 1] = '\0';
    drawScreen();
    lastActivityTime = millis();
  }
}

void handleConfirmLongPress() {
  if (sendingConfirm || otaUpdateMode || group_invitation_pending) return;
  int len = strlen(messageBuffer);
  if (len < sizeof(messageBuffer) - 2) {
    messageBuffer[len] = ' ';
    messageBuffer[len + 1] = '\0';
    drawScreen();
    lastActivityTime = millis();
  }
}

void handleActionClick() {
  if (group_invitation_pending) {
    sendResponse(false); // Botão de ação REJEITA o convite
    return;
  }
  if (otaUpdateMode) return;
  if (sendingConfirm) {
    sendingConfirm = false;
    drawScreen();
    return;
  }
  int len = strlen(messageBuffer);
  if (len > 0) {
    messageBuffer[len - 1] = '\0';
    drawScreen();
    lastActivityTime = millis();
  }
}

void handleActionLongPressStart() {
  if (strlen(messageBuffer) == 0 || otaUpdateMode || group_invitation_pending) return;
  sendingConfirm = true;
  drawScreen();
}

void handleActionLongPressStop() {
  if (sendingConfirm) {
    sendMessage(messageBuffer, nullptr);
  }
}

/*******************************************************************************
 * FUNÇÕES DE ENVIO E ATUALIZAÇÃO OTA
 *******************************************************************************/
void sendMessage(const char* textPayload, const char* statusPayload) {
  lastActivityTime = millis();
  showStatus("Enviando...", 500);

  bool success = false;
  if (currentCommsMode == MODE_WIFI) {
    if (Firebase.ready()) {
      String chatPath = "chats/" + deviceMacAddress + "/messages";
      FirebaseJson json;
      json.set("senderId", deviceMacAddress);
      json.set("text", textPayload);
      json.set("timestamp/.sv", "timestamp");
      if (Firebase.RTDB.pushJSON(&fbdo, chatPath, &json)) {
        success = true;
      }
    }
  } else { // MODE_LORA
      StaticJsonDocument<200> doc;
      doc["from_mac"] = deviceMacAddress;
      if (textPayload) doc["text"] = textPayload;
      if (statusPayload) doc["status"] = statusPayload;
      char json_output[128];
      serializeJson(doc, json_output);
      if (manager.sendtoWait((uint8_t*)json_output, strlen(json_output), GATEWAY_ADDRESS) == RH_ROUTER_ERROR_NONE) {
        success = true;
      }
  }

  if(success) {
    showStatus(currentCommsMode == MODE_WIFI ? "Enviado (WiFi)!" : "Enviado (LoRa)!", 1500);
  } else {
    showStatus(currentCommsMode == MODE_WIFI ? "Falha (WiFi)!" : "Falha (LoRa)!", 1500);
  }

  if (textPayload && strlen(textPayload) > 0) {
      messageBuffer[0] = '\0';
      currentGroupIndex = 0;
      currentCharIndex = 0;
  }
  sendingConfirm = false;
  goToDeepSleep();
}

void enterOtaMode() {
    otaUpdateMode = true;
    showStatus("Modo OTA...", 10000, false);
    
    if (currentCommsMode == MODE_LORA) {
      manager.sleep(); // Desliga LoRa se estiver ativo
    }
    
    if (WiFi.status() != WL_CONNECTED) {
        WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
        Serial.print("Conectando ao Wi-Fi para OTA");
        int attempts = 0;
        while (WiFi.status() != WL_CONNECTED && attempts < 20) {
            Serial.print(".");
            delay(500);
            attempts++;
        }
    }

    if (WiFi.status() == WL_CONNECTED) {
        Serial.println();
        Serial.print("Conectado! IP: ");
        Serial.println(WiFi.localIP());
        showStatus(WiFi.localIP().toString().c_str(), 5000, true);
        setupOTA();
    } else {
        Serial.println("Falha ao conectar no WiFi. Reiniciando...");
        showStatus("Falha WiFi!", 2000, false);
        ESP.restart();
    }
}

void setupOTA() {
    String hostname = "lora-device-" + deviceMacAddress;
    hostname.replace(":", "");
    ArduinoOTA.setHostname(hostname.c_str());
    ArduinoOTA.setPassword(OTA_PASSWORD);

    ArduinoOTA
        .onStart([]() { showStatus("Atualizando...", 10000, false); })
        .onEnd([]() { 
            showStatus("Sucesso!", 2000, false); 
            ESP.restart(); 
        })
        .onProgress([](unsigned int progress, unsigned int total) {
            u8g2.clearBuffer();
            u8g2.setFont(u8g2_font_ncenB10_tr);
            char progressStr[20];
            sprintf(progressStr, "Progresso: %u%%", (progress / (total / 100)));
            u8g2.drawStr((128 - u8g2.getStrWidth(progressStr)) / 2, 38, progressStr);
            u8g2.sendBuffer();
        })
        .onError([](ota_error_t error) {
            showStatus("Erro OTA!", 3000, false);
            ESP.restart();
        });

    ArduinoOTA.begin();
    Serial.println("OTA Pronto");
    showStatus("OTA Pronto!", 2000, true);
}

/*******************************************************************************
 * FUNÇÕES DE UI E SISTEMA
 *******************************************************************************/
void drawScreen() {
    u8g2.clearBuffer();
    
    // Desenha Ícone de Status da Conexão
    if (currentCommsMode == MODE_WIFI) {
        u8g2.setFont(u8g2_font_open_iconic_www_1x_t);
        u8g2.drawGlyph(0, 10, 80); // Ícone de WiFi
    } else {
        u8g2.setFont(u8g2_font_profont12_tr);
        u8g2.drawStr(0, 10, "LoRa");
    }

    u8g2.setFont(u8g2_font_profont12_tr);
    const int screenWidth = u8g2.getDisplayWidth();
    int messageWidth = u8g2.getStrWidth(messageBuffer);
    int textX = 24;
    if (messageWidth > screenWidth - textX) {
      textX = screenWidth - messageWidth;
    }
    u8g2.drawStr(textX, 12, messageBuffer);

    u8g2.drawHLine(0, 48, 128);

    if (group_invitation_pending) {
        u8g2.setFont(u8g2_font_ncenB10_tr);
        u8g2.drawStr((screenWidth - u8g2.getStrWidth("Convite de Grupo!"))/2, 40, "Convite de Grupo!");
        u8g2.setFont(u8g2_font_profont12_tr);
        u8g2.drawStr(0, 60, "[Aceitar]       [Rejeitar]");
    } else if (sendingConfirm) {
        u8g2.drawStr((screenWidth - u8g2.getStrWidth("Solte para enviar"))/2, 60, "Solte para enviar");
    } else {
      String t9_display = "";
      const char* currentGroup = t9_map[currentGroupIndex];
      for (int i = 0; i < strlen(currentGroup); i++) {
        if (i == currentCharIndex) {
          t9_display += "["; t9_display += currentGroup[i]; t9_display += "]";
        } else {
          t9_display += " "; t9_display += currentGroup[i]; t9_display += " ";
        }
      }
      u8g2.drawStr((screenWidth - u8g2.getStrWidth(t9_display.c_str()))/2, 60, t9_display.c_str());
    }
    u8g2.sendBuffer();
    lastActivityTime = millis();
}

void showStatus(const char* status, int duration, bool smallFont) {
  u8g2.clearBuffer();
  u8g2.setFont(smallFont ? u8g2_font_profont11_tr : u8g2_font_ncenB10_tr);
  u8g2.drawStr((128 - u8g2.getStrWidth(status)) / 2, 38, status);
  u8g2.sendBuffer();
  delay(duration);
  drawScreen();
}

void goToDeepSleep() {
  Serial.println("Entrando em Deep Sleep...");
  u8g2.setPowerSave(1);
  if(currentCommsMode == MODE_WIFI) {
    WiFi.disconnect(true);
  }
  esp_deep_sleep_start();
}
