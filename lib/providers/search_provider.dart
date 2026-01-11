import 'package:flutter/material.dart';

class SearchProvider with ChangeNotifier {
  String _query = '';

  String get query => _query;

  set query(String newQuery) {
    if (_query != newQuery) {
      _query = newQuery;
      notifyListeners();
    }
  }

  void clear() {
    _query = '';
    notifyListeners();
  }
}
