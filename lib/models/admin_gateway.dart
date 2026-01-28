import 'package:latlong2/latlong.dart';

class AdminGateway {
  final String id;
  final String name;
  final LatLng location;
  bool isOnline;
  DateTime lastSeen;

  AdminGateway({
    required this.id,
    required this.name,
    required this.location,
    required this.lastSeen,
    this.isOnline = false,
  });
}
