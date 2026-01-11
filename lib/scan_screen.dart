import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController controller = MobileScannerController();
  final _storage = const FlutterSecureStorage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('scan'.tr())),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          _onDetect(capture, context);
        },
      ),
    );
  }

  void _onDetect(BarcodeCapture capture, BuildContext context) async {
    if (!mounted) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? rawValue = barcodes.first.rawValue;
      if (rawValue != null) {
        try {
          final data = jsonDecode(rawValue);
          final String? devEUI = data['devEUI'];
          final String? appEUI = data['appEUI'];
          final String? appKey = data['appKey'];

          if (devEUI != null && appEUI != null && appKey != null) {
            controller.stop();

            await _storage.write(key: 'devEUI_$devEUI', value: devEUI);
            await _storage.write(key: 'appEUI_$devEUI', value: appEUI);
            await _storage.write(key: 'appKey_$devEUI', value: appKey);

            if (mounted) {
              // Use a local variable to avoid using context across an async gap.
              final goRouter = GoRouter.of(context);
              goRouter.go('/device/$devEUI');
            }
          } else {
            _showErrorDialog('invalid'.tr(), 'missingDeviceData'.tr());
          }
        } catch (e) {
          _showErrorDialog('error'.tr(), 'dataFormatInvalid'.tr());
        }
      }
    }
  }

  void _showErrorDialog(String title, String content) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.start();
            },
            child: Text('ok'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
