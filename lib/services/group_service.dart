import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:myapp/models/user_group.dart';
import './auth_service.dart';
import './admin_service.dart';

class GroupService with ChangeNotifier {
  final AuthService _authService;
  final AdminService _adminService;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  String? get _userId => _authService.currentUser?.uid;

  GroupService(this._authService, this._adminService);

  Future<void> createGroup(String name, List<String> memberIds) async {
    final groupRef = _dbRef.child('groups').push();
    final groupId = groupRef.key!;

    final membersMap = {for (final id in memberIds) id: 'member'};

    final Map<String, dynamic> multiPathUpdates = {};

    // group node
    multiPathUpdates['/groups/$groupId'] = {
      'name': name,
      'isGroup': true,
      'members': membersMap,
      'createdAt': ServerValue.timestamp,
    };

    // user_chats for each member
    for (final uid in memberIds) {
      multiPathUpdates['/user_chats/$uid/$groupId'] = {
        'name': name,
        'isGroup': true,
        'unreadCount': 0,
        'createdAt': ServerValue.timestamp,
      };
    }

    await _dbRef.update(multiPathUpdates);
  }

  Future<Map<String, String>> getGroupMembers(String groupId) async {
    final snapshot = await _dbRef.child('groups/$groupId/members').get();

    if (!snapshot.exists || snapshot.value == null) return {};

    final raw = Map<String, dynamic>.from(snapshot.value as Map);
    final Map<String, String> result = {};

    raw.forEach((key, value) {
      if (value is String) {
        // ✅ Correct case: email : "member"
        result[key] = value;
      } else if (value is Map) {
        // ✅ Nested case: uid : { status: "member", email: "a@b.com" }
        final map = Map<String, dynamic>.from(value);
        final email = map['email']?.toString();
        final status = map['status']?.toString() ?? 'member';

        if (email != null) {
          result[email] = status;
        }
      }
    });

    return result;
  }

  Future<void> removeMemberFromGroup(String groupId, String memberId) async {
    final Map<String, dynamic> multiPathUpdates = {};
    multiPathUpdates['/groups/$groupId/members/$memberId'] = null;
    final isUser = _adminService.users.any((u) => u.id == memberId);
    if (isUser) {
      multiPathUpdates['/user_chats/$memberId/$groupId'] = null;
    }
    await _dbRef.update(multiPathUpdates);
  }

  Future<void> leaveGroup(String groupId) async {
    if (_userId == null) throw Exception("userNotAuthenticated".tr());
    await removeMemberFromGroup(groupId, _userId!);
  }

  // NOVA FUNÇÃO para adicionar membros a um grupo existente
  Future<void> addMembersToGroup(
    String groupId,
    List<String> newMemberIds,
  ) async {
    if (_userId == null) throw Exception("Utilizador não autenticado.");
    if (newMemberIds.isEmpty) return;

    // Obter o nome do grupo para adicionar aos chats dos novos utilizadores
    final groupSnapshot = await _dbRef.child('groups/$groupId/name').get();
    final groupName = groupSnapshot.value as String? ?? 'Grupo Desconhecido';

    final List<String> newUserMemberIds = [];
    final List<String> newDeviceMemberIds = [];
    final allDevices = _adminService.devices;

    for (final id in newMemberIds) {
      if (allDevices.any((d) => d.id == id)) {
        newDeviceMemberIds.add(id);
      } else {
        newUserMemberIds.add(id);
      }
    }

    final Map<String, dynamic> multiPathUpdates = {};

    for (final uid in newUserMemberIds) {
      multiPathUpdates['/groups/$groupId/members/$uid'] = 'member';
      multiPathUpdates['/user_chats/$uid/$groupId'] = {
        'name': groupName,
        'isGroup': true,
        'unreadCount': 0,
        'createdAt': ServerValue.timestamp,
      };
    }

    for (final did in newDeviceMemberIds) {
      multiPathUpdates['/groups/$groupId/members/$did'] = 'pending';
      multiPathUpdates['/devices/$did/downlink'] = {
        'from': _userId!,
        'to_mac': did,
        'payload': 'INVITE:$groupId',
        'timestamp': ServerValue.timestamp,
      };
    }

    await _dbRef.update(multiPathUpdates);
  }

  // ------------- STORAGE ------------------ //

  final List<UserGroup> _userGroups = [];
  final List<Invitation> _pendingInvitations = [];

  List<UserGroup> get userGroups => List.unmodifiable(_userGroups);
  List<Invitation> get pendingInvitations =>
      List.unmodifiable(_pendingInvitations);

  // ============ LISTEN GROUPS USER BELONGS ============== //

  void _listenUserGroups() {
    if (_userId == null) return;

    _dbRef.child('groups').onValue.listen((event) {
      _userGroups.clear();

      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);

        data.forEach((groupId, groupData) {
          final members = Map<String, dynamic>.from(groupData['members'] ?? {});
          if (members.containsKey(_userId)) {
            _userGroups.add(
              UserGroup(
                id: groupId,
                name: groupData['name'] ?? "Grupo",
                memberIds: members.keys.toList(),
                deviceIds: members.entries
                    .where((e) => e.value == 'pending')
                    .map((e) => e.key)
                    .toList(),
              ),
            );
          }
        });
      }

      notifyListeners();
    });
  }

  // ============ LISTEN FOR INVITATIONS TO USER ============= //

  void _listenPendingInvitations() {
    if (_userId == null) return;

    _dbRef.child('groups').onValue.listen((event) {
      _pendingInvitations.clear();

      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);

        data.forEach((groupId, groupData) {
          final members = Map<String, dynamic>.from(groupData['members'] ?? {});

          if (members[_userId] == 'pending') {
            _pendingInvitations.add(
              Invitation(
                groupId: groupId,
                groupName: groupData['name'] ?? "Group",
              ),
            );
          }
        });
      }

      notifyListeners();
    });
  }

  // ================= ACCEPT INVITATION ============== //

  Future<void> acceptInvitation(String groupId) async {
    if (_userId == null) return;

    await _dbRef.update({
      '/groups/$groupId/members/${_userId!}': 'member',
      '/user_chats/${_userId!}/$groupId': {
        'name': _userGroups.firstWhere((g) => g.id == groupId).name,
        'isGroup': true,
        'unreadCount': 0,
        'createdAt': ServerValue.timestamp,
      },
    });

    notifyListeners();
  }

  // ================= REJECT INVITATION ============== //

  Future<void> rejectInvitation(String groupId) async {
    if (_userId == null) return;

    await _dbRef.child('groups/$groupId/members/${_userId!}').remove();

    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
