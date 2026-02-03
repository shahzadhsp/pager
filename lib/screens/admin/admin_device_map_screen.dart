import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../services/admin_service.dart';

class AdminDeviceMapScreen extends StatelessWidget {
  const AdminDeviceMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminService = Provider.of<AdminService>(context);
    final centerOfLisbon = LatLng(38.7223, -9.1393);
    // Gerar marcadores para os dispositivos
    final deviceMarkers = adminService.devices.map((device) {
      return Marker(
        width: 80,
        height: 80,
        point: device.location,
        child: _buildMarker(
          context,
          icon: Icons.memory,
          color: device.isOnline ? Colors.green.shade600 : Colors.grey.shade700,
          label: device.id,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.black87,
                content: Text(
                  '${'device'.tr()}: ${device.id} | ${'owner'.tr()}: ${device.ownerName} | ${'status'.tr()}: ${device.isOnline ? "Online" : "Offline"}',
                ),
              ),
            );
          },
        ),
      );
    }).toList();

    // Gerar marcadores para os gateways
    final gatewayMarkers = adminService.gateways.map((gateway) {
      return Marker(
        width: 80,
        height: 80,
        point: gateway.location,
        child: _buildMarker(
          context,
          icon: Icons.router_rounded,
          color: gateway.isOnline ? Colors.blue.shade700 : Colors.red.shade800,
          label: gateway.name,
          size: 40,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.black87,
                content: Text(
                  'Gateway: ${gateway.name} | Status: ${gateway.isOnline ? "Online" : "Offline"}',
                ),
              ),
            );
          },
        ),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('devicesAndGatewaysMap'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('updatingData'.tr()),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      resizeToAvoidBottomInset: false,
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(38.7223, -9.1393),
          initialZoom: 11,
        ),
        children: [
          TileLayer(
            urlTemplate:
                "https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=fAlTHh6RhbdmiGEwCw8A",
            userAgentPackageName: 'com.company.pager',
          ),
          MarkerLayer(markers: [...deviceMarkers, ...gatewayMarkers]),
        ],
      ),
    );
  }

  Widget _buildMarker(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
    double size = 30.0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: size,
            shadows: const [Shadow(blurRadius: 10.0, color: Colors.black54)],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
