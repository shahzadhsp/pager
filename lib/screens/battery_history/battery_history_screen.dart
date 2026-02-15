import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:myapp/services/battery_level_history/battery_level.dart';

class BatteryHistoryScreen extends StatefulWidget {
  const BatteryHistoryScreen({super.key});

  @override
  State<BatteryHistoryScreen> createState() => _BatteryHistoryScreenState();
}

class _BatteryHistoryScreenState extends State<BatteryHistoryScreen> {
  List<FlSpot> spots = [];

  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();
    loadData();

    refreshTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => loadData(),
    );
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> loadData() async {
    final data = await DBHelper.getHistory();

    spots = data.map((e) {
      final time = DateTime.parse(e['time']);
      final x = time.millisecondsSinceEpoch.toDouble();
      final y = e['level'].toDouble();
      return FlSpot(x, y);
    }).toList();

    setState(() {});
    double baseTime = DateTime.parse(
      data.first['time'],
    ).millisecondsSinceEpoch.toDouble();

    spots = data.map((e) {
      final time = DateTime.parse(e['time']);
      final x = time.millisecondsSinceEpoch.toDouble() - baseTime;
      final y = e['level'].toDouble();
      return FlSpot(x, y);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("batteryLevelHistory".tr())),
      body: spots.isEmpty
          ? Center(child: Text("noBatteryData".tr()))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
