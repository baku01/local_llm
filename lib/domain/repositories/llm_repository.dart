import '../entities/llm_model.dart';
import '../entities/llm_response.dart';

abstract class LlmRepository {
  Future<List<LlmModel>> getAvailableModels();
  Future<LlmResponse> generateResponse({
    required String prompt,
    required String modelName,
    bool stream = false,
  });
  
  Stream<String> generateResponseStream({
    required String prompt,
    required String modelName,
  });
}