class ChatMessageModel {
  final String messageId;
  final String senderId;
  final String text;
  final int timestamp;
  final String status;
  final bool edited;
  final bool isDeleted;

  ChatMessageModel({
    required this.messageId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.status = '',
    this.edited = false,
    this.isDeleted = false,
  });

  // MODIFICADO: O construtor de fábrica agora é mais robusto e chamado de 'fromJson'
  factory ChatMessageModel.fromJson(
    String messageId,
    Map<String, dynamic> json,
  ) {
    return ChatMessageModel(
      messageId: messageId,
      // Mensagens do operador usam 'senderId', mensagens de dispositivo usam 'from_mac'
      senderId:
          (json['senderId'] as String?) ??
          (json['from_mac'] as String? ?? 'unknown').replaceAll(':', ''),
      edited: json['edited'] == true,
      isDeleted: json['isDeleted'] == true,
      // Mensagens de operador usam 'text', de dispositivo T9 usam 'msg', de status usam 'status'
      text:
          (json['text'] as String?) ??
          (json['msg'] as String?) ??
          (json['status'] as String?) ??
          '',
      // Mensagens de operador usam 'timestamp', de dispositivo T9 usam 'ts'
      timestamp: (json['timestamp'] as int?) ?? (json['ts'] as int?) ?? 0,
      status: json['status'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp,
      'status': status,
      'edited': edited,
      'isDeleted': isDeleted,
    };
  }

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);
}
