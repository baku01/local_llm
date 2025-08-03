/// Estratégias de busca na internet com padrão Strategy.
///
/// Este módulo implementa o padrão Strategy para diferentes provedores
/// de busca web, permitindo flexibilidade e extensibilidade na escolha
/// de mecanismos de busca.
library;

import '../../domain/entities/search_result.dart';

/// Interface base para estratégias de busca.
abstract class SearchStrategy {
  /// Nome identificador da estratégia.
  String get name;

  /// Prioridade da estratégia (maior = mais prioritária).
  int get priority;

  /// Se a estratégia está disponível para uso.
  bool get isAvailable;

  /// Timeout específico da estratégia em segundos.
  int get timeoutSeconds;

  /// Executa a busca usando esta estratégia.
  Future<List<SearchResult>> search(SearchQuery query);

  /// Verifica se a estratégia pode lidar com o tipo de query.
  bool canHandle(SearchQuery query);

  /// Obtém métricas de performance da estratégia.
  SearchStrategyMetrics get metrics;
}

/// Métricas de performance de uma estratégia de busca.
class SearchStrategyMetrics {
  /// Número total de buscas realizadas.
  final int totalSearches;

  /// Número de buscas bem-sucedidas.
  final int successfulSearches;

  /// Tempo médio de resposta em milissegundos.
  final double averageResponseTime;

  /// Taxa de sucesso (0.0 a 1.0).
  double get successRate =>
      totalSearches > 0 ? successfulSearches / totalSearches : 0.0;

  /// Última atualização das métricas.
  final DateTime lastUpdated;

  const SearchStrategyMetrics({
    required this.totalSearches,
    required this.successfulSearches,
    required this.averageResponseTime,
    required this.lastUpdated,
  });

  /// Cria métricas vazias.
  factory SearchStrategyMetrics.empty() {
    return SearchStrategyMetrics(
      totalSearches: 0,
      successfulSearches: 0,
      averageResponseTime: 0.0,
      lastUpdated: DateTime.now(),
    );
  }
}

/// Resultado de uma busca com informações de estratégia.
class StrategySearchResult {
  /// Resultados da busca.
  final List<SearchResult> results;

  /// Estratégia utilizada.
  final String strategyName;

  /// Tempo de execução em milissegundos.
  final int executionTimeMs;

  /// Se a busca foi bem-sucedida.
  final bool isSuccessful;

  /// Erro ocorrido (se houver).
  final String? error;

  const StrategySearchResult({
    required this.results,
    required this.strategyName,
    required this.executionTimeMs,
    required this.isSuccessful,
    this.error,
  });
}
