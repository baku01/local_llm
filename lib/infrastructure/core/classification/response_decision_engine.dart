/// Motor de decisão inteligente para determinar quando responder baseado na qualidade das informações.
///
/// Este módulo implementa um sistema sofisticado de tomada de decisão que analisa
/// múltiplos fatores para determinar se as informações coletadas são suficientemente
/// boas para fornecer uma resposta satisfatória ao usuário.
library;

import 'dart:math' as math;
import '../../domain/entities/search_result.dart';
import '../../domain/entities/relevance_score.dart';
import 'quality_classifier.dart';

/// Estratégias de decisão para diferentes cenários.
enum DecisionStrategy {
  conservative, // Mais rigoroso, prefere não responder se há dúvida
  balanced, // Equilibrado entre qualidade e utilidade
  aggressive, // Mais permissivo, tenta responder sempre que possível
  adaptive, // Adapta baseado no histórico e contexto
}

/// Contexto da consulta para melhor tomada de decisão.
class QueryContext {
  final String originalQuery;
  final QueryType queryType;
  final int attemptNumber;
  final List<String> previousQueries;
  final double userExpertiseLevel; // 0.0 a 1.0
  final bool isUrgent;
  final List<String> preferredSources;

  const QueryContext({
    required this.originalQuery,
    required this.queryType,
    this.attemptNumber = 1,
    this.previousQueries = const [],
    this.userExpertiseLevel = 0.5,
    this.isUrgent = false,
    this.preferredSources = const [],
  });
}

/// Resultado da decisão do motor.
class ResponseDecision {
  final bool shouldRespond;
  final double confidenceLevel;
  final String reasoning;
  final List<String> recommendations;
  final List<SearchResult> selectedResults;
  final QualityAssessment qualityAssessment;
  final Map<String, dynamic> metadata;

  const ResponseDecision({
    required this.shouldRespond,
    required this.confidenceLevel,
    required this.reasoning,
    required this.recommendations,
    required this.selectedResults,
    required this.qualityAssessment,
    required this.metadata,
  });

  /// Indica se a decisão é de alta confiança.
  bool get isHighConfidence => confidenceLevel >= 0.8;

  /// Indica se a decisão é de baixa confiança.
  bool get isLowConfidence => confidenceLevel < 0.5;

  @override
  String toString() => 'ResponseDecision('
      'respond: $shouldRespond, '
      'confidence: ${confidenceLevel.toStringAsFixed(3)}, '
      'reasoning: $reasoning)';
}

/// Motor de decisão para respostas inteligentes.
class ResponseDecisionEngine {
  final QualityClassifier _qualityClassifier;
  final DecisionStrategy _strategy;

  /// Histórico de decisões para aprendizado adaptativo.
  final List<ResponseDecision> _decisionHistory = [];

  /// Configurações adaptáveis baseadas no aprendizado.
  final Map<QueryType, double> _adaptiveThresholds = {
    QueryType.factual: 0.8,
    QueryType.technical: 0.85,
    QueryType.explanatory: 0.7,
    QueryType.procedural: 0.75,
    QueryType.comparative: 0.7,
    QueryType.general: 0.6,
  };

  ResponseDecisionEngine({
    QualityClassifier? qualityClassifier,
    DecisionStrategy strategy = DecisionStrategy.balanced,
  })  : _qualityClassifier = qualityClassifier ?? QualityClassifier(),
        _strategy = strategy;

  /// Decide se deve responder baseado na qualidade das informações.
  ///
  /// [query] - Consulta original
  /// [results] - Resultados da busca
  /// [relevanceScores] - Pontuações de relevância
  /// [context] - Contexto adicional da consulta
  ///
  /// Returns: [ResponseDecision] com a decisão e justificativa
  ResponseDecision makeDecision({
    required String query,
    required List<SearchResult> results,
    required List<RelevanceScore> relevanceScores,
    QueryContext? context,
  }) {
    final queryContext = context ??
        QueryContext(
          originalQuery: query,
          queryType: _qualityClassifier.identifyQueryType(query),
        );

    // 1. Avaliar qualidade das informações
    final qualityAssessment = _qualityClassifier.classifyQuality(
      query: query,
      results: results,
      relevanceScores: relevanceScores,
      queryType: queryContext.queryType,
    );

    // 2. Aplicar estratégia de decisão
    final decision = _applyDecisionStrategy(
      qualityAssessment,
      queryContext,
      results,
      relevanceScores,
    );

    // 3. Registrar decisão para aprendizado
    _recordDecision(decision, queryContext);

    return decision;
  }

  /// Aplica a estratégia de decisão configurada.
  ResponseDecision _applyDecisionStrategy(
    QualityAssessment assessment,
    QueryContext context,
    List<SearchResult> results,
    List<RelevanceScore> relevanceScores,
  ) {
    switch (_strategy) {
      case DecisionStrategy.conservative:
        return _makeConservativeDecision(
            assessment, context, results, relevanceScores);

      case DecisionStrategy.balanced:
        return _makeBalancedDecision(
            assessment, context, results, relevanceScores);

      case DecisionStrategy.aggressive:
        return _makeAggressiveDecision(
            assessment, context, results, relevanceScores);

      case DecisionStrategy.adaptive:
        return _makeAdaptiveDecision(
            assessment, context, results, relevanceScores);
    }
  }

  /// Estratégia conservadora - alta qualidade exigida.
  ResponseDecision _makeConservativeDecision(
    QualityAssessment assessment,
    QueryContext context,
    List<SearchResult> results,
    List<RelevanceScore> relevanceScores,
  ) {
    final threshold = _getThresholdForQueryType(context.queryType) + 0.1;
    final shouldRespond = assessment.isSatisfactory &&
        assessment.confidenceScore >= threshold &&
        assessment.authorityScore >= 0.7;

    return ResponseDecision(
      shouldRespond: shouldRespond,
      confidenceLevel: shouldRespond ? assessment.confidenceScore : 0.0,
      reasoning: shouldRespond
          ? 'Informações de alta qualidade com fontes confiáveis encontradas.'
          : 'Padrão conservador: ${assessment.qualityIssues.join(", ")}',
      recommendations: shouldRespond
          ? ['Resposta recomendada com alta confiança']
          : [
              'Buscar fontes mais autoritativas',
              'Aguardar informações de melhor qualidade'
            ],
      selectedResults:
          shouldRespond ? _selectBestResults(results, relevanceScores, 3) : [],
      qualityAssessment: assessment,
      metadata: {
        'strategy': 'conservative',
        'threshold_used': threshold,
        'decision_factors': ['quality', 'authority', 'confidence'],
      },
    );
  }

  /// Estratégia equilibrada - balanço entre qualidade e utilidade.
  ResponseDecision _makeBalancedDecision(
    QualityAssessment assessment,
    QueryContext context,
    List<SearchResult> results,
    List<RelevanceScore> relevanceScores,
  ) {
    final threshold = _getThresholdForQueryType(context.queryType);
    final urgencyBonus = context.isUrgent ? 0.1 : 0.0;
    final expertiseAdjustment = context.userExpertiseLevel > 0.7 ? -0.05 : 0.0;

    final adjustedThreshold =
        math.max(0.5, threshold - urgencyBonus + expertiseAdjustment);

    final shouldRespond = assessment.confidenceScore >= adjustedThreshold ||
        (assessment.isSatisfactory && assessment.confidenceScore >= 0.6);

    final recommendations = <String>[];
    if (shouldRespond) {
      if (assessment.confidenceScore < 0.7) {
        recommendations.add('Resposta com ressalvas sobre limitações');
      }
      if (assessment.sourceDiversityCount < 2) {
        recommendations.add('Mencionar limitação de fontes');
      }
    } else {
      recommendations.addAll([
        'Refinar consulta para melhor precisão',
        'Considerar busca em fontes especializadas'
      ]);
    }

    return ResponseDecision(
      shouldRespond: shouldRespond,
      confidenceLevel: shouldRespond ? assessment.confidenceScore : 0.0,
      reasoning: shouldRespond
          ? 'Informações suficientes para resposta útil encontradas.'
          : 'Qualidade insuficiente: ${assessment.qualityIssues.join(", ")}',
      recommendations: recommendations,
      selectedResults:
          shouldRespond ? _selectBestResults(results, relevanceScores, 5) : [],
      qualityAssessment: assessment,
      metadata: {
        'strategy': 'balanced',
        'threshold_used': adjustedThreshold,
        'urgency_bonus': urgencyBonus,
        'expertise_adjustment': expertiseAdjustment,
      },
    );
  }

  /// Estratégia agressiva - tenta responder sempre que possível.
  ResponseDecision _makeAggressiveDecision(
    QualityAssessment assessment,
    QueryContext context,
    List<SearchResult> results,
    List<RelevanceScore> relevanceScores,
  ) {
    final threshold =
        math.max(0.4, _getThresholdForQueryType(context.queryType) - 0.2);

    // Responde se houver pelo menos uma fonte razoável
    final hasDecentSource =
        relevanceScores.any((score) => score.overallScore >= 0.5);
    final shouldRespond =
        assessment.confidenceScore >= threshold || hasDecentSource;

    final recommendations = <String>[];
    if (shouldRespond) {
      if (assessment.confidenceScore < 0.6) {
        recommendations.add('Resposta baseada em informações limitadas');
      }
      if (assessment.qualityIssues.isNotEmpty) {
        recommendations
            .add('Mencionar limitações: ${assessment.qualityIssues.first}');
      }
      recommendations.add('Sugerir verificação adicional pelo usuário');
    } else {
      recommendations.add('Expandir critérios de busca');
    }

    return ResponseDecision(
      shouldRespond: shouldRespond,
      confidenceLevel: shouldRespond ? assessment.confidenceScore : 0.0,
      reasoning: shouldRespond
          ? 'Tentativa de resposta útil com informações disponíveis.'
          : 'Nenhuma informação minimamente útil encontrada.',
      recommendations: recommendations,
      selectedResults:
          shouldRespond ? _selectBestResults(results, relevanceScores, 7) : [],
      qualityAssessment: assessment,
      metadata: {
        'strategy': 'aggressive',
        'threshold_used': threshold,
        'has_decent_source': hasDecentSource,
      },
    );
  }

  /// Estratégia adaptativa - aprende com decisões anteriores.
  ResponseDecision _makeAdaptiveDecision(
    QualityAssessment assessment,
    QueryContext context,
    List<SearchResult> results,
    List<RelevanceScore> relevanceScores,
  ) {
    // Ajustar threshold baseado no histórico
    final baseThreshold = _adaptiveThresholds[context.queryType] ?? 0.6;
    final historyAdjustment = _calculateHistoryAdjustment(context.queryType);
    final attemptAdjustment = math.min(0.1, context.attemptNumber * 0.02);

    final adaptiveThreshold =
        math.max(0.3, baseThreshold + historyAdjustment - attemptAdjustment);

    final shouldRespond = assessment.confidenceScore >= adaptiveThreshold;

    // Aprender para próximas decisões
    if (shouldRespond) {
      _updateAdaptiveThreshold(context.queryType, assessment.confidenceScore);
    }

    return ResponseDecision(
      shouldRespond: shouldRespond,
      confidenceLevel: shouldRespond ? assessment.confidenceScore : 0.0,
      reasoning: shouldRespond
          ? 'Decisão adaptativa baseada em padrões aprendidos.'
          : 'Threshold adaptativo não atingido: ${adaptiveThreshold.toStringAsFixed(3)}',
      recommendations: shouldRespond
          ? ['Resposta com confiança adaptativa']
          : ['Ajustar estratégia baseada no aprendizado'],
      selectedResults:
          shouldRespond ? _selectBestResults(results, relevanceScores, 4) : [],
      qualityAssessment: assessment,
      metadata: {
        'strategy': 'adaptive',
        'threshold_used': adaptiveThreshold,
        'history_adjustment': historyAdjustment,
        'attempt_adjustment': attemptAdjustment,
      },
    );
  }

  /// Seleciona os melhores resultados para resposta.
  List<SearchResult> _selectBestResults(
    List<SearchResult> results,
    List<RelevanceScore> relevanceScores,
    int maxResults,
  ) {
    if (results.length != relevanceScores.length) {
      return results.take(maxResults).toList();
    }

    // Criar pares resultado-score
    final pairs = <MapEntry<SearchResult, RelevanceScore>>[];
    for (int i = 0; i < results.length; i++) {
      pairs.add(MapEntry(results[i], relevanceScores[i]));
    }

    // Ordenar por relevância
    pairs.sort((a, b) => b.value.overallScore.compareTo(a.value.overallScore));

    // Retornar top resultados
    return pairs.take(maxResults).map((pair) => pair.key).toList();
  }

  /// Obtém threshold para tipo de consulta.
  double _getThresholdForQueryType(QueryType queryType) {
    return _adaptiveThresholds[queryType] ?? 0.6;
  }

  /// Calcula ajuste baseado no histórico.
  double _calculateHistoryAdjustment(QueryType queryType) {
    final recentDecisions = _decisionHistory
        .where((d) => d.metadata['query_type'] == queryType.name)
        .toList();

    if (recentDecisions.length < 3) return 0.0;

    final successRate = recentDecisions
            .where((d) => d.shouldRespond && d.isHighConfidence)
            .length /
        recentDecisions.length;

    // Ajustar threshold baseado na taxa de sucesso
    if (successRate > 0.8) {
      return -0.05; // Reduzir threshold se está funcionando bem
    } else if (successRate < 0.3) {
      return 0.05; // Aumentar threshold se muitas decisões ruins
    }

    return 0.0;
  }

  /// Atualiza threshold adaptativo.
  void _updateAdaptiveThreshold(QueryType queryType, double observedQuality) {
    final currentThreshold = _adaptiveThresholds[queryType] ?? 0.6;
    final learningRate = 0.1;

    // Ajuste gradual baseado na qualidade observada
    final newThreshold =
        currentThreshold + (observedQuality - currentThreshold) * learningRate;

    _adaptiveThresholds[queryType] = math.max(0.3, math.min(0.9, newThreshold));
  }

  /// Registra decisão para aprendizado.
  void _recordDecision(ResponseDecision decision, QueryContext context) {
    // Adicionar metadata do contexto
    final enhancedMetadata = Map<String, dynamic>.from(decision.metadata);
    enhancedMetadata.addAll({
      'query_type': context.queryType.name,
      'attempt_number': context.attemptNumber,
      'user_expertise': context.userExpertiseLevel,
      'is_urgent': context.isUrgent,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    final enhancedDecision = ResponseDecision(
      shouldRespond: decision.shouldRespond,
      confidenceLevel: decision.confidenceLevel,
      reasoning: decision.reasoning,
      recommendations: decision.recommendations,
      selectedResults: decision.selectedResults,
      qualityAssessment: decision.qualityAssessment,
      metadata: enhancedMetadata,
    );

    _decisionHistory.add(enhancedDecision);

    // Manter apenas últimas 100 decisões
    if (_decisionHistory.length > 100) {
      _decisionHistory.removeRange(0, _decisionHistory.length - 100);
    }
  }

  /// Obtém estatísticas do motor de decisão.
  Map<String, dynamic> getStats() {
    final totalDecisions = _decisionHistory.length;
    if (totalDecisions == 0) {
      return {'total_decisions': 0};
    }

    final responsiveDecisions =
        _decisionHistory.where((d) => d.shouldRespond).length;
    final highConfidenceDecisions =
        _decisionHistory.where((d) => d.isHighConfidence).length;

    return {
      'total_decisions': totalDecisions,
      'response_rate': responsiveDecisions / totalDecisions,
      'high_confidence_rate': highConfidenceDecisions / totalDecisions,
      'adaptive_thresholds': Map.from(_adaptiveThresholds),
      'strategy': _strategy.name,
    };
  }

  /// Redefine o aprendizado adaptativo.
  void resetAdaptiveLearning() {
    _decisionHistory.clear();
    _adaptiveThresholds.clear();
    _adaptiveThresholds.addAll({
      QueryType.factual: 0.8,
      QueryType.technical: 0.85,
      QueryType.explanatory: 0.7,
      QueryType.procedural: 0.75,
      QueryType.comparative: 0.7,
      QueryType.general: 0.6,
    });
  }

  /// Força uma decisão específica (para testes ou override).
  ResponseDecision forceDecision({
    required bool shouldRespond,
    required String reason,
    required List<SearchResult> results,
    required List<RelevanceScore> relevanceScores,
    required QualityAssessment assessment,
  }) {
    return ResponseDecision(
      shouldRespond: shouldRespond,
      confidenceLevel: shouldRespond ? 1.0 : 0.0,
      reasoning: 'Decisão forçada: $reason',
      recommendations: shouldRespond
          ? ['Decisão manual - proceder com resposta']
          : ['Decisão manual - não responder'],
      selectedResults: shouldRespond ? results : [],
      qualityAssessment: assessment,
      metadata: {
        'strategy': 'forced',
        'forced_reason': reason,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
}
