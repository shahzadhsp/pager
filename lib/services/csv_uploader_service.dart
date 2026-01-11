import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:myapp/models/device_model.dart';
import 'dart:developer' as developer;

class CsvUploaderService {
  Future<List<Device>?> pickAndParseCsv() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null || result.files.single.bytes == null) {
      return null; 
    }

    final Uint8List fileBytes = result.files.single.bytes!;
    final String content = String.fromCharCodes(fileBytes);
    final List<String> lines = content
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    if (lines.length <= 1) {
      return [];
    }

    final List<Device> importedDevices = [];
    final header = lines.first.split(',').map((h) => h.trim()).toList();
    final idIndex = header.indexOf('id');
    final nameIndex = header.indexOf('name');
    final macIndex = header.indexOf('mac'); // Adicionado

    if (idIndex == -1 || nameIndex == -1 || macIndex == -1) { // Verificação adicionada
      developer.log('Invalid CSV header. Must contain id, name, and mac.', name: 'csv.uploader');
      return [];
    }

    for (int i = 1; i < lines.length; i++) {
      final values = lines[i].split(',').map((v) => v.trim()).toList();
      if (values.length == header.length) {
        try {
          final device = Device(
            id: values[idIndex],
            name: values[nameIndex],
            originalMac: values[macIndex], // Corrigido
            isOnline: false,
            batteryLevel: 0.0,
            lastActivity: 'N/A',
          );
          importedDevices.add(device);
        } catch (e, s) {
          if (kDebugMode) {
            developer.log('Skipping row: ${lines[i]}', name: 'csv.uploader', error: e, stackTrace: s);
          }
        }
      }
    }

    return importedDevices;
  }
}
