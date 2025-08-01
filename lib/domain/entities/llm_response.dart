/// Entidade que representa uma resposta gerada por um modelo LLM.
/// 
/// Encapsula tanto respostas bem-sucedidas quanto erros que possam
/// ocorrer durante a geração de conteúdo pelo modelo.
class LlmResponse {
  /// Conteúdo da resposta gerada pelo modelo ou mensagem de erro.
  final String content;
  
  /// Nome do modelo que gerou esta resposta.
  final String model;
  
  /// Timestamp de quando a resposta foi gerada.
  final DateTime timestamp;
  
  /// Indica se esta resposta representa um erro.
  final bool isError;

  /// Construtor principal da resposta LLM.
  /// 
  /// [content] - O texto da resposta ou mensagem de erro
  /// [model] - Nome do modelo que gerou a resposta
  /// [timestamp] - Momento da geração
  /// [isError] - Se a resposta representa um erro (padrão: false)
  const LlmResponse({
    required this.content,
    required this.model,
    required this.timestamp,
    this.isError = false,
  });

  /// Factory constructor para criar respostas de erro.
  /// 
  /// Facilita a criação de instâncias que representam erros,
  /// definindo automaticamente [isError] como true e o timestamp atual.
  /// 
  /// [errorMessage] - Mensagem descritiva do erro
  /// [model] - Nome do modelo onde ocorreu o erro
  factory LlmResponse.error(String errorMessage, String model) {
    return LlmResponse(
      content: errorMessage,
      model: model,
      timestamp: DateTime.now(),
      isError: true,
    );
  }

  /// Representação textual da resposta para debug.
  /// 
  /// Trunca o conteúdo em 50 caracteres para evitar logs excessivamente longos.
  @override
  String toString() =>
      'LlmResponse(content: ${content.length > 50 ? '${content.substring(0, 50)}...' : content})';
}
