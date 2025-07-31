import '../entities/llm_response.dart';
import '../repositories/llm_repository.dart';

class GenerateResponse {
  final LlmRepository repository;

  const GenerateResponse(this.repository);

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