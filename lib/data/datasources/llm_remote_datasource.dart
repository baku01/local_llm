library;

import '../models/llm_model_dto.dart';
import '../models/llm_response_dto.dart';

/// Interface genérica para comunicação com backends LLM.
///
/// Define os contratos necessários para obter modelos disponíveis e gerar
/// respostas, incluindo suporte a streaming.
abstract class LlmRemoteDataSource {
  /// Obtém a lista de modelos disponíveis no backend.
  Future<List<LlmModelDto>> getAvailableModels();

  /// Gera uma resposta completa usando o modelo especificado.
  Future<LlmResponseDto> generateResponse({
    required String prompt,
    required String modelName,
    bool stream = false,
  });

  /// Gera uma resposta em streaming usando o modelo especificado.
  Stream<String> generateResponseStream({
    required String prompt,
    required String modelName,
  });
}

