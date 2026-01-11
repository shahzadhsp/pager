import 'dart:developer' as developer;
import 'package:intl/intl.dart';

class DeviceStatusModel {
  final String id;
  final int lastSeen; // timestamp
  final bool isActive;
  final String? nickname;
  final double? lat;
  final double? lon;

  DeviceStatusModel({
    required this.id,
    required this.lastSeen,
    required this.isActive,
    this.nickname,
    this.lat,
    this.lon,
  });

  String get formattedLastSeen {
    if (lastSeen == 0) return 'Nunca';
    final DateTime date = DateTime.fromMillisecondsSinceEpoch(lastSeen);
    final Duration difference = DateTime.now().difference(date);

    if (difference.inSeconds < 60) return 'Agora mesmo';
    if (difference.inMinutes < 60) return 'Há ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'Há ${difference.inHours}h';
    
    return DateFormat('dd/MM/yy HH:mm').format(date);
  }

  // Construtor factory para criar uma instância a partir dos dados do Firebase
  factory DeviceStatusModel.fromFirebase(String key, Map<dynamic, dynamic> data) {
    try {
      final int lastSeenTimestamp = (data['last_seen'] ?? 0) as int;
      final bool isActive = (DateTime.now().millisecondsSinceEpoch - lastSeenTimestamp) < 300000; // 5 minutos

      // Extrai lat e lon, garantindo que são doubles
      final num? latNum = data['lat'] as num?;
      final num? lonNum = data['lon'] as num?;

      return DeviceStatusModel(
        id: key,
        lastSeen: lastSeenTimestamp,
        isActive: isActive,
        nickname: data['nickname'] as String?,
        lat: latNum?.toDouble(),
        lon: lonNum?.toDouble(),
      );
    } catch (e, s) {
      developer.log(
        'Erro ao converter DeviceStatusModel para o ID: $key',
        name: 'app.model',
        error: e,
        stackTrace: s,
      );
      // Retorna um estado padrão para evitar que a app quebre
      return DeviceStatusModel(id: key, lastSeen: 0, isActive: false);
    }
  }
}
