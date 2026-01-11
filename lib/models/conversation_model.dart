class ConversationModel {
  final String id;
  final String name;
  final bool isGroup;
  final String lastMessage;
  final int lastMessageTimestamp;
  final String lastMessageSenderId;
  final int unreadCount;
  final String lastMessageStatus;

  ConversationModel({
    required this.id,
    required this.name,
    this.isGroup = false,
    this.lastMessage = '',
    this.lastMessageTimestamp = 0,
    this.lastMessageSenderId = '',
    this.unreadCount = 0,
    this.lastMessageStatus = '',
  });

  DateTime get lastMessageDateTime =>
      DateTime.fromMillisecondsSinceEpoch(lastMessageTimestamp);

  factory ConversationModel.fromFirebase(String id, Map<String, dynamic> data) {
    return ConversationModel(
      id: id,
      name: (data['name'] != null && data['name'].toString().isNotEmpty)
          ? data['name']
          : 'Unknown Conversation',
      isGroup: data['isGroup'] ?? false,
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTimestamp: data['lastMessageTimestamp'] ?? 0,
      lastMessageSenderId: data['lastMessageSenderId'] ?? '',
      unreadCount: data['unreadCount'] ?? 0,
      lastMessageStatus: data['lastMessageStatus'] ?? '',
    );
  }

  /// copyWith method (added without changing anything else)
  ConversationModel copyWith({
    String? id,
    String? name,
    bool? isGroup,
    String? lastMessage,
    int? lastMessageTimestamp,
    String? lastMessageSenderId,
    int? unreadCount,
    String? lastMessageStatus,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isGroup: isGroup ?? this.isGroup,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTimestamp: lastMessageTimestamp ?? this.lastMessageTimestamp,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessageStatus: lastMessageStatus ?? this.lastMessageStatus,
    );
  }
}
