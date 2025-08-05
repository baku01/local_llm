/// Biblioteca que define os casos de uso para operações de busca web.
///
/// Esta biblioteca contém os casos de uso [SearchWeb] e [FetchWebContent]
/// que permitem realizar buscas na web e obter conteúdo de páginas
/// específicas, respectivamente.
library;

import '../entities/search_result.dart';
import '../entities/search_query.dart';
import '../repositories/search_repository.dart';

/// Caso de uso para realização de buscas na web.
///
/// Esta classe encapsula a lógica de negócio para realizar buscas
/// na web usando consultas estruturadas. Inclui validação de entrada
/// e coordenação com o repositório de busca.
///
/// O caso de uso valida que:
/// - A consulta não esteja vazia
/// - Os parâmetros da consulta sejam válidos
///
/// Exemplo de uso:
/// ```dart
/// final useCase = SearchWeb(repository);
///
/// final query = SearchQuery('Flutter development');
/// final results = await useCase(query);
///
/// for (final result in results) {
///   print('${result.title}: ${result.url}');
/// }
/// ```
class SearchWeb {
  /// Repositório para operações de busca web.
  ///
  /// Esta propriedade mantém uma referência para o [SearchRepository]
  /// que será usado para executar operações de busca.
  final SearchRepository repository;

  /// Cria uma nova instância de [SearchWeb].
  ///
  /// Parâmetros:
  /// - [repository]: O repositório para operações de busca.
  const SearchWeb(this.repository);

  /// Executa o caso de uso de busca web.
  ///
  /// Este método valida a consulta e delega a operação de busca
  /// para o repositório, retornando os resultados encontrados.
  ///
  /// Parâmetros:
  /// - [query]: A consulta de busca estruturada.
  ///
  /// Retorna uma [Future] que completa com uma lista de [SearchResult]
  /// representando os resultados da busca.
  ///
  /// Throws:
  /// - [ArgumentError]: Se a consulta estiver vazia.
  /// - [Exception]: Se houver falha na execução da busca.
  ///
  /// Exemplo:
  /// ```dart
  /// try {
  ///   final query = SearchQuery('tecnologia');
  ///   final results = await useCase(query);
  ///   print('Encontrados ${results.length} resultados');
  /// } catch (e) {
  ///   print('Erro na busca: $e');
  /// }
  /// ```
  Future<List<SearchResult>> call(SearchQuery query) async {
    if (query.query.trim().isEmpty) {
      throw ArgumentError('Query não pode estar vazia');
    }

    return await repository.search(query);
  }
}

/// Caso de uso para obtenção de conteúdo de páginas web.
///
/// Esta classe encapsula a lógica de negócio para obter o conteúdo
/// de uma página web específica. Inclui validação de URL e
/// coordenação com o repositório de busca.
///
/// O caso de uso valida que:
/// - A URL não esteja vazia
/// - A URL seja válida para processamento
///
/// Exemplo de uso:
/// ```dart
/// final useCase = FetchWebContent(repository);
///
/// final content = await useCase('https://flutter.dev');
/// print('Conteúdo obtido: ${content.length} caracteres');
/// ```
class FetchWebContent {
  /// Repositório para operações de busca web.
  ///
  /// Esta propriedade mantém uma referência para o [SearchRepository]
  /// que será usado para obter conteúdo de páginas.
  final SearchRepository repository;

  /// Cria uma nova instância de [FetchWebContent].
  ///
  /// Parâmetros:
  /// - [repository]: O repositório para operações de busca.
  const FetchWebContent(this.repository);

  /// Executa o caso de uso de obtenção de conteúdo web.
  ///
  /// Este método valida a URL e delega a operação de obtenção
  /// de conteúdo para o repositório.
  ///
  /// Parâmetros:
  /// - [url]: A URL da página cujo conteúdo deve ser obtido.
  ///
  /// Retorna uma [Future] que completa com uma string contendo
  /// o conteúdo da página.
  ///
  /// Throws:
  /// - [ArgumentError]: Se a URL estiver vazia.
  /// - [Exception]: Se houver falha na obtenção do conteúdo.
  ///
  /// Exemplo:
  /// ```dart
  /// try {
  ///   final content = await useCase('https://example.com');
  ///   print('Página carregada: ${content.substring(0, 100)}...');
  /// } catch (e) {
  ///   print('Erro ao carregar página: $e');
  /// }
  /// ```
  Future<String> call(String url) async {
    if (url.trim().isEmpty) {
      throw ArgumentError('URL não pode estar vazia');
    }

    return await repository.fetchPageContent(url);
  }
}
