import 'package:flutter/material.dart';
import 'package:myapp/models/device_model.dart';
import 'package:myapp/screens/device_details_screen.dart';

class DeviceListItemWidget extends StatelessWidget {
  final Device device;

  const DeviceListItemWidget({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: device.isOnline ? Colors.green : Colors.red,
          child: const Icon(Icons.phone_android, color: Colors.white),
        ),
        title: Text(device.name),
        subtitle: Text(
          'Battery: ${(device.batteryLevel * 100).toStringAsFixed(0)}% - Last seen: ${device.lastActivity}',
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeviceDetailsScreen(deviceId: device.id, originalMac: device.originalMac),
            ),
          );
        },
      ),
    );
  }
}
