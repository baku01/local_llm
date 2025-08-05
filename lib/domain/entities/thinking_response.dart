/// Biblioteca que define a entidade para respostas processadas com pensamento.
///
/// Esta biblioteca contém a classe [ThinkingResponse] que representa
/// uma resposta de LLM processada, separando o conteúdo principal
/// do processo de "pensamento" do modelo.
library;

import 'llm_response.dart';

/// Entidade que representa uma resposta processada com pensamento.
///
/// Esta classe encapsula o resultado do processamento de uma resposta
/// de modelo LLM que pode conter tags de pensamento (`<think>`),
/// separando o conteúdo de pensamento do conteúdo principal da resposta.
///
/// Propriedades:
/// - [mainContent]: O conteúdo principal da resposta, sem tags de pensamento
/// - [thinkingContent]: O conteúdo de pensamento extraído, se presente
/// - [hasThinking]: Indica se a resposta continha pensamento
/// - [originalResponse]: A resposta LLM original para referência
///
/// Exemplo de uso:
/// ```dart
/// final thinkingResponse = ThinkingResponse(
///   mainContent: 'A resposta é 42.',
///   thinkingContent: 'Preciso analisar esta pergunta sobre o universo...',
///   hasThinking: true,
///   originalResponse: originalLlmResponse,
/// );
///
/// if (thinkingResponse.hasThinking) {
///   print('Pensamento: ${thinkingResponse.thinkingContent}');
/// }
/// print('Resposta: ${thinkingResponse.mainContent}');
/// ```
class ThinkingResponse {
  /// O conteúdo principal da resposta, sem tags de pensamento.
  ///
  /// Este é o conteúdo que deve ser exibido ao usuário como a
  /// resposta final do modelo, após remover as tags `<think>`.
  final String mainContent;

  /// O conteúdo de pensamento extraído das tags `<think>`.
  ///
  /// Contém o processo de raciocínio do modelo, se presente.
  /// Pode ser null se a resposta não continha pensamento.
  final String? thinkingContent;

  /// Indica se a resposta original continha pensamento.
  ///
  /// É true quando tags `<think>` válidas foram encontradas
  /// e processadas na resposta original.
  final bool hasThinking;

  /// A resposta LLM original para referência.
  ///
  /// Mantém uma referência à resposta original para casos
  /// onde informações adicionais sejam necessárias.
  final LlmResponse originalResponse;

  /// Cria uma nova instância de [ThinkingResponse].
  ///
  /// Parâmetros:
  /// - [mainContent]: O conteúdo principal processado.
  /// - [thinkingContent]: O conteúdo de pensamento, se presente.
  /// - [hasThinking]: Se a resposta continha pensamento.
  /// - [originalResponse]: A resposta LLM original.
  const ThinkingResponse({
    required this.mainContent,
    required this.thinkingContent,
    required this.hasThinking,
    required this.originalResponse,
  });

  /// Cria uma resposta sem pensamento a partir de uma resposta LLM.
  ///
  /// Este método de conveniência cria uma [ThinkingResponse] para
  /// respostas que não contêm pensamento, usando o conteúdo original
  /// como conteúdo principal.
  ///
  /// Parâmetros:
  /// - [response]: A resposta LLM original.
  ///
  /// Retorna uma [ThinkingResponse] sem pensamento.
  factory ThinkingResponse.withoutThinking(LlmResponse response) {
    return ThinkingResponse(
      mainContent: response.content,
      thinkingContent: null,
      hasThinking: false,
      originalResponse: response,
    );
  }

  /// Retorna uma representação em string da resposta processada.
  ///
  /// Inclui informações sobre se há pensamento e o tamanho
  /// do conteúdo principal.
  @override
  String toString() {
    return 'ThinkingResponse('
        'mainContent: ${mainContent.length} chars, '
        'hasThinking: $hasThinking, '
        'thinkingContent: ${thinkingContent?.length ?? 0} chars'
        ')';
  }

  /// Compara duas instâncias de [ThinkingResponse] para igualdade.
  ///
  /// Duas respostas são consideradas iguais se têm o mesmo
  /// conteúdo principal, pensamento e resposta original.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ThinkingResponse &&
        other.mainContent == mainContent &&
        other.thinkingContent == thinkingContent &&
        other.hasThinking == hasThinking &&
        other.originalResponse == originalResponse;
  }

  /// Retorna o hash code da resposta processada.
  @override
  int get hashCode {
    return Object.hash(
      mainContent,
      thinkingContent,
      hasThinking,
      originalResponse,
    );
  }
}
