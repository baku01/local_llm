import '../../domain/entities/llm_model.dart';
import '../../domain/entities/llm_response.dart';
import '../../domain/repositories/llm_repository.dart';
import '../datasources/ollama_remote_datasource.dart';

class LlmRepositoryImpl implements LlmRepository {
  final OllamaRemoteDataSource remoteDataSource;

  const LlmRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<List<LlmModel>> getAvailableModels() async {
    try {
      final modelDtos = await remoteDataSource.getAvailableModels();
      return modelDtos.map((dto) => dto.toEntity()).toList();
    } catch (e) {
      throw Exception('Falha ao obter modelos disponíveis: $e');
    }
  }

  @override
  Future<LlmResponse> generateResponse({
    required String prompt,
    required String modelName,
    bool stream = false,
  }) async {
    try {
      final responseDto = await remoteDataSource.generateResponse(
        prompt: prompt,
        modelName: modelName,
        stream: stream,
      );
      return responseDto.toEntity();
    } catch (e) {
      return LlmResponse.error(
        'Falha ao gerar resposta: $e',
        modelName,
      );
    }
  }

  @override
  Stream<String> generateResponseStream({
    required String prompt,
    required String modelName,
  }) {
    return remoteDataSource.generateResponseStream(
      prompt: prompt,
      modelName: modelName,
    );
  }
}