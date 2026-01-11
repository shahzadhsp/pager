import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/admin_service.dart';

class AdminGatewayManagementScreen extends StatelessWidget {
  const AdminGatewayManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminService = Provider.of<AdminService>(context);
    final gateways = adminService.gateways;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(title: Text('gatewayManagement'.tr())),
      body: ListView.builder(
        itemCount: gateways.length,
        itemBuilder: (context, index) {
          final gateway = gateways[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: Icon(
                gateway.isOnline
                    ? Icons.router_rounded
                    : Icons.signal_wifi_off_outlined,
                color: gateway.isOnline
                    ? Colors.green.shade600
                    : Colors.red.shade400,
                size: 30,
              ),
              title: Text(
                gateway.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ID: ${gateway.id}'),
                  Text(
                    '${'lastContact'.tr()}: ${dateFormat.format(gateway.lastSeen)}',
                  ),

                  Text(
                    '${'local'.tr()}: ${gateway.location.latitude.toStringAsFixed(3)}, ${gateway.location.longitude.toStringAsFixed(3)}',
                  ),
                ],
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                //In the future, navigate to a gateway details screen.
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('gateWayDetailsScreen'.tr()),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
