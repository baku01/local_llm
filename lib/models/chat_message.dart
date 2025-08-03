class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? id;
  final String? thinkingText;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.id,
    this.thinkingText,
  });

  ChatMessage copyWith({
    String? text,
    bool? isUser,
    DateTime? timestamp,
    String? id,
    String? thinkingText,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      id: id ?? this.id,
      thinkingText: thinkingText ?? this.thinkingText,
    );
  }
}