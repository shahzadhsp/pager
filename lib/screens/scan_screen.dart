import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _isProcessing = false;

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return; // Evita processamento múltiplo do mesmo código

    final String? deviceId = capture.barcodes.first.rawValue;
    if (deviceId == null || deviceId.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('invalidOrEmpty'.tr())));
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      // O nome do dispositivo pode vir do QR code no futuro, se o formato for "id;name"
      await chatProvider.createConversationWithDevice(deviceId.trim());

      // Navega para o ecrã de chat, substituindo o ecrã de scan
      if (mounted) {
        context.replace('/chat/${deviceId.trim()}');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${'errorAddingDevice'.tr()} $e')));
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('addDevice'.tr())),
      body: Stack(
        children: [
          MobileScanner(onDetect: _handleBarcode),
          // Overlay para a área de scan e feedback
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // Indicador de processamento
          if (_isProcessing)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'newDevice'.tr(),
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
