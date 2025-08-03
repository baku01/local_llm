/// Entidade que representa uma mensagem no chat.
/// 
/// Encapsula as informações de uma mensagem trocada entre o usuário
/// e o assistente de IA, incluindo metadados como timestamp e estado.
class ChatMessage {
  /// Conteúdo textual da mensagem.
  final String text;
  
  /// Indica se a mensagem foi enviada pelo usuário (true) ou pelo assistente (false).
  final bool isUser;
  
  /// Timestamp de quando a mensagem foi criada.
  final DateTime timestamp;
  
  /// Identificador único da mensagem (opcional).
  final String? id;
  
  /// Texto de "pensamento" do assistente durante o processamento (opcional).
  final String? thinkingText;

  /// Construtor da entidade ChatMessage.
  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.id,
    this.thinkingText,
  });

  /// Cria uma cópia da mensagem com campos opcionalmente modificados.
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

  /// Factory constructor para criar mensagem do usuário.
  factory ChatMessage.user(String text, {String? id}) {
    return ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      id: id,
    );
  }

  /// Factory constructor para criar mensagem do assistente.
  factory ChatMessage.assistant(String text, {String? id, String? thinkingText}) {
    return ChatMessage(
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      id: id,
      thinkingText: thinkingText,
    );
  }

  /// Representação textual da mensagem para debug.
  @override
  String toString() {
    final userType = isUser ? 'User' : 'AI';
    final thinking = thinkingText != null ? ' (thinking: $thinkingText)' : '';
    final truncatedText = text.length > 100 ? '${text.substring(0, 100)}...' : text;
    final dateStr = '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
    return 'ChatMessage($userType: $truncatedText, $dateStr$thinking)';
  }

  /// Comparação de igualdade baseada em todos os campos.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage &&
        other.text == text &&
        other.isUser == isUser &&
        other.timestamp == timestamp &&
        other.id == id &&
        other.thinkingText == thinkingText;
  }

  /// Hash code baseado em todos os campos.
  @override
  int get hashCode {
    return Object.hash(
      text,
      isUser,
      timestamp,
      id,
      thinkingText,
    );
  }
}