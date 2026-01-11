import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:developer' as developer;

import '../models/device_status_model.dart';

class DeviceProvider with ChangeNotifier {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  User? _currentUser;

  List<String> _deviceIds = [];
  final Map<String, DeviceStatusModel> _deviceStatusMap = {};
  final Map<String, StreamSubscription> _statusSubscriptions = {};

  bool _isLoading = false;
  String? _error;

  List<String> get deviceIds => _deviceIds;
  Map<String, DeviceStatusModel> get deviceStatusMap => _deviceStatusMap;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasDevices => _deviceIds.isNotEmpty;

  DeviceProvider() {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      fetchUserDevices();
    } else {
      FirebaseAuth.instance.userChanges().listen((user) {
        if (user != null && _currentUser?.uid != user.uid) {
          _currentUser = user;
          fetchUserDevices();
        } else if (user == null) {
          _clearData();
        }
      });
    }
  }

  Future<void> fetchUserDevices() async {
    if (_currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final userDevicesSnapshot = await _dbRef.child('users/${_currentUser!.uid}/devices').get();
      if (userDevicesSnapshot.exists && userDevicesSnapshot.value != null) {
        final data = userDevicesSnapshot.value as Map<dynamic, dynamic>;
        _deviceIds = data.keys.cast<String>().toList();
        await _listenToDeviceStatuses();
      } else {
        _deviceIds = [];
      }
      _error = null;
    } catch (e) {
      _error = "Erro ao buscar dispositivos: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _listenToDeviceStatuses() async {
    for (var sub in _statusSubscriptions.values) {
      sub.cancel();
    }
    _statusSubscriptions.clear();

    List<Future> initialFetches = [];

    for (final deviceId in _deviceIds) {
        final initialFetch = _dbRef.child('device_status/$deviceId').get().then((snapshot) {
            if(snapshot.exists && snapshot.value != null) {
                 final status = DeviceStatusModel.fromFirebase(deviceId, snapshot.value as Map<dynamic, dynamic>);
                 _deviceStatusMap[deviceId] = status;
            }
        });
        initialFetches.add(initialFetch);

      final sub = _dbRef.child('device_status/$deviceId').onValue.listen((event) {
        if (event.snapshot.exists && event.snapshot.value != null) {
          final status = DeviceStatusModel.fromFirebase(deviceId, event.snapshot.value as Map<dynamic, dynamic>);
          _deviceStatusMap[deviceId] = status;
          notifyListeners();
        }
      });
      _statusSubscriptions[deviceId] = sub;
    }

    await Future.wait(initialFetches);
  }

  Future<String> sendCommand(String deviceId, String command) async {
    final ref = _dbRef.child('downlink_commands').push();
    try {
      await ref.set({
        'to_mac': deviceId,
        'command': command,
        'timestamp': ServerValue.timestamp,
      });
      return "Comando '$command' enviado com sucesso!";
    } catch (e) {
      return "Erro ao enviar comando: $e";
    }
  }

  Future<void> setDeviceNickname(String deviceId, String nickname) async {
    try {
      await _dbRef.child('device_status/$deviceId/nickname').set(nickname.isNotEmpty ? nickname : null);
    } catch (e, s) {
      developer.log("Erro ao definir apelido: $e", name: 'device.provider', error: e, stackTrace: s);
    }
  }

  void _clearData() {
    _deviceIds = [];
    _deviceStatusMap.clear();
    for (var sub in _statusSubscriptions.values) {
      sub.cancel();
    }
    _statusSubscriptions.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _clearData();
    super.dispose();
  }
}
