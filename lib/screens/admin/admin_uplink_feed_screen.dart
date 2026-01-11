import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/admin_service.dart';

class AdminUplinkFeedScreen extends StatelessWidget {
  const AdminUplinkFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminService = context.watch<AdminService>();
    // Ordena os uplinks do mais recente para o mais antigo
    final sortedUplinks = adminService.uplinks.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Scaffold(
      appBar: AppBar(title: Text('realTimeUplinkFeed'.tr())),
      body: ListView.builder(
        itemCount: sortedUplinks.length,
        itemBuilder: (context, index) {
          final uplink = sortedUplinks[index];
          return _buildUplinkCard(context, uplink);
        },
      ),
    );
  }

  Widget _buildUplinkCard(BuildContext context, AdminUplink uplink) {
    final payloadString = uplink.payload.entries
        .map((e) => '${e.key}: ${e.value.toStringAsFixed(1)}')
        .join(', ');
    final rssiColor = _getRssiColor(uplink.rssi);
    final dateFormat = DateFormat('dd/MM/yy HH:mm:ss');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: rssiColor.withOpacity(0.2),
          child: Icon(Icons.arrow_circle_up_outlined, color: rssiColor),
        ),
        title: InkWell(
          onTap: () => context.go('/admin/devices/${uplink.deviceId}'),
          child: Text(
            '${'device'.tr()}: ${uplink.deviceId}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${'payLoad'.tr()}: $payloadString'),

            const SizedBox(height: 4),
            Text('${'viaGateway'.tr()}: ${uplink.gatewayId}'),

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RSSI: ${uplink.rssi} dBm',
                  style: TextStyle(
                    color: rssiColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  dateFormat.format(uplink.timestamp),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Color _getRssiColor(int rssi) {
    if (rssi > -70) return Colors.green.shade700; // Forte
    if (rssi > -100) return Colors.orange.shade700; // Médio
    return Colors.red.shade700; // Fraco
  }
}
