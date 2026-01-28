import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String name;
  final String description;
  final String ownerId; // ID of user who created the group
  final List<String> deviceIds; // Devices in the group
  final Timestamp createdAt;
  bool isActive; // admin control

  GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.deviceIds,
    required this.createdAt,
    required this.isActive,
  });

  /// 🔥 Create from Firestore document
  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return GroupModel.fromMap(data, doc.id);
  }

  /// 🔁 Create from Map (generic / reusable)
  factory GroupModel.fromMap(Map<String, dynamic> data, String id) {
    return GroupModel(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      ownerId: data['ownerId'] ?? '',
      deviceIds: List<String>.from(data['deviceIds'] ?? []),
      createdAt: data['createdAt'] is Timestamp
          ? data['createdAt']
          : Timestamp.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  /// 📝 Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'deviceIds': deviceIds,
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }

  /// 🔁 From Realtime Database
  factory GroupModel.fromRTDB(String id, Map data) {
    return GroupModel(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      ownerId: data['ownerId'] ?? '',
      deviceIds: data['deviceIds'] != null
          ? List<String>.from(data['deviceIds'].values)
          : [],
      createdAt: data['createdAt'] ?? 0,
      isActive: data['isActive'] ?? true,
    );
  }
}
