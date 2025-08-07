/// Biblioteca que implementa o repositório para gerenciamento de modelos de LLM.
///
/// Esta biblioteca contém a implementação concreta do [LlmRepository],
/// responsável por intermediar entre a camada de domínio e as fontes de dados
/// para operações relacionadas a modelos de linguagem local (LLM).
library;

import '../../domain/entities/llm_model.dart';
import '../../domain/entities/llm_response.dart';
import '../../domain/repositories/llm_repository.dart';
import '../datasources/llm_remote_datasource.dart';

/// Implementação concreta do repositório de modelos LLM.
///
/// Esta classe implementa [LlmRepository] e serve como uma ponte entre
/// a camada de domínio e a fonte de dados remota (Ollama). É responsável
/// por converter DTOs em entidades de domínio e tratar erros de forma
/// apropriada para a camada de domínio.
///
/// Exemplo de uso:
/// ```dart
/// final repository = LlmRepositoryImpl(
///   remoteDataSource: ollamaDataSource,
/// );
///
/// final models = await repository.getAvailableModels();
/// final response = await repository.generateResponse(
///   prompt: 'Olá, mundo!',
///   modelName: 'llama2',
/// );
/// ```
class LlmRepositoryImpl implements LlmRepository {
  /// Fonte de dados remota para operações com modelos LLM.
  ///
  /// Esta propriedade mantém uma referência para o [LlmRemoteDataSource]
  /// que é usado para realizar operações de rede com o servidor Ollama.
  final LlmRemoteDataSource remoteDataSource;

  /// Cria uma nova instância de [LlmRepositoryImpl].
  ///
  /// Parâmetros:
  /// - [remoteDataSource]: A fonte de dados remota para operações LLM.
  const LlmRepositoryImpl({required this.remoteDataSource});

  /// Obtém a lista de modelos LLM disponíveis.
  ///
  /// Este método consulta a fonte de dados remota para obter todos os
  /// modelos disponíveis e os converte para entidades de domínio.
  ///
  /// Retorna uma [Future] que completa com uma lista de [LlmModel]
  /// representando os modelos disponíveis.
  ///
  /// Throws:
  /// - [Exception]: Se houver falha na comunicação com a fonte de dados.
  @override
  Future<List<LlmModel>> getAvailableModels() async {
    try {
      final modelDtos = await remoteDataSource.getAvailableModels();
      return modelDtos.map((dto) => dto.toEntity()).toList();
    } catch (e) {
      throw Exception('Falha ao obter modelos disponíveis: $e');
    }
  }

  /// Gera uma resposta usando um modelo LLM específico.
  ///
  /// Este método envia um prompt para o modelo especificado e retorna
  /// a resposta gerada. Em caso de erro, retorna uma resposta de erro
  /// em vez de lançar uma exceção.
  ///
  /// Parâmetros:
  /// - [prompt]: O texto de entrada para o modelo.
  /// - [modelName]: O nome do modelo a ser usado para gerar a resposta.
  /// - [stream]: Se true, indica que a resposta deve ser em stream (não usado neste método).
  ///
  /// Retorna uma [Future] que completa com uma [LlmResponse] contendo
  /// a resposta gerada ou informações de erro.
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
      return LlmResponse.error('Falha ao gerar resposta: $e', modelName);
    }
  }

  /// Gera uma resposta em stream usando um modelo LLM específico.
  ///
  /// Este método envia um prompt para o modelo especificado e retorna
  /// um stream de strings que representa a resposta sendo gerada em
  /// tempo real, permitindo exibição progressiva da resposta.
  ///
  /// Parâmetros:
  /// - [prompt]: O texto de entrada para o modelo.
  /// - [modelName]: O nome do modelo a ser usado para gerar a resposta.
  ///
  /// Retorna um [Stream<String>] que emite partes da resposta conforme
  /// são geradas pelo modelo.
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
