import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart' as cluster_manager;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../providers/map_provider.dart';
import '../../../models/device_location_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late cluster_manager.ClusterManager<DeviceLocation> _clusterManager;
  final Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = {};

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(38.7223, -9.1393),
    zoom: 7,
  );

  @override
  void initState() {
    super.initState();
    _clusterManager = cluster_manager.ClusterManager<DeviceLocation>(
      [],
      _updateMarkers,
      markerBuilder: _markerBuilder,
      stopClusteringZoom: 17.0,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locations = context.watch<MapProvider>().locations;
    _clusterManager.setItems(locations);
  }

  void _updateMarkers(Set<Marker> markers) {
    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);

    return mapProvider.isLoading
        ? const Center(child: CircularProgressIndicator())
        : GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _initialPosition,
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              _clusterManager.setMapId(controller.mapId);
            },
            onCameraMove: _clusterManager.onCameraMove,
            onCameraIdle: _clusterManager.updateMap,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          );
  }

  Future<Marker> _markerBuilder(dynamic cluster) async {
    final cluster_manager.Cluster<DeviceLocation> c = cluster;
    return Marker(
      markerId: MarkerId(c.getId()),
      position: c.location,
      onTap: () {
        if (!c.isMultiple) {
          final device = c.items.first;
          showModalBottomSheet(context: context, builder: (context) => _buildDeviceInfoSheet(device));
        }
      },
      icon: await _getMarkerBitmap(c.isMultiple ? 125 : 75,
          text: c.isMultiple ? c.count.toString() : null),
    );
  }

  Widget _buildDeviceInfoSheet(DeviceLocation device) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(device.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('ID: ${device.id}'),
          Text('Última atualização: ${device.dateTime.toString()}'),
          const SizedBox(height: 16),
          ElevatedButton(
            child: const Text('Ver Detalhes'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          )
        ],
      ),
    );
  }

  Future<BitmapDescriptor> _getMarkerBitmap(int size, {String? text}) async {
    final PictureRecorder pictureRecorder = PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint1 = Paint()..color = Colors.deepPurple;

    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.0, paint1);

    if (text != null) {
      TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
      painter.text = TextSpan(
        text: text,
        style: TextStyle(fontSize: size / 3, color: Colors.white, fontWeight: FontWeight.normal),
      );
      painter.layout();
      painter.paint(
        canvas,
        Offset(size / 2 - painter.width / 2, size / 2 - painter.height / 2),
      );
    }

    final img = await pictureRecorder.endRecording().toImage(size, size);
    final data = await img.toByteData(format: ImageByteFormat.png) as ByteData;

    return BitmapDescriptor.fromBytes(data.buffer.asUint8List());
  }
}
