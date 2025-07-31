import '../repositories/llm_repository.dart';

class GenerateResponseStream {
  final LlmRepository repository;

  const GenerateResponseStream(this.repository);

  Stream<String> call({
    required String prompt,
    required String modelName,
  }) {
    return repository.generateResponseStream(
      prompt: prompt,
      modelName: modelName,
    );
  }
}