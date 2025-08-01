class LlmResponse {
  final String content;
  final String model;
  final DateTime timestamp;
  final bool isError;

  const LlmResponse({
    required this.content,
    required this.model,
    required this.timestamp,
    this.isError = false,
  });

  factory LlmResponse.error(String errorMessage, String model) {
    return LlmResponse(
      content: errorMessage,
      model: model,
      timestamp: DateTime.now(),
      isError: true,
    );
  }

  @override
  String toString() =>
      'LlmResponse(content: ${content.length > 50 ? '${content.substring(0, 50)}...' : content})';
}
