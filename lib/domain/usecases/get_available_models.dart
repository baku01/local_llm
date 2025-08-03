/// Biblioteca que define o caso de uso para obtenção de modelos LLM disponíveis.
///
/// Esta biblioteca contém o caso de uso [GetAvailableModels] que
/// permite obter a lista de todos os modelos de linguagem
/// disponíveis no sistema.
library;

import '../entities/llm_model.dart';
import '../repositories/llm_repository.dart';

/// Caso de uso para obtenção de modelos LLM disponíveis.
///
/// Esta classe encapsula a lógica de negócio para obter a lista
/// de todos os modelos de linguagem disponíveis no sistema.
/// É responsável por coordenar a operação com o repositório
/// e garantir que os dados sejam apresentados adequadamente
/// para a camada de apresentação.
///
/// Este caso de uso é tipicamente usado para:
/// - Preencher dropdowns de seleção de modelo
/// - Validar se um modelo específico está disponível
/// - Exibir informações sobre os modelos instalados
///
/// Exemplo de uso:
/// ```dart
/// final useCase = GetAvailableModels(repository);
///
/// final models = await useCase();
/// for (final model in models) {
///   print('Modelo: ${model.name} - Tamanho: ${model.size}');
/// }
/// ```
class GetAvailableModels {
  /// Repositório para operações com modelos LLM.
  ///
  /// Esta propriedade mantém uma referência para o [LlmRepository]
  /// que será usado para executar operações de consulta de modelos.
  final LlmRepository repository;

  /// Cria uma nova instância de [GetAvailableModels].
  ///
  /// Parâmetros:
  /// - [repository]: O repositório para operações LLM.
  const GetAvailableModels(this.repository);

  /// Executa o caso de uso de obtenção de modelos disponíveis.
  ///
  /// Este método consulta o repositório para obter a lista completa
  /// de modelos de linguagem disponíveis no sistema.
  ///
  /// Retorna uma [Future] que completa com uma lista de [LlmModel]
  /// representando todos os modelos disponíveis. A lista pode estar
  /// vazia se nenhum modelo estiver instalado.
  ///
  /// Throws:
  /// - [Exception]: Se houver falha na consulta dos modelos.
  ///
  /// Exemplo:
  /// ```dart
  /// try {
  ///   final models = await useCase();
  ///   if (models.isEmpty) {
  ///     print('Nenhum modelo disponível');
  ///   } else {
  ///     print('Encontrados ${models.length} modelos');
  ///   }
  /// } catch (e) {
  ///   print('Erro ao obter modelos: $e');
  /// }
  /// ```
  Future<List<LlmModel>> call() async {
    return await repository.getAvailableModels();
  }
}
