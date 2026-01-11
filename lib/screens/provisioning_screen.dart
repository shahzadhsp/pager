import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:myapp/models/device_model.dart';

class ProvisioningScreen extends StatefulWidget {
  const ProvisioningScreen({super.key});

  @override
  State<ProvisioningScreen> createState() => _ProvisioningScreenState();
}

class _ProvisioningScreenState extends State<ProvisioningScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        setState(() {
          _isProcessing = true;
        });
        _scannerController.stop();
        _handleScannedData(code);
      }
    }
  }

  void _handleScannedData(String data) {
    try {
      final decoded = jsonDecode(data) as Map<String, dynamic>;
      final String? id = decoded['id'];
      final String? name = decoded['name'];
      final String? mac = decoded['mac']; // Adicionado

      if (id == null || name == null || mac == null) { // Verificação adicionada
        _showErrorDialog('QR Code has invalid data format. Missing id, name, or mac.');
        return;
      }

      final newDevice = Device(
        id: id,
        name: name,
        isOnline: true,
        batteryLevel: 1.0,
        lastActivity: 'Just now',
        originalMac: mac, // Corrigido
      );

      _showConfirmationDialog(newDevice);
    } catch (e) {
      _showErrorDialog('Failed to parse QR Code data.');
    }
  }

  void _resumeScanning() {
    setState(() {
      _isProcessing = false;
    });
    _scannerController.start();
  }

  void _showConfirmationDialog(Device device) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Provisioning'),
        content: Text(
          'Do you want to add this device?\n\nID: ${device.id}\nName: ${device.name}\nMAC: ${device.originalMac}', // Adicionado MAC para confirmação
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _resumeScanning();
            },
          ),
          ElevatedButton(
            child: const Text('Add'),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(device); // Return the new device
            },
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _resumeScanning();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code to Provision')),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          _buildScannerOverlay(context),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay(BuildContext context) {
    final double scanArea = MediaQuery.of(context).size.width * 0.8;
    return Container(
      width: scanArea,
      height: scanArea,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
          width: 10,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }
}
