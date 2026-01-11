/*******************************************************************************
 * CÓDIGO DO DISPOSITIVO FILHO (COM LORA MESH)
 * 
 * Placa Alvo: Heltec WiFi LoRa 32 (V3)
 * 
 * Funcionalidades:
 * 1. Nó em rede LoRa Mesh, com gestão de energia (Deep Sleep).
 * 2. Envia mensagens pré-definidas (Estou bem, Pode buscar-me, Sim).
 * 3. Recebe notificações (vibração) e convites para grupos.
 * 4. Implementa fluxo de convite/aceitação de grupo com botão físico.
 * 
 * Bibliotecas necessárias:
 * - RadioHead by Mike McCauley (instalar pela Arduino IDE Library Manager)
 * 
 *******************************************************************************/

#include <RHMesh.h>
#include <RH_RF95.h>
#include <SPI.h>

// --- PINAGEM (Heltec WiFi LoRa 32 V3) ---
#define RFM95_CS      8
#define RFM95_RST     12
#define RFM95_INT     14

// --- PINOS DOS COMPONENTES ---
const int BUTTON1_PIN   = 15; // Usado para ACEITAR convites
const int BUTTON2_PIN   = 16; // Usado para REJEITAR convites
const int BUTTON3_PIN   = 17; // Usado para REJEITAR convites
const int VIBRATOR_PIN  = 2; 
const int INVITE_LED_PIN = 4; // LED para sinalizar convite pendente

// --- CONFIGURAÇÃO DA REDE MESH ---
#define CHILD_NODE_ADDRESS 2
#define GATEWAY_ADDRESS    1

// --- DRIVER E GESTOR DA MALHA ---
RH_RF95 driver(RFM95_CS, RFM95_INT);
RHMesh manager(driver, CHILD_NODE_ADDRESS);

// --- MENSAGENS E ESTADO (ARMAZENADOS NA MEMÓRIA RTC) ---
// Mensagens estáticas pré-definidas
const char *msg_btn1 = "BTN1: Estou bem!";
const char *msg_btn2 = "BTN2: Pode me buscar.";
const char *msg_btn3 = "BTN3: Sim!";

// Variáveis que persistem durante o Deep Sleep
RTC_DATA_ATTR const char* message_to_send = nullptr;
RTC_DATA_ATTR bool woke_up_by_button = false;

// Estado do convite para grupo
RTC_DATA_ATTR bool group_invitation_pending = false;
RTC_DATA_ATTR char pending_group_id[37] = ""; // Suporta IDs de 36 chars + null
RTC_DATA_ATTR char dynamic_message[64] = ""; // Buffer para msgs dinâmicas (ACCEPT/REJECT)

void setup() {
  Serial.begin(115200);

  // --- CONFIGURAÇÃO DOS PINOS ---
  pinMode(VIBRATOR_PIN, OUTPUT);
  digitalWrite(VIBRATOR_PIN, LOW);
  pinMode(INVITE_LED_PIN, OUTPUT);
  
  pinMode(BUTTON1_PIN, INPUT_PULLUP);
  pinMode(BUTTON2_PIN, INPUT_PULLUP);
  pinMode(BUTTON3_PIN, INPUT_PULLUP);

  // Restaura o estado do LED de convite (se houver convite pendente)
  digitalWrite(INVITE_LED_PIN, group_invitation_pending ? HIGH : LOW);

  // Configura os botões como fonte para acordar o ESP32
  esp_sleep_enable_ext1_wakeup((1ULL << BUTTON1_PIN) | (1ULL << BUTTON2_PIN) | (1ULL << BUTTON3_PIN), ESP_EXT1_WAKEUP_ANY_LOW);

  // --- LÓGICA DE DESPERTAR (WAKE UP) ---
  esp_sleep_wakeup_cause_t wakeup_reason = esp_sleep_get_wakeup_cause();
  
  if (wakeup_reason == ESP_SLEEP_WAKEUP_EXT1) {
      woke_up_by_button = true;
      uint64_t wakeup_pins = esp_sleep_get_ext1_wakeup_status();

      if (group_invitation_pending) {
        // Se há um convite, um botão pressionado é uma resposta
        if (wakeup_pins & (1ULL << BUTTON1_PIN)) { // Aceitar com Botão 1
            sprintf(dynamic_message, "ACCEPT:%s", pending_group_id);
            message_to_send = dynamic_message;
            Serial.println("Group invitation ACCEPTED.");
        } else { // Rejeitar com qualquer outro botão
            sprintf(dynamic_message, "REJECT:%s", pending_group_id);
            message_to_send = dynamic_message;
            Serial.println("Group invitation REJECTED.");
        }
        // Limpa o estado do convite
        group_invitation_pending = false;
        pending_group_id[0] = '\0';

      } else {
        // Lógica normal dos botões se não houver convite
        if (wakeup_pins & (1ULL << BUTTON1_PIN)) message_to_send = msg_btn1;
        else if (wakeup_pins & (1ULL << BUTTON2_PIN)) message_to_send = msg_btn2;
        else if (wakeup_pins & (1ULL << BUTTON3_PIN)) message_to_send = msg_btn3;
      }
  }

  // --- INICIALIZAÇÃO DO RÁDIO LORA ---
  if (!manager.init()) {
    Serial.println("Falha ao iniciar o Mesh Manager!");
    while(1);
  }
  driver.setTxPower(23, false);
  driver.setFrequency(915.0);
  driver.setCADTimeout(500);

  Serial.println("Child Node Online. Endereço: #" + String(CHILD_NODE_ADDRESS));

  // --- AÇÃO PRINCIPAL ---
  if (woke_up_by_button && message_to_send != nullptr) {
    digitalWrite(INVITE_LED_PIN, LOW); // Garante que o LED apaga após a ação
    sendMessage(message_to_send);
    woke_up_by_button = false; // Reseta os flags
    message_to_send = nullptr;
  } else {
    // Se não acordou por botão, escuta por mensagens
    receiveMessage();
  }
}

void loop() {
  // O loop principal apenas direciona para o Deep Sleep.
  // A lógica está toda no setup() para otimizar o consumo de energia.
  goToDeepSleep();
}

// --- FUNÇÕES DE COMUNICAÇÃO ---
void sendMessage(const char* msg) {
  uint8_t buf[RH_MESH_MAX_MESSAGE_LEN];
  strncpy((char*)buf, msg, RH_MESH_MAX_MESSAGE_LEN - 1);
  buf[RH_MESH_MAX_MESSAGE_LEN - 1] = '\0'; // Garante terminação nula
  uint8_t len = strlen((char*)buf);
  
  Serial.println("A enviar: '" + String(msg) + "' para o nó #" + String(GATEWAY_ADDRESS));
  
  if (manager.sendtoWait(buf, len, GATEWAY_ADDRESS) == RH_ROUTER_ERROR_NONE) {
    Serial.println("Mensagem enviada com sucesso!");
  } else {
    Serial.println("Falha no envio.");
  }
}

void receiveMessage() {
  Serial.println("A escutar por mensagens...");
  uint8_t buf[RH_MESH_MAX_MESSAGE_LEN];
  uint8_t len = sizeof(buf);
  uint8_t from;
  
  if (manager.recvfromAckTimeout(buf, &len, 2000, &from)) {
    char* msg = (char*)buf;
    Serial.print("Mensagem recebida de #");
    Serial.print(from);
    Serial.print(": ");
    Serial.println(msg);

    // Verifica se é um convite para grupo
    if (strncmp(msg, "INVITE:", 7) == 0) {
      strncpy(pending_group_id, msg + 7, sizeof(pending_group_id) - 1);
      pending_group_id[sizeof(pending_group_id) - 1] = '\0'; // Segurança
      group_invitation_pending = true;
      digitalWrite(INVITE_LED_PIN, HIGH); // Liga o LED
      // Vibra para notificar o utilizador
      digitalWrite(VIBRATOR_PIN, HIGH);
      delay(200);
      digitalWrite(VIBRATOR_PIN, LOW);
      delay(200);
      digitalWrite(VIBRATOR_PIN, HIGH);
      delay(200);
      digitalWrite(VIBRATOR_PIN, LOW);
      Serial.println("Convite de grupo recebido! Pressione BTN1 para aceitar.");
    } else {
      // Se for outra mensagem, apenas vibra uma vez
      digitalWrite(VIBRATOR_PIN, HIGH);
      delay(500);
      digitalWrite(VIBRATOR_PIN, LOW);
    }
  }
}

// --- FUNÇÃO DE GESTÃO DE ENERGIA ---
void goToDeepSleep() {
  Serial.println("A entrar em modo Deep Sleep...");
  Serial.flush();
  esp_deep_sleep_start();
}
