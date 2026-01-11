import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:developer' as developer;

import '../models/device_status_model.dart';

class AdminMapScreen extends StatefulWidget {
  const AdminMapScreen({super.key});

  @override
  State<AdminMapScreen> createState() => _AdminMapScreenState();
}

class _AdminMapScreenState extends State<AdminMapScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  final DatabaseReference _devicesRef = FirebaseDatabase.instance.ref('device_status');
  late StreamSubscription<DatabaseEvent> _devicesSubscription;
  
  final Map<String, Marker> _markers = {};
  String? _mapStyle;

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _activateListeners();
  }

  Future<void> _loadMapStyle() async {
    _mapStyle = await rootBundle.loadString('assets/map_style.json');
  }

  @override
  void dispose() {
    _devicesSubscription.cancel();
    super.dispose();
  }

  void _activateListeners() {
    _devicesSubscription = _devicesRef.onValue.listen(
      (DatabaseEvent event) {
        if (!mounted || !event.snapshot.exists || event.snapshot.value == null) return;
        try {
          final data = event.snapshot.value as Map<dynamic, dynamic>;
          _updateMarkers(data);
        } catch (e, s) {
          developer.log('Erro ao processar dados do Firebase: $e', name: 'admin.map.screen', error: e, stackTrace: s);
        }
      },
      onError: (Object o, StackTrace s) => developer.log('Erro no stream do Firebase', name: 'admin.map.screen', error: o, stackTrace: s),
    );
  }

  void _updateMarkers(Map<dynamic, dynamic> devicesData) {
    final Map<String, Marker> newMarkers = {};
    final List<LatLng> markerPositions = [];

    devicesData.forEach((key, value) {
      if (value is! Map<dynamic, dynamic>) return;
      final device = DeviceStatusModel.fromFirebase(key, value);

      if (device.lat != null && device.lon != null) {
        final position = LatLng(device.lat!, device.lon!);
        markerPositions.add(position);

        final marker = Marker(
          markerId: MarkerId(device.id),
          position: position,
          infoWindow: InfoWindow(
            title: device.nickname ?? device.id,
            snippet: 'Visto por último: ${device.formattedLastSeen}',
          ),
          icon: device.isActive
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        );
        newMarkers[device.id] = marker;
      }
    });

    if (mounted) {
      setState(() {
        _markers.clear();
        _markers.addAll(newMarkers);
      });

      if (markerPositions.isNotEmpty) {
        _centerMapOnMarkers(markerPositions);
      }
    }
  }

  Future<void> _centerMapOnMarkers(List<LatLng> positions) async {
    if (positions.isEmpty || !_mapController.isCompleted) return;

    final GoogleMapController controller = await _mapController.future;

    if (positions.length == 1) {
      controller.animateCamera(CameraUpdate.newLatLngZoom(positions.first, 15));
    } else {
      final LatLngBounds bounds = _boundsFromLatLngList(positions);
      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100.0));
    }
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(northeast: LatLng(x1!, y1!), southwest: LatLng(x0!, y0!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: const CameraPosition(
          target: LatLng(38.736946, -9.142685),
          zoom: 7,
        ),
        onMapCreated: (GoogleMapController controller) {
          if (!_mapController.isCompleted) {
            _mapController.complete(controller);
          }
          controller.setMapStyle(_mapStyle);
        },
        markers: Set<Marker>.of(_markers.values),
        myLocationButtonEnabled: false,
        zoomControlsEnabled: true,
      ),
    );
  }
}
