import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/widgets/sample_report_widget.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  bool _reportGenerated = false;

  Future<void> _selectDate(
    BuildContext context, {
    required bool isStartDate,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
        _reportGenerated = false; // Reset on date change
      });
    }
  }

  void _generateReport() {
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('endDate'.tr())));
      return;
    }
    setState(() {
      _reportGenerated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final _ = DateFormat('yyyy-MM-dd');

    return Scaffold(
      appBar: AppBar(title: Text('generateReport'.tr())),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDatePickerButton(
                  context,
                  'startDate'.tr(),
                  _startDate,
                  isStartDate: true,
                ),
                _buildDatePickerButton(
                  context,
                  'endDateLabel'.tr(),
                  _endDate,
                  isStartDate: false,
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.bar_chart),
              label: Text('generateReport'.tr()),
              onPressed: _generateReport,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Expanded(
              child: _reportGenerated
                  ? SampleReportWidget(startDate: _startDate, endDate: _endDate)
                  : Center(
                      child: Text(
                        'selectDateRange'.tr(),
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerButton(
    BuildContext context,
    String label,
    DateTime date, {
    required bool isStartDate,
  }) {
    final dateFormat = DateFormat('MMM d, yyyy');
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => _selectDate(context, isStartDate: isStartDate),
          child: Text(dateFormat.format(date)),
        ),
      ],
    );
  }
}
