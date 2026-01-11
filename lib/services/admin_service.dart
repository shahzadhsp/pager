import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

// --- Modelos de Dados ---

class AdminUser {
  final String id;
  final String name;
  final String email;
  final DateTime registrationDate;
  final List<String> deviceIds;
  bool isActive;

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.registrationDate,
    required this.deviceIds,
    this.isActive = true,
  });
}

class AdminDevice {
  final String id;
  final String macAddress;
  final String ownerId;
  final String ownerName;
  final LatLng location;
  final DateTime addedDate;
  DateTime lastUplink;
  bool isOnline;
  String lastHeardByGatewayId;

  AdminDevice({
    required this.id,
    required this.macAddress,
    required this.ownerId,
    required this.ownerName,
    required this.location,
    required this.addedDate,
    required this.lastUplink,
    required this.lastHeardByGatewayId,
    this.isOnline = false,
  });
}

class AdminGateway {
  final String id;
  final String name;
  final LatLng location;
  bool isOnline;
  DateTime lastSeen;

  AdminGateway({
    required this.id,
    required this.name,
    required this.location,
    required this.lastSeen,
    this.isOnline = false,
  });
}

class AdminUplink {
  final String id;
  final String deviceId;
  final String gatewayId;
  final DateTime timestamp;
  final Map<String, dynamic> payload;
  final int rssi;

  AdminUplink({
    required this.id,
    required this.deviceId,
    required this.gatewayId,
    required this.timestamp,
    required this.payload,
    required this.rssi,
  });
}

class AdminGroup {
  final String id;
  String name;
  final List<String> memberIds;
  final List<String> deviceIds;

  AdminGroup({
    required this.id,
    required this.name,
    required this.memberIds,
    required this.deviceIds,
  });
}

// --- Tipos de Retorno para Relatórios ---

typedef GrowthData = ({List<int> userCounts, List<int> deviceCounts});
// typedef MostActiveDevice = (AdminDevice? device, int uplinkCount);
typedef MostActiveDevice = (AdminDevice? device, int uplinkCount);

// --- Serviço de Administração ---

class AdminService with ChangeNotifier {
  List<AdminUser> _users = [];
  List<AdminGateway> _gateways = [];
  List<AdminDevice> _devices = [];
  List<AdminUplink> _uplinks = [];
  List<AdminGroup> _groups = [];

  bool _isInitialized = false;

  // --- Getters Públicos ---

  List<AdminUser> get users => _users;
  List<AdminGateway> get gateways => _gateways;
  List<AdminDevice> get devices => _devices;
  List<AdminUplink> get uplinks => _uplinks;
  List<AdminGroup> get groups => _groups;
  int get totalUsers => _users.length;
  int get totalDevices => _devices.length;
  int get totalGateways => _gateways.length;
  int get totalGroups => _groups.length;

  int get activeDevices24h {
    final now = DateTime.now();
    return _devices
        .where((d) => now.difference(d.lastUplink).inHours < 24)
        .length;
  }

  int get uplinksToday {
    final today = DateTime.now();
    return _uplinks
        .where(
          (u) =>
              u.timestamp.year == today.year &&
              u.timestamp.month == today.month &&
              u.timestamp.day == today.day,
        )
        .length;
  }

  AdminService() {
    _initializeData();
  }

  // Método auxiliar para encontrar nomes
  String getNameForId(String id) {
    final user = _users.firstWhereOrNull((u) => u.id == id);
    if (user != null) return user.name;

    final device = _devices.firstWhereOrNull((d) => d.id == id);
    if (device != null) {
      return 'Dispositivo ${device.id.split('_').last}'; // e.g., 'Dispositivo 12'
    }

    return 'Desconhecido';
  }

  String _generateMacAddress(Random random) {
    return List<String>.generate(6, (index) {
      return random
          .nextInt(256)
          .toRadixString(16)
          .padLeft(2, '0')
          .toUpperCase();
    }).join(':');
  }

  void _initializeData() {
    if (_isInitialized) return;

    final random = Random();
    final lisbonCenter = LatLng(38.7223, -9.1393);

    // Gerar Gateways
    final List<AdminGateway> generatedGateways = [];
    for (int i = 1; i <= 5; i++) {
      final gatewayLocation = LatLng(
        lisbonCenter.latitude + (random.nextDouble() - 0.5) * 0.1,
        lisbonCenter.longitude + (random.nextDouble() - 0.5) * 0.1,
      );
      final lastSeenTime = DateTime.now().subtract(
        Duration(minutes: random.nextInt(60)),
      );
      generatedGateways.add(
        AdminGateway(
          id: 'gw_$i',
          name: 'Gateway $i - Lisboa',
          location: gatewayLocation,
          lastSeen: lastSeenTime,
          isOnline: DateTime.now().difference(lastSeenTime).inMinutes < 10,
        ),
      );
    }
    _gateways = generatedGateways;

    // Gerar Utilizadores
    final List<AdminUser> generatedUsers = [];
    for (int i = 1; i <= 50; i++) {
      generatedUsers.add(
        AdminUser(
          id: 'user_$i',
          name: 'Utilizador $i',
          email: 'user$i@exemplo.com',
          registrationDate: DateTime.now().subtract(
            Duration(days: random.nextInt(365)),
          ),
          deviceIds: [],
          isActive: random.nextBool(),
        ),
      );
    }
    _users = generatedUsers;

    // Gerar Dispositivos
    final List<AdminDevice> generatedDevices = [];
    int deviceCount = 1;
    for (final user in _users) {
      final deviceQty = random.nextInt(5) + 1;
      for (int j = 0; j < deviceQty; j++) {
        final deviceLocation = LatLng(
          lisbonCenter.latitude + (random.nextDouble() - 0.5) * 0.2,
          lisbonCenter.longitude + (random.nextDouble() - 0.5) * 0.2,
        );
        final lastUplinkTime = DateTime.now().subtract(
          Duration(hours: random.nextInt(72)),
        );
        final hearingGateway = _gateways[random.nextInt(_gateways.length)];
        final device = AdminDevice(
          id: 'dev_${deviceCount++}',
          macAddress: _generateMacAddress(random),
          ownerId: user.id,
          ownerName: user.name,
          location: deviceLocation,
          addedDate: user.registrationDate.add(
            Duration(days: random.nextInt(10)),
          ),
          lastUplink: lastUplinkTime,
          isOnline: DateTime.now().difference(lastUplinkTime).inMinutes < 15,
          lastHeardByGatewayId: hearingGateway.id,
        );
        generatedDevices.add(device);
        user.deviceIds.add(device.id);
      }
    }
    _devices = generatedDevices;

    // Gerar Uplinks
    final List<AdminUplink> generatedUplinks = [];
    int uplinkCount = 1;
    for (final device in _devices) {
      final uplinkQty = random.nextInt(100) + 20;
      for (int k = 0; k < uplinkQty; k++) {
        generatedUplinks.add(
          AdminUplink(
            id: 'up_${uplinkCount++}',
            deviceId: device.id,
            gatewayId: device.lastHeardByGatewayId,
            timestamp: device.lastUplink.subtract(Duration(minutes: k * 30)),
            payload: {
              'temp': 15 + random.nextDouble() * 10,
              'humidity': 40 + random.nextDouble() * 20,
            },
            rssi: -120 + random.nextInt(60),
          ),
        );
      }
    }
    _uplinks = generatedUplinks;

    // Gerar Grupos
    final List<AdminGroup> generatedGroups = [];
    for (int i = 1; i <= 5; i++) {
      final groupUserIds = (_users.sample(
        random.nextInt(10) + 2,
      )).map((u) => u.id).toList();
      final groupDeviceIds = groupUserIds
          .expand(
            (userId) => _users.firstWhere((u) => u.id == userId).deviceIds,
          )
          .toList()
          .sample(random.nextInt(5) + 1);
      generatedGroups.add(
        AdminGroup(
          id: 'group_$i',
          name: 'Grupo de Teste $i',
          memberIds: groupUserIds,
          deviceIds: groupDeviceIds,
        ),
      );
    }
    _groups = generatedGroups;

    _isInitialized = true;
    if (kDebugMode) {
      print(
        'AdminService Inicializado: ${_users.length} utilizadores, ${_gateways.length} gateways, ${_devices.length} dispositivos, ${_uplinks.length} uplinks, ${_groups.length} grupos.',
      );
    }
  }

  // --- Lógica de Negócio e CRUD ---

  void updateUserStatus(String userId, bool isActive) {
    final user = _users.firstWhere((u) => u.id == userId);
    user.isActive = isActive;
    notifyListeners();
  }

  // --- Gestão de Grupos ---

  void createGroup(String name) {
    final newGroup = AdminGroup(
      id: 'group_${_groups.length + 1}',
      name: name,
      memberIds: [],
      deviceIds: [],
    );
    _groups.add(newGroup);
    notifyListeners();
  }

  void deleteGroup(String groupId) {
    _groups.removeWhere((g) => g.id == groupId);
    notifyListeners();
  }

  void inviteUserToGroup(String groupId, String userId) {
    final group = _groups.firstWhere((g) => g.id == groupId);
    if (!group.memberIds.contains(userId)) {
      // Simula o envio do comando para o dispositivo do utilizador.
      if (kDebugMode) {
        print(
          'SIMULANDO COMANDO: Enviando "INVITE:${group.id}:${group.name}" para os dispositivos do utilizador $userId',
        );
      }
      // Aqui, na vida real, você enviaria um downlink/notificação.
      // Para o demo, adicionamos diretamente.
      group.memberIds.add(userId);
      notifyListeners();
    }
  }

  void removeUserFromGroup(String groupId, String userId) {
    final group = _groups.firstWhere((g) => g.id == groupId);
    if (group.memberIds.remove(userId)) {
      notifyListeners();
    }
  }

  void addDeviceToGroup(String groupId, String deviceId) {
    final group = _groups.firstWhere((g) => g.id == groupId);
    if (!group.deviceIds.contains(deviceId)) {
      group.deviceIds.add(deviceId);
      notifyListeners();
    }
  }

  void removeDeviceFromGroup(String groupId, String deviceId) {
    final group = _groups.firstWhere((g) => g.id == groupId);
    if (group.deviceIds.remove(deviceId)) {
      notifyListeners();
    }
  }

  // --- Métodos para Relatórios ---

  List<AdminDevice> getInactiveDevices({int inactiveForDays = 7}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: inactiveForDays));
    return _devices.where((d) => d.lastUplink.isBefore(cutoffDate)).toList();
  }

  Map<int, int> getHourlyUplinkVolume({int hours = 24}) {
    final now = DateTime.now();
    final Map<int, int> volumeByHour = {
      for (var i = 0; i < hours; i++) now.subtract(Duration(hours: i)).hour: 0,
    };

    for (final uplink in _uplinks) {
      final timeDifference = now.difference(uplink.timestamp);
      if (timeDifference.inHours < hours) {
        final hour = uplink.timestamp.hour;
        if (volumeByHour.containsKey(hour)) {
          volumeByHour[hour] = volumeByHour[hour]! + 1;
        }
      }
    }
    return volumeByHour;
  }

  int getUplinksLastWeek() {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
    return _uplinks.where((u) => u.timestamp.isAfter(cutoffDate)).length;
  }

  MostActiveDevice getMostActiveDevice() {
    if (_uplinks.isEmpty) return (null, 0);
    final uplinkCounts = groupBy(_uplinks, (uplink) => uplink.deviceId);
    final sortedCounts = uplinkCounts.entries.sorted(
      (a, b) => b.value.length.compareTo(a.value.length),
    );
    final mostActiveId = sortedCounts.first.key;
    final device = _devices.firstWhere((d) => d.id == mostActiveId);
    return (device, sortedCounts.first.value.length);
  }

  GrowthData getNetworkGrowthLast30Days() {
    final now = DateTime.now();
    final userCounts = <int>[];
    final deviceCounts = <int>[];

    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final usersOnDate = _users
          .where((u) => u.registrationDate.isBefore(date))
          .length;
      final devicesOnDate = _devices
          .where((d) => d.addedDate.isBefore(date))
          .length;
      userCounts.add(usersOnDate);
      deviceCounts.add(devicesOnDate);
    }
    return (userCounts: userCounts, deviceCounts: deviceCounts);
  }

  Map<int, int> getNewUsersByWeek() {
    final now = DateTime.now();
    final Map<int, int> usersByWeek = {
      for (var i = 0; i < 8; i++) i: 0,
    }; // 8 semanas atrás

    for (final user in _users) {
      final weeksAgo = now.difference(user.registrationDate).inDays ~/ 7;
      if (weeksAgo < 8) {
        usersByWeek[weeksAgo] = (usersByWeek[weeksAgo] ?? 0) + 1;
      }
    }
    return usersByWeek;
  }

  List<AdminUser> getRecentlyRegisteredUsers({int count = 5}) {
    final sortedUsers = _users.sorted(
      (a, b) => b.registrationDate.compareTo(a.registrationDate),
    );
    return sortedUsers.take(count).toList();
  }

  Map<String, int> getDeviceDistributionPerUser() {
    return {for (var user in _users) user.name: user.deviceIds.length};
  }

  Map<String, int> getUplinksByGateway() {
    final gatewayMap = {for (var gw in _gateways) gw.id: gw.name};
    final Map<String, int> counts = {};
    for (final uplink in _uplinks) {
      final gwName = gatewayMap[uplink.gatewayId] ?? 'Desconhecido';
      counts[gwName] = (counts[gwName] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, double> getAverageRssiPerGateway() {
    final gatewayMap = {for (var gw in _gateways) gw.id: gw.name};
    final Map<String, List<int>> rssiLists = {};
    for (final uplink in _uplinks) {
      final gwName = gatewayMap[uplink.gatewayId] ?? 'Desconhecido';
      (rssiLists[gwName] ??= []).add(uplink.rssi);
    }

    return rssiLists.map((key, value) {
      final avg = value.reduce((a, b) => a + b) / value.length;
      return MapEntry(key, avg);
    });
  }
}
