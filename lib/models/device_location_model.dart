import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DeviceLocation with ClusterItem {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int timestamp;

  DeviceLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);

  @override
  LatLng get location => LatLng(latitude, longitude);
}
