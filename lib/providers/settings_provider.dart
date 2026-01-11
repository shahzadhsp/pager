import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  static const String _readReceiptsKey = 'read_receipts_enabled';

  bool _readReceiptsEnabled = true;
  bool _isLoading = true;

  bool get readReceiptsEnabled => _readReceiptsEnabled;
  bool get isLoading => _isLoading;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _readReceiptsEnabled = prefs.getBool(_readReceiptsKey) ?? true;
    } catch (e) {
      // Em caso de erro (por exemplo, em ambientes de teste sem SharedPreferences), use o valor padrão
      _readReceiptsEnabled = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleReadReceipts(bool value) async {
    _readReceiptsEnabled = value;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_readReceiptsKey, value);
  }
}
