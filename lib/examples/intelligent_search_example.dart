/// Exemplo de como usar o sistema de busca inteligente com classificação de qualidade.
///
/// Este arquivo demonstra como integrar o novo sistema de busca que só responde
/// quando considera as informações como satisfatórias.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../infrastructure/core/services/intelligent_search_service.dart';
import '../infrastructure/core/classification/quality_classifier.dart';
import '../infrastructure/core/classification/response_decision_engine.dart';

/// Exemplo prático de uso do sistema de busca inteligente.
class IntelligentSearchExample {
  late final IntelligentSearchService _searchService;

  /// Inicializa o serviço com configurações personalizadas.
  Future<void> initialize() async {
    // Configuração personalizada para diferentes cenários
    final config = IntelligentSearchConfig(
      maxSearchAttempts: 3,
      maxResultsPerAttempt: 10,
      decisionStrategy: DecisionStrategy.balanced,
      minConfidenceThreshold: 0.7,
      enableAdaptiveLearning: true,
      enableCaching: true,
      preferredDomains: [
        'stackoverflow.com',
        'github.com',
        'docs.flutter.dev',
        'wikipedia.org',
      ],
      blockedDomains: [
        'spam.com',
        'clickbait.net',
      ],
    );

    // Criar componentes com configurações específicas
    final qualityClassifier = QualityClassifier();
    final decisionEngine = ResponseDecisionEngine(
      strategy: DecisionStrategy.balanced,
    );

    // Inicializar o serviço
    _searchService = IntelligentSearchService(
      config: config,
      qualityClassifier: qualityClassifier,
      decisionEngine: decisionEngine,
    );

    debugPrint('✅ Sistema de busca inteligente inicializado');
  }

  /// Exemplo de busca com diferentes tipos de consulta.
  Future<void> demonstrateSearchTypes() async {
    debugPrint('\n🔍 Demonstrando diferentes tipos de busca:\n');

    // 1. Pergunta factual - requer alta precisão
    await _performExampleSearch(
      'O que é Flutter framework?',
      QueryContext(
        originalQuery: 'O que é Flutter framework?',
        queryType: QueryType.factual,
        userExpertiseLevel: 0.3, // Usuário iniciante
      ),
    );

    // 2. Pergunta técnica - requer fontes autoritativas
    await _performExampleSearch(
      'Como implementar state management no Flutter com Riverpod?',
      QueryContext(
        originalQuery:
            'Como implementar state management no Flutter com Riverpod?',
        queryType: QueryType.technical,
        userExpertiseLevel: 0.7, // Usuário avançado
      ),
    );

    // 3. Pergunta comparativa - requer múltiplas fontes
    await _performExampleSearch(
      'Flutter vs React Native performance comparison',
      QueryContext(
        originalQuery: 'Flutter vs React Native performance comparison',
        queryType: QueryType.comparative,
        userExpertiseLevel: 0.5,
      ),
    );

    // 4. Pergunta procedural - requer tutorial passo a passo
    await _performExampleSearch(
      'Como instalar Flutter no macOS',
      QueryContext(
        originalQuery: 'Como instalar Flutter no macOS',
        queryType: QueryType.procedural,
        userExpertiseLevel: 0.2, // Usuário iniciante
        isUrgent: true, // Contexto urgente
      ),
    );
  }

  /// Realiza uma busca de exemplo e mostra os resultados.
  Future<void> _performExampleSearch(String query, QueryContext context) async {
    debugPrint('🔍 Buscando: "$query"');
    debugPrint('📊 Tipo: ${context.queryType.name}');
    debugPrint(
        '👤 Nível de experiência: ${(context.userExpertiseLevel * 100).toStringAsFixed(0)}%');
    if (context.isUrgent) debugPrint('⚡ Urgente: Sim');
    debugPrint('---');

    try {
      final result = await _searchService.searchIntelligently(
        query: query,
        context: context,
      );

      _displaySearchResult(result);
    } catch (e) {
      debugPrint('❌ Erro na busca: $e');
    }

    debugPrint('\n${'=' * 80}\n');
  }

  /// Exibe os resultados da busca de forma detalhada.
  void _displaySearchResult(IntelligentSearchResult result) {
    debugPrint('📋 RESULTADO DA ANÁLISE:');
    debugPrint('');

    // Status da resposta
    if (result.canProvideAnswer) {
      if (result.isHighQuality) {
        debugPrint('✅ PODE RESPONDER - Alta Qualidade');
      } else if (result.isQualifiedAnswer) {
        debugPrint('⚠️  PODE RESPONDER - Com Ressalvas');
      } else {
        debugPrint('📝 PODE RESPONDER - Qualidade Básica');
      }
    } else {
      debugPrint('❌ NÃO DEVE RESPONDER');
    }

    debugPrint(
        '🎯 Confiança: ${(result.confidenceLevel * 100).toStringAsFixed(1)}%');
    debugPrint('⏱️  Tempo: ${result.totalSearchTime.inMilliseconds}ms');
    debugPrint('🔄 Tentativas: ${result.attemptsUsed}');
    debugPrint('');

    // Análise de qualidade
    final qa = result.qualityAssessment;
    debugPrint('📊 ANÁLISE DE QUALIDADE:');
    debugPrint(
        '  • Cobertura: ${(qa.coverageScore * 100).toStringAsFixed(1)}%');
    debugPrint(
        '  • Autoridade: ${(qa.authorityScore * 100).toStringAsFixed(1)}%');
    debugPrint(
        '  • Profundidade: ${(qa.contentDepthScore * 100).toStringAsFixed(1)}%');
    debugPrint('  • Diversidade de fontes: ${qa.sourceDiversityCount}');
    debugPrint('');

    // Pontos fortes
    if (qa.strengths.isNotEmpty) {
      debugPrint('✅ PONTOS FORTES:');
      for (final strength in qa.strengths) {
        debugPrint('  • $strength');
      }
      debugPrint('');
    }

    // Problemas identificados
    if (qa.qualityIssues.isNotEmpty) {
      debugPrint('⚠️  PROBLEMAS IDENTIFICADOS:');
      for (final issue in qa.qualityIssues) {
        debugPrint('  • $issue');
      }
      debugPrint('');
    }

    // Raciocínio da decisão
    debugPrint('🧠 RACIOCÍNIO: ${result.reasoning}');
    debugPrint('');

    // Recomendações
    if (result.decision.recommendations.isNotEmpty) {
      debugPrint('💡 RECOMENDAÇÕES:');
      for (final rec in result.decision.recommendations) {
        debugPrint('  • $rec');
      }
      debugPrint('');
    }

    // Resultados selecionados
    if (result.selectedResults.isNotEmpty) {
      debugPrint('📄 FONTES SELECIONADAS (${result.selectedResults.length}):');
      for (int i = 0; i < result.selectedResults.length; i++) {
        final source = result.selectedResults[i];
        debugPrint('  ${i + 1}. ${source.title}');
        debugPrint('     🔗 ${source.url}');
        if (source.snippet.isNotEmpty) {
          final snippet = source.snippet.length > 100
              ? '${source.snippet.substring(0, 100)}...'
              : source.snippet;
          debugPrint('     📝 $snippet');
        }
        debugPrint('');
      }
    }

    // Sugestão para próximos passos
    if (result.suggestAdditionalSearch) {
      debugPrint('🔍 PRÓXIMOS PASSOS SUGERIDOS:');
      debugPrint('  • Considerar busca adicional para melhor qualidade');
      if (result.confidenceLevel < 0.5) {
        debugPrint('  • Refinar termos de busca');
        debugPrint('  • Tentar abordagem diferente');
      }
      debugPrint('');
    }
  }

  /// Demonstra diferentes estratégias de decisão.
  Future<void> demonstrateDecisionStrategies() async {
    debugPrint('\n🎯 Comparando estratégias de decisão:\n');

    const query = 'Como funciona machine learning?';
    final context = QueryContext(
      originalQuery: query,
      queryType: QueryType.explanatory,
      userExpertiseLevel: 0.4,
    );

    final strategies = [
      DecisionStrategy.conservative,
      DecisionStrategy.balanced,
      DecisionStrategy.aggressive,
    ];

    for (final strategy in strategies) {
      debugPrint('📊 Estratégia: ${strategy.name.toUpperCase()}');

      // Criar serviço com estratégia específica
      final config = IntelligentSearchConfig(
        decisionStrategy: strategy,
        minConfidenceThreshold:
            strategy == DecisionStrategy.conservative ? 0.8 : 0.6,
        maxSearchAttempts: 3,
        maxResultsPerAttempt: 10,
        enableAdaptiveLearning: true,
        enableCaching: true,
      );

      final strategyService = IntelligentSearchService(config: config);

      try {
        final result = await strategyService.searchIntelligently(
          query: query,
          context: context,
        );

        debugPrint('  Pode responder: ${result.canProvideAnswer ? "✅" : "❌"}');
        debugPrint(
            '  Confiança: ${(result.confidenceLevel * 100).toStringAsFixed(1)}%');
        debugPrint('  Raciocínio: ${result.reasoning}');
        debugPrint('');
      } catch (e) {
        debugPrint('  Erro: $e\n');
      }
    }
  }

  /// Mostra métricas de desempenho do sistema.
  void showPerformanceMetrics() {
    debugPrint('\n📈 MÉTRICAS DE DESEMPENHO:\n');

    final metrics = _searchService.getPerformanceMetrics();

    debugPrint('📊 Estatísticas Gerais:');
    debugPrint('  • Total de consultas: ${metrics.totalQueries}');
    debugPrint(
        '  • Taxa de sucesso: ${(metrics.successRate * 100).toStringAsFixed(1)}%');
    debugPrint(
        '  • Taxa de rejeição: ${(metrics.rejectionRate * 100).toStringAsFixed(1)}%');
    debugPrint(
        '  • Confiança média: ${(metrics.averageConfidence * 100).toStringAsFixed(1)}%');
    debugPrint(
        '  • Tempo médio: ${metrics.averageSearchTime.inMilliseconds}ms');
    debugPrint('');

    if (metrics.queryTypeDistribution.isNotEmpty) {
      debugPrint('📋 Distribuição por Tipo de Consulta:');
      for (final entry in metrics.queryTypeDistribution.entries) {
        final percentage =
            (entry.value / metrics.totalQueries * 100).toStringAsFixed(1);
        debugPrint('  • ${entry.key.name}: ${entry.value} ($percentage%)');
      }
      debugPrint('');
    }

    // Estatísticas do motor de decisão
    final decisionStats =
        (_searchService as dynamic)._decisionEngine.getStats();
    debugPrint('🧠 Estatísticas do Motor de Decisão:');
    debugPrint('  • Total de decisões: ${decisionStats['total_decisions']}');
    debugPrint(
        '  • Taxa de resposta: ${(decisionStats['response_rate'] * 100).toStringAsFixed(1)}%');
    debugPrint(
        '  • Taxa alta confiança: ${(decisionStats['high_confidence_rate'] * 100).toStringAsFixed(1)}%');
    debugPrint('  • Estratégia: ${decisionStats['strategy']}');
  }

  /// Exemplo de como processar uma consulta do usuário real.
  Future<Map<String, dynamic>> processUserQuery(
    String userQuery, {
    double userExpertiseLevel = 0.5,
    bool isUrgent = false,
    List<String> preferredSources = const [],
  }) async {
    // Identificar automaticamente o tipo de consulta
    final qualityClassifier = QualityClassifier();
    final queryType = qualityClassifier.identifyQueryType(userQuery);

    // Criar contexto
    final context = QueryContext(
      originalQuery: userQuery,
      queryType: queryType,
      userExpertiseLevel: userExpertiseLevel,
      isUrgent: isUrgent,
      preferredSources: preferredSources,
    );

    // Realizar busca
    final result = await _searchService.searchIntelligently(
      query: userQuery,
      context: context,
    );

    // Retornar resposta estruturada
    return {
      'should_respond': result.canProvideAnswer,
      'confidence_level': result.confidenceLevel,
      'quality_tier': result.isHighQuality
          ? 'high'
          : result.isQualifiedAnswer
              ? 'medium'
              : 'low',
      'reasoning': result.reasoning,
      'recommendations': result.decision.recommendations,
      'sources': result.selectedResults
          .map((r) => {
                'title': r.title,
                'url': r.url,
                'snippet': r.snippet,
              })
          .toList(),
      'quality_issues': result.qualityAssessment.qualityIssues,
      'search_metrics': {
        'attempts_used': result.attemptsUsed,
        'search_time_ms': result.totalSearchTime.inMilliseconds,
        'query_type': queryType.name,
      },
      'next_actions': _generateNextActions(result),
    };
  }

  /// Gera ações recomendadas baseadas no resultado.
  List<String> _generateNextActions(IntelligentSearchResult result) {
    final actions = <String>[];

    if (result.canProvideAnswer) {
      if (result.isHighQuality) {
        actions.add('Fornecer resposta completa com confiança');
      } else {
        actions.add('Fornecer resposta com ressalvas sobre limitações');
        actions.add('Mencionar nível de confiança ao usuário');
      }

      if (result.qualityAssessment.sourceDiversityCount < 2) {
        actions.add('Sugerir verificação em fontes adicionais');
      }
    } else {
      actions.add('Informar que não há informações suficientemente confiáveis');
      actions.add('Sugerir reformulação da pergunta');

      if (result.qualityAssessment.authorityScore < 0.5) {
        actions.add('Recomendar busca em fontes mais especializadas');
      }

      if (result.qualityAssessment.coverageScore < 0.5) {
        actions.add('Sugerir termos de busca mais específicos');
      }
    }

    return actions;
  }

  /// Limpa recursos e estado.
  void dispose() {
    _searchService.dispose();
  }
}

/// Função principal para executar os exemplos.
Future<void> main() async {
  final example = IntelligentSearchExample();

  try {
    debugPrint('🚀 Inicializando Sistema de Busca Inteligente\n');

    await example.initialize();

    debugPrint('📝 Executando demonstrações...\n');

    // Demonstrar diferentes tipos de busca
    await example.demonstrateSearchTypes();

    // Comparar estratégias de decisão
    await example.demonstrateDecisionStrategies();

    // Mostrar métricas de desempenho
    example.showPerformanceMetrics();

    debugPrint('\n✅ Demonstração concluída com sucesso!');

    // Exemplo de processamento de consulta real
    debugPrint('\n🔍 Exemplo de processamento de consulta real:');
    final result = await example.processUserQuery(
      'Como criar um app Flutter responsivo?',
      userExpertiseLevel: 0.3,
      isUrgent: false,
    );

    debugPrint(
        'Resultado: ${result['should_respond'] ? "Pode responder" : "Não deve responder"}');
    debugPrint(
        'Confiança: ${(result['confidence_level'] * 100).toStringAsFixed(1)}%');
    debugPrint('Qualidade: ${result['quality_tier']}');
  } catch (e) {
    debugPrint('❌ Erro durante a execução: $e');
  } finally {
    example.dispose();
  }
}
