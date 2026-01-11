/*******************************************************************************
 * CÓDIGO DO GATEWAY (PONTE LoRa-MQTT) - VERSÃO V3.0 (PROVISIONING)
 * 
 * Placa Alvo: Heltec WiFi LoRa 32 (V3)
 * 
 * FUNCIONALIDADES DESTA VERSÃO:
 * 1. [Tradutor JSON] Converte mensagens JSON da rede LoRa para um formato JSON
 *    que a Cloud Function entende (e vice-versa).
 * 2. [Agnóstico de Conteúdo] Não analisa mais o conteúdo das mensagens de downlink.
 *    Simplesmente transmite o JSON recebido do MQTT para toda a rede LoRa.
 * 
 *******************************************************************************/

#include <WiFi.h>
#include <PubSubClient.h>
#include <RHMesh.h>
#include <RH_RF95.h>
#include <SPI.h>
#include <ArduinoJson.h>

// --- PINAGEM (inalterada) ---
#define RFM95_CS 8
#define RFM95_RST 12
#define RFM95_INT 14

// --- CONFIGURAÇÃO DA REDE MESH ---
#define GATEWAY_ADDRESS 1

// --- CONFIGURAÇÃO WIFI e MQTT ---
// TODO: Substitua pelas suas credenciais
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";
const char* mqtt_server = "broker.hivemq.com";
const int mqtt_port = 1883;

// --- OBJETOS GLOBAIS ---
RH_RF95 driver(RFM95_CS, RFM95_INT);
RHMesh manager(driver, GATEWAY_ADDRESS);
WiFiClient espClient;
PubSubClient mqttClient(espClient);

// --- PROTÓTIPOS ---
void setup_wifi();
void connect_and_subscribe_mqtt();
void mqtt_callback(char* topic, byte* payload, unsigned int length);
void listen_lora_mesh();

/*******************************************************************************
 * SETUP
 *******************************************************************************/
void setup() {
  Serial.begin(115200);

  if (!manager.init()) {
    Serial.println("Falha ao iniciar o LoRa Mesh Manager!");
    while (1);
  }
  driver.setTxPower(23, false);
  driver.setFrequency(915.0);
  Serial.println("Gateway LoRa-MQTT V3.0 (Provisioning) inicializado.");

  setup_wifi();
  mqttClient.setServer(mqtt_server, mqtt_port);
  mqttClient.setCallback(mqtt_callback);
}

/*******************************************************************************
 * LOOP
 *******************************************************************************/
void loop() {
  if (!mqttClient.connected()) {
    connect_and_subscribe_mqtt();
  }
  mqttClient.loop();
  listen_lora_mesh();
}

/*******************************************************************************
 * FUNÇÕES DE REDE MODIFICADAS
 *******************************************************************************/

// MODIFICADO: Não se inscreve mais em 'lora/config'
void connect_and_subscribe_mqtt() {
  while (!mqttClient.connected()) {
    Serial.print("Conectando ao Broker MQTT...");
    String clientId = "Gateway-LoRa-" + String(random(0xffff), HEX);
    if (mqttClient.connect(clientId.c_str())) {
      Serial.println("Conectado!");
      mqttClient.subscribe("lora/downlink");
    } else {
      Serial.print("Falha, rc="); Serial.print(mqttClient.state());
      Serial.println(" Tentando novamente em 5 segundos");
      delay(5000);
    }
  }
}

// MODIFICADO: Apenas retransmite o JSON do downlink para a rede LoRa
void mqtt_callback(char* topic, byte* payload, unsigned int length) {
  Serial.println("Mensagem JSON recebida de lora/downlink. Retransmitindo para a rede LoRa...");
  
  // O payload é o JSON que veio da Cloud Function.
  // RH_BROADCAST_ADDRESS (255) envia para todos os nós na rede.
  // O dispositivo final é responsável por verificar se a mensagem é para ele.
  manager.sendtoWait(payload, length, RH_BROADCAST_ADDRESS);
}

// MODIFICADO: Ouve JSON do LoRa e publica JSON para o MQTT
void listen_lora_mesh() {
  uint8_t buf[RH_MESH_MAX_MESSAGE_LEN];
  uint8_t len = sizeof(buf);
  uint8_t from;

  if (manager.recvfromAckTimeout(buf, &len, 2000, &from)) {
    // 1. Recebe JSON do dispositivo LoRa
    StaticJsonDocument<200> received_doc;
    DeserializationError error = deserializeJson(received_doc, buf, len);

    if (error) {
      Serial.print(F("Falha ao ler JSON do LoRa: "));
      Serial.println(error.c_str());
      return;
    }

    const char* mac = received_doc["from_mac"] | "";
    const char* text = received_doc["text"] | "";

    Serial.println("Recebido do no LoRa com MAC " + String(mac) + ": " + String(text));

    // 2. Cria um NOVO JSON para publicar no MQTT
    StaticJsonDocument<256> doc_to_publish;
    doc_to_publish["mac_address"] = mac;
    doc_to_publish["payload"] = text;

    char json_buffer[256];
    size_t n = serializeJson(doc_to_publish, json_buffer);
    
    // 3. Publica no tópico de uplink para a Cloud Function
    mqttClient.publish("lora/uplink", json_buffer, n);
  } 
}

/*******************************************************************************
 * FUNÇÕES INALTERADAS
 *******************************************************************************/
void setup_wifi() {
  delay(10);
  Serial.println("Conectando ao WiFi: " + String(ssid));
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi conectado. IP: " + WiFi.localIP().toString());
}

