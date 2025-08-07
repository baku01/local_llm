/// Estratégia de busca para Bing com parsing otimizado.
///
/// Implementa busca no Bing com técnicas de scraping resilientes
/// e parsing específico para a estrutura HTML do Bing.
library;

import 'dart:async';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import '../../../../domain/entities/search_result.dart';
import '../../../../domain/entities/search_query.dart';
import '../search_strategy.dart';
import '../../utils/logger.dart';

/// Estratégia de busca otimizada para Bing.
class BingSearchStrategy implements SearchStrategy {
  final http.Client _client;
  final List<String> _userAgents;
  SearchStrategyMetrics _metrics = SearchStrategyMetrics.empty();

  /// User-Agents otimizados para Bing.
  static const List<String> _defaultUserAgents = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0',
  ];

  BingSearchStrategy({
    required http.Client client,
    List<String>? userAgents,
  })  : _client = client,
        _userAgents = userAgents ?? _defaultUserAgents;

  @override
  String get name => 'Bing';

  @override
  int get priority => 8; // Prioridade média-alta

  @override
  bool get isAvailable => true;

  @override
  int get timeoutSeconds => 12;

  @override
  SearchStrategyMetrics get metrics => _metrics;

  @override
  bool canHandle(SearchQuery query) {
    // Bing funciona bem com consultas gerais e de notícias
    return query.query.trim().isNotEmpty &&
        (query.type == SearchType.general || query.type == SearchType.news);
  }

  @override
  Future<List<SearchResult>> search(SearchQuery query) async {
    final stopwatch = Stopwatch()..start();

    try {
      final encodedQuery = Uri.encodeComponent(query.formattedQuery);
      final url =
          'https://www.bing.com/search?q=$encodedQuery&count=${query.maxResults}';

      final response = await _client
          .get(
            Uri.parse(url),
            headers: _buildHeaders(),
          )
          .timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode != 200) {
        throw Exception('Bing search failed: ${response.statusCode}');
      }

      final results = _parseBingResults(response.body, query.maxResults);

      stopwatch.stop();
      _updateMetrics(true, stopwatch.elapsedMilliseconds);

      AppLogger.info(
        'Bing search completed: ${results.length} results in ${stopwatch.elapsedMilliseconds}ms',
        'BingSearchStrategy',
      );

      return results;
    } catch (e) {
      stopwatch.stop();
      _updateMetrics(false, stopwatch.elapsedMilliseconds);

      AppLogger.warning('Bing search failed: $e', 'BingSearchStrategy');
      rethrow;
    }
  }

  /// Constrói headers otimizados para Bing.
  Map<String, String> _buildHeaders() {
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
      'Referer': 'https://www.bing.com/',
    };
  }

  /// Faz parsing dos resultados do Bing.
  List<SearchResult> _parseBingResults(String htmlContent, int maxResults) {
    final document = html.parse(htmlContent);
    final results = <SearchResult>[];

    // Seletores principais para resultados do Bing
    final resultElements = document.querySelectorAll('li.b_algo, .b_algo');

    for (final element in resultElements) {
      if (results.length >= maxResults) break;

      try {
        final result = _extractBingResult(element);
        if (result != null) {
          results.add(result);
        }
      } catch (e) {
        AppLogger.debug('Error parsing Bing result: $e', 'BingSearchStrategy');
        continue;
      }
    }

    // Fallback para seletores alternativos
    if (results.length < 3) {
      final fallbackElements =
          document.querySelectorAll('.b_title, .b_topTitle');

      for (final element in fallbackElements) {
        if (results.length >= maxResults) break;

        try {
          final result = _extractBingResultFallback(element);
          if (result != null && !_isDuplicate(result, results)) {
            results.add(result);
          }
        } catch (e) {
          continue;
        }
      }
    }

    return results;
  }

  /// Extrai um resultado de busca do elemento HTML do Bing.
  SearchResult? _extractBingResult(dynamic element) {
    // Buscar título e link
    final titleElement = element.querySelector('h2 a, .b_title a, a[href]');
    if (titleElement == null) return null;

    final url = titleElement.attributes['href'];
    if (url == null || !url.startsWith('http')) return null;

    final title = titleElement.text?.trim();
    if (title == null || title.isEmpty) return null;

    // Buscar snippet
    final snippetElement =
        element.querySelector('.b_caption p, .b_snippet, .b_descript');
    final snippet = snippetElement?.text?.trim() ?? '';

    return SearchResult(
      title: _cleanText(title),
      url: url,
      snippet: _cleanText(snippet),
      timestamp: DateTime.now(),
    );
  }

  /// Extrai resultado usando seletores de fallback para Bing.
  SearchResult? _extractBingResultFallback(dynamic element) {
    final linkElement = element.querySelector('a');
    if (linkElement == null) return null;

    final url = linkElement.attributes['href'];
    if (url == null || !url.startsWith('http')) return null;

    final title = linkElement.text?.trim();
    if (title == null || title.isEmpty) return null;

    // Buscar snippet no elemento pai ou irmão
    final parent = element.parent;
    final snippetElement = parent?.querySelector('.b_caption, .b_snippet') ??
        element.nextElementSibling?.querySelector('.b_caption');
    final snippet = snippetElement?.text?.trim() ?? '';

    return SearchResult(
      title: _cleanText(title),
      url: url,
      snippet: _cleanText(snippet),
      timestamp: DateTime.now(),
    );
  }

  /// Limpa e normaliza texto extraído.
  String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[\n\r\t]'), ' ')
        .replaceAll('...', '')
        .trim();
  }

  /// Verifica se o resultado é duplicado.
  bool _isDuplicate(SearchResult result, List<SearchResult> existingResults) {
    return existingResults.any((existing) =>
        existing.url == result.url || existing.title == result.title);
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
