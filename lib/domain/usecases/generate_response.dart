/// Caso de uso para geração de resposta única por modelo LLM.
/// 
/// Este caso de uso encapsula a lógica de negócio para gerar uma resposta
/// completa (não streaming) usando um modelo LLM específico.
library;

import '../entities/llm_response.dart';
import '../repositories/llm_repository.dart';

/// Caso de uso responsável por gerar respostas LLM de forma síncrona.
/// 
/// Implementa validações de entrada e delega a geração para o repositório.
/// Ideal para casos onde uma resposta completa é necessária de uma vez.
class GenerateResponse {
  /// Repositório para acesso aos serviços de LLM.
  final LlmRepository repository;

  /// Construtor que recebe o repositório por injeção de dependência.
  const GenerateResponse(this.repository);

  /// Gera uma resposta completa usando o modelo especificado.
  /// 
  /// [prompt] - O texto de entrada para o modelo
  /// [modelName] - Nome do modelo LLM a ser usado
  /// [stream] - Se deve usar streaming (padrão: false para este caso de uso)
  /// 
  /// Returns: [LlmResponse] contendo a resposta gerada
  /// 
  /// Throws: 
  /// - [ArgumentError] se prompt ou modelName estiverem vazios
  /// - Exceções do repositório para erros de comunicação ou processamento
  Future<LlmResponse> call({
    required String prompt,
    required String modelName,
    bool stream = false,
  }) async {
    if (prompt.trim().isEmpty) {
      throw ArgumentError('O prompt não pode estar vazio');
    }

    if (modelName.trim().isEmpty) {
      throw ArgumentError('O nome do modelo não pode estar vazio');
    }

    return await repository.generateResponse(
      prompt: prompt,
      modelName: modelName,
      stream: stream,
    );
  }
}
