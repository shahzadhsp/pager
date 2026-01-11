class Device {
  final String id;
  final String name;
  final bool isOnline;
  final double batteryLevel;
  final String lastActivity;
  final String originalMac;

  Device({
    required this.id,
    required this.name,
    required this.isOnline,
    required this.batteryLevel,
    required this.lastActivity,
    required this.originalMac,
  });
}
