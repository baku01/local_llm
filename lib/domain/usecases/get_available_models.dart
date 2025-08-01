import '../entities/llm_model.dart';
import '../repositories/llm_repository.dart';

class GetAvailableModels {
  final LlmRepository repository;

  const GetAvailableModels(this.repository);

  Future<List<LlmModel>> call() async {
    return await repository.getAvailableModels();
  }
}
