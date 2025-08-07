/// DataSource inteligente para pesquisas web com análise de relevância avançada.
///
/// Implementa um sistema robusto de web scraping que integra múltiplos provedores
/// de busca com análise automática de relevância, filtragem de qualidade e
/// otimizações para obter resultados mais precisos e úteis.
library;

import 'dart:async';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

import '../../core/utils/relevance_analyzer.dart';
import '../../core/utils/text_processor.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/entities/search_query.dart';
import 'web_search_datasource.dart';

/// Configuração para o datasource inteligente.
class IntelligentSearchConfig {
  /// Número máximo de resultados por provedor.
  final int maxResultsPerProvider;

  /// Threshold mínimo de relevância para incluir resultado.
  final double minRelevanceThreshold;

  /// Se deve buscar conteúdo completo das páginas.
  final bool fetchFullContent;

  /// Timeout para requisições HTTP em segundos.
  final int requestTimeoutSeconds;

  /// Se deve usar cache para resultados.
  final bool enableCaching;

  /// Tempo de vida do cache em minutos.
  final int cacheLifetimeMinutes;

  const IntelligentSearchConfig({
    this.maxResultsPerProvider = 5,
    this.minRelevanceThreshold = 0.4,
    this.fetchFullContent = true,
    this.requestTimeoutSeconds = 15,
    this.enableCaching = true,
    this.cacheLifetimeMinutes = 30,
  });
}

/// DataSource inteligente que combina múltiplos provedores com análise de relevância.
///
/// Características principais:
/// - Múltiplos provedores de busca com análise de relevância
/// - Extração e análise de conteúdo completo das páginas
/// - Sistema de cache inteligente para otimização
/// - Filtragem automática de resultados de baixa qualidade
/// - Detecção e remoção de spam/conteúdo duplicado
/// - Análise de autoridade da fonte
class IntelligentWebSearchDataSource implements WebSearchDataSource {
  final http.Client _client;
  final RelevanceAnalyzer _relevanceAnalyzer;
  final TextProcessor _textProcessor;
  final IntelligentSearchConfig _config;

  /// Cache de resultados para otimização.
  final Map<String, _CachedSearchResult> _cache = {};

  /// Lista de User-Agents otimizada para evitar bloqueios.
  final List<String> _userAgents = [
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1.2 Safari/605.1.15',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:121.0) Gecko/20100101 Firefox/121.0',
  ];

  IntelligentWebSearchDataSource({
    required http.Client client,
    IntelligentSearchConfig? config,
  })  : _client = client,
        _config = config ?? const IntelligentSearchConfig(),
        _relevanceAnalyzer = RelevanceAnalyzer(),
        _textProcessor = TextProcessor();

  /// Retorna um User-Agent aleatório para evitar detecção.
  String get _randomUserAgent =>
      _userAgents[math.Random().nextInt(_userAgents.length)];

  @override
  Future<List<SearchResult>> search(SearchQuery query) async {
    try {
      AppLogger.info('Iniciando pesquisa inteligente para: "${query.query}"',
          'IntelligentWebSearch');

      // Verificar cache primeiro
      if (_config.enableCaching) {
        final cached = _getCachedResult(query.query);
        if (cached != null) {
          AppLogger.info(
              'Resultado encontrado no cache', 'IntelligentWebSearch');
          return cached;
        }
      }

      // Executar pesquisas em paralelo
      final futures = <Future<List<SearchResult>>>[
        _searchGoogle(query),
        _searchBing(query),
        _searchDuckDuckGo(query),
      ];

      final allResults = await Future.wait(futures, eagerError: false);

      // Combinar resultados e remover duplicados
      final combinedResults = _combineAndDeduplicateResults(allResults);

      if (combinedResults.isEmpty) {
        AppLogger.warning('Nenhum resultado encontrado para: "${query.query}"',
            'IntelligentWebSearch');
        return [];
      }

      // Buscar conteúdo completo se habilitado
      List<SearchResult> enrichedResults = combinedResults;
      if (_config.fetchFullContent) {
        enrichedResults = await _enrichWithFullContent(combinedResults);
      }

      // Analisar relevância de todos os resultados
      final analyzedResults =
          await _analyzeRelevance(enrichedResults, query.query);

      // Filtrar por relevância mínima
      final filteredResults = analyzedResults
          .where((result) =>
              result.overallRelevance >= _config.minRelevanceThreshold)
          .toList();

      // Ordenar por relevância
      filteredResults
          .sort((a, b) => b.overallRelevance.compareTo(a.overallRelevance));

      // Limitar número de resultados
      final finalResults = filteredResults.take(query.maxResults).toList();

      // Cachear resultado
      if (_config.enableCaching && finalResults.isNotEmpty) {
        _cacheResult(query.query, finalResults);
      }

      AppLogger.info(
          'Pesquisa concluída: ${finalResults.length} resultados relevantes',
          'IntelligentWebSearch');
      return finalResults;
    } catch (e, stackTrace) {
      AppLogger.error('Erro na pesquisa inteligente', 'IntelligentWebSearch', e,
          stackTrace);
      return [];
    }
  }

  /// Pesquisa no Google com parsing avançado.
  Future<List<SearchResult>> _searchGoogle(SearchQuery query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query.formattedQuery);
      final url =
          'https://www.google.com/search?q=$encodedQuery&num=${_config.maxResultsPerProvider}&hl=pt-BR';

      final response = await _client
          .get(
            Uri.parse(url),
            headers: _buildHeaders(),
          )
          .timeout(Duration(seconds: _config.requestTimeoutSeconds));

      if (response.statusCode != 200) {
        AppLogger.warning('Google search failed: ${response.statusCode}',
            'IntelligentWebSearch');
        return [];
      }

      return _parseGoogleResults(response.body);
    } catch (e) {
      AppLogger.warning('Erro no Google search: $e', 'IntelligentWebSearch');
      return [];
    }
  }

  /// Pesquisa no Bing com parsing avançado.
  Future<List<SearchResult>> _searchBing(SearchQuery query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query.formattedQuery);
      final url =
          'https://www.bing.com/search?q=$encodedQuery&count=${_config.maxResultsPerProvider}';

      final response = await _client
          .get(
            Uri.parse(url),
            headers: _buildHeaders(),
          )
          .timeout(Duration(seconds: _config.requestTimeoutSeconds));

      if (response.statusCode != 200) {
        AppLogger.warning('Bing search failed: ${response.statusCode}',
            'IntelligentWebSearch');
        return [];
      }

      return _parseBingResults(response.body);
    } catch (e) {
      AppLogger.warning('Erro no Bing search: $e', 'IntelligentWebSearch');
      return [];
    }
  }

  /// Pesquisa no DuckDuckGo com parsing avançado.
  Future<List<SearchResult>> _searchDuckDuckGo(SearchQuery query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query.formattedQuery);
      final url = 'https://html.duckduckgo.com/html/?q=$encodedQuery';

      final response = await _client
          .get(
            Uri.parse(url),
            headers: _buildHeaders(),
          )
          .timeout(Duration(seconds: _config.requestTimeoutSeconds));

      if (response.statusCode != 200) {
        AppLogger.warning('DuckDuckGo search failed: ${response.statusCode}',
            'IntelligentWebSearch');
        return [];
      }

      return _parseDuckDuckGoResults(response.body);
    } catch (e) {
      AppLogger.warning(
          'Erro no DuckDuckGo search: $e', 'IntelligentWebSearch');
      return [];
    }
  }

  /// Constrói headers HTTP otimizados.
  Map<String, String> _buildHeaders() {
    return {
      'User-Agent': _randomUserAgent,
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Accept-Language': 'pt-BR,pt;q=0.9,en;q=0.8,en-US;q=0.7',
      'Accept-Encoding': 'gzip, deflate, br',
      'Connection': 'keep-alive',
      'Upgrade-Insecure-Requests': '1',
      'Sec-Fetch-Dest': 'document',
      'Sec-Fetch-Mode': 'navigate',
      'Sec-Fetch-Site': 'none',
      'Cache-Control': 'max-age=0',
    };
  }

  /// Parse melhorado dos resultados do Google.
  List<SearchResult> _parseGoogleResults(String html) {
    final document = html_parser.parse(html);
    final results = <SearchResult>[];

    // Seletores otimizados para resultados do Google
    final searchResults =
        document.querySelectorAll('div.g, div[data-ved], .rc');

    for (final element in searchResults) {
      try {
        final titleElement = element.querySelector('h3, .LC20lb, .DKV0Md') ??
            element.querySelector('a h3');
        final linkElement =
            element.querySelector('a[href^="http"], a[href^="/url"]') ??
                element.querySelector('a');
        final snippetElement =
            element.querySelector('.VwiC3b, .s3v9rd, .hgKElc, .IsZvec') ??
                element.querySelector('.st');

        if (titleElement != null && linkElement != null) {
          String url = linkElement.attributes['href'] ?? '';

          // Limpar URLs do Google
          url = _cleanGoogleUrl(url);

          if (url.startsWith('http') &&
              !url.contains('google.com') &&
              !_isAdUrl(url)) {
            final title = _textProcessor.processText(titleElement.text);
            final snippet =
                _textProcessor.processText(snippetElement?.text ?? '');

            if (title.isNotEmpty && title.length > 5) {
              results.add(SearchResult(
                title: title,
                url: url,
                snippet: snippet,
                timestamp: DateTime.now(),
                metadata: {'source': 'google'},
              ));
            }
          }
        }
      } catch (e) {
        AppLogger.debug('Erro ao processar resultado do Google: $e',
            'IntelligentWebSearch');
        continue;
      }
    }

    return results;
  }

  /// Parse melhorado dos resultados do Bing.
  List<SearchResult> _parseBingResults(String html) {
    final document = html_parser.parse(html);
    final results = <SearchResult>[];

    final searchResults = document.querySelectorAll('.b_algo, .b_algo_group');

    for (final element in searchResults) {
      try {
        final titleElement = element.querySelector('h2 a, .b_title a');
        final snippetElement =
            element.querySelector('.b_caption p, .b_snippet');

        if (titleElement != null) {
          final url = titleElement.attributes['href'] ?? '';

          if (url.startsWith('http') &&
              !url.contains('bing.com') &&
              !_isAdUrl(url)) {
            final title = _textProcessor.processText(titleElement.text);
            final snippet =
                _textProcessor.processText(snippetElement?.text ?? '');

            if (title.isNotEmpty && title.length > 5) {
              results.add(SearchResult(
                title: title,
                url: url,
                snippet: snippet,
                timestamp: DateTime.now(),
                metadata: {'source': 'bing'},
              ));
            }
          }
        }
      } catch (e) {
        AppLogger.debug(
            'Erro ao processar resultado do Bing: $e', 'IntelligentWebSearch');
        continue;
      }
    }

    return results;
  }

  /// Parse melhorado dos resultados do DuckDuckGo.
  List<SearchResult> _parseDuckDuckGoResults(String html) {
    final document = html_parser.parse(html);
    final results = <SearchResult>[];

    final searchResults = document.querySelectorAll('.result, .web-result');

    for (final element in searchResults) {
      try {
        final titleElement =
            element.querySelector('.result__title a, .result__a');
        final snippetElement =
            element.querySelector('.result__snippet, .result__body');

        if (titleElement != null) {
          final url = titleElement.attributes['href'] ?? '';

          if (url.startsWith('http') && !_isAdUrl(url)) {
            final title = _textProcessor.processText(titleElement.text);
            final snippet =
                _textProcessor.processText(snippetElement?.text ?? '');

            if (title.isNotEmpty && title.length > 5) {
              results.add(SearchResult(
                title: title,
                url: url,
                snippet: snippet,
                timestamp: DateTime.now(),
                metadata: {'source': 'duckduckgo'},
              ));
            }
          }
        }
      } catch (e) {
        AppLogger.debug('Erro ao processar resultado do DuckDuckGo: $e',
            'IntelligentWebSearch');
        continue;
      }
    }

    return results;
  }

  /// Combina e deduplica resultados de múltiplas fontes.
  List<SearchResult> _combineAndDeduplicateResults(
      List<List<SearchResult>> allResults) {
    final seen = <String>{};
    final combined = <SearchResult>[];

    for (final resultList in allResults) {
      for (final result in resultList) {
        final normalizedUrl = _normalizeUrl(result.url);
        if (!seen.contains(normalizedUrl) && normalizedUrl.isNotEmpty) {
          seen.add(normalizedUrl);
          combined.add(result);
        }
      }
    }

    return combined;
  }

  /// Enriquece resultados com conteúdo completo das páginas.
  Future<List<SearchResult>> _enrichWithFullContent(
      List<SearchResult> results) async {
    final enrichedResults = <SearchResult>[];

    for (final result in results) {
      try {
        final content = await fetchPageContent(result.url);
        enrichedResults.add(result.copyWith(content: content));
      } catch (e) {
        AppLogger.debug('Erro ao buscar conteúdo de ${result.url}: $e',
            'IntelligentWebSearch');
        enrichedResults.add(result); // Manter resultado original
      }
    }

    return enrichedResults;
  }

  /// Analisa relevância de todos os resultados.
  Future<List<SearchResult>> _analyzeRelevance(
      List<SearchResult> results, String query) async {
    final analyzedResults = <SearchResult>[];

    for (final result in results) {
      final relevanceScore = _relevanceAnalyzer.analyzeRelevance(
        query: query,
        title: result.title,
        snippet: result.snippet,
        url: result.url,
        content: result.content,
      );

      analyzedResults.add(result.copyWith(relevanceScore: relevanceScore));
    }

    return analyzedResults;
  }

  @override
  Future<String> fetchPageContent(String url) async {
    try {
      final response = await _client
          .get(
            Uri.parse(url),
            headers: _buildHeaders(),
          )
          .timeout(Duration(seconds: _config.requestTimeoutSeconds));

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final document = html_parser.parse(response.body);

      // Remover elementos desnecessários
      document
          .querySelectorAll(
              'script, style, nav, header, footer, aside, .ads, .advertisement, '
              '.sidebar, .menu, .navigation, .comments, .social, .share')
          .forEach((element) => element.remove());

      // Extrair conteúdo principal
      dom.Element? mainContent = document.querySelector(
          'main, article, .content, .post, .entry, .article-body, '
          '[role="main"], .main-content');

      mainContent ??= document.querySelector('body');

      if (mainContent == null) return '';

      final textContent = mainContent.text;

      // Processar e limitar conteúdo
      final processedContent =
          _textProcessor.processText(textContent, preserveStructure: true);

      const maxLength = 5000;
      if (processedContent.length > maxLength) {
        // Extrair sentenças principais
        final keySentences = _textProcessor
            .extractKeySentences(processedContent, maxSentences: 10);
        return keySentences.join(' ');
      }

      return processedContent;
    } catch (e) {
      AppLogger.debug(
          'Erro ao buscar conteúdo de $url: $e', 'IntelligentWebSearch');
      return '';
    }
  }

  /// Limpa URLs do Google removendo parâmetros de redirecionamento.
  String _cleanGoogleUrl(String url) {
    if (url.startsWith('/url?')) {
      final uri = Uri.parse('https://google.com$url');
      return uri.queryParameters['url'] ?? url;
    }
    return url;
  }

  /// Normaliza URL para comparação.
  String _normalizeUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return '${uri.scheme}://${uri.host}${uri.path}';
    } catch (e) {
      return url;
    }
  }

  /// Detecta URLs de anúncios.
  bool _isAdUrl(String url) {
    final adIndicators = [
      'googleadservices',
      'doubleclick',
      'googlesyndication',
      'ads.',
      '/ads/',
      'advertisement',
      'sponsored'
    ];
    return adIndicators
        .any((indicator) => url.toLowerCase().contains(indicator));
  }

  /// Obtém resultado do cache se válido.
  List<SearchResult>? _getCachedResult(String query) {
    final cached = _cache[query.toLowerCase()];
    if (cached != null && !cached.isExpired) {
      return cached.results;
    }
    _cache.remove(query.toLowerCase());
    return null;
  }

  /// Armazena resultado no cache.
  void _cacheResult(String query, List<SearchResult> results) {
    _cache[query.toLowerCase()] = _CachedSearchResult(
      results: results,
      timestamp: DateTime.now(),
      lifetimeMinutes: _config.cacheLifetimeMinutes,
    );
  }
}

/// Resultado de pesquisa em cache.
class _CachedSearchResult {
  final List<SearchResult> results;
  final DateTime timestamp;
  final int lifetimeMinutes;

  _CachedSearchResult({
    required this.results,
    required this.timestamp,
    required this.lifetimeMinutes,
  });

  bool get isExpired {
    final expiry = timestamp.add(Duration(minutes: lifetimeMinutes));
    return DateTime.now().isAfter(expiry);
  }
}
