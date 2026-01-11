import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {PubSub} from "@google-cloud/pubsub";

// Inicialize o Firebase Admin e o Pub/Sub
admin.initializeApp();
const firestore = admin.firestore();
const pubsub = new PubSub();

// Tópicos do Pub/Sub que espelham os tópicos MQTT
const UPLINK_TOPIC = "lora-uplink";
const DOWNLINK_TOPIC = "lora-downlink";

/**
 * Função #1: LORA UPLINK
 * Gatilho: Mensagem no tópico Pub/Sub 'lora-uplink' (vinda do Gateway).
 * Ação: Salva a mensagem do dispositivo no chat correto no Firestore.
 */
export const loraUplink = functions.pubsub.topic(UPLINK_TOPIC).onPublish(async (message) => {
  try {
    const data = JSON.parse(Buffer.from(message.data, "base64").toString());
    const macAddress = data.mac_address;
    const payload = data.payload;

    if (!macAddress || !payload) {
      console.error("Dados invalidos no uplink:", data);
      return null;
    }

    console.log(`Uplink recebido do MAC: ${macAddress}. Payload: ${payload}`);

    // Salva a mensagem na subcoleção do dispositivo
    await firestore.collection("devices").doc(macAddress).collection("messages").add({
      text: payload,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      direction: "uplink", // Mensagem do dispositivo para o app
    });

    return console.log("Uplink salvo no Firestore com sucesso.");
  } catch (error) {
    console.error("Erro ao processar uplink:", error);
    return null;
  }
});

/**
 * Função #2: QUEUE DOWNLINK
 * Gatilho: Nova mensagem criada na subcoleção /devices/{deviceId}/messages.
 * Ação: Envia a mensagem do app para o dispositivo via MQTT.
 */
export const queueDownlink = functions.firestore
    .document("devices/{deviceId}/messages/{messageId}")
    .onCreate(async (snap, context) => {
      const messageData = snap.data();

      // Envia apenas se for uma mensagem do app para o dispositivo
      if (messageData.direction !== "downlink") {
        return null;
      }

      const deviceId = context.params.deviceId; // Este é o MAC Address
      const payload = messageData.text;

      console.log(`Enviando downlink para o MAC: ${deviceId}. Payload: ${payload}`);

      // Monta o JSON para o dispositivo
      const downlinkJson = {
        to_mac: deviceId,
        payload: payload,
      };

      // Publica no tópico de downlink
      try {
        await pubsub.topic(DOWNLINK_TOPIC).publishMessage({json: downlinkJson});
        return console.log("Downlink publicado no Pub/Sub com sucesso.");
      } catch (error) {
        console.error("Erro ao publicar downlink:", error);
        return null;
      }
    });

/**
 * Função #3: ON USER PLAN CHANGE
 * Gatilho: Documento de usuário na coleção /users é atualizado.
 * Ação: Envia comando de configuração para os dispositivos do usuário.
 */
export const onUserPlanChange = functions.firestore
    .document("users/{userId}")
    .onUpdate(async (change, context) => {
      const before = change.before.data();
      const after = change.after.data();

      // Verifica se o plano realmente mudou
      if (before.subscriptionPlan === after.subscriptionPlan) {
        return null;
      }

      const userId = context.params.userId;
      const newPlan = after.subscriptionPlan;
      const allowP2P = (newPlan === "monthly" || newPlan === "annual");

      console.log(`Plano do usuario ${userId} mudou para ${newPlan}. Permitir P2P: ${allowP2P}`);

      // Encontra todos os dispositivos pertencentes a este usuário
      const devicesSnapshot = await firestore.collection("devices").where("owner_uid", "==", userId).get();

      if (devicesSnapshot.empty) {
        console.log("Nenhum dispositivo encontrado para este usuario.");
        return null;
      }

      // Cria uma promessa de publicação para cada dispositivo
      const publishPromises = devicesSnapshot.docs.map((doc) => {
        const deviceId = doc.id; // O ID do documento é o MAC Address
        console.log(`Enviando config para o dispositivo MAC: ${deviceId}`);

        const configJson = {
          to_mac: deviceId,
          config: {
            allow_p2p: allowP2P,
          },
        };

        return pubsub.topic(DOWNLINK_TOPIC).publishMessage({json: configJson});
      });

      await Promise.all(publishPromises);
      return console.log("Comandos de configuracao enviados para todos os dispositivos do usuario.");
    });
