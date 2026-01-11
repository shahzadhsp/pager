// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart' ;
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:provider/provider.dart';
// import '../../services/admin_service.dart';

// class AdminDeviceMapScreen extends StatelessWidget {
//   const AdminDeviceMapScreen({super.key});
//   @override
//   Widget build(BuildContext context) {
//     final adminService = Provider.of<AdminService>(context);
//     final centerOfLisbon = LatLng(38.7223, -9.1393);
//     // Gerar marcadores para os dispositivos
//     final deviceMarkers = adminService.devices.map((device) {
//       return Marker(
//         width: 80.0,
//         height: 80.0,
//         point: device.location,
//         builder: (ctx) => _buildMarker(
//           context,
//           icon: Icons.memory, // Ícone de chip para dispositivo
//           color: device.isOnline ? Colors.green.shade600 : Colors.grey.shade700,
//           label: device.id,
//           onTap: () {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 backgroundColor: Colors.black87,
//                 content: Text(
//                   'Dispositivo: ${device.id} | Proprietário: ${device.ownerName} | Status: ${device.isOnline ? "Online" : "Offline"}',
//                 ),
//                 duration: const Duration(seconds: 3),
//               ),
//             );
//           },
//         ),
//       );
//     }).toList();
//     // Gerar marcadores para os gateways
//     final gatewayMarkers = adminService.gateways.map((gateway) {
//       return Marker(
//         width: 80.0,
//         height: 80.0,
//         point: gateway.location,
//         builder: (ctx) => _buildMarker(
//           context,
//           icon: Icons.router_rounded, // Ícone de torre para gateway
//           color: gateway.isOnline ? Colors.blue.shade700 : Colors.red.shade800,
//           label: gateway.name,
//           size: 40.0, // Gateways são maiores
//           onTap: () {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 backgroundColor: Colors.black87,
//                 content: Text(
//                   'Gateway: ${gateway.name} | Status: ${gateway.isOnline ? "Online" : "Offline"}',
//                 ),
//                 duration: const Duration(seconds: 3),
//               ),
//             );
//           },
//         ),
//       );
//     }).toList();
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Mapa de Dispositivos e Gateways'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () {
//               // Apenas para dar feedback visual, o provider fará o resto
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                   content: Text('Atualizando dados...'),
//                   duration: Duration(seconds: 1),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//       body: FlutterMap(
//         options: MapOptions(center: centerOfLisbon, zoom: 11.5),
//         children: [
//           TileLayer(
//             urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
//             subdomains: const ['a', 'b', 'c'],
//             userAgentPackageName:
//                 'com.example.app', // Adicione o nome do seu pacote aqui
//           ),
//           MarkerLayer(markers: [...deviceMarkers, ...gatewayMarkers]),
//         ],
//       ),
//     );
//   }
//   Widget _buildMarker(
//     BuildContext context, {
//     required IconData icon,
//     required Color color,
//     required String label,
//     required VoidCallback onTap,
//     double size = 30.0,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             icon,
//             color: color,
//             size: size,
//             shadows: const [Shadow(blurRadius: 10.0, color: Colors.black54)],
//           ),
//           const SizedBox(height: 4),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.8),
//               borderRadius: BorderRadius.circular(5),
//             ),
//             child: Text(
//               label,
//               style: const TextStyle(
//                 fontSize: 8,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black,
//               ),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

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
      // return Marker(
      //   width: 80.0,
      //   height: 80.0,
      //   point: device.location,
      //   builder: (ctx) => _buildMarker(
      //     context,
      //     icon: Icons.memory,
      //     color: device.isOnline ? Colors.green.shade600 : Colors.grey.shade700,
      //     label: device.id,
      //     onTap: () {
      //       ScaffoldMessenger.of(context).showSnackBar(
      //         SnackBar(
      //           backgroundColor: Colors.black87,
      //           content: Text(
      //             'Dispositivo: ${device.id} | Proprietário: ${device.ownerName} | Status: ${device.isOnline ? "Online" : "Offline"}',
      //           ),
      //           duration: const Duration(seconds: 3),
      //         ),
      //       );
      //     },
      //   ),
      //   child: null,
      // );
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
      // return Marker(
      //   width: 80.0,
      //   height: 80.0,
      //   point: gateway.location,
      //   builder: (ctx) => _buildMarker(
      //     context,
      //     icon: Icons.router_rounded,
      //     color: gateway.isOnline ? Colors.blue.shade700 : Colors.red.shade800,
      //     label: gateway.name,
      //     size: 40.0,
      //     onTap: () {
      //       ScaffoldMessenger.of(context).showSnackBar(
      //         SnackBar(
      //           backgroundColor: Colors.black87,
      //           content: Text(
      //             'Gateway: ${gateway.name} | Status: ${gateway.isOnline ? "Online" : "Offline"}',
      //           ),
      //           duration: const Duration(seconds: 3),
      //         ),
      //       );
      //     },
      //   ),
      // );
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
      // body: FlutterMap(
      //   options: MapOptions(center: centerOfLisbon, zoom: 11.5),
      //   children: [
      //     TileLayer(
      //       urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
      //       subdomains: const ['a', 'b', 'c'],
      //       userAgentPackageName: 'com.example.app',
      //     ),
      //     MarkerLayer(markers: [...deviceMarkers, ...gatewayMarkers]),
      //   ],
      // ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: centerOfLisbon, // 🔥 FIXED
          initialZoom: 11.5, // 🔥 FIXED
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.app',
          ),

          MarkerLayer(
            // 🔥 FIXED
            markers: [...deviceMarkers, ...gatewayMarkers],
          ),
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
