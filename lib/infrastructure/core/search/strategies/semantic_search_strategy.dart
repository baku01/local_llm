/// Estratégia de busca semântica usando embeddings e NLP.
///
/// Implementa busca baseada em similaridade semântica para melhor
/// compreensão de intent e contexto das consultas do usuário.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

import '../../../../domain/entities/search_query.dart';
import '../../../../domain/entities/search_result.dart';
import '../search_strategy.dart';
import '../semantic_search_engine.dart';
import '../../utils/logger.dart';

/// Estratégia de busca semântica com embeddings e processamento de linguagem natural.
///
/// Características principais:
/// - Interpretação semântica de consultas
/// - Ranking baseado em similaridade vetorial
/// - Cache inteligente de embeddings
/// - Expansão automática de consultas
/// - Análise de intent e contexto
class SemanticSearchStrategy implements SearchStrategy {
  final http.Client _httpClient;
  final Map<String, List<double>> _embeddingCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheLifetime = Duration(hours: 24);

  SemanticSearchStrategy({
    required http.Client httpClient,
  }) : _httpClient = httpClient;

  @override
  String get name => 'semantic_search';

  @override
  int get priority => 9; // Alta prioridade por ser mais inteligente

  @override
  int get timeoutSeconds => 45; // Mais tempo para processamento semântico

  @override
  bool get isAvailable => true;

  @override
  SearchStrategyMetrics get metrics => SearchStrategyMetrics.empty();

  @override
  bool canHandle(SearchQuery query) {
    // Pode lidar com qualquer tipo de consulta
    return query.formattedQuery.isNotEmpty;
  }

  @override
  Future<List<SearchResult>> search(SearchQuery query) async {
    try {
      AppLogger.info('Iniciando busca semântica para: ${query.formattedQuery}',
          'SemanticSearchStrategy');

      // 1. Análise semântica da consulta
      final semanticQuery = await _enhanceQuery(query);

      // 2. Geração de embedding da consulta
      final queryEmbedding = await _getQueryEmbedding(semanticQuery);

      // 3. Busca com múltiplas estratégias semânticas
      final results =
          await _performSemanticSearch(semanticQuery, queryEmbedding);

      // 4. Ranking semântico dos resultados
      final rankedResults = await _rankSemanticResults(results, queryEmbedding);

      AppLogger.info(
          'Busca semântica concluída: ${rankedResults.length} resultados',
          'SemanticSearchStrategy');

      return rankedResults;
    } catch (e) {
      AppLogger.warning(
          'Falha na busca semântica: $e', 'SemanticSearchStrategy');
      rethrow;
    }
  }

  /// Aprimora a consulta com análise semântica e expansão de termos.
  Future<String> _enhanceQuery(SearchQuery query) async {
    String enhanced = query.formattedQuery;

    // Expandir consultas curtas com contexto
    if (enhanced.split(' ').length <= 2) {
      enhanced = await _expandShortQuery(enhanced);
    }

    // Adicionar sinônimos relevantes para termos técnicos
    enhanced = await _addSynonyms(enhanced);

    // Normalizar e limpar a consulta
    enhanced = _normalizeQuery(enhanced);

    AppLogger.debug('Consulta expandida: $enhanced', 'SemanticSearchStrategy');
    return enhanced;
  }

  /// Expande consultas curtas com contexto adicional.
  Future<String> _expandShortQuery(String query) async {
    // Mapeamento de termos técnicos comuns
    final techTermsContext = {
      'flutter': 'flutter dart mobile app development',
      'dart': 'dart programming language flutter',
      'api': 'api rest web service integration',
      'database': 'database sql nosql storage',
      'auth': 'authentication authorization security',
      'ui': 'user interface design components',
      'performance': 'optimization speed memory efficiency',
      'testing': 'unit test integration test automation',
      'deployment': 'deployment production CI CD',
      'debug': 'debugging error handling troubleshooting',
    };

    String expanded = query.toLowerCase();

    for (final term in techTermsContext.keys) {
      if (expanded.contains(term)) {
        expanded = techTermsContext[term]!;
        break;
      }
    }

    return expanded;
  }

  /// Adiciona sinônimos relevantes à consulta.
  Future<String> _addSynonyms(String query) async {
    final synonyms = {
      'error': ['bug', 'issue', 'problem', 'exception'],
      'fix': ['solve', 'resolve', 'repair', 'correct'],
      'optimize': ['improve', 'enhance', 'boost', 'accelerate'],
      'create': ['build', 'develop', 'implement', 'generate'],
      'delete': ['remove', 'destroy', 'eliminate', 'drop'],
      'update': ['modify', 'change', 'edit', 'revise'],
    };

    String enhanced = query;

    for (final word in synonyms.keys) {
      if (query.toLowerCase().contains(word)) {
        final relatedTerms = synonyms[word]!.take(2).join(' ');
        enhanced += ' $relatedTerms';
      }
    }

    return enhanced;
  }

  /// Normaliza a consulta removendo caracteres desnecessários.
  String _normalizeQuery(String query) {
    return query
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Obtém embedding da consulta com cache inteligente.
  Future<List<double>> _getQueryEmbedding(String query) async {
    final cacheKey = _generateCacheKey(query);

    // Verificar cache
    if (_embeddingCache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheLifetime) {
        AppLogger.debug(
            'Embedding recuperado do cache', 'SemanticSearchStrategy');
        return _embeddingCache[cacheKey]!;
      }
    }

    // Gerar novo embedding
    final embedding = await _generateEmbedding(query);

    // Atualizar cache
    _embeddingCache[cacheKey] = embedding;
    _cacheTimestamps[cacheKey] = DateTime.now();

    return embedding;
  }

  /// Gera embedding usando serviço local ou fallback simples.
  Future<List<double>> _generateEmbedding(String text) async {
    try {
      // Tentar usar serviço de embedding local (ex: sentence-transformers)
      return await _generateLocalEmbedding(text);
    } catch (e) {
      AppLogger.warning('Falha no embedding local, usando fallback: $e',
          'SemanticSearchStrategy');
      // Fallback para embedding baseado em características
      return _generateSimpleEmbedding(text);
    }
  }

  /// Gera embedding usando serviço local (ex: Ollama com modelo de embedding).
  Future<List<double>> _generateLocalEmbedding(String text) async {
    final response = await _httpClient
        .post(
          Uri.parse('http://localhost:11434/api/embeddings'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'model': 'nomic-embed-text', // Modelo de embedding
            'prompt': text,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<double>.from(data['embedding']);
    } else {
      throw Exception('Falha no serviço de embedding: ${response.statusCode}');
    }
  }

  /// Gera embedding simples baseado em características do texto.
  List<double> _generateSimpleEmbedding(String text) {
    final words = text.toLowerCase().split(' ');
    final embedding = List<double>.filled(100, 0.0);

    // Características simples
    embedding[0] = words.length.toDouble() / 10.0; // Comprimento
    embedding[1] =
        words.where((w) => w.length > 6).length.toDouble(); // Palavras longas
    embedding[2] =
        words.where((w) => w.contains('ing')).length.toDouble(); // Verbos

    // Hash das palavras para distribuição
    for (int i = 0; i < words.length && i < 50; i++) {
      final hash = words[i].hashCode % 97;
      embedding[3 + i] = (hash / 97.0) * 2 - 1; // Normalizar para [-1, 1]
    }

    // Normalizar o vetor
    final magnitude = math.sqrt(embedding.fold(0.0, (a, b) => a + b * b));
    if (magnitude > 0) {
      for (int i = 0; i < embedding.length; i++) {
        embedding[i] /= magnitude;
      }
    }

    return embedding;
  }

  /// Realiza busca semântica usando múltiplas abordagens.
  Future<List<SearchResult>> _performSemanticSearch(
    String query,
    List<double> queryEmbedding,
  ) async {
    final results = <SearchResult>[];

    // 1. Busca contextual (termos expandidos)
    final contextualResults = await _performContextualSearch(query);
    results.addAll(contextualResults);

    // 2. Busca por similaridade de texto
    final similarityResults = await _performSimilaritySearch(query);
    results.addAll(similarityResults);

    // 3. Busca por intent (intenção do usuário)
    final intentResults = await _performIntentSearch(query);
    results.addAll(intentResults);

    // Remover duplicatas
    return _removeDuplicates(results);
  }

  /// Remove resultados duplicados baseado no URL e título.
  List<SearchResult> _removeDuplicates(List<SearchResult> results) {
    final seen = <String>{};
    return results.where((result) {
      final key = '${result.url}_${result.title}';
      if (seen.contains(key)) {
        return false;
      }
      seen.add(key);
      return true;
    }).toList();
  }

  /// Classifica resultados usando ranking semântico avançado.
  Future<List<SearchResult>> _rankSemanticResults(
    List<SearchResult> results,
    List<double> queryEmbedding,
  ) async {
    final scoredResults = <ScoredSearchResult>[];

    for (final result in results) {
      final score = await _calculateSemanticScore(result, queryEmbedding);
      scoredResults.add(ScoredSearchResult(result, score));
    }

    // Ordenar por score decrescente
    scoredResults.sort((a, b) => b.score.compareTo(a.score));

    return scoredResults.map((sr) => sr.result).toList();
  }

  /// Calcula score semântico para um resultado.
  Future<double> _calculateSemanticScore(
    SearchResult result,
    List<double> queryEmbedding,
  ) async {
    double score = 0.0;

    // 1. Similaridade do título (peso: 40%)
    final titleEmbedding = await _generateEmbedding(result.title);
    final titleSimilarity = _cosineSimilarity(queryEmbedding, titleEmbedding);
    score += titleSimilarity * 0.4;

    // 2. Similaridade do snippet (peso: 30%)
    if (result.snippet.isNotEmpty) {
      final descEmbedding = await _generateEmbedding(result.snippet);
      final descSimilarity = _cosineSimilarity(queryEmbedding, descEmbedding);
      score += descSimilarity * 0.3;
    }

    // 3. Relevância contextual (peso: 20%)
    final contextScore = _calculateContextualRelevance(result);
    score += contextScore * 0.2;

    // 4. Qualidade do resultado (peso: 10%)
    final qualityScore = _calculateQualityScore(result);
    score += qualityScore * 0.1;

    return math.max(0.0, math.min(1.0, score));
  }

  /// Calcula similaridade coseno entre dois vetores.
  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0.0 || normB == 0.0) return 0.0;

    return dotProduct / (math.sqrt(normA) * math.sqrt(normB));
  }

  /// Calcula relevância contextual baseada no domínio.
  double _calculateContextualRelevance(SearchResult result) {
    final url = result.url.toLowerCase();
    final title = result.title.toLowerCase();

    // Domínios técnicos relevantes
    final techDomains = [
      'stackoverflow.com',
      'github.com',
      'pub.dev',
      'flutter.dev',
      'dart.dev',
      'api.flutter.dev',
      'medium.com',
      'dev.to'
    ];

    double relevance = 0.5; // Base score

    // Bonus para domínios técnicos
    if (techDomains.any((domain) => url.contains(domain))) {
      relevance += 0.3;
    }

    // Bonus para títulos técnicos
    final techTerms = ['flutter', 'dart', 'api', 'development', 'programming'];
    final matchingTerms =
        techTerms.where((term) => title.contains(term)).length;
    relevance += (matchingTerms / techTerms.length) * 0.2;

    return math.max(0.0, math.min(1.0, relevance));
  }

  /// Calcula score de qualidade baseado nas características do resultado.
  double _calculateQualityScore(SearchResult result) {
    double quality = 0.5; // Base score

    // Qualidade do título
    if (result.title.length > 10 && result.title.length < 100) {
      quality += 0.2;
    }

    // Qualidade do snippet
    if (result.snippet.length > 50 && result.snippet.length < 300) {
      quality += 0.2;
    }

    // URL válida e segura
    if (result.url.startsWith('https://')) {
      quality += 0.1;
    }

    return math.max(0.0, math.min(1.0, quality));
  }

  /// Gera chave de cache para embedding.
  String _generateCacheKey(String text) {
    final bytes = utf8.encode(text);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Realiza busca contextual com termos expandidos.
  Future<List<SearchResult>> _performContextualSearch(String query) async {
    // Implementação simplificada - pode ser expandida futuramente
    return <SearchResult>[];
  }

  /// Realiza busca por similaridade de texto.
  Future<List<SearchResult>> _performSimilaritySearch(String query) async {
    // Implementação simplificada - pode ser expandida futuramente
    return <SearchResult>[];
  }

  /// Realiza busca por intent do usuário.
  Future<List<SearchResult>> _performIntentSearch(String query) async {
    // Implementação simplificada - pode ser expandida futuramente
    return <SearchResult>[];
  }

  void dispose() {
    _embeddingCache.clear();
    _cacheTimestamps.clear();
  }
}

/// Resultado com score para ranking.
class ScoredSearchResult {
  final SearchResult result;
  final double score;

  const ScoredSearchResult(this.result, this.score);
}
