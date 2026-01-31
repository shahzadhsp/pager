import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AnalyticsProvider extends ChangeNotifier {
  final _db = FirebaseDatabase.instance;

  Map<int, int> hourlyUplinks = {};
  int todayUplinks = 0;

  void listenAnalytics() {
    _db.ref('analytics/hourly').onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return;

      hourlyUplinks.clear();
      data.forEach((key, value) {
        hourlyUplinks[int.parse(key.toString())] = value as int;
      });

      notifyListeners();
    });

    _db.ref('analytics/daily/2026-01-29').onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return;

      todayUplinks = data['totalUplinks'] ?? 0;
      notifyListeners();
    });
  }
}
