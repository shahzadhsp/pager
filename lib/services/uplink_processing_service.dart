import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'dart:developer' as developer;

class UplinkProcessingService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  late StreamSubscription _uplinkSubscription;

  UplinkProcessingService() {
    _listenForUplinks();
  }

  void _listenForUplinks() {
    final uplinkRef = _dbRef.child('uplink_log').orderByChild('timestamp').startAt(DateTime.now().millisecondsSinceEpoch);

    _uplinkSubscription = uplinkRef.onChildAdded.listen((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return;

      try {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        final payload = data['payload'] as String?;
        final deviceId = data['dev_eui'] as String?; // Assumindo que o ID do dispositivo está aqui

        if (payload == null || deviceId == null) return;

        developer.log('Novo uplink recebido de $deviceId com payload: $payload', name: 'UplinkService');

        if (payload.startsWith('ACCEPT:')) {
          _handleAccept(payload, deviceId);
        } else if (payload.startsWith('REJECT:')) {
          _handleReject(payload, deviceId);
        }
      } catch (e, s) {
        developer.log('Erro ao processar uplink', name: 'UplinkService', error: e, stackTrace: s);
      }
    }, onError: (error, stackTrace) {
       developer.log('Erro no stream de uplink', name: 'UplinkService', error: error, stackTrace: stackTrace);
    });
  }

  void _handleAccept(String payload, String deviceId) {
    final parts = payload.split(':');
    if (parts.length < 2) return;
    final groupId = parts[1];

    developer.log('Processando ACCEPT para o grupo $groupId do dispositivo $deviceId', name: 'UplinkService');

    final memberRef = _dbRef.child('/groups/$groupId/members/$deviceId');
    memberRef.set('member').then((_) {
      developer.log('Dispositivo $deviceId aceite no grupo $groupId.', name: 'UplinkService');
    }).catchError((e) {
      developer.log('Erro ao atualizar o estado do membro para o grupo $groupId', name: 'UplinkService', error: e);
    });
  }

  void _handleReject(String payload, String deviceId) {
    final parts = payload.split(':');
    if (parts.length < 2) return;
    final groupId = parts[1];

    developer.log('Processando REJECT para o grupo $groupId do dispositivo $deviceId', name: 'UplinkService');

    final memberRef = _dbRef.child('/groups/$groupId/members/$deviceId');
    memberRef.remove().then((_) {
      developer.log('Dispositivo $deviceId rejeitado e removido do grupo $groupId.', name: 'UplinkService');
    }).catchError((e) {
      developer.log('Erro ao remover o membro do grupo $groupId', name: 'UplinkService', error: e);
    });
  }

  void dispose() {
    _uplinkSubscription.cancel();
  }
}
