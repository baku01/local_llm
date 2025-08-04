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

  /// Fatores que contribuíram para a pontuação.
  final Map<String, double> scoringFactors;

  /// Indica se o resultado é considerado relevante.
  bool get isRelevant => overallScore >= 0.6;

  /// Indica se o resultado tem alta relevância.
  bool get isHighlyRelevant => overallScore >= 0.8;

  const RelevanceScore({
    required this.overallScore,
    required this.semanticScore,
    required this.keywordScore,
    required this.qualityScore,
    required this.authorityScore,
    required this.scoringFactors,
  });

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
