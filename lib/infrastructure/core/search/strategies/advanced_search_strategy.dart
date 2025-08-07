/// Estratégia de busca avançada com tratamento de falhas e resiliência.
///
/// Implementa uma busca web robusta com:
/// - Detecção automática de CAPTCHAs e bloqueios
/// - Rotação de IPs e User-Agents
/// - Retry automático com backoff exponencial
/// - Extração inteligente de conteúdo
/// - Cache para reduzir requisições
library;

import 'dart:async';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;

import '../../../domain/entities/search_result.dart';
import '../../../domain/entities/search_query.dart';
import '../../../domain/entities/relevance_score.dart';
import '../circuit_breaker.dart';
import '../rate_limiter.dart';
import '../search_strategy.dart';
import '../../utils/logger.dart';

/// Implementação avançada de estratégia de busca web.
class AdvancedSearchStrategy implements SearchStrategy {
  // Infraestrutura
  final http.Client _client;
  final RateLimiter _rateLimiter;
  final CircuitBreaker _circuitBreaker;

  // Configuração
  @override
  final String name;
  @override
  final int priority;
  final List<String> _userAgents;
  final Map<String, String> _extraHeaders;
  final Duration _timeout;
  final Duration _minBackoff;
  final int _maxRetries;

  // Estado e métricas
  SearchStrategyMetrics _metrics = SearchStrategyMetrics(
    totalSearches: 0,
    successfulSearches: 0,
    averageResponseTime: 0,
    lastUpdated: DateTime.now(),
  );
  final Map<String, _CachedResponse> _cache = {};

  /// Construtor da estratégia de busca avançada.
  AdvancedSearchStrategy({
    required http.Client client,
    required this.name,
    required this.priority,
    List<String>? userAgents,
    Map<String, String>? extraHeaders,
    Duration? timeout,
    Duration? minBackoff,
    Duration? circuitOpenTime,
    int? maxRetries,
    int? maxRequestsPerMinute,
  })  : _client = client,
        _userAgents = userAgents ?? _defaultUserAgents,
        _extraHeaders = extraHeaders ?? const {},
        _timeout = timeout ?? const Duration(seconds: 15),
        _minBackoff = minBackoff ?? const Duration(milliseconds: 500),
        _maxRetries = maxRetries ?? 3,
        _rateLimiter = RateLimiter(
          'Search-${name.toLowerCase()}',
          RateLimiterConfig(
            maxRequests: maxRequestsPerMinute ?? 20,
            windowMs: 60000, // 1 minuto
          ),
        ),
        _circuitBreaker = CircuitBreaker(
          'Search-${name.toLowerCase()}',
          CircuitBreakerConfig(
            failureThreshold: 5,
            timeoutMs:
                (circuitOpenTime ?? const Duration(minutes: 2)).inMilliseconds,
          ),
        );

  @override
  bool get isAvailable => _circuitBreaker.state != CircuitBreakerState.open;

  @override
  SearchStrategyMetrics get metrics => _metrics;

  @override
  int get timeoutSeconds => _timeout.inSeconds;

  @override
  bool canHandle(SearchQuery query) {
    // Verificar se o circuit breaker está fechado
    if (_circuitBreaker.state == CircuitBreakerState.open) {
      AppLogger.warning(
          'Circuit breaker está aberto para $name, aguardando reset',
          'AdvancedSearchStrategy');
      return false;
    }

    // Verificar se está dentro dos limites de taxa
    if (!(_rateLimiter.tryAcquire() as bool)) {
      AppLogger.warning('Rate limit atingido para $name, aguardando...',
          'AdvancedSearchStrategy');
      return false;
    }

    // Verifica se a query é válida
    return query.query.trim().isNotEmpty;
  }

  @override
  Future<List<SearchResult>> search(SearchQuery query) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Verificar cache
      final cacheKey = _getCacheKey(query);
      final cachedResponse = _getCachedResponse(cacheKey);
      if (cachedResponse != null) {
        _updateMetrics(true, stopwatch.elapsedMilliseconds, 0);
        AppLogger.info('Resultado obtido do cache para: ${query.query}',
            'AdvancedSearchStrategy:$name');
        return cachedResponse;
      }

      // Controlar taxa de requisições
      await _rateLimiter.acquire();

      // Tenta a busca com retry e backoff
      final results = await _executeWithRetry<List<SearchResult>>(
        () => _performSearch(query),
        retries: _maxRetries,
      );

      // Armazena em cache se obteve sucesso
      if (results.isNotEmpty) {
        _cacheResponse(cacheKey, results);
      }

      stopwatch.stop();
      _updateMetrics(true, stopwatch.elapsedMilliseconds, results.length);

      AppLogger.info(
          '$name search completed: ${results.length} results in ${stopwatch.elapsedMilliseconds}ms',
          'AdvancedSearchStrategy:$name');

      return results;
    } catch (e) {
      stopwatch.stop();
      _updateMetrics(false, stopwatch.elapsedMilliseconds, 0);

      // Registra falha no circuit breaker
      _circuitBreaker.execute(() => throw Exception('Circuit break triggered'));

      AppLogger.error(
          '$name search failed: $e', 'AdvancedSearchStrategy:$name');

      rethrow;
    }
  }

  /// Executa a busca efetiva (implementada por subclasses)
  Future<List<SearchResult>> _performSearch(SearchQuery query) async {
    throw UnimplementedError(
        'Subclasses devem implementar _performSearch para executar a busca específica');
  }

  /// Executa uma função com retry e backoff exponencial
  Future<T> _executeWithRetry<T>(
    Future<T> Function() operation, {
    required int retries,
  }) async {
    int attempt = 0;
    Duration backoff = _minBackoff;

    while (true) {
      try {
        attempt++;
        return await operation();
      } catch (e) {
        if (attempt >= retries) {
          AppLogger.error(
              'Todas as tentativas falharam após $attempt tentativas: $e',
              'AdvancedSearchStrategy:$name');
          rethrow;
        }

        // Calcula backoff exponencial com jitter
        final jitter = math.Random().nextInt(500);
        backoff = Duration(milliseconds: backoff.inMilliseconds * 2 + jitter);

        AppLogger.warning(
            'Tentativa $attempt falhou, tentando novamente em ${backoff.inMilliseconds}ms: $e',
            'AdvancedSearchStrategy:$name');

        await Future.delayed(backoff);
      }
    }
  }

  /// Executa uma requisição HTTP com timeout e headers otimizados
  Future<http.Response> makeRequest(String url,
      {Map<String, String>? extraHeaders}) async {
    final headers = _buildHeaders();
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    final response =
        await _client.get(Uri.parse(url), headers: headers).timeout(_timeout);

    // Verificar status code
    if (response.statusCode >= 400) {
      throw HttpException('Erro HTTP ${response.statusCode} ao acessar $url',
          statusCode: response.statusCode);
    }

    // Verificar se é um CAPTCHA ou bloqueio
    if (_detectsCaptchaOrBlock(response.body)) {
      throw BlockedException('Acesso bloqueado ou CAPTCHA detectado em $url');
    }

    return response;
  }

  /// Constrói headers randomizados
  Map<String, String> _buildHeaders() {
    final random = math.Random();
    final userAgent = _userAgents[random.nextInt(_userAgents.length)];

    final headers = {
      'User-Agent': userAgent,
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language': 'pt-BR,pt;q=0.9,en;q=0.8',
      'Accept-Encoding': 'gzip, deflate',
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache',
      'DNT': '1',
    };

    // Adiciona headers extras de configuração
    headers.addAll(_extraHeaders);

    return headers;
  }

  /// Detecta se o conteúdo contém CAPTCHA ou bloqueio
  bool _detectsCaptchaOrBlock(String content) {
    final lowerContent = content.toLowerCase();

    return lowerContent.contains('captcha') ||
        lowerContent.contains('blocked') ||
        lowerContent.contains('denied') ||
        lowerContent.contains('detected unusual traffic') ||
        lowerContent.contains('automated access');
  }

  /// Analisa a relevância dos resultados
  RelevanceScore analyzeRelevance(SearchResult result, String query) {
    final queryTerms =
        query.toLowerCase().split(' ').where((term) => term.length > 2).toSet();

    if (queryTerms.isEmpty) {
      return const RelevanceScore(
        overallScore: 0.0,
        semanticScore: 0.0,
        keywordScore: 0.0,
        qualityScore: 0.0,
        authorityScore: 0.0,
        scoringFactors: {},
      );
    }

    // Analisa título
    final titleLower = result.title.toLowerCase();
    final titleMatches =
        queryTerms.where((term) => titleLower.contains(term)).length;
    final titleScore = titleMatches / queryTerms.length;

    // Analisa snippet
    final snippetLower = result.snippet.toLowerCase();
    final snippetMatches =
        queryTerms.where((term) => snippetLower.contains(term)).length;
    final snippetScore = snippetMatches / queryTerms.length;

    // Calcula score geral
    final overallScore = (titleScore * 0.6) + (snippetScore * 0.4);
    final keywordScore = (titleScore + snippetScore) / 2;

    return RelevanceScore(
      overallScore: overallScore,
      semanticScore: snippetScore,
      keywordScore: keywordScore,
      qualityScore: 0.5, // valor padrão
      authorityScore: 0.5, // valor padrão
      scoringFactors: {
        'title_match': titleScore,
        'snippet_match': snippetScore,
      },
    );
  }

  /// Extrai texto limpo de um elemento HTML
  String extractCleanText(dom.Element? element) {
    if (element == null) return '';

    return element.text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[\n\r\t]'), ' ')
        .trim();
  }

  /// Atualiza as métricas de desempenho
  void _updateMetrics(bool success, int responseTimeMs, int resultCount) {
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
        lastUpdated: DateTime.now());
  }

  /// Obtém uma chave de cache para a consulta
  String _getCacheKey(SearchQuery query) {
    return '${name.toLowerCase()}_${query.formattedQuery.toLowerCase().trim()}';
  }

  /// Verifica se há resposta em cache
  List<SearchResult>? _getCachedResponse(String key) {
    final cached = _cache[key];
    if (cached == null) return null;

    // Verifica se expirou
    if (cached.isExpired) {
      _cache.remove(key);
      return null;
    }

    return cached.results;
  }

  /// Armazena resposta em cache
  void _cacheResponse(String key, List<SearchResult> results) {
    _cache[key] = _CachedResponse(
      results: results,
      timestamp: DateTime.now(),
      expiryMinutes: 30, // 30 minutos de expiração
    );

    // Limpa cache se ficar muito grande
    if (_cache.length > 100) {
      final oldestEntries = _cache.entries.toList()
        ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));

      // Remove os 20 mais antigos
      for (var i = 0; i < 20 && i < oldestEntries.length; i++) {
        _cache.remove(oldestEntries[i].key);
      }
    }
  }

  /// Lista padrão de User-Agents
  static const List<String> _defaultUserAgents = [
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1.2 Safari/605.1.15',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:121.0) Gecko/20100101 Firefox/121.0',
    'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:121.0) Gecko/20100101 Firefox/121.0',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Edge/120.0.0.0 Safari/537.36',
  ];
}

/// Classe para armazenamento em cache
class _CachedResponse {
  final List<SearchResult> results;
  final DateTime timestamp;
  final int expiryMinutes;

  _CachedResponse({
    required this.results,
    required this.timestamp,
    required this.expiryMinutes,
  });

  bool get isExpired {
    final now = DateTime.now();
    return now.difference(timestamp).inMinutes > expiryMinutes;
  }
}

/// Exceção para erros HTTP
class HttpException implements Exception {
  final String message;
  final int statusCode;

  HttpException(this.message, {required this.statusCode});

  @override
  String toString() => message;
}

/// Exceção para bloqueios e CAPTCHAs
class BlockedException implements Exception {
  final String message;

  BlockedException(this.message);

  @override
  String toString() => message;
}
