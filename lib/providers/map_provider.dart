import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/device_location_model.dart';

class MapProvider with ChangeNotifier {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  StreamSubscription? _locationsSubscription;

  Map<String, DeviceLocation> _locations = {};
  bool _isLoading = true;
  String? _error;

  List<DeviceLocation> get locations => _locations.values.toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  MapProvider() {
    _listenForDeviceLocations();
  }

  void _listenForDeviceLocations() {
    _isLoading = true;
    notifyListeners();

    final locationsRef = _dbRef.child('last_seen');

    _locationsSubscription = locationsRef.onValue.listen((event) {
      if (!event.snapshot.exists) {
        _isLoading = false;
        _locations = {};
        notifyListeners();
        return;
      }

      final allDevicesData = event.snapshot.value as Map<dynamic, dynamic>;
      final Map<String, DeviceLocation> newLocations = {};

      allDevicesData.forEach((deviceId, deviceData) {
        final data = deviceData as Map<dynamic, dynamic>;
        final location = data['location'];

        if (location != null) {
          final parts = location.split(',');
          if (parts.length == 2) {
            final lat = double.tryParse(parts[0]);
            final lon = double.tryParse(parts[1]);

            if (lat != null && lon != null) {
              newLocations[deviceId] = DeviceLocation(
                id: deviceId,
                name: data['name'] ?? deviceId, // Usa o nome se disponível
                latitude: lat,
                longitude: lon,
                timestamp: data['timestamp'] ?? 0,
              );
            }
          }
        }
      });

      _locations = newLocations;
      _isLoading = false;
      _error = null;
      notifyListeners();

    }, onError: (e) {
      _error = "Erro ao carregar localizações: $e";
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _locationsSubscription?.cancel();
    super.dispose();
  }
}
