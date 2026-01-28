class AdminUplink {
  final String id;
  final String deviceId;
  final String gatewayId;
  final DateTime timestamp;
  final Map<String, dynamic> payload;
  final int rssi;

  AdminUplink({
    required this.id,
    required this.deviceId,
    required this.gatewayId,
    required this.timestamp,
    required this.payload,
    required this.rssi,
  });
}
