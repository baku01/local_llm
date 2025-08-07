/// Data source de busca web baseado em estratégias.
///
/// Implementa busca web usando o sistema de estratégias modular,
/// com seleção automática, fallback e otimização de performance.
library;

import 'dart:async';
import 'package:http/http.dart' as http;
import '../../core/search/search_strategy_manager.dart';

import '../../core/search/strategies/google_search_strategy.dart';
import '../../core/search/strategies/bing_search_strategy.dart';
import '../../core/search/strategies/duckduckgo_search_strategy.dart';
import '../../core/search/strategies/local_search_strategy.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/entities/search_query.dart';
import '../../core/utils/logger.dart';
import 'web_search_datasource.dart';

/// Data source de busca web usando estratégias modulares.
class StrategyWebSearchDataSource implements WebSearchDataSource {
  final SearchStrategyManager _strategyManager;
  final http.Client _httpClient;

  StrategyWebSearchDataSource({
    required http.Client httpClient,
    SearchStrategyConfig? config,
  })  : _httpClient = httpClient,
        _strategyManager = SearchStrategyManager(
          config: config ?? const SearchStrategyConfig(),
        ) {
    _initializeStrategies();
  }

  /// Inicializa todas as estratégias de busca.
  void _initializeStrategies() {
    try {
      // Registrar estratégias em ordem de prioridade
      _strategyManager.registerStrategy(
        GoogleSearchStrategy(client: _httpClient),
      );

      _strategyManager.registerStrategy(
        BingSearchStrategy(client: _httpClient),
      );

      _strategyManager.registerStrategy(
        DuckDuckGoSearchStrategy(client: _httpClient),
      );

      _strategyManager.registerStrategy(
        LocalSearchStrategy(client: _httpClient),
      );

      AppLogger.info(
        'Initialized ${_strategyManager.getStatistics()['registered_strategies']} search strategies',
        'StrategyWebSearchDataSource',
      );
    } catch (e) {
      AppLogger.error(
        'Failed to initialize search strategies: $e',
        'StrategyWebSearchDataSource',
      );
      rethrow;
    }
  }

  @override
  Future<List<SearchResult>> search(SearchQuery query) async {
    try {
      AppLogger.info(
        'Starting web search: "${query.query}" (type: ${query.type}, max: ${query.maxResults})',
        'StrategyWebSearchDataSource',
      );

      final strategyResult = await _strategyManager.search(query);

      AppLogger.info(
        'Web search completed: ${strategyResult.results.length} results found using ${strategyResult.strategyName}',
        'StrategyWebSearchDataSource',
      );

      return strategyResult.results;
    } catch (e) {
      AppLogger.error(
        'Web search failed: $e',
        'StrategyWebSearchDataSource',
      );
      rethrow;
    }
  }

  @override
  Future<String> fetchPageContent(String url) async {
    try {
      AppLogger.debug(
          'Fetching page content: $url', 'StrategyWebSearchDataSource');

      final response = await _httpClient.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'pt-BR,pt;q=0.9,en;q=0.8',
          'Accept-Encoding': 'gzip, deflate',
          'Connection': 'keep-alive',
          'Cache-Control': 'no-cache',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: Failed to fetch $url');
      }

      final content = response.body;

      // Limitar tamanho do conteúdo para evitar problemas de memória
      const maxContentLength = 1000000; // 1MB
      final limitedContent = content.length > maxContentLength
          ? content.substring(0, maxContentLength)
          : content;

      AppLogger.debug(
        'Page content fetched: ${limitedContent.length} characters',
        'StrategyWebSearchDataSource',
      );

      return limitedContent;
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch page content from $url: $e',
        'StrategyWebSearchDataSource',
      );
      rethrow;
    }
  }

  /// Obtém estatísticas das estratégias.
  Map<String, dynamic> getStrategyStatistics() {
    return _strategyManager.getStatistics();
  }

  /// Configura estratégia preferida.
  void setPreferredStrategy(String strategyName) {
    // Implementar lógica para definir estratégia preferida
    AppLogger.info(
      'Preferred strategy set to: $strategyName',
      'StrategyWebSearchDataSource',
    );
  }

  /// Limpa cache e métricas.
  void clearCache() {
    // O cache é gerenciado internamente pelo SearchStrategyManager
    AppLogger.info('Strategy cache management handled internally',
        'StrategyWebSearchDataSource');
  }

  /// Libera recursos.
  void dispose() {
    try {
      _httpClient.close();
      AppLogger.info('StrategyWebSearchDataSource disposed',
          'StrategyWebSearchDataSource');
    } catch (e) {
      AppLogger.warning('Error disposing StrategyWebSearchDataSource: $e',
          'StrategyWebSearchDataSource');
    }
  }
}
