import 'package:flutter/material.dart';
import 'package:myapp/widgets/summary_card.dart';
import 'package:myapp/widgets/chart_widget.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: SummaryCard(
                  title: 'Total Devices',
                  value: '128',
                  icon: Icons.devices,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SummaryCard(
                  title: 'Online',
                  value: '110',
                  icon: Icons.wifi,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SummaryCard(
                  title: 'Low Battery',
                  value: '15',
                  icon: Icons.battery_alert,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SummaryCard(
                  title: 'Alerts',
                  value: '3',
                  icon: Icons.warning,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Charts
          const ChartWidget(),
        ],
      ),
    );
  }
}
