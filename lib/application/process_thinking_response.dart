/// Biblioteca que define o caso de uso para processamento de respostas com pensamento.
///
/// Esta biblioteca contém o caso de uso [ProcessThinkingResponse] que
/// processa respostas de modelos LLM que contêm tags de pensamento (`<think>`),
/// separando o conteúdo principal do processo de "pensamento" do modelo.
library;

import '../domain/entities/llm_response.dart';
import '../domain/entities/thinking_response.dart';

/// Caso de uso para processamento de respostas com pensamento.
///
/// Esta classe encapsula a lógica de negócio para processar respostas
/// de modelos LLM que suportam "pensamento" (como a série R1), extraindo
/// o conteúdo de pensamento das tags `<think>` e separando do conteúdo
/// principal da resposta.
///
/// O caso de uso:
/// - Identifica tags `<think>` e `</think>` na resposta
/// - Extrai o conteúdo de pensamento
/// - Remove as tags da resposta final
/// - Retorna um objeto estruturado com ambos os conteúdos
///
/// Exemplo de uso:
/// ```dart
/// final useCase = ProcessThinkingResponse();
///
/// final response = LlmResponse(
///   content: '<think>Preciso analisar...</think>A resposta é 42.',
///   model: 'llama-r1',
///   timestamp: DateTime.now(),
/// );
///
/// final processed = useCase(response);
/// print('Pensamento: ${processed.thinkingContent}');
/// print('Resposta: ${processed.mainContent}');
/// ```
class ProcessThinkingResponse {
  /// Cria uma nova instância de [ProcessThinkingResponse].
  const ProcessThinkingResponse();

  /// Executa o processamento da resposta com pensamento.
  ///
  /// Este método analisa o conteúdo da resposta em busca de tags de
  /// pensamento, extrai o conteúdo relevante e retorna um objeto
  /// estruturado com o pensamento e a resposta final.
  ///
  /// Parâmetros:
  /// - [response]: A resposta LLM a ser processada.
  ///
  /// Retorna um [ThinkingResponse] contendo:
  /// - mainContent: O conteúdo principal sem as tags de pensamento
  /// - thinkingContent: O conteúdo extraído das tags `<think>`
  /// - hasThinking: Se a resposta continha pensamento
  /// - originalResponse: A resposta original para referência
  ///
  /// Exemplo:
  /// ```dart
  /// final processed = useCase(response);
  /// if (processed.hasThinking) {
  ///   print('O modelo pensou: ${processed.thinkingContent}');
  /// }
  /// print('Resposta final: ${processed.mainContent}');
  /// ```
  ThinkingResponse call(LlmResponse response) {
    final content = response.content;

    if (!content.contains('<think>')) {
      // Sem pensamento, retorna resposta original
      return ThinkingResponse(
        mainContent: content,
        thinkingContent: null,
        hasThinking: false,
        originalResponse: response,
      );
    }

    // Processar tags de pensamento
    final thinkStart = content.indexOf('<think>');
    final thinkEnd = content.indexOf('</think>');

    if (thinkStart == -1 || thinkEnd == -1 || thinkEnd <= thinkStart) {
      // Tags malformadas, retorna resposta original
      return ThinkingResponse(
        mainContent: content,
        thinkingContent: null,
        hasThinking: false,
        originalResponse: response,
      );
    }

    // Extrair o pensamento
    final thinkingContent = content
        .substring(
          thinkStart + 7, // length of '<think>'
          thinkEnd,
        )
        .trim();

    // Remover tags de pensamento da resposta final
    final mainContent = content
        .replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '')
        .trim();

    return ThinkingResponse(
      mainContent: mainContent,
      thinkingContent: thinkingContent.isNotEmpty ? thinkingContent : null,
      hasThinking: thinkingContent.isNotEmpty,
      originalResponse: response,
    );
  }
}
