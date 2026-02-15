import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:developer' as developer;
import '../models/conversation_model.dart';
import '../models/chat_message_model.dart';
import '../services/admin_service.dart';
import 'user_provider.dart';
import 'settings_provider.dart';

class ChatProvider with ChangeNotifier {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final UserProvider _userProvider;
  final SettingsProvider _settingsProvider;
  final AdminService _adminService;

  User? _currentUser;

  final Map<String, ConversationModel> _conversationsMap = {};
  final Map<String, StreamSubscription> _conversationSubscriptions = {};
  final Map<String, StreamSubscription> _deviceStatusSubscriptions = {};

  StreamSubscription? _userChatsSubscription;
  StreamSubscription? _groupsSubscription;

  bool _isLoading = true;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  List<ConversationModel> get conversations => _conversationsMap.values.toList()
    ..sort((a, b) => b.lastMessageTimestamp.compareTo(a.lastMessageTimestamp));

  ChatProvider(this._userProvider, this._settingsProvider, this._adminService) {
    _initialize();
  }

  ConversationModel? getConversationById(String conversationId) {
    return _conversationsMap[conversationId];
  }
  /* ================= INITIALIZE ================= */

  void _initialize() {
    FirebaseAuth.instance.userChanges().listen((user) {
      _cancelAllSubscriptions();

      if (user == null) {
        _currentUser = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      _currentUser = user;
      _isLoading = true;
      notifyListeners();

      _listenForUserChats();
      _listenForGroups();
    });
  }

  /* ================= GROUPS ================= */
  Future<void> updateGroupName(String groupId, String newName) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await _dbRef.child('groups/$groupId').update({
      'name': newName,
      'updatedBy': uid,
      'updatedAt': ServerValue.timestamp,
    });
  }

  /* ================= USER CHATS ================= */

  void _listenForUserChats() {
    if (_currentUser == null) return;

    final ref = _dbRef.child('user_chats/${_currentUser!.uid}');
    _userChatsSubscription = ref.onValue.listen((event) {
      if (!event.snapshot.exists) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);

      for (final entry in data.entries) {
        final chatId = entry.key;
        final chatData = Map<String, dynamic>.from(entry.value);

        final isGroup = chatData['isGroup'] == true;

        final existing = _conversationsMap[chatId];

        // 🔥 GROUP → name overwrite mat karo
        if (isGroup && existing != null) {
          _conversationsMap[chatId] = existing.copyWith(
            unreadCount: chatData['unreadCount'] ?? existing.unreadCount,
          );
          continue;
        }

        final conversation = ConversationModel.fromFirebase(chatId, chatData);

        if (!_conversationsMap.containsKey(chatId)) {
          _listenForLastMessage(chatId);
          if (!conversation.isGroup) {
            _listenForDeviceStatus(chatId);
          }
        }

        _conversationsMap[chatId] = conversation;
      }

      _isLoading = false;
      notifyListeners();
    });
  }

  void _listenForGroups() {
    if (_currentUser == null) return;

    final ref = _dbRef.child('groups');

    _groupsSubscription?.cancel();
    _groupsSubscription = ref.onValue.listen(
      (event) {
        if (!event.snapshot.exists) {
          _isLoading = false;
          notifyListeners();
          return;
        }

        final data = Map<String, dynamic>.from(event.snapshot.value as Map);

        for (final entry in data.entries) {
          final groupId = entry.key;
          final groupData = Map<String, dynamic>.from(entry.value);

          final members = groupData['members'] as Map<dynamic, dynamic>?;

          // ❌ Skip if user is not member
          if (members == null || !members.containsKey(_currentUser!.uid)) {
            continue;
          }

          final existing = _conversationsMap[groupId];

          // ✅ Preserve existing conversation & update name safely
          _conversationsMap[groupId] = existing != null
              ? existing.copyWith(
                  name: groupData['name'] ?? existing.name,
                  isGroup: true,
                )
              : ConversationModel(
                  id: groupId,
                  name: groupData['name'] ?? '',
                  isGroup: true,
                  lastMessage: '',
                  lastMessageTimestamp: 0,
                  unreadCount: 0,
                );

          // ✅ Listen for last message ONLY once
          if (!_conversationSubscriptions.containsKey(groupId)) {
            _listenForLastMessage(groupId);
          }
        }

        _isLoading = false;
        notifyListeners();
      },
      onError: (e, s) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /* ================= LAST MESSAGE ================= */

  void _listenForLastMessage(String chatId) {
    final ref = _dbRef
        .child('chats/$chatId/messages')
        .orderByChild('timestamp')
        .limitToLast(1);

    _conversationSubscriptions[chatId]?.cancel();

    _conversationSubscriptions[chatId] = ref.onValue.listen((event) {
      if (!event.snapshot.exists || !_conversationsMap.containsKey(chatId))
        return;

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final last = data.entries.first;
      final msg = Map<String, dynamic>.from(last.value);

      _conversationsMap[chatId] = _conversationsMap[chatId]!.copyWith(
        lastMessage: msg['text'] ?? '',
        lastMessageTimestamp: msg['timestamp'] ?? 0,
        lastMessageSenderId: msg['senderId'],
        lastMessageStatus: msg['senderId'] == _currentUser?.uid
            ? msg['status']
            : '',
      );

      notifyListeners();
    });
  }

  /* ================= DEVICE STATUS ================= */

  void _listenForDeviceStatus(String deviceId) {
    final ref = _dbRef.child('last_seen/$deviceId');
    _deviceStatusSubscriptions[deviceId]?.cancel();
    _deviceStatusSubscriptions[deviceId] = ref.onValue.listen((_) {});
  }

  /* ================= MESSAGES ================= */

  Stream<List<ChatMessageModel>> getMessagesStream(String conversationId) {
    final ref = _dbRef
        .child('chats/$conversationId/messages')
        .orderByChild('timestamp');

    return ref.onValue.map((event) {
      if (!event.snapshot.exists) return [];

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);

      final messages =
          data.entries
              .map(
                (e) => ChatMessageModel.fromJson(
                  e.key,
                  Map<String, dynamic>.from(e.value),
                ),
              )
              // 🔥 THIS LINE IS THE KEY
              .where((m) => m.isDeleted != true)
              .toList()
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      return messages;
    });
  }

  /* ================= SEND MESSAGE ================= */

  Future<void> sendMessage(String conversationId, String text) async {
    if (_currentUser == null || text.trim().isEmpty) return;

    final conversation = _conversationsMap[conversationId];
    final isGroup = conversation?.isGroup ?? false;

    final msgRef = _dbRef.child('chats/$conversationId/messages').push();

    await msgRef.set({
      'senderId': _currentUser!.uid,
      'text': text.trim(),
      'timestamp': ServerValue.timestamp,
      'status': 'sent',
    });

    if (!isGroup) return;

    final membersRef = _dbRef.child('groups/$conversationId/members');
    final snapshot = await membersRef.get();

    if (!snapshot.exists) return;

    final members = Map<String, dynamic>.from(snapshot.value as Map);

    for (final uid in members.keys) {
      if (uid == _currentUser!.uid) continue;
      _dbRef
          .child('user_chats/$uid/$conversationId/unreadCount')
          .set(ServerValue.increment(1));
    }
  }

  /* ================= CLEANUP ================= */

  void _cancelAllSubscriptions() {
    _userChatsSubscription?.cancel();
    _groupsSubscription?.cancel();

    for (final sub in _conversationSubscriptions.values) {
      sub.cancel();
    }

    for (final sub in _deviceStatusSubscriptions.values) {
      sub.cancel();
    }

    _conversationSubscriptions.clear();
    _deviceStatusSubscriptions.clear();
    _conversationsMap.clear();
  }

  @override
  void dispose() {
    _cancelAllSubscriptions();
    super.dispose();
  }

  // mark conversation as read function can be added here if needed
  Future<void> markConversationAsRead(String conversationId) async {
    if (_currentUser == null) return;

    try {
      // 1️⃣ Reset unread count for current user
      final unreadRef = _dbRef.child(
        'user_chats/${_currentUser!.uid}/$conversationId/unreadCount',
      );
      await unreadRef.set(0);

      // 2️⃣ Mark messages as read (optional – only if read receipts enabled)
      if (!_settingsProvider.readReceiptsEnabled) return;

      final messagesRef = _dbRef.child('chats/$conversationId/messages');
      final snapshot = await messagesRef.get();

      if (!snapshot.exists) return;

      final messages = Map<String, dynamic>.from(snapshot.value as Map);
      final Map<String, dynamic> updates = {};

      for (final entry in messages.entries) {
        final messageId = entry.key;
        final data = Map<String, dynamic>.from(entry.value);

        if (data['senderId'] != _currentUser!.uid && data['status'] != 'read') {
          updates['/chats/$conversationId/messages/$messageId/status'] = 'read';
        }
      }

      if (updates.isNotEmpty) {
        await _dbRef.update(updates);
      }
    } catch (e, s) {
      developer.log(
        'markConversationAsRead failed',
        name: 'chat.provider',
        error: e,
        stackTrace: s,
      );
    }
  }

  // conversation with device
  Future<void> createConversationWithDevice(
    String deviceId, {
    String? deviceName,
  }) async {
    if (_currentUser == null) {
      throw Exception('User not authenticated');
    }

    final name = deviceName ?? deviceId;

    try {
      // 1️⃣ Create chat entry for current user
      final userChatRef = _dbRef.child(
        'user_chats/${_currentUser!.uid}/$deviceId',
      );

      await userChatRef.set({
        'name': name,
        'isGroup': false,
        'createdAt': ServerValue.timestamp,
        'unreadCount': 0,
      });

      // 2️⃣ Register chat members (user + device)
      final membersRef = _dbRef.child('chat_members/$deviceId');
      await membersRef.update({_currentUser!.uid: true, deviceId: true});
    } catch (e, s) {
      developer.log(
        'createConversationWithDevice failed',
        name: 'chat.provider',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  // edit message
  Future<void> editMessage({
    required String conversationId,
    required String messageId,
    required String newText,
  }) async {
    if (_currentUser == null || newText.trim().isEmpty) return;

    final msgRef = _dbRef.child('chats/$conversationId/messages/$messageId');

    await msgRef.update({
      'text': newText.trim(),
      'editedAt': ServerValue.timestamp,
    });
  }

  // delete message
  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
  }) async {
    if (_currentUser == null) return;

    final msgRef = _dbRef.child('chats/$conversationId/messages/$messageId');

    await msgRef.update({'isDeleted': true});
  }
  /* ================= Delete Groups ================= */

  Future<void> deleteGroup(String groupId) async {
    if (_currentUser == null) return;

    try {
      final groupRef = _dbRef.child('groups/$groupId');
      final groupSnap = await groupRef.get();

      if (!groupSnap.exists) return;

      final groupData = Map<String, dynamic>.from(groupSnap.value as Map);
      final members = Map<String, dynamic>.from(groupData['members'] ?? {});

      final Map<String, dynamic> updates = {};

      // 1️⃣ Remove group from each user's chat list
      for (final uid in members.keys) {
        updates['/user_chats/$uid/$groupId'] = null;
      }

      // 2️⃣ Remove group data
      updates['/groups/$groupId'] = null;

      // 3️⃣ Remove messages
      updates['/chats/$groupId'] = null;

      // 🔥 Atomic delete
      await _dbRef.update(updates);

      // 4️⃣ Remove locally
      _conversationsMap.remove(groupId);

      notifyListeners();
    } catch (e, s) {
      developer.log(
        'deleteGroup failed',
        name: 'chat.provider',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  // delete conversation
  Future<void> deleteConversation(String conversationId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseDatabase.instance
        .ref('user_chats/$uid/$conversationId')
        .remove();
  }
}
