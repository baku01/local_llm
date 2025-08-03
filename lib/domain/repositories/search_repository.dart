/// Biblioteca que define o contrato para operações de busca web.
///
/// Esta biblioteca contém a interface [SearchRepository] que define
/// os métodos necessários para realizar operações de busca na web
/// e obtenção de conteúdo de páginas.
library;

import '../entities/search_result.dart';

/// Interface para operações de busca web.
///
/// Esta classe abstrata define o contrato para implementações de
/// repositórios que realizam operações de busca na web e obtenção
/// de conteúdo de páginas.
///
/// As implementações desta interface devem fornecer:
/// - Busca web usando consultas estruturadas
/// - Obtenção de conteúdo de páginas web
///
/// Exemplo de implementação:
/// ```dart
/// class MySearchRepository implements SearchRepository {
///   @override
///   Future<List<SearchResult>> search(SearchQuery query) async {
///     // Implementação da busca
///   }
///
///   @override
///   Future<String> fetchPageContent(String url) async {
///     // Implementação da obtenção de conteúdo
///   }
/// }
/// ```
abstract class SearchRepository {
  /// Realiza uma busca web usando a consulta especificada.
  ///
  /// Parâmetros:
  /// - [query]: A consulta de busca contendo os termos e parâmetros.
  ///
  /// Retorna uma [Future] que completa com uma lista de [SearchResult]
  /// representando os resultados da busca.
  ///
  /// Throws:
  /// - [Exception]: Se houver falha na execução da busca.
  Future<List<SearchResult>> search(SearchQuery query);

  /// Obtém o conteúdo de uma página web.
  ///
  /// Parâmetros:
  /// - [url]: A URL da página cujo conteúdo deve ser obtido.
  ///
  /// Retorna uma [Future] que completa com uma string contendo
  /// o conteúdo da página.
  ///
  /// Throws:
  /// - [Exception]: Se houver falha na obtenção do conteúdo.
  Future<String> fetchPageContent(String url);
}
