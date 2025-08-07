/// Serviço de busca inteligente que integra classificação de qualidade e tomada de decisão.
///
/// Este serviço combina múltiplas estratégias de busca com análise de qualidade avançada
/// para fornecer respostas apenas quando as informações coletadas são consideradas
/// satisfatórias e confiáveis.
library;

import 'dart:async';
import 'dart:math' as math;
import '../../domain/entities/search_result.dart';
import '../../domain/entities/search_query.dart';
import '../../domain/entities/relevance_score.dart';
import '../../infrastructure/datasources/intelligent_web_search_datasource.dart';
import '../classification/quality_classifier.dart';
import '../classification/response_decision_engine.dart';
import '../utils/relevance_analyzer.dart';
import 'package:http/http.dart' as http;

/// Configuração do serviço de busca inteligente.
class IntelligentSearchConfig {
  final int maxSearchAttempts;
  final int maxResultsPerAttempt;
  final Duration timeoutPerAttempt;
  final DecisionStrategy decisionStrategy;
  final double minConfidenceThreshold;
  final bool enableAdaptiveLearning;
  final bool enableCaching;
  final List<String> preferredDomains;
  final List<String> blockedDomains;

  const IntelligentSearchConfig({
    this.maxSearchAttempts = 3,
    this.maxResultsPerAttempt = 10,
    this.timeoutPerAttempt = const Duration(seconds: 30),
    this.decisionStrategy = DecisionStrategy.balanced,
    this.minConfidenceThreshold = 0.6,
    this.enableAdaptiveLearning = true,
    this.enableCaching = true,
    this.preferredDomains = const [],
    this.blockedDomains = const [],
  });
}

/// Resultado da busca inteligente com informações de qualidade.
class IntelligentSearchResult {
  final bool canProvideAnswer;
  final double confidenceLevel;
  final String reasoning;
  final List<SearchResult> selectedResults;
  final QualityAssessment qualityAssessment;
  final ResponseDecision decision;
  final Map<String, dynamic> searchMetrics;
  final Duration totalSearchTime;
  final int attemptsUsed;

  const IntelligentSearchResult({
    required this.canProvideAnswer,
    required this.confidenceLevel,
    required this.reasoning,
    required this.selectedResults,
    required this.qualityAssessment,
    required this.decision,
    required this.searchMetrics,
    required this.totalSearchTime,
    required this.attemptsUsed,
  });

  /// Indica se é uma resposta de alta qualidade.
  bool get isHighQuality => canProvideAnswer && confidenceLevel >= 0.8;

  /// Indica se é uma resposta com ressalvas.
  bool get isQualifiedAnswer =>
      canProvideAnswer && confidenceLevel >= 0.6 && confidenceLevel < 0.8;

  /// Indica se deve sugerir busca adicional.
  bool get suggestAdditionalSearch =>
      !canProvideAnswer || confidenceLevel < 0.7;

  @override
  String toString() => 'IntelligentSearchResult('
      'canAnswer: $canProvideAnswer, '
      'confidence: ${confidenceLevel.toStringAsFixed(3)}, '
      'attempts: $attemptsUsed, '
      'time: ${totalSearchTime.inMilliseconds}ms)';
}

/// Métricas de desempenho da busca.
class SearchMetrics {
  final int totalQueries;
  final int successfulQueries;
  final int rejectedQueries;
  final double averageConfidence;
  final Duration averageSearchTime;
  final Map<QueryType, int> queryTypeDistribution;
  final Map<DecisionStrategy, double> strategyPerformance;

  const SearchMetrics({
    required this.totalQueries,
    required this.successfulQueries,
    required this.rejectedQueries,
    required this.averageConfidence,
    required this.averageSearchTime,
    required this.queryTypeDistribution,
    required this.strategyPerformance,
  });

  double get successRate =>
      totalQueries > 0 ? successfulQueries / totalQueries : 0.0;
  double get rejectionRate =>
      totalQueries > 0 ? rejectedQueries / totalQueries : 0.0;
}

/// Serviço principal de busca inteligente.
class IntelligentSearchService {
  final IntelligentWebSearchDataSource _searchDataSource;
  final QualityClassifier _qualityClassifier;
  final ResponseDecisionEngine _decisionEngine;
  final RelevanceAnalyzer _relevanceAnalyzer;
  final IntelligentSearchConfig _config;
  final http.Client _httpClient;

  /// Cache de resultados para consultas similares.
  final Map<String, IntelligentSearchResult> _resultCache = {};

  /// Histórico de métricas para análise de desempenho.
  final List<IntelligentSearchResult> _searchHistory = [];

  /// Controlador para timeouts.
  Timer? _searchTimeoutTimer;

  IntelligentSearchService({
    IntelligentWebSearchDataSource? searchDataSource,
    QualityClassifier? qualityClassifier,
    ResponseDecisionEngine? decisionEngine,
    RelevanceAnalyzer? relevanceAnalyzer,
    IntelligentSearchConfig? config,
  })  : _httpClient = http.Client(),
        _searchDataSource = searchDataSource ??
            IntelligentWebSearchDataSource(client: http.Client()),
        _qualityClassifier = qualityClassifier ?? QualityClassifier(),
        _decisionEngine = decisionEngine ?? ResponseDecisionEngine(),
        _relevanceAnalyzer = relevanceAnalyzer ?? RelevanceAnalyzer(),
        _config = config ?? const IntelligentSearchConfig();

  /// Realiza busca inteligente com análise de qualidade.
  ///
  /// [query] - Consulta do usuário
  /// [context] - Contexto adicional da consulta
  /// [forceSearch] - Força nova busca ignorando cache
  ///
  /// Returns: [IntelligentSearchResult] com decisão sobre responder
  Future<IntelligentSearchResult> searchIntelligently({
    required String query,
    QueryContext? context,
    bool forceSearch = false,
  }) async {
    final startTime = DateTime.now();
    final searchMetrics = <String, dynamic>{};

    try {
      // 1. Verificar cache se habilitado
      if (_config.enableCaching && !forceSearch) {
        final cachedResult = _getCachedResult(query);
        if (cachedResult != null) {
          searchMetrics['cache_hit'] = true;
          return cachedResult;
        }
      }

      // 2. Identificar tipo de consulta se não fornecido no contexto
      final queryType =
          context?.queryType ?? _qualityClassifier.identifyQueryType(query);

      final searchContext = context ??
          QueryContext(
            originalQuery: query,
            queryType: queryType,
          );

      // 3. Realizar busca iterativa com melhoria de qualidade
      final searchResult = await _performIterativeSearch(
        query,
        searchContext,
        searchMetrics,
      );

      // 4. Calcular tempo total
      final totalTime = DateTime.now().difference(startTime);
      final finalResult = IntelligentSearchResult(
        canProvideAnswer: searchResult.canProvideAnswer,
        confidenceLevel: searchResult.confidenceLevel,
        reasoning: searchResult.reasoning,
        selectedResults: searchResult.selectedResults,
        qualityAssessment: searchResult.qualityAssessment,
        decision: searchResult.decision,
        searchMetrics: {
          ...searchResult.searchMetrics,
          ...searchMetrics,
          'query_type': queryType.name,
          'decision_strategy': _config.decisionStrategy.name,
        },
        totalSearchTime: totalTime,
        attemptsUsed: searchResult.attemptsUsed,
      );

      // 5. Salvar no cache e histórico
      if (_config.enableCaching) {
        _cacheResult(query, finalResult);
      }
      _recordSearchResult(finalResult);

      return finalResult;
    } catch (e) {
      // Retornar resultado de erro
      final totalTime = DateTime.now().difference(startTime);
      return IntelligentSearchResult(
        canProvideAnswer: false,
        confidenceLevel: 0.0,
        reasoning: 'Erro durante a busca: $e',
        selectedResults: [],
        qualityAssessment: QualityAssessment(
          isSatisfactory: false,
          confidenceScore: 0.0,
          coverageScore: 0.0,
          authorityScore: 0.0,
          contentDepthScore: 0.0,
          sourceDiversityCount: 0,
          qualityIssues: ['Erro técnico durante a busca'],
          strengths: [],
          recommendation: 'Tentar novamente mais tarde',
        ),
        decision: ResponseDecision(
          shouldRespond: false,
          confidenceLevel: 0.0,
          reasoning: 'Falha técnica',
          recommendations: ['Verificar conectividade', 'Tentar novamente'],
          selectedResults: [],
          qualityAssessment: QualityAssessment(
            isSatisfactory: false,
            confidenceScore: 0.0,
            coverageScore: 0.0,
            authorityScore: 0.0,
            contentDepthScore: 0.0,
            sourceDiversityCount: 0,
            qualityIssues: [],
            strengths: [],
            recommendation: '',
          ),
          metadata: {'error': e.toString()},
        ),
        searchMetrics: {'error': e.toString()},
        totalSearchTime: totalTime,
        attemptsUsed: 0,
      );
    }
  }

  /// Realiza busca iterativa melhorando a qualidade a cada tentativa.
  Future<IntelligentSearchResult> _performIterativeSearch(
    String query,
    QueryContext context,
    Map<String, dynamic> searchMetrics,
  ) async {
    QualityAssessment? bestAssessment;
    ResponseDecision? bestDecision;
    List<SearchResult>? bestResults;

    for (int attempt = 1; attempt <= _config.maxSearchAttempts; attempt++) {
      try {
        // Configurar timeout para esta tentativa
        _setupSearchTimeout();

        // Ajustar consulta para tentativas subsequentes
        final adjustedQuery =
            _adjustQueryForAttempt(query, attempt, bestAssessment);

        searchMetrics['attempt_$attempt'] = {
          'query': adjustedQuery,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };

        // Realizar busca
        final searchQuery = SearchQuery(
          query: adjustedQuery,
          maxResults: _config.maxResultsPerAttempt,
        );
        final results = await _searchDataSource.search(searchQuery);

        // Filtrar domínios bloqueados
        final filteredResults = _filterResults(results);

        if (filteredResults.isEmpty) {
          searchMetrics['attempt_$attempt']['no_results'] = true;
          continue;
        }

        // Analisar relevância
        final relevanceScores =
            await _analyzeRelevance(adjustedQuery, filteredResults);

        // Avaliar qualidade
        final assessment = _qualityClassifier.classifyQuality(
          query: adjustedQuery,
          results: filteredResults,
          relevanceScores: relevanceScores,
          queryType: context.queryType,
        );

        // Tomar decisão
        final updatedContext = QueryContext(
          originalQuery: query,
          queryType: context.queryType,
          attemptNumber: attempt,
          previousQueries: context.previousQueries,
          userExpertiseLevel: context.userExpertiseLevel,
          isUrgent: context.isUrgent,
          preferredSources: context.preferredSources,
        );

        final decision = _decisionEngine.makeDecision(
          query: adjustedQuery,
          results: filteredResults,
          relevanceScores: relevanceScores,
          context: updatedContext,
        );

        searchMetrics['attempt_$attempt'].addAll({
          'results_count': filteredResults.length,
          'quality_score': assessment.confidenceScore,
          'decision': decision.shouldRespond,
          'confidence': decision.confidenceLevel,
        });

        // Verificar se é melhor que tentativas anteriores
        if (_isBetterResult(decision, bestDecision)) {
          bestResults = filteredResults;
          bestAssessment = assessment;
          bestDecision = decision;
        }

        // Verificar se atingiu qualidade satisfatória
        if (decision.shouldRespond &&
            decision.confidenceLevel >= _config.minConfidenceThreshold) {
          searchMetrics['early_termination'] = {
            'attempt': attempt,
            'reason': 'satisfactory_quality',
          };
          break;
        }

        // Para consultas urgentes, aceitar qualidade menor após primeira tentativa
        if (context.isUrgent && attempt >= 2 && decision.shouldRespond) {
          searchMetrics['early_termination'] = {
            'attempt': attempt,
            'reason': 'urgent_context',
          };
          break;
        }
      } catch (e) {
        searchMetrics['attempt_$attempt']['error'] = e.toString();
        continue;
      } finally {
        _cancelSearchTimeout();
      }
    }

    // Usar melhor resultado encontrado ou resultado padrão se nenhum
    final finalDecision = bestDecision ??
        ResponseDecision(
          shouldRespond: false,
          confidenceLevel: 0.0,
          reasoning:
              'Nenhum resultado satisfatório encontrado após ${_config.maxSearchAttempts} tentativas',
          recommendations: ['Refinar consulta', 'Tentar termos diferentes'],
          selectedResults: bestResults ?? [],
          qualityAssessment: bestAssessment ??
              QualityAssessment(
                isSatisfactory: false,
                confidenceScore: 0.0,
                coverageScore: 0.0,
                authorityScore: 0.0,
                contentDepthScore: 0.0,
                sourceDiversityCount: 0,
                qualityIssues: ['Nenhum resultado encontrado'],
                strengths: [],
                recommendation: 'Tentar consulta diferente',
              ),
          metadata: {'max_attempts_reached': true},
        );

    return IntelligentSearchResult(
      canProvideAnswer: finalDecision.shouldRespond,
      confidenceLevel: finalDecision.confidenceLevel,
      reasoning: finalDecision.reasoning,
      selectedResults: finalDecision.selectedResults,
      qualityAssessment: finalDecision.qualityAssessment,
      decision: finalDecision,
      searchMetrics: searchMetrics,
      totalSearchTime: Duration.zero, // Será calculado no método principal
      attemptsUsed: _config.maxSearchAttempts,
    );
  }

  /// Ajusta a consulta para tentativas subsequentes.
  String _adjustQueryForAttempt(String originalQuery, int attempt,
      QualityAssessment? previousAssessment) {
    if (attempt == 1) return originalQuery;

    // Estratégias de ajuste baseadas no feedback
    if (previousAssessment != null &&
        previousAssessment.qualityIssues.isNotEmpty) {
      final mainIssue = previousAssessment.qualityIssues.first;

      if (mainIssue.contains('autoridade')) {
        // Adicionar termos que favorecem fontes autoritativas
        return '$originalQuery site:edu OR site:gov OR documentation';
      }

      if (mainIssue.contains('cobertura')) {
        // Expandir consulta com sinônimos
        return _expandQueryWithSynonyms(originalQuery);
      }

      if (mainIssue.contains('profundidade')) {
        // Adicionar termos que favorecem conteúdo detalhado
        return '$originalQuery tutorial OR guide OR detailed OR comprehensive';
      }
    }

    // Estratégias gerais por tentativa
    switch (attempt) {
      case 2:
        return _expandQueryWithSynonyms(originalQuery);
      case 3:
        return _simplifyQuery(originalQuery);
      default:
        return originalQuery;
    }
  }

  /// Expande consulta com sinônimos.
  String _expandQueryWithSynonyms(String query) {
    // Mapeamento simples de sinônimos - poderia ser expandido
    final synonyms = {
      'como': 'how tutorial guide',
      'what': 'que definição conceito',
      'why': 'por que motivo razão',
      'erro': 'error bug problema issue',
      'instalar': 'install setup configurar',
    };

    var expandedQuery = query;
    for (final entry in synonyms.entries) {
      if (query.toLowerCase().contains(entry.key)) {
        expandedQuery = '$expandedQuery ${entry.value}';
        break; // Aplicar apenas um sinônimo por vez
      }
    }

    return expandedQuery;
  }

  /// Simplifica consulta removendo termos menos importantes.
  String _simplifyQuery(String query) {
    final words = query.split(' ');
    if (words.length <= 3) return query;

    // Manter apenas palavras principais (remove artigos, preposições, etc.)
    final stopWords = {
      'o',
      'a',
      'de',
      'da',
      'do',
      'em',
      'para',
      'com',
      'por',
      'the',
      'an',
      'in',
      'on',
      'at',
      'to',
      'for'
    };
    final importantWords =
        words.where((word) => !stopWords.contains(word.toLowerCase())).toList();

    return importantWords.take(math.min(5, importantWords.length)).join(' ');
  }

  /// Filtra resultados baseado em configurações.
  List<SearchResult> _filterResults(List<SearchResult> results) {
    return results.where((result) {
      final uri = Uri.tryParse(result.url);
      if (uri == null) return false;

      final domain = uri.host.toLowerCase();

      // Verificar domínios bloqueados
      if (_config.blockedDomains.any((blocked) => domain.contains(blocked))) {
        return false;
      }

      // Priorizar domínios preferidos (não filtrar, apenas reordenar depois)
      return true;
    }).toList();
  }

  /// Analisa relevância dos resultados.
  Future<List<RelevanceScore>> _analyzeRelevance(
      String query, List<SearchResult> results) async {
    final scores = <RelevanceScore>[];

    for (final result in results) {
      final score = _relevanceAnalyzer.analyzeRelevance(
        query: query,
        title: result.title,
        snippet: result.snippet,
        url: result.url,
        content: result.content,
      );
      scores.add(score);
    }

    return scores;
  }

  /// Verifica se um resultado é melhor que outro.
  bool _isBetterResult(ResponseDecision current, ResponseDecision? previous) {
    if (previous == null) return true;

    // Priorizar decisões que permitem resposta
    if (current.shouldRespond && !previous.shouldRespond) return true;
    if (!current.shouldRespond && previous.shouldRespond) return false;

    // Se ambos permitem ou não permitem resposta, comparar confiança
    return current.confidenceLevel > previous.confidenceLevel;
  }

  /// Configura timeout para busca.
  void _setupSearchTimeout() {
    _cancelSearchTimeout();
    _searchTimeoutTimer = Timer(_config.timeoutPerAttempt, () {
      throw TimeoutException('Search timeout', _config.timeoutPerAttempt);
    });
  }

  /// Cancela timeout de busca.
  void _cancelSearchTimeout() {
    _searchTimeoutTimer?.cancel();
    _searchTimeoutTimer = null;
  }

  /// Obtém resultado do cache.
  IntelligentSearchResult? _getCachedResult(String query) {
    final normalizedQuery = query.toLowerCase().trim();
    return _resultCache[normalizedQuery];
  }

  /// Salva resultado no cache.
  void _cacheResult(String query, IntelligentSearchResult result) {
    final normalizedQuery = query.toLowerCase().trim();
    _resultCache[normalizedQuery] = result;

    // Limitar tamanho do cache
    if (_resultCache.length > 100) {
      final firstKey = _resultCache.keys.first;
      _resultCache.remove(firstKey);
    }
  }

  /// Registra resultado no histórico.
  void _recordSearchResult(IntelligentSearchResult result) {
    _searchHistory.add(result);

    // Manter apenas últimos 500 resultados
    if (_searchHistory.length > 500) {
      _searchHistory.removeRange(0, _searchHistory.length - 500);
    }
  }

  /// Obtém métricas de desempenho.
  SearchMetrics getPerformanceMetrics() {
    if (_searchHistory.isEmpty) {
      return const SearchMetrics(
        totalQueries: 0,
        successfulQueries: 0,
        rejectedQueries: 0,
        averageConfidence: 0.0,
        averageSearchTime: Duration.zero,
        queryTypeDistribution: {},
        strategyPerformance: {},
      );
    }

    final total = _searchHistory.length;
    final successful = _searchHistory.where((r) => r.canProvideAnswer).length;
    final rejected = total - successful;

    final avgConfidence =
        _searchHistory.map((r) => r.confidenceLevel).reduce((a, b) => a + b) /
            total;

    final avgTime = Duration(
      milliseconds: (_searchHistory
                  .map((r) => r.totalSearchTime.inMilliseconds)
                  .reduce((a, b) => a + b) /
              total)
          .round(),
    );

    // Distribuição por tipo de consulta
    final queryTypeDistribution = <QueryType, int>{};
    for (final result in _searchHistory) {
      final queryType = result.searchMetrics['query_type'] as String?;
      if (queryType != null) {
        final type = QueryType.values.firstWhere(
          (t) => t.name == queryType,
          orElse: () => QueryType.general,
        );
        queryTypeDistribution[type] = (queryTypeDistribution[type] ?? 0) + 1;
      }
    }

    return SearchMetrics(
      totalQueries: total,
      successfulQueries: successful,
      rejectedQueries: rejected,
      averageConfidence: avgConfidence,
      averageSearchTime: avgTime,
      queryTypeDistribution: queryTypeDistribution,
      strategyPerformance: {_config.decisionStrategy: avgConfidence},
    );
  }

  /// Limpa cache e histórico.
  void clearCacheAndHistory() {
    _resultCache.clear();
    _searchHistory.clear();
    _qualityClassifier.clearCache();
    _decisionEngine.resetAdaptiveLearning();
  }

  /// Obtém configuração atual.
  IntelligentSearchConfig get config => _config;

  /// Dispose dos recursos.
  void dispose() {
    _cancelSearchTimeout();
    clearCacheAndHistory();
    _httpClient.close();
  }
}
