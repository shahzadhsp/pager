
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  /// Envia um comando de downlink para a fila no Firebase Realtime Database.
  ///
  /// O gateway ESP32 estará a ouvir no nó 'downlink_commands' e irá
  /// processar o comando, enviando-o via LoRa para o dispositivo com o
  /// MAC address correspondente.
  ///
  /// [macAddress]: O endereço MAC do dispositivo de destino.
  /// [command]: O comando a ser executado (ex: 'RESTART', 'STATUS_REQUEST').
  Future<bool> sendDownlinkCommand(String macAddress, String command) async {
    try {
      final commandRef = _dbRef.child('downlink_commands').push();
      await commandRef.set({
        'mac_address': macAddress,
        'command': command,
        'timestamp': ServerValue.timestamp, // Usa o timestamp do servidor Firebase
        'status': 'pending' // Status inicial do comando
      });
      if (kDebugMode) {
        print('Comando \'$command\' enviado para $macAddress via Firebase.');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao enviar comando de downlink: $e');
      }
      return false;
    }
  }
}
