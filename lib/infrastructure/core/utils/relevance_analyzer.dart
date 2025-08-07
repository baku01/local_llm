/// Sistema avançado de análise de relevância de conteúdo web.
///
/// Este módulo implementa algoritmos sofisticados para avaliar a relevância
/// de resultados de pesquisa web em relação à consulta do usuário, usando
/// técnicas de processamento de linguagem natural e análise de similaridade.
library;

import 'dart:math' as math;
import 'package:string_similarity/string_similarity.dart';
import 'text_processor.dart';
import '../../../domain/entities/relevance_score.dart';

/// Analisador avançado de relevância de conteúdo web.
///
/// Implementa múltiplos algoritmos de análise para determinar a relevância
/// de conteúdo web em relação a uma consulta específica, considerando:
/// - Similaridade semântica entre consulta e conteúdo
/// - Densidade e posição de palavras-chave
/// - Qualidade e estrutura do conteúdo
/// - Autoridade e confiabilidade da fonte
/// - Contexto e tópico relevante
class RelevanceAnalyzer {
  final TextProcessor _textProcessor;

  /// Lista de domínios considerados autoritativos.
  static const _authorityDomains = {
    'wikipedia.org': 0.9,
    'github.com': 0.8,
    'stackoverflow.com': 0.85,
    'docs.flutter.dev': 0.9,
    '.edu': 0.85,
    '.gov': 0.9,
    'medium.com': 0.7,
    'dev.to': 0.7,
  };

  /// Stop words em português e inglês para filtragem.
  static const _stopWords = {
    // Português
    'o', 'e', 'da', 'em', 'uma', 'para', 'com', 'por',
    'na', 'ao', 'dos', 'das', 'como', 'mais', 'mas', 'foi', 'ele', 'ela',
    'seu', 'sua', 'ou', 'ser', 'ter', 'que', 'não', 'são', 'este', 'esta',
    'isso', 'essa', 'esse', 'pelo', 'pela', 'pelos', 'pelas',
    // Inglês
    'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
    'of', 'with', 'by', 'from', 'up', 'about', 'into', 'through', 'during',
    'before', 'after', 'above', 'below', 'out', 'off', 'over', 'under',
    'again', 'further', 'then', 'once', 'here', 'there', 'when', 'where',
    'why', 'how', 'all', 'any', 'both', 'each', 'few', 'most',
    'other', 'some', 'such', 'nor', 'not', 'only', 'own', 'same',
    'so', 'than', 'too', 'very', 'can', 'will', 'shall', 'should', 'would',
    'could', 'may', 'might', 'must', 'ought', 'is', 'are', 'was', 'were',
    'be', 'been', 'being', 'have', 'has', 'had', 'do', 'does', 'did',
  };

  RelevanceAnalyzer() : _textProcessor = TextProcessor();

  /// Analisa a relevância de um resultado de pesquisa.
  ///
  /// [query] - Consulta original do usuário
  /// [title] - Título da página/resultado
  /// [snippet] - Snippet/descrição do resultado
  /// [url] - URL da página
  /// [content] - Conteúdo completo da página (opcional)
  ///
  /// Returns: [RelevanceScore] com pontuação detalhada de relevância
  RelevanceScore analyzeRelevance({
    required String query,
    required String title,
    required String snippet,
    required String url,
    String? content,
  }) {
    final scoringFactors = <String, double>{};

    // Preprocessar textos
    final processedQuery = _textProcessor.processText(query);
    final processedTitle = _textProcessor.processText(title);
    final processedSnippet = _textProcessor.processText(snippet);
    final processedContent =
        content != null ? _textProcessor.processText(content) : '';

    // 1. Análise de similaridade semântica
    final semanticScore = _calculateSemanticSimilarity(
      processedQuery,
      processedTitle,
      processedSnippet,
      processedContent,
    );
    scoringFactors['semantic_similarity'] = semanticScore;

    // 2. Análise de palavras-chave
    final keywordScore = _calculateKeywordScore(
      processedQuery,
      processedTitle,
      processedSnippet,
      processedContent,
    );
    scoringFactors['keyword_density'] = keywordScore;

    // 3. Análise de qualidade do conteúdo
    final qualityScore = _calculateContentQuality(
      title,
      snippet,
      content ?? '',
    );
    scoringFactors['content_quality'] = qualityScore;

    // 4. Análise de autoridade da fonte
    final authorityScore = _calculateAuthorityScore(url);
    scoringFactors['source_authority'] = authorityScore;

    // 5. Bônus por posição de palavras-chave
    final positionBonus = _calculatePositionBonus(
      processedQuery,
      processedTitle,
      processedSnippet,
    );
    scoringFactors['position_bonus'] = positionBonus;

    // 6. Penalização por conteúdo duplicado/spam
    final spamPenalty = _calculateSpamPenalty(title, snippet, content ?? '');
    scoringFactors['spam_penalty'] = spamPenalty;

    // Calcular pontuação geral com pesos otimizados
    final overallScore = _calculateWeightedScore({
      'semantic': semanticScore * 0.35,
      'keyword': keywordScore * 0.25,
      'quality': qualityScore * 0.20,
      'authority': authorityScore * 0.10,
      'position': positionBonus * 0.05,
      'spam_penalty': spamPenalty * 0.05,
    });

    return RelevanceScore(
      overallScore: math.max(0.0, math.min(1.0, overallScore)),
      semanticScore: semanticScore,
      keywordScore: keywordScore,
      qualityScore: qualityScore,
      authorityScore: authorityScore,
      scoringFactors: scoringFactors,
    );
  }

  /// Calcula similaridade semântica usando múltiplas métricas.
  double _calculateSemanticSimilarity(
    String query,
    String title,
    String snippet,
    String content,
  ) {
    if (query.isEmpty) return 0.0;

    final titleSim = StringSimilarity.compareTwoStrings(query, title);
    final snippetSim = StringSimilarity.compareTwoStrings(query, snippet);

    double contentSim = 0.0;
    if (content.isNotEmpty) {
      // Para conteúdo longo, usar similaridade com fragmentos
      final contentFragments = _extractRelevantFragments(content, query);
      contentSim = contentFragments.isNotEmpty
          ? contentFragments
              .map((fragment) =>
                  StringSimilarity.compareTwoStrings(query, fragment))
              .reduce(math.max)
          : 0.0;
    }

    // Pontuação ponderada: título tem maior peso
    return (titleSim * 0.5) + (snippetSim * 0.3) + (contentSim * 0.2);
  }

  /// Calcula pontuação baseada em densidade de palavras-chave.
  double _calculateKeywordScore(
    String query,
    String title,
    String snippet,
    String content,
  ) {
    final queryWords = _extractKeywords(query);
    if (queryWords.isEmpty) return 0.0;

    final titleWords = _extractKeywords(title);
    final snippetWords = _extractKeywords(snippet);
    final contentWords =
        content.isNotEmpty ? _extractKeywords(content) : <String>[];

    double score = 0.0;

    for (final keyword in queryWords) {
      double keywordScore = 0.0;

      // Correspondência exata no título (peso alto)
      if (titleWords.contains(keyword)) {
        keywordScore += 0.4;
      }

      // Correspondência no snippet
      if (snippetWords.contains(keyword)) {
        keywordScore += 0.3;
      }

      // Correspondência no conteúdo
      if (contentWords.contains(keyword)) {
        keywordScore += 0.2;
      }

      // Correspondência parcial (substring)
      if (title.toLowerCase().contains(keyword.toLowerCase())) {
        keywordScore += 0.1;
      }

      if (keywordScore > 0) {
        score += keywordScore;
      }
    }

    // Normalizar pela quantidade de palavras-chave
    return queryWords.isNotEmpty ? score / queryWords.length : 0.0;
  }

  /// Avalia a qualidade geral do conteúdo.
  double _calculateContentQuality(
      String title, String snippet, String content) {
    double score = 0.0;

    // Qualidade do título
    if (title.length >= 10 && title.length <= 100) score += 0.2;
    if (title.split(' ').length >= 3) score += 0.1;
    if (!title.contains('...')) score += 0.1;

    // Qualidade do snippet
    if (snippet.length >= 50 && snippet.length <= 300) score += 0.2;
    if (snippet.split(' ').length >= 10) score += 0.1;

    // Qualidade do conteúdo (se disponível)
    if (content.isNotEmpty) {
      final wordCount = content.split(' ').length;
      if (wordCount >= 100) score += 0.1;
      if (wordCount >= 500) score += 0.1;

      // Verifica estrutura (parágrafos, listas)
      if (content.contains('\n\n') || content.contains('<p>')) score += 0.1;
    }

    return math.min(1.0, score);
  }

  /// Calcula pontuação de autoridade da fonte.
  double _calculateAuthorityScore(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return 0.0;

    final domain = uri.host.toLowerCase();

    // Verifica domínios autoritativos específicos
    for (final entry in _authorityDomains.entries) {
      if (domain.contains(entry.key)) {
        return entry.value;
      }
    }

    // Heurísticas gerais
    double score = 0.5; // Pontuação base

    // HTTPS é melhor
    if (uri.scheme == 'https') score += 0.1;

    // Domínios mais curtos tendem a ser mais estabelecidos
    if (domain.split('.').length == 2) score += 0.1;

    // Evita subdomínios suspeitos
    if (domain.contains('blog') || domain.contains('news')) score += 0.05;
    if (domain.contains('spam') || domain.contains('ads')) score -= 0.3;

    return math.max(0.0, math.min(1.0, score));
  }

  /// Calcula bônus por posição estratégica de palavras-chave.
  double _calculatePositionBonus(String query, String title, String snippet) {
    final queryWords = _extractKeywords(query);
    if (queryWords.isEmpty) return 0.0;

    double bonus = 0.0;

    for (final keyword in queryWords) {
      // Bônus se palavra-chave está no início do título
      if (title.toLowerCase().startsWith(keyword.toLowerCase())) {
        bonus += 0.3;
      }

      // Bônus se palavra-chave está no início do snippet
      if (snippet.toLowerCase().startsWith(keyword.toLowerCase())) {
        bonus += 0.2;
      }
    }

    return math.min(0.5, bonus);
  }

  /// Detecta e penaliza conteúdo spam ou de baixa qualidade.
  double _calculateSpamPenalty(String title, String snippet, String content) {
    double penalty = 0.0;

    final allText = '$title $snippet $content'.toLowerCase();

    // Penalidades por indicadores de spam
    if (allText.contains('click here') || allText.contains('clique aqui')) {
      penalty += 0.2;
    }

    if (allText.contains('buy now') || allText.contains('compre agora')) {
      penalty += 0.3;
    }

    // Excesso de caracteres especiais ou maiúsculas
    final specialCharCount =
        title.replaceAll(RegExp(r'[a-zA-Z0-9\s]'), '').length;
    if (specialCharCount > title.length * 0.2) penalty += 0.2;

    final upperCaseCount = title.replaceAll(RegExp(r'[^A-Z]'), '').length;
    if (upperCaseCount > title.length * 0.5) penalty += 0.3;

    return math.min(1.0, penalty);
  }

  /// Extrai palavras-chave relevantes removendo stop words.
  List<String> _extractKeywords(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 2 && !_stopWords.contains(word))
        .toList();
  }

  /// Extrai fragmentos relevantes do conteúdo baseado na consulta.
  List<String> _extractRelevantFragments(String content, String query) {
    final queryWords = _extractKeywords(query);
    final sentences = content.split(RegExp(r'[.!?]+'));

    final relevantSentences = <String>[];

    for (final sentence in sentences) {
      if (sentence.trim().length < 20) continue;

      final sentenceWords = _extractKeywords(sentence);
      final matchCount = queryWords
          .where((qWord) => sentenceWords
              .any((sWord) => sWord.contains(qWord) || qWord.contains(sWord)))
          .length;

      if (matchCount >= 1) {
        relevantSentences.add(sentence.trim());
      }
    }

    // Limitar a 5 fragmentos mais relevantes
    return relevantSentences.take(5).toList();
  }

  /// Calcula pontuação final ponderada.
  double _calculateWeightedScore(Map<String, double> scores) {
    return scores.values.fold(0.0, (sum, score) => sum + score);
  }

  /// Filtra e ordena resultados por relevância.
  List<T> filterAndRankResults<T>(
    List<T> results,
    List<RelevanceScore> scores, {
    double minRelevanceThreshold = 0.4,
  }) {
    if (results.length != scores.length) {
      throw ArgumentError('Results and scores lists must have the same length');
    }

    final indexedResults = <int, T>{};
    final indexedScores = <int, RelevanceScore>{};

    for (int i = 0; i < results.length; i++) {
      if (scores[i].overallScore >= minRelevanceThreshold) {
        indexedResults[i] = results[i];
        indexedScores[i] = scores[i];
      }
    }

    final sortedIndices = indexedScores.keys.toList()
      ..sort((a, b) => indexedScores[b]!
          .overallScore
          .compareTo(indexedScores[a]!.overallScore));

    return sortedIndices.map((index) => indexedResults[index]!).toList();
  }
}
