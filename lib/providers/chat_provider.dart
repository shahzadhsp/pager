// import 'dart:async';
// import 'package:flutter/foundation.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'dart:developer' as developer;
// import '../models/conversation_model.dart';
// import '../models/chat_message_model.dart';
// import '../services/admin_service.dart';
// import 'user_provider.dart';
// import 'settings_provider.dart';

// class ChatProvider with ChangeNotifier {
//   final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
//   final UserProvider _userProvider;
//   final SettingsProvider _settingsProvider;
//   final AdminService _adminService;
//   User? _currentUser;

//   Map<String, ConversationModel> _conversationsMap = {};
//   Map<String, StreamSubscription> _conversationSubscriptions = {};
//   Map<String, StreamSubscription> _deviceStatusSubscriptions = {};
//   StreamSubscription? _userChatsSubscription;

//   bool _isLoading = true;
//   String? _error;

//   List<ConversationModel> get conversations => _conversationsMap.values.toList()
//     ..sort((a, b) => b.lastMessageTimestamp.compareTo(a.lastMessageTimestamp));
//   bool get isLoading => _isLoading;
//   String? get error => _error;

//   ChatProvider(this._userProvider, this._settingsProvider, this._adminService) {
//     _initialize();
//   }

//   void _initialize() {
//     FirebaseAuth.instance.userChanges().listen((user) {
//       _cancelAllSubscriptions();
//       if (user != null) {
//         _currentUser = user;
//         _listenForUserChats();
//       } else {
//         _currentUser = null;
//         _isLoading = false;
//         _conversationsMap = {};
//         notifyListeners();
//       }
//     });
//   }

//   ConversationModel? getConversationById(String id) => _conversationsMap[id];

//   void _listenForUserChats() {
//     if (_currentUser == null) return;
//     _isLoading = true;
//     notifyListeners();
//     final userChatsRef = _dbRef.child('user_chats/${_currentUser!.uid}');

//     _userChatsSubscription = userChatsRef.onValue.listen(
//       (event) {
//         _isLoading = false;
//         if (!event.snapshot.exists) {
//           _conversationsMap = {};
//           notifyListeners();
//           return;
//         }

//         final chats = event.snapshot.value as Map<dynamic, dynamic>;
//         final newChatIds = chats.keys.cast<String>().toSet();

//         // Remove conversas que já não existem
//         _conversationsMap.keys
//             .where((key) => !newChatIds.contains(key))
//             .toList()
//             .forEach((chatId) {
//               _conversationSubscriptions.remove(chatId)?.cancel();
//               _deviceStatusSubscriptions.remove(chatId)?.cancel();
//               _conversationsMap.remove(chatId);
//             });

//         // Adiciona ou atualiza conversas
//         for (var chatId in newChatIds) {
//           final chatData = chats[chatId] as Map<dynamic, dynamic>;

//           // Usar o novo factory constructor do ConversationModel
//           final conversation = ConversationModel.fromFirebase(
//             chatId,
//             Map<String, dynamic>.from(chatData),
//           );

//           // Se a conversa for nova, subscreve a novas mensagens e status
//           if (!_conversationsMap.containsKey(chatId)) {
//             _listenForLastMessage(chatId);
//             // Só subscreve ao status se não for um grupo
//             if (!conversation.isGroup) {
//               _listenForDeviceStatus(chatId);
//             }
//           }

//           _conversationsMap[chatId] = conversation;
//         }
//         notifyListeners();
//       },
//       onError: (e, s) {
//         _error = "Erro ao carregar conversas: $e";
//         _isLoading = false;
//         developer.log(
//           'Erro em _listenForUserChats',
//           name: 'chat.provider',
//           error: e,
//           stackTrace: s,
//         );
//         notifyListeners();
//       },
//     );
//   }

//   void _listenForDeviceStatus(String deviceId) {
//     final statusRef = _dbRef.child('last_seen/$deviceId');
//     _deviceStatusSubscriptions[deviceId]?.cancel();
//     _deviceStatusSubscriptions[deviceId] = statusRef.onValue.listen((event) {
//       // O status é agora parte do ConversationModel, que pode vir de outro stream.
//       // Esta lógica precisa ser ajustada para não sobrescrever dados.
//     });
//   }

//   void _listenForLastMessage(String chatId) {
//     final messagesRef = _dbRef
//         .child('chats/$chatId/messages')
//         .orderByKey()
//         .limitToLast(1);

//     _conversationSubscriptions[chatId]?.cancel();

//     _conversationSubscriptions[chatId] = messagesRef.onValue.listen((event) {
//       if (!event.snapshot.exists || !_conversationsMap.containsKey(chatId))
//         return;

//       final messages = event.snapshot.value as Map<dynamic, dynamic>;
//       final lastMessageKey = messages.keys.first;
//       final Map<String, dynamic> lastMessageData = Map<String, dynamic>.from(
//         messages[lastMessageKey],
//       );

//       final updatedConversation = _conversationsMap[chatId]!.copyWith(
//         lastMessage: lastMessageData['text'] ?? '',
//         lastMessageTimestamp: (lastMessageData['timestamp'] ?? 0) as int,
//         lastMessageSenderId: lastMessageData['senderId'] ?? '',
//         lastMessageStatus: (lastMessageData['senderId'] == _currentUser?.uid)
//             ? lastMessageData['status']
//             : '',
//       );

//       _conversationsMap[chatId] = updatedConversation;
//       notifyListeners();
//     });
//   }

//   Stream<List<ChatMessageModel>> getMessagesStream(String conversationId) {
//     final messagesRef = _dbRef
//         .child('chats/$conversationId/messages')
//         .orderByChild('timestamp');
//     return messagesRef.onValue.map((event) {
//       if (!event.snapshot.exists) return <ChatMessageModel>[];
//       final messagesData = Map<String, dynamic>.from(
//         event.snapshot.value as Map,
//       );
//       final messages = messagesData.entries.map((entry) {
//         final msg = Map<String, dynamic>.from(entry.value);
//         return ChatMessageModel.fromJson(entry.key, msg);
//       }).toList();
//       messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
//       return messages;
//     });
//   }

//   Future<void> markConversationAsRead(String conversationId) async {
//     if (_currentUser == null) return;

//     final conversationRef = _dbRef.child(
//       'user_chats/${_currentUser!.uid}/$conversationId',
//     );
//     final unreadCountRef = conversationRef.child('unreadCount');

//     await unreadCountRef.set(0);

//     if (!_settingsProvider.readReceiptsEnabled) return;

//     final messagesRef = _dbRef.child('chats/$conversationId/messages');
//     try {
//       final messagesSnapshot = await messagesRef
//           .orderByChild('senderId')
//           .startAt(null)
//           .endAt(_currentUser!.uid)
//           .get();
//       if (!messagesSnapshot.exists) return;

//       final messagesData = Map<String, dynamic>.from(
//         messagesSnapshot.value as Map,
//       );
//       final Map<String, dynamic> updates = {};

//       for (var entry in messagesData.entries) {
//         final messageId = entry.key;
//         final messageData = Map<String, dynamic>.from(entry.value);

//         if (messageData['senderId'] != _currentUser!.uid &&
//             messageData['status'] != 'read') {
//           updates['/chats/$conversationId/messages/$messageId/status'] = 'read';
//         }
//       }

//       if (updates.isNotEmpty) {
//         await _dbRef.root.update(updates);
//         developer.log(
//           'Marcadas ${updates.length} mensagens como lidas em $conversationId',
//           name: 'chat.provider',
//         );
//       }
//     } catch (e, s) {
//       developer.log(
//         'Erro ao marcar mensagens como lidas',
//         name: 'chat.provider',
//         error: e,
//         stackTrace: s,
//       );
//     }
//   }

//   // LÓGICA DE ENVIO MODIFICADA
//   Future<void> sendMessage(String conversationId, String text) async {
//     if (_currentUser == null || text.trim().isEmpty) return;

//     final conversation = _conversationsMap[conversationId];
//     final bool isGroup = conversation?.isGroup ?? false;

//     try {
//       // Se for uma conversa 1-para-1 com um dispositivo
//       if (!isGroup &&
//           _adminService.devices.any((d) => d.id == conversationId)) {
//         // Lógica de Downlink para Dispositivo
//         final downlinkRef = _dbRef.child('devices/$conversationId/downlink');
//         await downlinkRef.set({
//           'from': _currentUser!.uid,
//           'to_mac': conversationId,
//           'payload': text.trim(),
//           'timestamp': ServerValue.timestamp,
//         });

//         // Também guarda a mensagem no chat para o histórico do utilizador
//         final newMessageRef = _dbRef
//             .child('chats/$conversationId/messages')
//             .push();
//         await newMessageRef.set({
//           'senderId': _currentUser!.uid,
//           'text': text.trim(),
//           'timestamp': ServerValue.timestamp,
//           'status': 'sent',
//         });
//       } else {
//         // Lógica para Conversas de Grupo ou entre Utilizadores
//         final newMessageRef = _dbRef
//             .child('chats/$conversationId/messages')
//             .push();
//         await newMessageRef.set({
//           'senderId': _currentUser!.uid,
//           'text': text.trim(),
//           'timestamp': ServerValue.timestamp,
//           'status': 'sent',
//         });

//         // Atualiza contagem de não lidas para outros membros
//         final membersRef = isGroup
//             ? _dbRef.child('groups/$conversationId/members')
//             : _dbRef.child('chat_members/$conversationId');

//         final snapshot = await membersRef.get();
//         if (snapshot.exists) {
//           final members = Map<String, dynamic>.from(snapshot.value as Map);
//           for (var memberId in members.keys) {
//             if (memberId != _currentUser!.uid) {
//               final userChatRef = _dbRef.child(
//                 'user_chats/$memberId/$conversationId/unreadCount',
//               );
//               userChatRef.set(ServerValue.increment(1));
//             }
//           }
//         }
//       }
//     } catch (e, s) {
//       developer.log(
//         "Erro ao enviar mensagem",
//         name: 'chat.provider',
//         error: e,
//         stackTrace: s,
//       );
//       rethrow;
//     }
//   }

//   Future<void> createConversationWithDevice(
//     String deviceId, {
//     String? deviceName,
//   }) async {
//     if (_currentUser == null) throw Exception("Utilizador não autenticado.");
//     final name = deviceName ?? deviceId;
//     final userChatRef = _dbRef.child(
//       'user_chats/${_currentUser!.uid}/$deviceId',
//     );
//     try {
//       await userChatRef.set({
//         'name': name,
//         'isGroup': false, // Explicitamente não é um grupo
//         'createdAt': ServerValue.timestamp,
//         'unreadCount': 0,
//       });
//       final chatMembersRef = _dbRef.child('chat_members/$deviceId');
//       await chatMembersRef.update({_currentUser!.uid: true, deviceId: true});
//     } catch (e, s) {
//       developer.log(
//         "Erro ao criar a conversa",
//         name: 'chat.provider',
//         error: e,
//         stackTrace: s,
//       );
//       rethrow;
//     }
//   }

//   void _cancelAllSubscriptions() {
//     _userChatsSubscription?.cancel();
//     _conversationSubscriptions.forEach((_, sub) => sub.cancel());
//     _deviceStatusSubscriptions.forEach((_, sub) => sub.cancel());
//     _conversationsMap = {};
//     _conversationSubscriptions = {};
//     _deviceStatusSubscriptions = {};
//   }

//   @override
//   void dispose() {
//     _cancelAllSubscriptions();
//     super.dispose();
//   }

//   ConversationModel? copyWith({
//     String? lastMessage,
//     int? lastMessageTimestamp,
//     String? lastMessageSenderId,
//     int? unreadCount,
//     String? lastMessageStatus,
//     String? status,
//   }) {
//     return null;
//   }
// }

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

      _listenForUserChats(); // 1-to-1 + device chats
      _listenForGroups(); // group chats
    });
  }

  /* ================= USER CHATS ================= */

  void _listenForUserChats() {
    if (_currentUser == null) return;

    final ref = _dbRef.child('user_chats/${_currentUser!.uid}');
    _userChatsSubscription = ref.onValue.listen(
      (event) {
        if (!event.snapshot.exists) {
          _isLoading = false;
          notifyListeners();
          return;
        }

        final data = Map<String, dynamic>.from(event.snapshot.value as Map);

        for (final entry in data.entries) {
          final chatId = entry.key;
          final chatData = Map<String, dynamic>.from(entry.value);

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
      },
      onError: (e, s) {
        _error = e.toString();
        _isLoading = false;
        developer.log('User chats error', error: e, stackTrace: s);
        notifyListeners();
      },
    );
  }

  /* ================= GROUP CHATS ================= */

  void _listenForGroups() {
    if (_currentUser == null) return;

    final ref = _dbRef.child('groups');
    _groupsSubscription = ref.onValue.listen((event) {
      if (!event.snapshot.exists) return;

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);

      for (final entry in data.entries) {
        final groupId = entry.key;
        final groupData = Map<String, dynamic>.from(entry.value);

        final members = groupData['members'] as Map<dynamic, dynamic>?;

        if (members == null || !members.containsKey(_currentUser!.uid)) {
          continue;
        }

        if (!_conversationsMap.containsKey(groupId)) {
          _listenForLastMessage(groupId);
        }

        _conversationsMap[groupId] = ConversationModel(
          id: groupId,
          name: groupData['name'] ?? '',
          isGroup: true,
          lastMessage: '',
          lastMessageTimestamp: 0,
          unreadCount: 0,
        );
      }

      _isLoading = false;
      notifyListeners();
    });
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
}
