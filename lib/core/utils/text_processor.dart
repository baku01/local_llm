/// Processador avançado de texto para análise de conteúdo web.
///
/// Este módulo fornece funcionalidades de processamento de linguagem natural
/// para normalização, limpeza e análise de texto, otimizado para conteúdo web
/// em português e inglês.
library;

import 'dart:math' as math;

/// Processador de texto com funcionalidades avançadas de NLP.
///
/// Implementa algoritmos de processamento de texto incluindo:
/// - Normalização e limpeza de texto
/// - Remoção de elementos HTML e markup
/// - Tokenização inteligente
/// - Detecção de idioma básica
/// - Extração de entidades principais
class TextProcessor {
  /// Expressões regulares para limpeza de texto.
  static final _htmlTagRegex = RegExp(r'<[^>]*>');
  static final _whitespaceRegex = RegExp(r'\s+');
  static final _punctuationRegex = RegExp(r'[^\w\s]');
  static final _numberRegex = RegExp(r'\b\d+\b');
  static final _urlRegex = RegExp(r'https?://[^\s]+');
  static final _emailRegex =
      RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');

  /// Palavras comuns em português que podem indicar qualidade de conteúdo.
  static const _qualityIndicators = {
    'introdução',
    'conclusão',
    'resumo',
    'exemplo',
    'definição',
    'conceito',
    'importante',
    'fundamental',
    'essencial',
    'principais',
    'características',
    'vantagens',
    'desvantagens',
    'benefícios',
    'como',
    'quando',
    'onde',
    'porque',
    'introduction',
    'conclusion',
    'summary',
    'example',
    'definition',
    'concept',
    'important',
    'essential',
    'main',
    'characteristics',
    'advantages',
    'disadvantages',
    'benefits',
    'how',
    'when',
    'where',
    'why',
  };

  /// Processa e normaliza texto para análise.
  ///
  /// [text] - Texto original a ser processado
  /// [preserveStructure] - Se deve preservar quebras de linha e estrutura
  /// [removeNumbers] - Se deve remover números do texto
  ///
  /// Returns: Texto processado e normalizado
  String processText(
    String text, {
    bool preserveStructure = false,
    bool removeNumbers = false,
  }) {
    if (text.isEmpty) return '';

    String processed = text;

    // 1. Remover tags HTML
    processed = _removeHtmlTags(processed);

    // 2. Normalizar URLs e emails
    processed = _normalizeUrlsAndEmails(processed);

    // 3. Normalizar espaços em branco
    processed = _normalizeWhitespace(processed, preserveStructure);

    // 4. Remover números se solicitado
    if (removeNumbers) {
      processed = _removeNumbers(processed);
    }

    // 5. Normalizar pontuação
    processed = _normalizePunctuation(processed);

    // 6. Converter para minúsculas para análise
    processed = processed.toLowerCase().trim();

    return processed;
  }

  /// Remove tags HTML e entidades do texto.
  String _removeHtmlTags(String text) {
    // Substituir entidades HTML comuns
    String cleaned = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'");

    // Remover tags HTML
    cleaned = cleaned.replaceAll(_htmlTagRegex, ' ');

    return cleaned;
  }

  /// Normaliza URLs e emails no texto.
  String _normalizeUrlsAndEmails(String text) {
    return text
        .replaceAll(_urlRegex, '[URL]')
        .replaceAll(_emailRegex, '[EMAIL]');
  }

  /// Normaliza espaços em branco e quebras de linha.
  String _normalizeWhitespace(String text, bool preserveStructure) {
    if (preserveStructure) {
      // Preservar quebras de linha duplas (parágrafos)
      return text
          .replaceAll(RegExp(r'\n{3,}'), '\n\n')
          .replaceAll(RegExp(r'[ \t]+'), ' ')
          .replaceAll(RegExp(r'\n[ \t]+'), '\n')
          .trim();
    } else {
      // Normalizar todos os espaços
      return text.replaceAll(_whitespaceRegex, ' ').trim();
    }
  }

  /// Remove números do texto.
  String _removeNumbers(String text) {
    return text.replaceAll(_numberRegex, '').replaceAll(_whitespaceRegex, ' ');
  }

  /// Normaliza pontuação mantendo contexto semântico.
  String _normalizePunctuation(String text) {
    // Preservar pontuação importante
    String processed = text;

    // Normalizar aspas
    processed =
        processed.replaceAll('"', '"').replaceAll('"', '"').replaceAll(''', "'")
        .replaceAll(''', "'");

    // Normalizar travessões
    processed = processed.replaceAll('—', '-').replaceAll('–', '-');

    return processed;
  }

  /// Extrai palavras-chave relevantes do texto.
  ///
  /// [text] - Texto para extração
  /// [maxKeywords] - Número máximo de palavras-chave a retornar
  ///
  /// Returns: Lista de palavras-chave ordenadas por relevância
  List<String> extractKeywords(String text, {int maxKeywords = 10}) {
    if (text.isEmpty) return [];

    final processed = processText(text);
    final words = processed.split(' ').where((w) => w.length > 2).toList();

    if (words.isEmpty) return [];

    // Calcular frequência de palavras
    final wordFreq = <String, int>{};
    for (final word in words) {
      wordFreq[word] = (wordFreq[word] ?? 0) + 1;
    }

    // Calcular pontuação TF-IDF simplificada
    final wordScores = <String, double>{};
    final totalWords = words.length;

    for (final entry in wordFreq.entries) {
      final word = entry.key;
      final freq = entry.value;

      // Term Frequency
      final tf = freq / totalWords;

      // Bônus para palavras de qualidade
      final qualityBonus = _qualityIndicators.contains(word) ? 1.5 : 1.0;

      // Penalidade para palavras muito comuns
      final commonPenalty = freq > totalWords * 0.1 ? 0.5 : 1.0;

      wordScores[word] = tf * qualityBonus * commonPenalty;
    }

    // Ordenar por pontuação e retornar top keywords
    final sortedWords = wordScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedWords.take(maxKeywords).map((entry) => entry.key).toList();
  }

  /// Extrai sentenças principais do texto.
  ///
  /// [text] - Texto para extração
  /// [maxSentences] - Número máximo de sentenças a retornar
  ///
  /// Returns: Lista de sentenças ordenadas por relevância
  List<String> extractKeySentences(String text, {int maxSentences = 3}) {
    if (text.isEmpty) return [];

    // Dividir em sentenças
    final sentences = text
        .split(RegExp(r'[.!?]+'))
        .map((s) => s.trim())
        .where((s) => s.length > 20)
        .toList();

    if (sentences.isEmpty) return [];

    // Extrair palavras-chave do texto completo
    final keywords = extractKeywords(text, maxKeywords: 20);
    final keywordSet = keywords.toSet();

    // Pontuar sentenças baseado em palavras-chave
    final sentenceScores = <String, double>{};

    for (final sentence in sentences) {
      final sentenceWords = processText(sentence).split(' ');
      final keywordMatches =
          sentenceWords.where((word) => keywordSet.contains(word)).length;

      // Pontuação baseada em densidade de palavras-chave
      final keywordDensity = keywordMatches / sentenceWords.length;

      // Bônus para sentenças de tamanho ideal
      final lengthScore = _calculateLengthScore(sentence.length);

      // Bônus para sentenças com indicadores de qualidade
      final qualityScore = _calculateSentenceQualityScore(sentence);

      sentenceScores[sentence] = keywordDensity * lengthScore * qualityScore;
    }

    // Ordenar e retornar top sentenças
    final sortedSentences = sentenceScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedSentences
        .take(maxSentences)
        .map((entry) => entry.key)
        .toList();
  }

  /// Calcula pontuação baseada no comprimento da sentença.
  double _calculateLengthScore(int length) {
    // Sentenças ideais: 50-200 caracteres
    if (length >= 50 && length <= 200) return 1.0;
    if (length >= 30 && length <= 300) return 0.8;
    if (length >= 20 && length <= 400) return 0.6;
    return 0.3;
  }

  /// Calcula pontuação de qualidade da sentença.
  double _calculateSentenceQualityScore(String sentence) {
    double score = 1.0;
    final lowerSentence = sentence.toLowerCase();

    // Bônus para sentenças informativas
    for (final indicator in _qualityIndicators) {
      if (lowerSentence.contains(indicator)) {
        score *= 1.2;
        break;
      }
    }

    // Penalidade para sentenças com muitos números ou símbolos
    final specialCharCount =
        sentence.replaceAll(RegExp(r'[a-zA-Z\s]'), '').length;
    if (specialCharCount > sentence.length * 0.3) {
      score *= 0.7;
    }

    return math.min(2.0, score);
  }

  /// Detecta idioma básico do texto (português ou inglês).
  ///
  /// [text] - Texto para análise
  ///
  /// Returns: 'pt' para português, 'en' para inglês, 'unknown' para indeterminado
  String detectLanguage(String text) {
    if (text.length < 50) return 'unknown';

    final processed = processText(text);
    final words = processed.split(' ');

    // Palavras indicativas de português
    const ptIndicators = {
      'que',
      'não',
      'com',
      'uma',
      'para',
      'são',
      'como',
      'mais',
      'por',
      'sua',
      'seu',
      'ela',
      'ele',
      'isso',
      'essa',
      'este',
      'esta',
      'muito',
      'também',
    };

    // Palavras indicativas de inglês
    const enIndicators = {
      'the',
      'and',
      'that',
      'have',
      'for',
      'not',
      'with',
      'you',
      'this',
      'but',
      'his',
      'from',
      'they',
      'she',
      'her',
      'been',
      'than',
      'its',
      'who',
      'did',
    };

    int ptScore = 0;
    int enScore = 0;

    for (final word in words.take(100)) {
      // Analisar apenas primeiras 100 palavras
      if (ptIndicators.contains(word)) ptScore++;
      if (enIndicators.contains(word)) enScore++;
    }

    if (ptScore > enScore && ptScore > 2) return 'pt';
    if (enScore > ptScore && enScore > 2) return 'en';
    return 'unknown';
  }

  /// Calcula índice de legibilidade do texto.
  ///
  /// [text] - Texto para análise
  ///
  /// Returns: Pontuação de legibilidade (0.0 a 1.0, maior = mais legível)
  double calculateReadabilityScore(String text) {
    if (text.isEmpty) return 0.0;

    final sentences =
        text.split(RegExp(r'[.!?]+')).where((s) => s.trim().isNotEmpty).length;

    if (sentences == 0) return 0.0;

    final words = processText(text).split(' ').length;
    final avgWordsPerSentence = words / sentences;

    // Pontuação baseada na complexidade
    double score = 1.0;

    // Penalizar sentenças muito longas
    if (avgWordsPerSentence > 25) {
      score *= 0.7;
    } else if (avgWordsPerSentence > 15) {
      score *= 0.9;
    }

    // Bônus para estrutura balanceada
    if (avgWordsPerSentence >= 8 && avgWordsPerSentence <= 20) {
      score *= 1.1;
    }

    return math.min(1.0, score);
  }

  /// Normaliza texto para comparação de similaridade.
  String normalizeForComparison(String text) {
    return processText(text, removeNumbers: true)
        .replaceAll(_punctuationRegex, ' ')
        .replaceAll(_whitespaceRegex, ' ')
        .trim();
  }
}
