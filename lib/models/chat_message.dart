/// A single chat message (user, bot, or system).
class ChatMessage {
  final String id;
  final String content;
  final String senderType; // "user", "bot", or "system"
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.content,
    required this.senderType,
    required this.createdAt,
  });

  /// Parse a message from the API response (GET /api/v1/messages).
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      senderType: json['sender_type'] ?? 'system',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  /// Create a local user message (before API responds).
  factory ChatMessage.user(String content) {
    return ChatMessage(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      senderType: 'user',
      createdAt: DateTime.now(),
    );
  }

  /// Create a system message (e.g., welcome, errors).
  factory ChatMessage.system(String content) {
    return ChatMessage(
      id: 'system_${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      senderType: 'system',
      createdAt: DateTime.now(),
    );
  }

  bool get isUser => senderType == 'user';
  bool get isBot => senderType == 'bot';
  bool get isSystem => senderType == 'system';
}
