import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

import '../models/group_model.dart';

class GroupProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<GroupModel> _groups = [];
  bool _isLoading = false;

  List<GroupModel> get groups => _groups;
  bool get isLoading => _isLoading;

  GroupProvider() {
    fetchGroups();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> fetchGroups() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _setLoading(true);
    try {
      final snapshot = await _firestore
          .collection('groups')
          .where('ownerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      _groups = snapshot.docs.map((doc) => GroupModel.fromFirestore(doc)).toList();
    } catch (e, s) {
      developer.log('Erro ao carregar grupos', name: 'group.provider', error: e, stackTrace: s);
    }
    _setLoading(false);
  }

  Future<void> createGroup(String name, String description) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilizador não autenticado.');

    _setLoading(true);
    try {
      await _firestore.collection('groups').add({
        'name': name,
        'description': description,
        'ownerId': user.uid,
        'deviceIds': [],
        'createdAt': Timestamp.now(),
      });
      await fetchGroups();
    } catch (e, s) {
      developer.log('Erro ao criar grupo', name: 'group.provider', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> sendGroupInvitation(String groupId, String deviceId) async {
    try {
      final command = 'INVITE:$groupId';
      await _rtdb.ref('devices/$deviceId/command').set(command);
      developer.log('Convite enviado para o dispositivo $deviceId para o grupo $groupId', name: 'group.provider');
    } catch (e, s) {
      developer.log('Erro ao enviar convite para o grupo', name: 'group.provider', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> processGroupInvitationResponse(String deviceId, String message) async {
    if (message.startsWith('ACCEPT:')) {
      final groupId = message.substring(7);
      try {
        await _firestore.collection('groups').doc(groupId).update({
          'deviceIds': FieldValue.arrayUnion([deviceId]),
        });

        final groupIndex = _groups.indexWhere((g) => g.id == groupId);
        if (groupIndex != -1 && !_groups[groupIndex].deviceIds.contains(deviceId)) {
          _groups[groupIndex].deviceIds.add(deviceId);
          notifyListeners();
          developer.log('Dispositivo $deviceId adicionado com sucesso ao grupo $groupId', name: 'group.provider');
        }
      } catch (e, s) {
        developer.log('Erro ao processar aceitação de convite', name: 'group.provider', error: e, stackTrace: s);
      }
    } else if (message.startsWith('REJECT:')) {
      final groupId = message.substring(7);
      developer.log('Dispositivo $deviceId rejeitou o convite para o grupo $groupId', name: 'group.provider');
    }
  }

  Future<void> removeDeviceFromGroup(String groupId, String deviceId) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'deviceIds': FieldValue.arrayRemove([deviceId]),
      });
      final groupIndex = _groups.indexWhere((g) => g.id == groupId);
      if (groupIndex != -1) {
        _groups[groupIndex].deviceIds.remove(deviceId);
        notifyListeners();
      }
    } catch (e, s) {
      developer.log('Erro ao remover dispositivo do grupo', name: 'group.provider', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> deleteGroup(String groupId) async {
    try {
      await _firestore.collection('groups').doc(groupId).delete();
      _groups.removeWhere((g) => g.id == groupId);
      notifyListeners();
    } catch (e, s) {
      developer.log('Erro ao apagar grupo', name: 'group.provider', error: e, stackTrace: s);
      rethrow;
    }
  }
}
