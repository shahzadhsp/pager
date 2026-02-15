import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'dart:async';
import 'package:battery_plus/battery_plus.dart';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'battery.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE battery(level INTEGER, time TEXT)');
      },
    );
  }

  static Future<void> cleanOldData() async {
    final db = await database;

    final cutoff = DateTime.now()
        .subtract(const Duration(days: 7))
        .toIso8601String();

    await db.delete('battery', where: 'time < ?', whereArgs: [cutoff]);
  }

  static Future<void> insert(int level) async {
    final db = await database;
    await db.insert('battery', {
      'level': level,
      'time': DateTime.now().toIso8601String(),
    });
    await cleanOldData();
  }

  static Future<List<Map<String, dynamic>>> getHistory() async {
    final db = await database;
    return db.query('battery', orderBy: 'time ASC');
  }
}

class BatteryTracker {
  static final Battery _battery = Battery();

  static void startTracking() {
    Timer.periodic(const Duration(minutes: 15), (timer) async {
      int level = await _battery.batteryLevel;
      await DBHelper.insert(level);
    });
  }
}

class BatteryLevelService {
  static final Battery _battery = Battery();
  static Timer? _timer;

  static void start() {
    if (_timer != null) return;

    _timer = Timer.periodic(const Duration(minutes: 15), (timer) async {
      final level = await _battery.batteryLevel;
      await DBHelper.insert(level);
    });
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
