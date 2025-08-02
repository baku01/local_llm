/// Contrato do repositório para interação com modelos LLM.
///
/// Define a interface abstrata que deve ser implementada por qualquer
/// repositório que forneça acesso a serviços de modelos de linguagem.
library;

import '../entities/llm_model.dart';
import '../entities/llm_response.dart';

/// Repositório abstrato para operações com modelos LLM.
///
/// Define os métodos necessários para:
/// - Obter lista de modelos disponíveis
/// - Gerar respostas de forma síncrona
/// - Gerar respostas via streaming
///
/// Implementações concretas devem fornecer a integração específica
/// com o servidor LLM (ex: Ollama, OpenAI, etc.).
abstract class LlmRepository {
  /// Obtém a lista de modelos LLM disponíveis no servidor.
  ///
  /// Returns: Lista de [LlmModel] com os modelos disponíveis
  ///
  /// Throws: Exceções específicas da implementação para falhas de rede ou servidor
  Future<List<LlmModel>> getAvailableModels();

  /// Gera uma resposta completa usando o modelo especificado.
  ///
  /// [prompt] - Texto de entrada para o modelo
  /// [modelName] - Nome do modelo a ser utilizado
  /// [stream] - Se deve usar streaming interno (geralmente false para este método)
  ///
  /// Returns: [LlmResponse] com a resposta completa gerada
  ///
  /// Throws: Exceções para erros de comunicação, modelo não encontrado, etc.
  Future<LlmResponse> generateResponse({
    required String prompt,
    required String modelName,
    bool stream = false,
  });

  /// Gera uma resposta em streaming usando o modelo especificado.
  ///
  /// [prompt] - Texto de entrada para o modelo
  /// [modelName] - Nome do modelo a ser utilizado
  ///
  /// Returns: Stream de strings com chunks da resposta conforme são gerados
  ///
  /// Throws: Exceções para erros de comunicação, modelo não encontrado, etc.
  Stream<String> generateResponseStream({
    required String prompt,
    required String modelName,
  });
}
