import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String name;
  final String description;
  final String ownerId; // ID do utilizador que criou o grupo
  final List<String> deviceIds; // Lista de IDs dos dispositivos no grupo
  final Timestamp createdAt;

  GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.deviceIds,
    required this.createdAt,
  });

  // Fábrica para criar uma instância a partir de um DocumentSnapshot do Firestore
  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return GroupModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      ownerId: data['ownerId'] ?? '',
      // Garante que a lista é sempre do tipo correto
      deviceIds: List<String>.from(data['deviceIds'] ?? []),
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  // Método para converter uma instância para um mapa, útil para escrever no Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'deviceIds': deviceIds,
      'createdAt': createdAt,
    };
  }
}
