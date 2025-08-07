/// Resultado de análise de relevância com pontuação detalhada.
///
/// Esta entidade representa o score de relevância de um resultado de busca,
/// seguindo os princípios da Clean Architecture mantendo-se na camada de domínio.
class RelevanceScore {
  /// Pontuação geral de relevância (0.0 a 1.0).
  final double overallScore;

  /// Pontuação de similaridade semântica.
  final double semanticScore;

  /// Pontuação baseada em palavras-chave.
  final double keywordScore;

  /// Pontuação de qualidade do conteúdo.
  final double qualityScore;

  /// Pontuação de autoridade da fonte.
  final double authorityScore;

  /// Relevância do título (0.0 a 1.0)
  final double titleRelevance;

  /// Relevância do conteúdo principal (0.0 a 1.0)
  final double contentRelevance;

  /// Relevância da URL (0.0 a 1.0)
  final double urlRelevance;

  /// Relevância dos metadados (0.0 a 1.0)
  final double metadataRelevance;

  /// Fatores que contribuíram para a pontuação.
  final Map<String, double> scoringFactors;

  /// Explicação da pontuação para debugging
  final String? explanation;

  /// Indica se o resultado é considerado relevante.
  bool get isRelevant => overallScore >= 0.6;

  /// Indica se o resultado tem alta relevância.
  bool get isHighlyRelevant => overallScore >= 0.8;

  /// Indica se o resultado tem baixa relevância (score < 0.3).
  bool get isLowRelevance => overallScore < 0.3;

  /// Retorna a categoria de relevância como string.
  String get relevanceCategory {
    if (isHighlyRelevant) return 'Alta';
    if (isRelevant) return 'Média';
    return 'Baixa';
  }

  const RelevanceScore({
    required this.overallScore,
    required this.semanticScore,
    required this.keywordScore,
    required this.qualityScore,
    required this.authorityScore,
    required this.scoringFactors,
    this.titleRelevance = 0.0,
    this.contentRelevance = 0.0,
    this.urlRelevance = 0.0,
    this.metadataRelevance = 0.0,
    this.explanation,
  });

  /// Construtor para criar pontuação com cálculo automático.
  factory RelevanceScore.calculate({
    required double titleRelevance,
    required double contentRelevance,
    required double urlRelevance,
    required double metadataRelevance,
    double semanticScore = 0.0,
    double keywordScore = 0.0,
    double qualityScore = 0.0,
    double authorityScore = 0.0,
    Map<String, double>? weights,
    Map<String, double>? contributingFactors,
    String? explanation,
  }) {
    final defaultWeights = weights ?? {
      'title': 0.25,
      'content': 0.35,
      'url': 0.10,
      'metadata': 0.10,
      'semantic': 0.10,
      'keyword': 0.05,
      'quality': 0.03,
      'authority': 0.02,
    };

    final overall = (titleRelevance * defaultWeights['title']!) +
        (contentRelevance * defaultWeights['content']!) +
        (urlRelevance * defaultWeights['url']!) +
        (metadataRelevance * defaultWeights['metadata']!) +
        (semanticScore * defaultWeights['semantic']!) +
        (keywordScore * defaultWeights['keyword']!) +
        (qualityScore * defaultWeights['quality']!) +
        (authorityScore * defaultWeights['authority']!);

    return RelevanceScore(
      titleRelevance: titleRelevance,
      contentRelevance: contentRelevance,
      urlRelevance: urlRelevance,
      metadataRelevance: metadataRelevance,
      semanticScore: semanticScore,
      keywordScore: keywordScore,
      qualityScore: qualityScore,
      authorityScore: authorityScore,
      overallScore: overall.clamp(0.0, 1.0),
      scoringFactors: contributingFactors ?? {},
      explanation: explanation,
    );
  }

  /// Cria uma nova instância com valores modificados.
  RelevanceScore copyWith({
    double? overallScore,
    double? semanticScore,
    double? keywordScore,
    double? qualityScore,
    double? authorityScore,
    double? titleRelevance,
    double? contentRelevance,
    double? urlRelevance,
    double? metadataRelevance,
    Map<String, double>? scoringFactors,
    String? explanation,
  }) {
    return RelevanceScore(
      overallScore: overallScore ?? this.overallScore,
      semanticScore: semanticScore ?? this.semanticScore,
      keywordScore: keywordScore ?? this.keywordScore,
      qualityScore: qualityScore ?? this.qualityScore,
      authorityScore: authorityScore ?? this.authorityScore,
      titleRelevance: titleRelevance ?? this.titleRelevance,
      contentRelevance: contentRelevance ?? this.contentRelevance,
      urlRelevance: urlRelevance ?? this.urlRelevance,
      metadataRelevance: metadataRelevance ?? this.metadataRelevance,
      scoringFactors: scoringFactors ?? this.scoringFactors,
      explanation: explanation ?? this.explanation,
    );
  }

  @override
  String toString() =>
      'RelevanceScore(overall: ${overallScore.toStringAsFixed(3)}, '
      'semantic: ${semanticScore.toStringAsFixed(3)}, '
      'keyword: ${keywordScore.toStringAsFixed(3)}, '
      'quality: ${qualityScore.toStringAsFixed(3)}, '
      'authority: ${authorityScore.toStringAsFixed(3)})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RelevanceScore &&
        other.overallScore == overallScore &&
        other.semanticScore == semanticScore &&
        other.keywordScore == keywordScore &&
        other.qualityScore == qualityScore &&
        other.authorityScore == authorityScore;
  }

  @override
  int get hashCode => Object.hash(
        overallScore,
        semanticScore,
        keywordScore,
        qualityScore,
        authorityScore,
      );
}
