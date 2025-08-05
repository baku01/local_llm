/// Gerenciador de estratégias de busca com fallback inteligente.
///
/// Este módulo implementa um sistema robusto de gerenciamento de estratégias
/// de busca, incluindo seleção automática, fallback, métricas de performance
/// e circuit breaker pattern para fault tolerance.
library;

import 'dart:async';
import 'dart:math' as math;
import '../../domain/entities/search_result.dart';
import '../../domain/entities/search_query.dart';
import 'search_strategy.dart';
import 'circuit_breaker.dart';
import '../utils/logger.dart';

/// Configuração do gerenciador de estratégias.
class SearchStrategyConfig {
  /// Timeout máximo para uma estratégia em segundos.
  final int maxTimeoutSeconds;

  /// Número máximo de tentativas de fallback.
  final int maxFallbackAttempts;

  /// Se deve usar cache de estratégias.
  final bool enableStrategyCache;

  /// Intervalo para limpeza de cache em minutos.
  final int cacheCleanupIntervalMinutes;

  /// Taxa mínima de sucesso para manter estratégia ativa.
  final double minSuccessRate;

  const SearchStrategyConfig({
    this.maxTimeoutSeconds = 30,
    this.maxFallbackAttempts = 3,
    this.enableStrategyCache = true,
    this.cacheCleanupIntervalMinutes = 60,
    this.minSuccessRate = 0.3,
  });
}

/// Gerenciador inteligente de estratégias de busca.
///
/// Características principais:
/// - Seleção automática da melhor estratégia baseada em métricas
/// - Sistema de fallback com múltiplas tentativas
/// - Monitoramento de performance em tempo real
/// - Cache inteligente de resultados
/// - Balanceamento de carga entre estratégias
/// - Circuit breaker pattern para fault tolerance
/// - Health check das estratégias
class SearchStrategyManager {
  final List<SearchStrategy> _strategies = [];
  final SearchStrategyConfig _config;
  final Map<String, List<StrategySearchResult>> _cache = {};
  final Map<String, CircuitBreaker> _circuitBreakers = {};
  Timer? _cacheCleanupTimer;
  Timer? _healthCheckTimer;

  /// Métricas globais do gerenciador.
  final Map<String, SearchStrategyMetrics> _strategyMetrics = {};

  SearchStrategyManager({SearchStrategyConfig? config})
      : _config = config ?? const SearchStrategyConfig() {
    _startCacheCleanup();
    _startHealthCheck();
  }

  /// Registra uma nova estratégia de busca.
  void registerStrategy(SearchStrategy strategy) {
    if (!_strategies.any((s) => s.name == strategy.name)) {
      _strategies.add(strategy);
      _strategyMetrics[strategy.name] = SearchStrategyMetrics.empty();
      _circuitBreakers[strategy.name] = CircuitBreaker(
        strategy.name,
        const CircuitBreakerConfig(
          failureThreshold: 3,
          timeoutMs: 30000,
          successThreshold: 2,
        ),
      );
      AppLogger.info(
          'Estratégia registrada: ${strategy.name}', 'SearchStrategyManager');
    }
  }

  /// Remove uma estratégia de busca.
  void unregisterStrategy(String strategyName) {
    _strategies.removeWhere((s) => s.name == strategyName);
    _strategyMetrics.remove(strategyName);
    _circuitBreakers.remove(strategyName);
    AppLogger.info(
        'Estratégia removida: $strategyName', 'SearchStrategyManager');
  }

  /// Executa busca usando a melhor estratégia disponível.
  Future<StrategySearchResult> search(SearchQuery query) async {
    if (_strategies.isEmpty) {
      throw Exception('Nenhuma estratégia de busca registrada');
    }

    // Verificar cache primeiro
    if (_config.enableStrategyCache) {
      final cachedResult = _getCachedResult(query);
      if (cachedResult != null) {
        AppLogger.debug(
            'Resultado encontrado no cache', 'SearchStrategyManager');
        return cachedResult;
      }
    }

    final availableStrategies = _getAvailableStrategies(query);
    if (availableStrategies.isEmpty) {
      throw Exception('Nenhuma estratégia disponível para esta consulta');
    }

    // Tentar estratégias em ordem de prioridade
    Exception? lastException;
    for (int attempt = 0; attempt < _config.maxFallbackAttempts; attempt++) {
      final strategy = _selectBestStrategy(availableStrategies, attempt);
      if (strategy == null) break;

      try {
        final result = await _executeStrategy(strategy, query);

        // Se o resultado é bem-sucedido, retornar
        if (result.isSuccessful) {
          // Cache do resultado se bem-sucedido
          if (_config.enableStrategyCache) {
            _cacheResult(query, result);
          }
          return result;
        } else {
          // Se não foi bem-sucedido, continuar para próxima estratégia
          lastException = Exception(result.error ?? 'Estratégia falhou');
          AppLogger.warning(
            'Estratégia ${strategy.name} falhou (tentativa ${attempt + 1}): ${result.error}',
            'SearchStrategyManager',
          );
        }
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        AppLogger.warning(
          'Estratégia ${strategy.name} falhou (tentativa ${attempt + 1}): $e',
          'SearchStrategyManager',
        );

        // Atualizar métricas de falha
        _updateStrategyMetrics(strategy.name, false, 0);
      }
    }

    throw lastException ?? Exception('Todas as estratégias falharam');
  }

  /// Obtém estratégias disponíveis para a consulta.
  List<SearchStrategy> _getAvailableStrategies(SearchQuery query) {
    return _strategies.where((strategy) {
      final successRate = _getStrategySuccessRate(strategy.name);
      final metrics =
          _strategyMetrics[strategy.name] ?? SearchStrategyMetrics.empty();

      // Permitir estratégias novas (sem histórico) ou com taxa de sucesso adequada
      final hasMinSuccessRate =
          metrics.totalSearches == 0 || successRate >= _config.minSuccessRate;

      return strategy.isAvailable &&
          strategy.canHandle(query) &&
          hasMinSuccessRate &&
          _isStrategyHealthy(strategy.name);
    }).toList();
  }

  /// Verifica se uma estratégia está saudável (circuit breaker fechado).
  bool _isStrategyHealthy(String strategyName) {
    final circuitBreaker = _circuitBreakers[strategyName];
    return circuitBreaker?.state != CircuitBreakerState.open;
  }

  /// Seleciona a melhor estratégia baseada em métricas.
  SearchStrategy? _selectBestStrategy(
      List<SearchStrategy> strategies, int attempt) {
    if (strategies.isEmpty) return null;

    // Na primeira tentativa, usar a estratégia com melhor score
    if (attempt == 0) {
      strategies.sort((a, b) =>
          _calculateStrategyScore(b).compareTo(_calculateStrategyScore(a)));
      return strategies.first;
    }

    // Em tentativas subsequentes, usar estratégias ainda não testadas
    final remainingStrategies = strategies.skip(attempt).toList();
    return remainingStrategies.isNotEmpty ? remainingStrategies.first : null;
  }

  /// Calcula score de uma estratégia baseado em métricas.
  double _calculateStrategyScore(SearchStrategy strategy) {
    final metrics =
        _strategyMetrics[strategy.name] ?? SearchStrategyMetrics.empty();
    final successRate = _getStrategySuccessRate(strategy.name);
    final avgResponseTime = metrics.averageResponseTime;

    // Score baseado em sucesso (70%) e velocidade (30%)
    final successScore = successRate * 0.7;
    final speedScore = avgResponseTime > 0
        ? math.max(0, (10000 - avgResponseTime) / 10000) * 0.3
        : 0.0;

    return (successScore + speedScore) * (strategy.priority / 10.0);
  }

  /// Executa uma estratégia específica com timeout e circuit breaker.
  Future<StrategySearchResult> _executeStrategy(
    SearchStrategy strategy,
    SearchQuery query,
  ) async {
    final stopwatch = Stopwatch()..start();
    final circuitBreaker = _circuitBreakers[strategy.name];

    try {
      late List<SearchResult> results;

      if (circuitBreaker != null) {
        // Usar circuit breaker para proteger a execução
        results = await circuitBreaker.execute(() => strategy
            .search(query)
            .timeout(Duration(seconds: strategy.timeoutSeconds)));
      } else {
        // Fallback sem circuit breaker
        results = await strategy
            .search(query)
            .timeout(Duration(seconds: strategy.timeoutSeconds));
      }

      stopwatch.stop();
      final executionTime = stopwatch.elapsedMilliseconds;

      // Atualizar métricas de sucesso
      _updateStrategyMetrics(strategy.name, true, executionTime);

      AppLogger.info(
        'Estratégia ${strategy.name} executada com sucesso em ${executionTime}ms',
        'SearchStrategyManager',
      );

      return StrategySearchResult(
        results: results,
        strategyName: strategy.name,
        executionTimeMs: executionTime,
        isSuccessful: true,
      );
    } catch (e) {
      stopwatch.stop();
      final executionTime = stopwatch.elapsedMilliseconds;

      // Determinar tipo de erro
      String errorType = 'Unknown';
      if (e is CircuitBreakerOpenException) {
        errorType = 'CircuitBreakerOpen';
      } else if (e is TimeoutException) {
        errorType = 'Timeout';
      } else {
        errorType = 'ExecutionFailure';
      }

      AppLogger.warning(
        'Estratégia ${strategy.name} falhou: $errorType - $e',
        'SearchStrategyManager',
      );

      return StrategySearchResult(
        results: [],
        strategyName: strategy.name,
        executionTimeMs: executionTime,
        isSuccessful: false,
        error: '$errorType: $e',
      );
    }
  }

  /// Atualiza métricas de uma estratégia.
  void _updateStrategyMetrics(
      String strategyName, bool success, int responseTime) {
    final current =
        _strategyMetrics[strategyName] ?? SearchStrategyMetrics.empty();

    final newTotal = current.totalSearches + 1;
    final newSuccessful =
        success ? current.successfulSearches + 1 : current.successfulSearches;
    final newAvgTime =
        ((current.averageResponseTime * current.totalSearches) + responseTime) /
            newTotal;

    _strategyMetrics[strategyName] = SearchStrategyMetrics(
      totalSearches: newTotal,
      successfulSearches: newSuccessful,
      averageResponseTime: newAvgTime,
      lastUpdated: DateTime.now(),
    );
  }

  /// Obtém taxa de sucesso de uma estratégia.
  double _getStrategySuccessRate(String strategyName) {
    final metrics = _strategyMetrics[strategyName];
    return metrics?.successRate ?? 0.0;
  }

  /// Verifica cache para resultado existente.
  StrategySearchResult? _getCachedResult(SearchQuery query) {
    final cacheKey = _generateCacheKey(query);
    final cachedResults = _cache[cacheKey];

    if (cachedResults != null && cachedResults.isNotEmpty) {
      // Retornar resultado mais recente e bem-sucedido
      final validResults = cachedResults.where((r) => r.isSuccessful).toList();
      if (validResults.isNotEmpty) {
        return validResults.last;
      }
    }

    return null;
  }

  /// Armazena resultado no cache.
  void _cacheResult(SearchQuery query, StrategySearchResult result) {
    final cacheKey = _generateCacheKey(query);
    _cache.putIfAbsent(cacheKey, () => []).add(result);

    // Limitar tamanho do cache por chave
    if (_cache[cacheKey]!.length > 5) {
      _cache[cacheKey]!.removeAt(0);
    }
  }

  /// Gera chave de cache para uma consulta.
  String _generateCacheKey(SearchQuery query) {
    return '${query.formattedQuery}_${query.type.name}_${query.maxResults}';
  }

  /// Inicia timer de limpeza de cache.
  void _startCacheCleanup() {
    if (!_config.enableStrategyCache) return;

    _cacheCleanupTimer = Timer.periodic(
      Duration(minutes: _config.cacheCleanupIntervalMinutes),
      (_) => _cleanupCache(),
    );
  }

  /// Inicia health check das estratégias.
  void _startHealthCheck() {
    _healthCheckTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _performHealthCheck(),
    );
  }

  /// Realiza health check das estratégias registradas.
  void _performHealthCheck() {
    AppLogger.debug(
        'Performing health check on strategies', 'SearchStrategyManager');

    for (final strategy in _strategies) {
      final metrics = _strategyMetrics[strategy.name];
      final circuitBreaker = _circuitBreakers[strategy.name];

      if (metrics != null && circuitBreaker != null) {
        // Log estado atual
        AppLogger.debug(
          'Strategy ${strategy.name}: Success rate ${(metrics.successRate * 100).toStringAsFixed(1)}%, '
              'Circuit breaker: ${circuitBreaker.state.name}, '
              'Available: ${strategy.isAvailable}',
          'SearchStrategyManager',
        );

        // Reset circuit breaker se estratégia não foi usada recentemente
        if (circuitBreaker.state == CircuitBreakerState.open &&
            metrics.lastUpdated.isBefore(
                DateTime.now().subtract(const Duration(minutes: 10)))) {
          AppLogger.info(
            'Resetting circuit breaker for inactive strategy: ${strategy.name}',
            'SearchStrategyManager',
          );
          circuitBreaker.reset();
        }
      }
    }
  }

  /// Limpa entradas antigas do cache.
  void _cleanupCache() {
    final cutoffMinutes = _config.cacheCleanupIntervalMinutes * 2;

    _cache.removeWhere((key, results) {
      results.removeWhere((result) =>
          DateTime.now().difference(DateTime.now()).inMinutes > cutoffMinutes);
      return results.isEmpty;
    });

    AppLogger.debug('Cache limpo', 'SearchStrategyManager');
  }

  /// Obtém estatísticas do gerenciador.
  Map<String, dynamic> getStatistics() {
    final circuitBreakerStats = _circuitBreakers.map(
      (name, breaker) => MapEntry(name, breaker.getStatistics()),
    );

    return {
      'registered_strategies': _strategies.length,
      'cache_entries': _cache.length,
      'strategy_metrics': _strategyMetrics,
      'circuit_breakers': circuitBreakerStats,
      'health_check_enabled': _healthCheckTimer != null,
      'available_strategies': _strategies.where((s) => s.isAvailable).length,
      'healthy_strategies':
          _strategies.where((s) => _isStrategyHealthy(s.name)).length,
    };
  }

  /// Força o reset de todos os circuit breakers.
  void resetAllCircuitBreakers() {
    for (final breaker in _circuitBreakers.values) {
      breaker.reset();
    }
    AppLogger.info('All circuit breakers reset', 'SearchStrategyManager');
  }

  /// Obtém estratégias ordenadas por score.
  List<Map<String, dynamic>> getStrategiesRanking() {
    return _strategies.map((strategy) {
      final score = _calculateStrategyScore(strategy);
      final metrics =
          _strategyMetrics[strategy.name] ?? SearchStrategyMetrics.empty();
      final circuitBreaker = _circuitBreakers[strategy.name];

      return {
        'name': strategy.name,
        'priority': strategy.priority,
        'score': score,
        'success_rate': metrics.successRate,
        'avg_response_time': metrics.averageResponseTime,
        'total_searches': metrics.totalSearches,
        'is_available': strategy.isAvailable,
        'is_healthy': _isStrategyHealthy(strategy.name),
        'circuit_breaker_state': circuitBreaker?.state.name ?? 'none',
      };
    }).toList()
      ..sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
  }

  /// Libera recursos do gerenciador.
  void dispose() {
    _cacheCleanupTimer?.cancel();
    _healthCheckTimer?.cancel();
    _cache.clear();
    _strategies.clear();
    _strategyMetrics.clear();
    _circuitBreakers.clear();
  }
}
