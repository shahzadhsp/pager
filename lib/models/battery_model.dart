class BatteryRecord {
  final int level;
  final DateTime time;

  BatteryRecord({required this.level, required this.time});

  Map<String, dynamic> toMap() {
    return {'level': level, 'time': time.toIso8601String()};
  }

  factory BatteryRecord.fromMap(Map<String, dynamic> map) {
    return BatteryRecord(
      level: map['level'],
      time: DateTime.parse(map['time']),
    );
  }
}
