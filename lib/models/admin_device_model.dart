import 'package:latlong2/latlong.dart';

class AdminDevice {
  final String id;
  final String macAddress;
  final String ownerId;
  final String ownerName;
  final LatLng location;
  final DateTime addedDate;
  DateTime lastUplink;
  bool isOnline;
  String lastHeardByGatewayId;

  AdminDevice({
    required this.id,
    required this.macAddress,
    required this.ownerId,
    required this.ownerName,
    required this.location,
    required this.addedDate,
    required this.lastUplink,
    required this.lastHeardByGatewayId,
    this.isOnline = false,
  });
  factory AdminDevice.fromMap(String id, Map<String, dynamic> data) {
    return AdminDevice(
      id: id,
      macAddress: data['macAddress'] ?? '',
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      location: LatLng(
        (data['lat'] ?? 0).toDouble(),
        (data['lng'] ?? 0).toDouble(),
      ),
      addedDate: DateTime.fromMillisecondsSinceEpoch(data['addedDate'] ?? 0),
      lastUplink: DateTime.fromMillisecondsSinceEpoch(data['lastUplink'] ?? 0),
      lastHeardByGatewayId: data['lastHeardByGatewayId'] ?? '',
      isOnline: data['isOnline'] ?? false,
    );
  }
}
