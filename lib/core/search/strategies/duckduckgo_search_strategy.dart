/// Estratégia de busca para DuckDuckGo com foco em privacidade.
///
/// Implementa busca no DuckDuckGo usando tanto a API quanto scraping,
/// priorizando privacidade e resultados não filtrados.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import '../../../domain/entities/search_result.dart';
import '../search_strategy.dart';
import '../../utils/logger.dart';

/// Estratégia de busca otimizada para DuckDuckGo.
class DuckDuckGoSearchStrategy implements SearchStrategy {
  final http.Client _client;
  final List<String> _userAgents;
  final bool _useApi;
  SearchStrategyMetrics _metrics = SearchStrategyMetrics.empty();

  /// User-Agents otimizados para DuckDuckGo.
  static const List<String> _defaultUserAgents = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0',
  ];

  DuckDuckGoSearchStrategy({
    required http.Client client,
    List<String>? userAgents,
    bool useApi = true,
  })  : _client = client,
        _userAgents = userAgents ?? _defaultUserAgents,
        _useApi = useApi;

  @override
  String get name => 'DuckDuckGo';

  @override
  int get priority => 7; // Prioridade média

  @override
  bool get isAvailable => true;

  @override
  int get timeoutSeconds => 10;

  @override
  SearchStrategyMetrics get metrics => _metrics;

  @override
  bool canHandle(SearchQuery query) {
    // DuckDuckGo funciona bem com todos os tipos de consulta
    return query.query.trim().isNotEmpty;
  }

  @override
  Future<List<SearchResult>> search(SearchQuery query) async {
    final stopwatch = Stopwatch()..start();

    try {
      List<SearchResult> results;

      if (_useApi) {
        results = await _searchWithApi(query);
        // Se a API falhar ou retornar poucos resultados, usar scraping
        if (results.length < 3) {
          final scrapingResults = await _searchWithScraping(query);
          results.addAll(scrapingResults);
        }
      } else {
        results = await _searchWithScraping(query);
      }

      // Remover duplicatas e limitar resultados
      final uniqueResults =
          _removeDuplicates(results).take(query.maxResults).toList();

      stopwatch.stop();
      _updateMetrics(true, stopwatch.elapsedMilliseconds);

      AppLogger.info(
        'DuckDuckGo search completed: ${uniqueResults.length} results in ${stopwatch.elapsedMilliseconds}ms',
        'DuckDuckGoSearchStrategy',
      );

      return uniqueResults;
    } catch (e) {
      stopwatch.stop();
      _updateMetrics(false, stopwatch.elapsedMilliseconds);

      AppLogger.warning(
          'DuckDuckGo search failed: $e', 'DuckDuckGoSearchStrategy');
      rethrow;
    }
  }

  /// Busca usando a API do DuckDuckGo.
  Future<List<SearchResult>> _searchWithApi(SearchQuery query) async {
    final encodedQuery = Uri.encodeComponent(query.formattedQuery);
    final url =
        'https://api.duckduckgo.com/?q=$encodedQuery&format=json&no_html=1&skip_disambig=1';

    final response = await _client
        .get(
          Uri.parse(url),
          headers: _buildApiHeaders(),
        )
        .timeout(Duration(seconds: timeoutSeconds));

    if (response.statusCode != 200) {
      throw Exception('DuckDuckGo API failed: ${response.statusCode}');
    }

    return _parseApiResults(response.body, query.maxResults);
  }

  /// Busca usando scraping do DuckDuckGo.
  Future<List<SearchResult>> _searchWithScraping(SearchQuery query) async {
    final encodedQuery = Uri.encodeComponent(query.formattedQuery);
    final url = 'https://duckduckgo.com/html/?q=$encodedQuery';

    final response = await _client
        .get(
          Uri.parse(url),
          headers: _buildScrapingHeaders(),
        )
        .timeout(Duration(seconds: timeoutSeconds));

    if (response.statusCode != 200) {
      throw Exception('DuckDuckGo scraping failed: ${response.statusCode}');
    }

    return _parseScrapingResults(response.body, query.maxResults);
  }

  /// Constrói headers para API.
  Map<String, String> _buildApiHeaders() {
    return {
      'User-Agent': 'DuckDuckGo-Search-Client/1.0',
      'Accept': 'application/json',
      'Accept-Language': 'pt-BR,pt;q=0.9,en;q=0.8',
    };
  }

  /// Constrói headers para scraping.
  Map<String, String> _buildScrapingHeaders() {
    final random = math.Random();
    final userAgent = _userAgents[random.nextInt(_userAgents.length)];

    return {
      'User-Agent': userAgent,
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language': 'pt-BR,pt;q=0.9,en;q=0.8',
      'Accept-Encoding': 'gzip, deflate',
      'Connection': 'keep-alive',
      'Upgrade-Insecure-Requests': '1',
      'Cache-Control': 'no-cache',
    };
  }

  /// Faz parsing dos resultados da API.
  List<SearchResult> _parseApiResults(String jsonContent, int maxResults) {
    final results = <SearchResult>[];

    try {
      final data = json.decode(jsonContent) as Map<String, dynamic>;

      // Resultados relacionados
      final relatedTopics = data['RelatedTopics'] as List?;
      if (relatedTopics != null) {
        for (final topic in relatedTopics) {
          if (results.length >= maxResults) break;

          if (topic is Map<String, dynamic>) {
            final result = _extractApiResult(topic);
            if (result != null) {
              results.add(result);
            }
          }
        }
      }

      // Resposta abstrata
      final abstractText = data['Abstract'] as String?;
      final abstractUrl = data['AbstractURL'] as String?;
      if (abstractText != null &&
          abstractText.isNotEmpty &&
          abstractUrl != null &&
          abstractUrl.isNotEmpty) {
        results.insert(
            0,
            SearchResult(
              title: data['Heading'] as String? ?? 'DuckDuckGo Result',
              url: abstractUrl,
              snippet: abstractText,
              timestamp: DateTime.now(),
            ));
      }
    } catch (e) {
      AppLogger.debug('Error parsing DuckDuckGo API results: $e',
          'DuckDuckGoSearchStrategy');
    }

    return results;
  }

  /// Extrai resultado da API.
  SearchResult? _extractApiResult(Map<String, dynamic> topic) {
    final text = topic['Text'] as String?;
    final firstUrl = topic['FirstURL'] as String?;

    if (text == null || text.isEmpty || firstUrl == null || firstUrl.isEmpty) {
      return null;
    }

    // Extrair título do texto (geralmente a primeira parte antes do hífen)
    final parts = text.split(' - ');
    final title = parts.isNotEmpty ? parts.first : text;
    final snippet = parts.length > 1 ? parts.skip(1).join(' - ') : text;

    return SearchResult(
      title: _cleanText(title),
      url: firstUrl,
      snippet: _cleanText(snippet),
      timestamp: DateTime.now(),
    );
  }

  /// Faz parsing dos resultados do scraping.
  List<SearchResult> _parseScrapingResults(String htmlContent, int maxResults) {
    final document = html.parse(htmlContent);
    final results = <SearchResult>[];

    // Seletores para resultados do DuckDuckGo
    final resultElements = document.querySelectorAll('.result, .web-result');

    for (final element in resultElements) {
      if (results.length >= maxResults) break;

      try {
        final result = _extractScrapingResult(element);
        if (result != null) {
          results.add(result);
        }
      } catch (e) {
        AppLogger.debug('Error parsing DuckDuckGo scraping result: $e',
            'DuckDuckGoSearchStrategy');
        continue;
      }
    }

    return results;
  }

  /// Extrai resultado do scraping.
  SearchResult? _extractScrapingResult(dynamic element) {
    // Buscar título e link
    final titleElement = element.querySelector('.result__title a, .result__a');
    if (titleElement == null) return null;

    final url = titleElement.attributes['href'];
    if (url == null || !url.startsWith('http')) return null;

    final title = titleElement.text?.trim();
    if (title == null || title.isEmpty) return null;

    // Buscar snippet
    final snippetElement =
        element.querySelector('.result__snippet, .result__body');
    final snippet = snippetElement?.text?.trim() ?? '';

    return SearchResult(
      title: _cleanText(title),
      url: url,
      snippet: _cleanText(snippet),
      timestamp: DateTime.now(),
    );
  }

  /// Remove resultados duplicados.
  List<SearchResult> _removeDuplicates(List<SearchResult> results) {
    final seen = <String>{};
    return results.where((result) {
      final key = '${result.url}|${result.title}';
      if (seen.contains(key)) {
        return false;
      }
      seen.add(key);
      return true;
    }).toList();
  }

  /// Limpa e normaliza texto extraído.
  String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[\n\r\t]'), ' ')
        .replaceAll('...', '')
        .trim();
  }

  /// Atualiza métricas da estratégia.
  void _updateMetrics(bool success, int responseTimeMs) {
    final current = _metrics;
    final newTotal = current.totalSearches + 1;
    final newSuccessful =
        success ? current.successfulSearches + 1 : current.successfulSearches;
    final newAvgTime = ((current.averageResponseTime * current.totalSearches) +
            responseTimeMs) /
        newTotal;

    _metrics = SearchStrategyMetrics(
      totalSearches: newTotal,
      successfulSearches: newSuccessful,
      averageResponseTime: newAvgTime,
      lastUpdated: DateTime.now(),
    );
  }
}
