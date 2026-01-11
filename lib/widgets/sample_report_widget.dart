import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SampleReportWidget extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;

  const SampleReportWidget({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report for ${dateFormat.format(startDate)} to ${dateFormat.format(endDate)}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Divider(),
            _buildSummaryRow('Total Alerts', '142'),
            _buildSummaryRow('Devices with Low Battery', '8'),
            _buildSummaryRow('Connection Timeouts', '23'),
            const SizedBox(height: 16),
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Expanded(
              child: ListTile(
                leading: Icon(Icons.warning, color: Colors.amber),
                title: Text('Device C3 - Low Battery Alert'),
                subtitle: Text('Battery at 15%'),
              ),
            ),
            const Expanded(
              child: ListTile(
                leading: Icon(Icons.error, color: Colors.red),
                title: Text('Device B2 - Connection Timeout'),
                subtitle: Text('Last seen 3 hours ago'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
