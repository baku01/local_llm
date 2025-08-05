/// Tipos de pesquisa disponíveis para refinar os resultados.
///
/// - [general]: Pesquisa geral na web
/// - [news]: Pesquisa focada em notícias
/// - [academic]: Pesquisa em conteúdo acadêmico
/// - [images]: Pesquisa por imagens
enum SearchType { general, news, academic, images }

/// Representa uma consulta de busca com parâmetros opcionais.
///
/// Esta entidade encapsula os parâmetros necessários para realizar uma busca,
/// seguindo os princípios da Clean Architecture na camada de domínio.
class SearchQuery {
  /// Texto da consulta
  final String query;

  /// Tipo de pesquisa a ser realizada
  final SearchType type;

  /// Número máximo de resultados a retornar
  final int maxResults;

  /// Tipo de conteúdo esperado (opcional)
  final String? contentType;

  /// Idioma preferido para resultados (opcional)
  final String? language;

  /// Período de tempo específico (opcional)
  final String? timeRange;

  /// Domínios específicos para busca (opcional)
  final List<String>? domains;

  /// Termos a serem excluídos (opcional)
  final List<String>? excludeTerms;

  /// Sinônimos a serem considerados (opcional)
  final List<String>? synonyms;

  const SearchQuery({
    required this.query,
    this.type = SearchType.general,
    this.maxResults = 5,
    this.contentType,
    this.language,
    this.timeRange,
    this.domains,
    this.excludeTerms,
    this.synonyms,
  });

  /// Cria uma nova consulta com parâmetros modificados.
  SearchQuery copyWith({
    String? query,
    SearchType? type,
    int? maxResults,
    String? contentType,
    String? language,
    String? timeRange,
    List<String>? domains,
    List<String>? excludeTerms,
    List<String>? synonyms,
  }) {
    return SearchQuery(
      query: query ?? this.query,
      type: type ?? this.type,
      maxResults: maxResults ?? this.maxResults,
      contentType: contentType ?? this.contentType,
      language: language ?? this.language,
      timeRange: timeRange ?? this.timeRange,
      domains: domains ?? this.domains,
      excludeTerms: excludeTerms ?? this.excludeTerms,
      synonyms: synonyms ?? this.synonyms,
    );
  }

  /// Adiciona sinônimos à consulta.
  SearchQuery addSynonyms(List<String> newSynonyms) {
    final currentSynonyms = synonyms ?? [];
    return copyWith(
      synonyms: [...currentSynonyms, ...newSynonyms],
    );
  }

  /// Adiciona domínios à consulta.
  SearchQuery addDomains(List<String> newDomains) {
    final currentDomains = domains ?? [];
    return copyWith(
      domains: [...currentDomains, ...newDomains],
    );
  }

  /// Adiciona termos a serem excluídos.
  SearchQuery addExcludeTerms(List<String> newExcludeTerms) {
    final currentExcludeTerms = excludeTerms ?? [];
    return copyWith(
      excludeTerms: [...currentExcludeTerms, ...newExcludeTerms],
    );
  }

  /// Retorna a query formatada com filtros aplicados para uso em motores de busca.
  String get formattedQuery {
    final parts = <String>[query];

    if (domains?.isNotEmpty ?? false) {
      // Join multiple domains with OR operator
      parts.add('site:${domains!.join(' OR site:')}');
    }

    if (excludeTerms?.isNotEmpty ?? false) {
      parts.addAll(excludeTerms!.map((term) => '-$term'));
    }

    if (synonyms?.isNotEmpty ?? false) {
      parts.add('(${synonyms!.join(' OR ')})');
    }

    if (language != null) {
      parts.add('lang:$language');
    }

    if (timeRange != null) {
      parts.add('when:$timeRange');
    }

    return parts.join(' ');
  }

  /// Converte para string formatada.
  @override
  String toString() {
    final parts = <String>[query];

    if (contentType != null) {
      parts.add('type:$contentType');
    }

    if (language != null) {
      parts.add('lang:$language');
    }

    if (timeRange != null) {
      parts.add('when:$timeRange');
    }

    if (domains?.isNotEmpty ?? false) {
      parts.add('site:${domains!.join(' OR site:')}');
    }

    if (excludeTerms?.isNotEmpty ?? false) {
      parts.addAll(excludeTerms!.map((term) => '-$term'));
    }

    if (synonyms?.isNotEmpty ?? false) {
      parts.add('(${synonyms!.join(' OR ')})');
    }

    return parts.join(' ');
  }

  /// Implementação de igualdade.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SearchQuery &&
        other.query == query &&
        other.contentType == contentType &&
        other.language == language &&
        other.timeRange == timeRange &&
        _listEquals(other.domains, domains) &&
        _listEquals(other.excludeTerms, excludeTerms) &&
        _listEquals(other.synonyms, synonyms);
  }

  /// Implementação de hash code.
  @override
  int get hashCode {
    return query.hashCode ^
        contentType.hashCode ^
        language.hashCode ^
        timeRange.hashCode ^
        domains.hashCode ^
        excludeTerms.hashCode ^
        synonyms.hashCode;
  }

  /// Compara igualdade de listas.
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Converte string para SearchQuery.
  static SearchQuery fromString(String queryString) {
    final parts = queryString.split(' ');
    final query = <String>[];
    final domains = <String>[];
    final excludeTerms = <String>[];
    String? contentType;
    String? language;
    String? timeRange;

    for (final part in parts) {
      if (part.startsWith('type:')) {
        contentType = part.substring(5);
      } else if (part.startsWith('lang:')) {
        language = part.substring(5);
      } else if (part.startsWith('when:')) {
        timeRange = part.substring(5);
      } else if (part.startsWith('site:')) {
        domains.add(part.substring(5));
      } else if (part.startsWith('-')) {
        excludeTerms.add(part.substring(1));
      } else {
        query.add(part);
      }
    }

    return SearchQuery(
      query: query.join(' '),
      contentType: contentType,
      language: language,
      timeRange: timeRange,
      domains: domains.isEmpty ? null : domains,
      excludeTerms: excludeTerms.isEmpty ? null : excludeTerms,
    );
  }
}
