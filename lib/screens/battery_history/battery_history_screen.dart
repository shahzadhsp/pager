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

  Future<void> loadData() async {
    final data = await DBHelper.getHistory();
    double index = 0.0;

    spots = data.map((e) {
      return FlSpot(index++, e['level'].toDouble());
    }).toList();

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    BatteryLevelService.start();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Battery History")),
      body: spots.isEmpty
          ? const Center(child: Text("No battery history yet"))
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
