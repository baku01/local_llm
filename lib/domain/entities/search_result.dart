import 'relevance_score.dart';

/// Entidade que representa um resultado individual de pesquisa web.
///
/// Contém as informações básicas extraídas de um resultado de busca,
/// incluindo título, URL, snippet, timestamp da busca e análise de relevância.
class SearchResult {
  /// Título da página ou resultado encontrado.
  final String title;

  /// URL completa do resultado.
  final String url;

  /// Snippet ou descrição curta do conteúdo da página.
  final String snippet;

  /// Timestamp de quando este resultado foi obtido.
  final DateTime timestamp;

  /// Conteúdo completo da página (opcional).
  final String? content;

  /// Análise de relevância do resultado (opcional).
  final RelevanceScore? relevanceScore;

  /// Metadados adicionais do resultado.
  final Map<String, dynamic>? metadata;

  /// Construtor do resultado de pesquisa.
  ///
  /// Todos os campos básicos são obrigatórios para garantir que o resultado
  /// contenha informações suficientes para ser útil.
  const SearchResult({
    required this.title,
    required this.url,
    required this.snippet,
    required this.timestamp,
    this.content,
    this.relevanceScore,
    this.metadata,
  });

  /// Cria uma cópia do resultado com novos valores.
  SearchResult copyWith({
    String? title,
    String? url,
    String? snippet,
    DateTime? timestamp,
    String? content,
    RelevanceScore? relevanceScore,
    Map<String, dynamic>? metadata,
  }) {
    return SearchResult(
      title: title ?? this.title,
      url: url ?? this.url,
      snippet: snippet ?? this.snippet,
      timestamp: timestamp ?? this.timestamp,
      content: content ?? this.content,
      relevanceScore: relevanceScore ?? this.relevanceScore,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Indica se o resultado tem análise de relevância.
  bool get hasRelevanceScore => relevanceScore != null;

  /// Indica se o resultado é considerado relevante.
  bool get isRelevant => relevanceScore?.isRelevant ?? false;

  /// Indica se o resultado tem alta relevância.
  bool get isHighlyRelevant => relevanceScore?.isHighlyRelevant ?? false;

  /// Pontuação geral de relevância (0.0 se não analisado).
  double get overallRelevance => relevanceScore?.overallScore ?? 0.0;

  /// Representação textual do resultado para debug.
  @override
  String toString() => 'SearchResult(title: $title, url: $url, '
      'relevance: ${overallRelevance.toStringAsFixed(3)})';

  /// Comparação baseada em relevância para ordenação.
  int compareTo(SearchResult other) {
    return other.overallRelevance.compareTo(overallRelevance);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchResult &&
        other.title == title &&
        other.url == url &&
        other.snippet == snippet;
  }

  @override
  int get hashCode => Object.hash(title, url, snippet);
}


