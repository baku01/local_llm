/// Sistema avançado de classificação de qualidade de informações para busca web.
///
/// Este módulo implementa algoritmos sofisticados para determinar se as informações
/// coletadas da web são suficientemente satisfatórias para fornecer uma resposta
/// confiável ao usuário, evitando respostas baseadas em dados incompletos ou irrelevantes.
library;

import 'dart:math' as math;
import '../../../domain/entities/search_result.dart';
import '../../../domain/entities/relevance_score.dart';
import '../utils/text_processor.dart';

/// Tipos de consulta para aplicar diferentes critérios de qualidade.
enum QueryType {
  factual, // Perguntas factuais que precisam de informações precisas
  explanatory, // Perguntas que requerem explicações detalhadas
  procedural, // Perguntas sobre como fazer algo (tutoriais)
  comparative, // Perguntas que comparam diferentes opções
  technical, // Perguntas técnicas específicas
  general, // Perguntas gerais
}

/// Configuração de critérios de qualidade por tipo de consulta.
class QualityConfig {
  final double minRelevanceThreshold;
  final double minCoverageScore;
  final double minAuthorityScore;
  final int minSourceDiversity;
  final double minContentDepth;
  final bool requireMultipleSources;

  const QualityConfig({
    required this.minRelevanceThreshold,
    required this.minCoverageScore,
    required this.minAuthorityScore,
    required this.minSourceDiversity,
    required this.minContentDepth,
    required this.requireMultipleSources,
  });

  /// Configurações padrão para diferentes tipos de consulta.
  static const Map<QueryType, QualityConfig> defaultConfigs = {
    QueryType.factual: QualityConfig(
      minRelevanceThreshold: 0.8,
      minCoverageScore: 0.75,
      minAuthorityScore: 0.7,
      minSourceDiversity: 2,
      minContentDepth: 0.4,
      requireMultipleSources: true,
    ),
    QueryType.technical: QualityConfig(
      minRelevanceThreshold: 0.85,
      minCoverageScore: 0.8,
      minAuthorityScore: 0.8,
      minSourceDiversity: 2,
      minContentDepth: 0.9,
      requireMultipleSources: true,
    ),
    QueryType.explanatory: QualityConfig(
      minRelevanceThreshold: 0.7,
      minCoverageScore: 0.75,
      minAuthorityScore: 0.6,
      minSourceDiversity: 2,
      minContentDepth: 0.85,
      requireMultipleSources: false,
    ),
    QueryType.procedural: QualityConfig(
      minRelevanceThreshold: 0.75,
      minCoverageScore: 0.8,
      minAuthorityScore: 0.65,
      minSourceDiversity: 1,
      minContentDepth: 0.8,
      requireMultipleSources: false,
    ),
    QueryType.comparative: QualityConfig(
      minRelevanceThreshold: 0.7,
      minCoverageScore: 0.8,
      minAuthorityScore: 0.6,
      minSourceDiversity: 3,
      minContentDepth: 0.75,
      requireMultipleSources: true,
    ),
    QueryType.general: QualityConfig(
      minRelevanceThreshold: 0.6,
      minCoverageScore: 0.65,
      minAuthorityScore: 0.5,
      minSourceDiversity: 1,
      minContentDepth: 0.6,
      requireMultipleSources: false,
    ),
  };
}

/// Resultado da classificação de qualidade.
class QualityAssessment {
  final bool isSatisfactory;
  final double confidenceScore;
  final double coverageScore;
  final double authorityScore;
  final double contentDepthScore;
  final int sourceDiversityCount;
  final List<String> qualityIssues;
  final List<String> strengths;
  final String recommendation;

  const QualityAssessment({
    required this.isSatisfactory,
    required this.confidenceScore,
    required this.coverageScore,
    required this.authorityScore,
    required this.contentDepthScore,
    required this.sourceDiversityCount,
    required this.qualityIssues,
    required this.strengths,
    required this.recommendation,
  });

  @override
  String toString() => 'QualityAssessment('
      'satisfactory: $isSatisfactory, '
      'confidence: ${confidenceScore.toStringAsFixed(3)}, '
      'coverage: ${coverageScore.toStringAsFixed(3)}, '
      'authority: ${authorityScore.toStringAsFixed(3)})';
}

/// Classificador avançado de qualidade de informações.
class QualityClassifier {
  final TextProcessor _textProcessor;

  /// Cache de avaliações para evitar reprocessamento.
  final Map<String, QualityAssessment> _assessmentCache = {};

  QualityClassifier() : _textProcessor = TextProcessor();

  /// Classifica a qualidade das informações coletadas.
  ///
  /// [query] - Consulta original do usuário
  /// [results] - Lista de resultados de busca
  /// [relevanceScores] - Pontuações de relevância correspondentes
  /// [queryType] - Tipo da consulta para aplicar critérios específicos
  ///
  /// Returns: [QualityAssessment] com avaliação detalhada da qualidade
  QualityAssessment classifyQuality({
    required String query,
    required List<SearchResult> results,
    required List<RelevanceScore> relevanceScores,
    QueryType queryType = QueryType.general,
  }) {
    // Verificar cache
    final cacheKey = _generateCacheKey(query, results, queryType);
    if (_assessmentCache.containsKey(cacheKey)) {
      return _assessmentCache[cacheKey]!;
    }

    final config = QualityConfig.defaultConfigs[queryType]!;
    final issues = <String>[];
    final strengths = <String>[];

    // 1. Avaliar cobertura da consulta
    final coverageScore =
        _evaluateQueryCoverage(query, results, relevanceScores);
    if (coverageScore < config.minCoverageScore) {
      issues.add(
          'Cobertura insuficiente da consulta (${(coverageScore * 100).toStringAsFixed(1)}%)');
    } else {
      strengths.add('Boa cobertura da consulta');
    }

    // 2. Avaliar autoridade das fontes
    final authorityScore = _evaluateSourceAuthority(results, relevanceScores);
    if (authorityScore < config.minAuthorityScore) {
      issues.add('Fontes com baixa autoridade');
    } else {
      strengths.add('Fontes confiáveis e autoritativas');
    }

    // 3. Avaliar profundidade do conteúdo
    final contentDepthScore = _evaluateContentDepth(results);
    if (contentDepthScore < config.minContentDepth) {
      issues.add('Conteúdo superficial ou insuficiente');
    } else {
      strengths.add('Conteúdo detalhado e profundo');
    }

    // 4. Avaliar diversidade de fontes
    final sourceDiversityCount = _evaluateSourceDiversity(results);
    if (sourceDiversityCount < config.minSourceDiversity) {
      issues.add('Falta diversidade de fontes');
    } else {
      strengths.add('Boa diversidade de fontes');
    }

    // 5. Verificar relevância mínima
    final highRelevanceCount = relevanceScores
        .where((score) => score.overallScore >= config.minRelevanceThreshold)
        .length;

    if (highRelevanceCount == 0) {
      issues.add('Nenhum resultado com relevância suficiente');
    }

    // 6. Verificar requisitos específicos do tipo de consulta
    if (config.requireMultipleSources && results.length < 2) {
      issues.add('Múltiplas fontes são necessárias para este tipo de consulta');
    }

    // Calcular pontuação de confiança
    final confidenceScore = _calculateConfidenceScore(
      coverageScore,
      authorityScore,
      contentDepthScore,
      sourceDiversityCount.toDouble() / config.minSourceDiversity,
      highRelevanceCount.toDouble() / math.max(1, results.length),
      config,
    );

    // Determinar se é satisfatório
    final isSatisfactory = _determineSatisfaction(
      coverageScore,
      authorityScore,
      contentDepthScore,
      sourceDiversityCount,
      highRelevanceCount,
      config,
    );

    // Gerar recomendação
    final recommendation = _generateRecommendation(
      isSatisfactory,
      issues,
      queryType,
      confidenceScore,
    );

    final assessment = QualityAssessment(
      isSatisfactory: isSatisfactory,
      confidenceScore: confidenceScore,
      coverageScore: coverageScore,
      authorityScore: authorityScore,
      contentDepthScore: contentDepthScore,
      sourceDiversityCount: sourceDiversityCount,
      qualityIssues: issues,
      strengths: strengths,
      recommendation: recommendation,
    );

    // Salvar no cache
    _assessmentCache[cacheKey] = assessment;

    return assessment;
  }

  /// Identifica automaticamente o tipo de consulta.
  QueryType identifyQueryType(String query) {
    final lowerQuery = query.toLowerCase();

    // Palavras-chave para diferentes tipos
    final Map<QueryType, List<String>> patterns = {
      QueryType.factual: [
        'o que é',
        'what is',
        'quem é',
        'who is',
        'quando',
        'when',
        'onde',
        'where',
        'quantos',
        'how many',
        'qual',
        'which'
      ],
      QueryType.technical: [
        'como implementar',
        'how to implement',
        'código',
        'code',
        'programação',
        'programming',
        'api',
        'framework',
        'biblioteca',
        'error',
        'erro',
        'debug',
        'configurar',
        'configure'
      ],
      QueryType.explanatory: [
        'por que',
        'why',
        'como funciona',
        'how does',
        'explique',
        'explain',
        'diferença',
        'difference',
        'motivo',
        'reason'
      ],
      QueryType.procedural: [
        'como fazer',
        'how to',
        'passo a passo',
        'step by step',
        'tutorial',
        'guia',
        'guide',
        'instalar',
        'install'
      ],
      QueryType.comparative: [
        'vs',
        'versus',
        'comparar',
        'compare',
        'melhor',
        'better',
        'diferença entre',
        'difference between',
        'qual escolher',
        'qual é melhor',
        'ou', // for "iOS ou Android"
        'versus'
      ],
    };

    // Tratamento especial para consultas muito simples
    if (lowerQuery.length <= 15 && !lowerQuery.contains(' ')) {
      return QueryType.general;
    }

    // Contar matches para cada tipo com prioridade
    final scores = <QueryType, double>{};
    for (final entry in patterns.entries) {
      double score = 0;
      for (final pattern in entry.value) {
        if (lowerQuery.contains(pattern)) {
          // Dar peso maior para matches mais específicos
          score += pattern.split(' ').length;
        }
      }
      scores[entry.key] = score;
    }

    // Retornar o tipo com mais score, ou general se nenhum
    final maxScore =
        scores.values.isNotEmpty ? scores.values.reduce(math.max) : 0.0;

    if (maxScore == 0) return QueryType.general;

    return scores.entries.where((entry) => entry.value == maxScore).first.key;
  }

  /// Avalia quão bem os resultados cobrem a consulta.
  double _evaluateQueryCoverage(
    String query,
    List<SearchResult> results,
    List<RelevanceScore> relevanceScores,
  ) {
    if (results.isEmpty) return 0.0;

    final queryTerms = _extractQueryTerms(query);
    if (queryTerms.isEmpty) return 0.0;

    final coveredTerms = <String>{};

    for (int i = 0; i < results.length; i++) {
      final result = results[i];
      final relevance = i < relevanceScores.length ? relevanceScores[i] : null;

      // Só considerar resultados com relevância razoável
      if (relevance != null && relevance.overallScore < 0.5) continue;

      final content =
          '${result.title} ${result.snippet} ${result.content ?? ''}'
              .toLowerCase();

      for (final term in queryTerms) {
        if (content.contains(term.toLowerCase())) {
          coveredTerms.add(term);
        }
      }
    }

    return coveredTerms.length / queryTerms.length;
  }

  /// Avalia a autoridade média das fontes.
  double _evaluateSourceAuthority(
    List<SearchResult> results,
    List<RelevanceScore> relevanceScores,
  ) {
    if (results.isEmpty) return 0.0;

    double totalAuthority = 0.0;
    int validSources = 0;

    for (int i = 0; i < results.length && i < relevanceScores.length; i++) {
      final relevance = relevanceScores[i];
      if (relevance.overallScore >= 0.3) {
        totalAuthority += relevance.authorityScore;
        validSources++;
      }
    }

    return validSources > 0 ? totalAuthority / validSources : 0.0;
  }

  /// Avalia a profundidade do conteúdo disponível.
  double _evaluateContentDepth(List<SearchResult> results) {
    if (results.isEmpty) return 0.0;

    double totalDepth = 0.0;
    int validResults = 0;

    for (final result in results) {
      final contentLength = (result.content?.length ?? 0) +
          result.snippet.length +
          result.title.length;

      // Normalizar por tamanho esperado
      double depthScore = 0.0;

      if (contentLength >= 2000) {
        depthScore = 1.0;
      } else if (contentLength >= 1000) {
        depthScore = 0.8;
      } else if (contentLength >= 500) {
        depthScore = 0.6;
      } else if (contentLength >= 200) {
        depthScore = 0.4;
      } else {
        depthScore = 0.2;
      }

      // Bônus por estrutura (parágrafos, listas, etc.)
      final content = result.content ?? '';
      if (content.contains('\n\n') || content.contains('<p>')) {
        depthScore += 0.1;
      }
      if (content.contains('```') || content.contains('<code>')) {
        depthScore += 0.1; // Código é valioso para consultas técnicas
      }

      totalDepth += math.min(1.0, depthScore);
      validResults++;
    }

    return validResults > 0 ? totalDepth / validResults : 0.0;
  }

  /// Conta o número de domínios únicos nas fontes.
  int _evaluateSourceDiversity(List<SearchResult> results) {
    final domains = <String>{};

    for (final result in results) {
      final uri = Uri.tryParse(result.url);
      if (uri != null) {
        domains.add(uri.host.toLowerCase());
      }
    }

    return domains.length;
  }

  /// Calcula a pontuação de confiança geral.
  double _calculateConfidenceScore(
    double coverage,
    double authority,
    double depth,
    double diversity,
    double relevance,
    QualityConfig config,
  ) {
    // Pesos ajustados por tipo de consulta
    return (coverage * 0.3) +
        (authority * 0.25) +
        (depth * 0.2) +
        (diversity * 0.15) +
        (relevance * 0.1);
  }

  /// Determina se as informações são satisfatórias.
  bool _determineSatisfaction(
    double coverage,
    double authority,
    double depth,
    int diversity,
    int relevantCount,
    QualityConfig config,
  ) {
    return coverage >= config.minCoverageScore &&
        authority >= config.minAuthorityScore &&
        depth >= config.minContentDepth &&
        diversity >= config.minSourceDiversity &&
        relevantCount > 0 &&
        (!config.requireMultipleSources || relevantCount >= 2);
  }

  /// Gera recomendação baseada na avaliação.
  String _generateRecommendation(
    bool isSatisfactory,
    List<String> issues,
    QueryType queryType,
    double confidence,
  ) {
    if (isSatisfactory && confidence >= 0.8) {
      return 'Informações de alta qualidade encontradas. Pode responder com confiança.';
    }

    if (isSatisfactory && confidence >= 0.6) {
      return 'Informações satisfatórias encontradas. Resposta recomendada com algumas ressalvas.';
    }

    if (issues.isNotEmpty) {
      final mainIssue = issues.first;
      switch (queryType) {
        case QueryType.factual:
          return 'Buscar fontes mais autoritativas para informações factuais. $mainIssue';
        case QueryType.technical:
          return 'Necessário encontrar documentação oficial ou fontes técnicas especializadas. $mainIssue';
        case QueryType.explanatory:
          return 'Buscar conteúdo mais detalhado e explicativo. $mainIssue';
        case QueryType.procedural:
          return 'Encontrar tutoriais ou guias passo-a-passo mais completos. $mainIssue';
        case QueryType.comparative:
          return 'Buscar mais fontes para comparação equilibrada. $mainIssue';
        case QueryType.general:
          return 'Expandir busca para encontrar informações mais relevantes. $mainIssue';
      }
    }

    return 'Qualidade insuficiente. Recomenda-se refinar a busca ou aguardar melhores resultados.';
  }

  /// Extrai termos principais da consulta.
  List<String> _extractQueryTerms(String query) {
    return _textProcessor
        .processText(query)
        .split(' ')
        .where((term) => term.length > 2)
        .toList();
  }

  /// Gera chave para cache.
  String _generateCacheKey(
    String query,
    List<SearchResult> results,
    QueryType queryType,
  ) {
    final resultHashes =
        results.map((r) => '${r.url.hashCode}${r.title.hashCode}').join('|');
    return '${query.hashCode}|${queryType.name}|${resultHashes.hashCode}';
  }

  /// Limpa o cache de avaliações.
  void clearCache() {
    _assessmentCache.clear();
  }

  /// Obtém estatísticas do cache.
  Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _assessmentCache.length,
      'memoryUsage': _assessmentCache.length * 1024, // Estimativa em bytes
    };
  }
}
