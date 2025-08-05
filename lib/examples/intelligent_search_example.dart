/// Exemplo de como usar o sistema de busca inteligente com classificação de qualidade.
///
/// Este arquivo demonstra como integrar o novo sistema de busca que só responde
/// quando considera as informações como satisfatórias.
library;

import 'dart:async';
import '../core/services/intelligent_search_service.dart';
import '../core/classification/quality_classifier.dart';
import '../core/classification/response_decision_engine.dart';

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

    print('✅ Sistema de busca inteligente inicializado');
  }

  /// Exemplo de busca com diferentes tipos de consulta.
  Future<void> demonstrateSearchTypes() async {
    print('\n🔍 Demonstrando diferentes tipos de busca:\n');

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
    print('🔍 Buscando: "$query"');
    print('📊 Tipo: ${context.queryType.name}');
    print(
        '👤 Nível de experiência: ${(context.userExpertiseLevel * 100).toStringAsFixed(0)}%');
    if (context.isUrgent) print('⚡ Urgente: Sim');
    print('---');

    try {
      final result = await _searchService.searchIntelligently(
        query: query,
        context: context,
      );

      _displaySearchResult(result);
    } catch (e) {
      print('❌ Erro na busca: $e');
    }

    print('\n${'=' * 80}\n');
  }

  /// Exibe os resultados da busca de forma detalhada.
  void _displaySearchResult(IntelligentSearchResult result) {
    print('📋 RESULTADO DA ANÁLISE:');
    print('');

    // Status da resposta
    if (result.canProvideAnswer) {
      if (result.isHighQuality) {
        print('✅ PODE RESPONDER - Alta Qualidade');
      } else if (result.isQualifiedAnswer) {
        print('⚠️  PODE RESPONDER - Com Ressalvas');
      } else {
        print('📝 PODE RESPONDER - Qualidade Básica');
      }
    } else {
      print('❌ NÃO DEVE RESPONDER');
    }

    print(
        '🎯 Confiança: ${(result.confidenceLevel * 100).toStringAsFixed(1)}%');
    print('⏱️  Tempo: ${result.totalSearchTime.inMilliseconds}ms');
    print('🔄 Tentativas: ${result.attemptsUsed}');
    print('');

    // Análise de qualidade
    final qa = result.qualityAssessment;
    print('📊 ANÁLISE DE QUALIDADE:');
    print('  • Cobertura: ${(qa.coverageScore * 100).toStringAsFixed(1)}%');
    print('  • Autoridade: ${(qa.authorityScore * 100).toStringAsFixed(1)}%');
    print(
        '  • Profundidade: ${(qa.contentDepthScore * 100).toStringAsFixed(1)}%');
    print('  • Diversidade de fontes: ${qa.sourceDiversityCount}');
    print('');

    // Pontos fortes
    if (qa.strengths.isNotEmpty) {
      print('✅ PONTOS FORTES:');
      for (final strength in qa.strengths) {
        print('  • $strength');
      }
      print('');
    }

    // Problemas identificados
    if (qa.qualityIssues.isNotEmpty) {
      print('⚠️  PROBLEMAS IDENTIFICADOS:');
      for (final issue in qa.qualityIssues) {
        print('  • $issue');
      }
      print('');
    }

    // Raciocínio da decisão
    print('🧠 RACIOCÍNIO: ${result.reasoning}');
    print('');

    // Recomendações
    if (result.decision.recommendations.isNotEmpty) {
      print('💡 RECOMENDAÇÕES:');
      for (final rec in result.decision.recommendations) {
        print('  • $rec');
      }
      print('');
    }

    // Resultados selecionados
    if (result.selectedResults.isNotEmpty) {
      print('📄 FONTES SELECIONADAS (${result.selectedResults.length}):');
      for (int i = 0; i < result.selectedResults.length; i++) {
        final source = result.selectedResults[i];
        print('  ${i + 1}. ${source.title}');
        print('     🔗 ${source.url}');
        if (source.snippet.isNotEmpty) {
          final snippet = source.snippet.length > 100
              ? '${source.snippet.substring(0, 100)}...'
              : source.snippet;
          print('     📝 $snippet');
        }
        print('');
      }
    }

    // Sugestão para próximos passos
    if (result.suggestAdditionalSearch) {
      print('🔍 PRÓXIMOS PASSOS SUGERIDOS:');
      print('  • Considerar busca adicional para melhor qualidade');
      if (result.confidenceLevel < 0.5) {
        print('  • Refinar termos de busca');
        print('  • Tentar abordagem diferente');
      }
      print('');
    }
  }

  /// Demonstra diferentes estratégias de decisão.
  Future<void> demonstrateDecisionStrategies() async {
    print('\n🎯 Comparando estratégias de decisão:\n');

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
      print('📊 Estratégia: ${strategy.name.toUpperCase()}');

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

        print('  Pode responder: ${result.canProvideAnswer ? "✅" : "❌"}');
        print(
            '  Confiança: ${(result.confidenceLevel * 100).toStringAsFixed(1)}%');
        print('  Raciocínio: ${result.reasoning}');
        print('');
      } catch (e) {
        print('  Erro: $e\n');
      }
    }
  }

  /// Mostra métricas de desempenho do sistema.
  void showPerformanceMetrics() {
    print('\n📈 MÉTRICAS DE DESEMPENHO:\n');

    final metrics = _searchService.getPerformanceMetrics();

    print('📊 Estatísticas Gerais:');
    print('  • Total de consultas: ${metrics.totalQueries}');
    print(
        '  • Taxa de sucesso: ${(metrics.successRate * 100).toStringAsFixed(1)}%');
    print(
        '  • Taxa de rejeição: ${(metrics.rejectionRate * 100).toStringAsFixed(1)}%');
    print(
        '  • Confiança média: ${(metrics.averageConfidence * 100).toStringAsFixed(1)}%');
    print('  • Tempo médio: ${metrics.averageSearchTime.inMilliseconds}ms');
    print('');

    if (metrics.queryTypeDistribution.isNotEmpty) {
      print('📋 Distribuição por Tipo de Consulta:');
      for (final entry in metrics.queryTypeDistribution.entries) {
        final percentage =
            (entry.value / metrics.totalQueries * 100).toStringAsFixed(1);
        print('  • ${entry.key.name}: ${entry.value} ($percentage%)');
      }
      print('');
    }

    // Estatísticas do motor de decisão
    final decisionStats =
        (_searchService as dynamic)._decisionEngine.getStats();
    print('🧠 Estatísticas do Motor de Decisão:');
    print('  • Total de decisões: ${decisionStats['total_decisions']}');
    print(
        '  • Taxa de resposta: ${(decisionStats['response_rate'] * 100).toStringAsFixed(1)}%');
    print(
        '  • Taxa alta confiança: ${(decisionStats['high_confidence_rate'] * 100).toStringAsFixed(1)}%');
    print('  • Estratégia: ${decisionStats['strategy']}');
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
    print('🚀 Inicializando Sistema de Busca Inteligente\n');

    await example.initialize();

    print('📝 Executando demonstrações...\n');

    // Demonstrar diferentes tipos de busca
    await example.demonstrateSearchTypes();

    // Comparar estratégias de decisão
    await example.demonstrateDecisionStrategies();

    // Mostrar métricas de desempenho
    example.showPerformanceMetrics();

    print('\n✅ Demonstração concluída com sucesso!');

    // Exemplo de processamento de consulta real
    print('\n🔍 Exemplo de processamento de consulta real:');
    final result = await example.processUserQuery(
      'Como criar um app Flutter responsivo?',
      userExpertiseLevel: 0.3,
      isUrgent: false,
    );

    print(
        'Resultado: ${result['should_respond'] ? "Pode responder" : "Não deve responder"}');
    print(
        'Confiança: ${(result['confidence_level'] * 100).toStringAsFixed(1)}%');
    print('Qualidade: ${result['quality_tier']}');
  } catch (e) {
    print('❌ Erro durante a execução: $e');
  } finally {
    example.dispose();
  }
}
