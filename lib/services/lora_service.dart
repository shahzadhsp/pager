import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:firebase_database/firebase_database.dart';

class UplinkMessage {
  final String key;
  final String fromMac;
  final String? text;
  final String? status;
  final DateTime timestamp;

  UplinkMessage({
    required this.key,
    required this.fromMac,
    this.text,
    this.status,
    required this.timestamp,
  });

  factory UplinkMessage.fromJson(String key, String jsonString) {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      return UplinkMessage(
        key: key,
        fromMac: data['from_mac'] ?? 'mac_desconhecido',
        text: data['text'],
        status: data['status'],
        timestamp: DateTime.now(),
      );
    } catch (e, s) {
      developer.log("Erro ao decodificar a mensagem de uplink", name: 'lora.service', error: e, stackTrace: s);
      return UplinkMessage(
        key: key,
        fromMac: 'erro_decodificacao',
        text: jsonString,
        status: 'error',
        timestamp: DateTime.now(),
      );
    }
  }
}

class LoraService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Stream<List<String>> getDeviceListStream() {
    final controller = StreamController<List<String>>();
    final subscription = _dbRef.child('devices').onValue.listen((DatabaseEvent event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final deviceIds = data.keys.cast<String>().toList();
        controller.add(deviceIds);
      } else {
        controller.add([]);
      }
    });

    controller.onCancel = () {
      subscription.cancel();
    };

    return controller.stream;
  }

  Stream<UplinkMessage> getUplinkStream(String deviceId) {
    final controller = StreamController<UplinkMessage>();
    final path = 'devices/$deviceId/uplink';
    
    final subscription = _dbRef.child(path).onChildAdded.listen((DatabaseEvent event) {
       if (event.snapshot.exists && event.snapshot.value != null) {
         final key = event.snapshot.key!;
         final value = event.snapshot.value as String; 
         final message = UplinkMessage.fromJson(key, value);
         controller.add(message);
       }
    });

    controller.onCancel = () {
      subscription.cancel();
    };
    
    return controller.stream;
  }

  Stream<bool> getOtaReadyStream(String deviceId) {
    return getUplinkStream(deviceId)
        .where((message) => message.status == 'ota_ready')
        .map((_) => true);
  }

  Future<void> sendDownlinkCommand(String deviceId, Map<String, dynamic> command) async {
    try {
      final path = 'devices/$deviceId/downlink';
      final jsonCommand = jsonEncode(command);
      await _dbRef.child(path).push().set(jsonCommand);
      developer.log("Enviado downlink para $path: $jsonCommand", name: 'lora.service');
    } catch (e, s) {
      developer.log("Erro ao enviar comando de downlink", name: 'lora.service', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> sendOtaStartCommand(String deviceId, String originalMac) async {
    final command = {
      'to_mac': originalMac,
      'cmd': 'start_ota',
    };
    await sendDownlinkCommand(deviceId, command);
  }

  Future<void> sendTextMessage(String deviceId, String originalMac, String text) async {
    final command = {
      'to_mac': originalMac,
      'payload': text,
    };
    await sendDownlinkCommand(deviceId, command);
  }
}
