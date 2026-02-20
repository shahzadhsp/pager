import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OneToOneChatProvider extends ChangeNotifier {
  final DatabaseReference db = FirebaseDatabase.instance.ref();
  String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  bool isLoading = true;
  List<Map> conversations = [];

  OneToOneChatProvider() {
    _listenConversations();
  }

  /// Listen all conversations of current user in real-time
  void _listenConversations() {
    db.child('conversation').onValue.listen((event) {
      final data = event.snapshot.value;
      if (data == null) {
        conversations = [];
        isLoading = false;
        notifyListeners();
        return;
      }

      final map = Map<String, dynamic>.from(data as Map);
      final convList = map.entries
          .map((e) {
            final conv = Map<String, dynamic>.from(e.value);
            conv['id'] = e.key;
            return conv;
          })
          .where((conv) => (conv['members'] as Map).containsKey(currentUserId))
          .toList();

      convList.sort(
        (a, b) => (b['lastMessageTimestamp'] ?? 0).compareTo(
          a['lastMessageTimestamp'] ?? 0,
        ),
      );

      conversations = convList;
      isLoading = false;
      notifyListeners();
    });
  }

  /// Send a message and update conversation info
  Future<void> sendMessage({
    required String conversationId,
    required String text,
    required String otherUserId,
  }) async {
    if (text.trim().isEmpty) return;

    final messageRef = db.child('messages/$conversationId').push();
    final timestamp = ServerValue.timestamp;

    // send message to messages node
    await messageRef.set({
      "senderId": currentUserId,
      "text": text,
      "timestamp": timestamp,
    });

    // update conversation node with last message
    await db.child('conversation/$conversationId').update({
      "lastMessage": text,
      "lastMessageSenderId": currentUserId,
      "lastMessageTimestamp": timestamp,
      "members": {currentUserId: true, otherUserId: true},
    });
  }

  /// Create or get a deterministic conversation ID for one-to-one chat
  Future<String> createOrGetPrivateConversation(String otherUserId) async {
    final ids = [currentUserId, otherUserId]..sort();
    final conversationId = "${ids[0]}_${ids[1]}";

    final ref = db.child("conversation/$conversationId");
    final snapshot = await ref.get();

    if (!snapshot.exists) {
      await ref.set({
        "isGroup": false,
        "members": {currentUserId: true, otherUserId: true},
        "lastMessage": "",
        "lastMessageSenderId": "",
        "lastMessageTimestamp": 0,
        "createdAt": ServerValue.timestamp,
      });
    }

    return conversationId;
  }

  /// DELETE MESSAGE
  Future<void> deleteMessage(String conversationId, String messageKey) async {
    await db.child('messages/$conversationId/$messageKey').remove();
  }

  /// EDIT MESSAGE
  Future<void> editMessage(
    String conversationId,
    String messageKey,
    String newText,
  ) async {
    await db.child('messages/$conversationId/$messageKey').update({
      "text": newText,
      "edited": true,
    });
  }

  /// DELETE WHOLE CONVERSATION
  Future<void> deleteConversation(String conversationId) async {
    try {
      /// delete all messages
      await db.child('messages/$conversationId').remove();

      /// delete conversation node
      await db.child('conversation/$conversationId').remove();
    } catch (e) {
      debugPrint("Delete Conversation Error: $e");
    }
  }
}
