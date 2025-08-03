/// Estratégia de busca para Google com parsing otimizado.
///
/// Implementa busca no Google com técnicas avançadas de scraping,
/// rotação de User-Agents e parsing inteligente de resultados.
library;

import 'dart:async';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import '../../../domain/entities/search_result.dart';
import '../search_strategy.dart';
import '../../utils/logger.dart';

/// Estratégia de busca otimizada para Google.
class GoogleSearchStrategy implements SearchStrategy {
  final http.Client _client;
  final List<String> _userAgents;
  SearchStrategyMetrics _metrics = SearchStrategyMetrics.empty();

  /// User-Agents otimizados para Google.
  static const List<String> _defaultUserAgents = [
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1.2 Safari/605.1.15',
  ];

  GoogleSearchStrategy({
    required http.Client client,
    List<String>? userAgents,
  })  : _client = client,
        _userAgents = userAgents ?? _defaultUserAgents;

  @override
  String get name => 'Google';

  @override
  int get priority => 10; // Prioridade alta

  @override
  bool get isAvailable => true;

  @override
  int get timeoutSeconds => 15;

  @override
  SearchStrategyMetrics get metrics => _metrics;

  @override
  bool canHandle(SearchQuery query) {
    // Google pode lidar com qualquer tipo de consulta
    return query.query.trim().isNotEmpty;
  }

  @override
  Future<List<SearchResult>> search(SearchQuery query) async {
    final stopwatch = Stopwatch()..start();

    try {
      final encodedQuery = Uri.encodeComponent(query.formattedQuery);
      final url =
          'https://www.google.com/search?q=$encodedQuery&num=${query.maxResults}&hl=pt-BR';

      final response = await _client
          .get(
            Uri.parse(url),
            headers: _buildHeaders(),
          )
          .timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode != 200) {
        throw Exception('Google search failed: ${response.statusCode}');
      }

      final results = _parseGoogleResults(response.body, query.maxResults);

      stopwatch.stop();
      _updateMetrics(true, stopwatch.elapsedMilliseconds);

      AppLogger.info(
        'Google search completed: ${results.length} results in ${stopwatch.elapsedMilliseconds}ms',
        'GoogleSearchStrategy',
      );

      return results;
    } catch (e) {
      stopwatch.stop();
      _updateMetrics(false, stopwatch.elapsedMilliseconds);

      AppLogger.warning('Google search failed: $e', 'GoogleSearchStrategy');
      rethrow;
    }
  }

  /// Constrói headers otimizados para Google.
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
      'Pragma': 'no-cache',
      'DNT': '1',
    };
  }

  /// Faz parsing dos resultados do Google.
  List<SearchResult> _parseGoogleResults(String htmlContent, int maxResults) {
    final document = html.parse(htmlContent);
    final results = <SearchResult>[];

    // Seletores otimizados para resultados do Google
    final resultElements = document.querySelectorAll('div.g, div[data-ved]');

    for (final element in resultElements) {
      if (results.length >= maxResults) break;

      try {
        final result = _extractSearchResult(element);
        if (result != null) {
          results.add(result);
        }
      } catch (e) {
        AppLogger.debug(
            'Error parsing Google result: $e', 'GoogleSearchStrategy');
        continue;
      }
    }

    // Fallback para seletores alternativos se poucos resultados
    if (results.length < 3) {
      final fallbackElements =
          document.querySelectorAll('div.yuRUbf, div.kCrYT');

      for (final element in fallbackElements) {
        if (results.length >= maxResults) break;

        try {
          final result = _extractSearchResultFallback(element);
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

  /// Extrai um resultado de busca do elemento HTML.
  SearchResult? _extractSearchResult(dynamic element) {
    // Buscar link
    final linkElement = element.querySelector('a[href]');
    if (linkElement == null) return null;

    final url = linkElement.attributes['href'];
    if (url == null || !url.startsWith('http')) return null;

    // Buscar título
    final titleElement = linkElement.querySelector('h3') ??
        element.querySelector('h3') ??
        linkElement;
    final title = titleElement?.text?.trim();
    if (title == null || title.isEmpty) return null;

    // Buscar snippet
    final snippetElement =
        element.querySelector('span[data-ved], .VwiC3b, .s3v9rd, .st');
    final snippet = snippetElement?.text?.trim() ?? '';

    return SearchResult(
      title: _cleanText(title),
      url: url,
      snippet: _cleanText(snippet),
      timestamp: DateTime.now(),
    );
  }

  /// Extrai resultado usando seletores de fallback.
  SearchResult? _extractSearchResultFallback(dynamic element) {
    final linkElement = element.querySelector('a');
    if (linkElement == null) return null;

    final url = linkElement.attributes['href'];
    if (url == null || !url.startsWith('http')) return null;

    final title = linkElement.text?.trim();
    if (title == null || title.isEmpty) return null;

    // Buscar snippet no elemento pai
    final parent = element.parent;
    final snippetElement = parent?.querySelector('.VwiC3b, .s3v9rd');
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
