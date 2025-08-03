/// Estratégia de busca local que combina múltiplas fontes.
/// 
/// Implementa busca local usando scraping direto de múltiplos motores
/// com rotação de User-Agent e técnicas anti-detecção.
library;

import 'dart:async';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import '../../../domain/entities/search_result.dart';
import '../search_strategy.dart';
import '../../utils/logger.dart';

/// Estratégia de busca local com múltiplas fontes.
class LocalSearchStrategy implements SearchStrategy {
  final http.Client _client;
  final List<String> _userAgents;
  final List<SearchEngine> _engines;
  SearchStrategyMetrics _metrics = SearchStrategyMetrics.empty();
  
  /// User-Agents diversificados para evitar detecção.
  static const List<String> _defaultUserAgents = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Safari/605.1.15',
    'Mozilla/5.0 (X11; Linux x86_64; rv:121.0) Gecko/20100101 Firefox/121.0',
  ];

  /// Motores de busca configurados.
  static final List<SearchEngine> _defaultEngines = [
    SearchEngine(
      name: 'StartPage',
      baseUrl: 'https://www.startpage.com/sp/search',
      queryParam: 'query',
      resultSelector: '.w-gl__result',
      titleSelector: '.w-gl__result-title',
      urlSelector: '.w-gl__result-title',
      snippetSelector: '.w-gl__description',
      priority: 9,
    ),
    SearchEngine(
      name: 'Searx',
      baseUrl: 'https://searx.be/search',
      queryParam: 'q',
      resultSelector: '.result',
      titleSelector: '.result_title a',
      urlSelector: '.result_title a',
      snippetSelector: '.result-content',
      priority: 8,
    ),
    SearchEngine(
      name: 'Yandex',
      baseUrl: 'https://yandex.com/search/',
      queryParam: 'text',
      resultSelector: '.serp-item',
      titleSelector: '.organic__title-wrapper a',
      urlSelector: '.organic__title-wrapper a',
      snippetSelector: '.organic__text',
      priority: 7,
    ),
  ];

  LocalSearchStrategy({
    required http.Client client,
    List<String>? userAgents,
    List<SearchEngine>? engines,
  }) : _client = client,
       _userAgents = userAgents ?? _defaultUserAgents,
       _engines = engines ?? _defaultEngines;

  @override
  String get name => 'Local';

  @override
  int get priority => 6; // Prioridade média-baixa

  @override
  bool get isAvailable => true;

  @override
  int get timeoutSeconds => 15;

  @override
  SearchStrategyMetrics get metrics => _metrics;

  @override
  bool canHandle(SearchQuery query) {
    // Estratégia local funciona como fallback para qualquer consulta
    return query.query.trim().isNotEmpty;
  }

  @override
  Future<List<SearchResult>> search(SearchQuery query) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final allResults = <SearchResult>[];
      final engines = _engines.toList()..sort((a, b) => b.priority.compareTo(a.priority));
      
      // Buscar em paralelo nos motores disponíveis
      final futures = engines.take(2).map((engine) => 
          _searchEngine(engine, query).catchError((e) {
            AppLogger.debug('Engine ${engine.name} failed: $e', 'LocalSearchStrategy');
            return <SearchResult>[];
          })
      );
      
      final results = await Future.wait(futures);
      
      // Combinar e deduplificar resultados
      for (final engineResults in results) {
        allResults.addAll(engineResults);
      }
      
      final uniqueResults = _removeDuplicates(allResults)
          .take(query.maxResults)
          .toList();
      
      stopwatch.stop();
      _updateMetrics(true, stopwatch.elapsedMilliseconds);
      
      AppLogger.info(
        'Local search completed: ${uniqueResults.length} results in ${stopwatch.elapsedMilliseconds}ms',
        'LocalSearchStrategy',
      );
      
      return uniqueResults;
    } catch (e) {
      stopwatch.stop();
      _updateMetrics(false, stopwatch.elapsedMilliseconds);
      
      AppLogger.warning('Local search failed: $e', 'LocalSearchStrategy');
      rethrow;
    }
  }

  /// Busca em um motor específico.
  Future<List<SearchResult>> _searchEngine(SearchEngine engine, SearchQuery query) async {
    final encodedQuery = Uri.encodeComponent(query.formattedQuery);
    final url = '${engine.baseUrl}?${engine.queryParam}=$encodedQuery';

    final response = await _client.get(
      Uri.parse(url),
      headers: _buildHeaders(engine),
    ).timeout(Duration(seconds: timeoutSeconds ~/ 2));

    if (response.statusCode != 200) {
      throw Exception('${engine.name} search failed: ${response.statusCode}');
    }

    return _parseEngineResults(response.body, engine, query.maxResults ~/ 2);
  }

  /// Constrói headers otimizados para cada motor.
  Map<String, String> _buildHeaders(SearchEngine engine) {
    final random = math.Random();
    final userAgent = _userAgents[random.nextInt(_userAgents.length)];
    
    final headers = {
      'User-Agent': userAgent,
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language': 'pt-BR,pt;q=0.9,en;q=0.8',
      'Accept-Encoding': 'gzip, deflate',
      'Connection': 'keep-alive',
      'Upgrade-Insecure-Requests': '1',
      'Cache-Control': 'no-cache',
      'DNT': '1',
    };
    
    // Headers específicos por motor
    switch (engine.name.toLowerCase()) {
      case 'startpage':
        headers['Referer'] = 'https://www.startpage.com/';
        break;
      case 'searx':
        headers['Referer'] = 'https://searx.be/';
        break;
      case 'yandex':
        headers['Referer'] = 'https://yandex.com/';
        break;
    }
    
    return headers;
  }

  /// Faz parsing dos resultados de um motor específico.
  List<SearchResult> _parseEngineResults(String htmlContent, SearchEngine engine, int maxResults) {
    final document = html.parse(htmlContent);
    final results = <SearchResult>[];

    final resultElements = document.querySelectorAll(engine.resultSelector);
    
    for (final element in resultElements) {
      if (results.length >= maxResults) break;
      
      try {
        final result = _extractEngineResult(element, engine);
        if (result != null) {
          results.add(result);
        }
      } catch (e) {
        AppLogger.debug('Error parsing ${engine.name} result: $e', 'LocalSearchStrategy');
        continue;
      }
    }

    return results;
  }

  /// Extrai resultado de um motor específico.
  SearchResult? _extractEngineResult(dynamic element, SearchEngine engine) {
    // Buscar título e link
    final titleElement = element.querySelector(engine.titleSelector);
    if (titleElement == null) return null;
    
    final title = titleElement.text?.trim();
    if (title == null || title.isEmpty) return null;

    // Buscar URL
    final urlElement = element.querySelector(engine.urlSelector);
    final url = urlElement?.attributes['href'];
    if (url == null || url.isEmpty) return null;
    
    // Processar URL relativa
    final processedUrl = _processUrl(url, engine);
    if (processedUrl == null || !processedUrl.startsWith('http')) return null;

    // Buscar snippet
    final snippetElement = element.querySelector(engine.snippetSelector);
    final snippet = snippetElement?.text?.trim() ?? '';

    return SearchResult(
      title: _cleanText(title),
      url: processedUrl,
      snippet: _cleanText(snippet),
      timestamp: DateTime.now(),
    );
  }

  /// Processa URL extraída.
  String? _processUrl(String url, SearchEngine engine) {
    if (url.startsWith('http')) {
      return url;
    }
    
    // URL relativa
    if (url.startsWith('/')) {
      final uri = Uri.parse(engine.baseUrl);
      return '${uri.scheme}://${uri.host}$url';
    }
    
    // URL de redirecionamento (StartPage, etc.)
    if (url.contains('url=')) {
      final match = RegExp(r'url=([^&]+)').firstMatch(url);
      if (match != null) {
        return Uri.decodeComponent(match.group(1)!);
      }
    }
    
    return url;
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
    final newSuccessful = success ? current.successfulSearches + 1 : current.successfulSearches;
    final newAvgTime = ((current.averageResponseTime * current.totalSearches) + responseTimeMs) / newTotal;
    
    _metrics = SearchStrategyMetrics(
      totalSearches: newTotal,
      successfulSearches: newSuccessful,
      averageResponseTime: newAvgTime,
      lastUpdated: DateTime.now(),
    );
  }
}

/// Configuração de um motor de busca.
class SearchEngine {
  final String name;
  final String baseUrl;
  final String queryParam;
  final String resultSelector;
  final String titleSelector;
  final String urlSelector;
  final String snippetSelector;
  final int priority;

  const SearchEngine({
    required this.name,
    required this.baseUrl,
    required this.queryParam,
    required this.resultSelector,
    required this.titleSelector,
    required this.urlSelector,
    required this.snippetSelector,
    required this.priority,
  });
}