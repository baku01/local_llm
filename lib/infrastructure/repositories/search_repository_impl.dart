/// Biblioteca que implementa o repositório para operações de busca web.
///
/// Esta biblioteca contém a implementação concreta do [SearchRepository],
/// responsável por intermediar entre a camada de domínio e as fontes de dados
/// para operações de busca na web e obtenção de conteúdo de páginas.
library;

import '../../domain/entities/search_result.dart';
import '../../domain/entities/search_query.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/web_search_datasource.dart';

/// Implementação concreta do repositório de busca web.
///
/// Esta classe implementa [SearchRepository] e serve como uma ponte entre
/// a camada de domínio e a fonte de dados de busca web. É responsável
/// por delegar operações de busca e obtenção de conteúdo para a fonte
/// de dados apropriada e tratar erros de forma adequada.
///
/// Exemplo de uso:
/// ```dart
/// final repository = SearchRepositoryImpl(
///   dataSource: webSearchDataSource,
/// );
///
/// final results = await repository.search(SearchQuery('Flutter'));
/// final content = await repository.fetchPageContent('https://flutter.dev');
/// ```
class SearchRepositoryImpl implements SearchRepository {
  /// Fonte de dados para operações de busca web.
  ///
  /// Esta propriedade mantém uma referência para o [WebSearchDataSource]
  /// que é usado para realizar operações de busca e obtenção de conteúdo.
  final WebSearchDataSource dataSource;

  /// Cria uma nova instância de [SearchRepositoryImpl].
  ///
  /// Parâmetros:
  /// - [dataSource]: A fonte de dados para operações de busca web.
  const SearchRepositoryImpl({required this.dataSource});

  /// Realiza uma busca web usando a consulta especificada.
  ///
  /// Este método delega a operação de busca para a fonte de dados
  /// e retorna os resultados encontrados.
  ///
  /// Parâmetros:
  /// - [query]: A consulta de busca contendo os termos e parâmetros.
  ///
  /// Retorna uma [Future] que completa com uma lista de [SearchResult]
  /// representando os resultados da busca.
  ///
  /// Throws:
  /// - [Exception]: Se houver falha na execução da busca.
  @override
  Future<List<SearchResult>> search(SearchQuery query) async {
    try {
      return await dataSource.search(query);
    } catch (e) {
      throw Exception('Falha na pesquisa: $e');
    }
  }

  /// Obtém o conteúdo de uma página web.
  ///
  /// Este método delega a operação de obtenção de conteúdo para a
  /// fonte de dados e retorna o conteúdo da página como string.
  ///
  /// Parâmetros:
  /// - [url]: A URL da página cujo conteúdo deve ser obtido.
  ///
  /// Retorna uma [Future] que completa com uma string contendo
  /// o conteúdo da página.
  ///
  /// Throws:
  /// - [Exception]: Se houver falha na obtenção do conteúdo.
  @override
  Future<String> fetchPageContent(String url) async {
    try {
      return await dataSource.fetchPageContent(url);
    } catch (e) {
      throw Exception('Falha ao buscar conteúdo: $e');
    }
  }
}
