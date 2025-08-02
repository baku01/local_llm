/// Entidade que representa um resultado individual de pesquisa web.
///
/// Contém as informações básicas extraídas de um resultado de busca,
/// incluindo título, URL, snippet e timestamp da busca.
class SearchResult {
  /// Título da página ou resultado encontrado.
  final String title;

  /// URL completa do resultado.
  final String url;

  /// Snippet ou descrição curta do conteúdo da página.
  final String snippet;

  /// Timestamp de quando este resultado foi obtido.
  final DateTime timestamp;

  /// Construtor do resultado de pesquisa.
  ///
  /// Todos os campos são obrigatórios para garantir que o resultado
  /// contenha informações suficientes para ser útil.
  const SearchResult({
    required this.title,
    required this.url,
    required this.snippet,
    required this.timestamp,
  });

  /// Representação textual do resultado para debug.
  @override
  String toString() => 'SearchResult(title: $title, url: $url)';
}

/// Entidade que representa uma consulta de pesquisa web.
///
/// Encapsula os parâmetros de uma busca incluindo o termo,
/// filtros por site, tipo de pesquisa e limites de resultados.
class SearchQuery {
  /// Termo ou frase a ser pesquisada.
  final String query;

  /// Site específico para restringir a busca (opcional).
  final String? site;

  /// Tipo de pesquisa a ser realizada.
  final SearchType type;

  /// Número máximo de resultados a retornar.
  final int maxResults;

  /// Construtor da consulta de pesquisa.
  ///
  /// [query] é obrigatório. [type] padrão é geral e [maxResults] padrão é 5.
  const SearchQuery({
    required this.query,
    this.site,
    this.type = SearchType.general,
    this.maxResults = 5,
  });

  /// Retorna a query formatada com filtros aplicados.
  ///
  /// Se [site] for especificado, adiciona o operador "site:" à consulta.
  String get formattedQuery {
    var formatted = query;
    if (site != null) {
      formatted += ' site:$site';
    }
    return formatted;
  }
}

/// Tipos de pesquisa disponíveis para refinar os resultados.
///
/// - [general]: Pesquisa geral na web
/// - [news]: Pesquisa focada em notícias
/// - [academic]: Pesquisa em conteúdo acadêmico
/// - [images]: Pesquisa por imagens
enum SearchType { general, news, academic, images }
