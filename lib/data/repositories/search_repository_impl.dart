import '../../domain/entities/search_result.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/web_search_datasource.dart';

class SearchRepositoryImpl implements SearchRepository {
  final WebSearchDataSource dataSource;

  const SearchRepositoryImpl({required this.dataSource});

  @override
  Future<List<SearchResult>> search(SearchQuery query) async {
    try {
      return await dataSource.search(query);
    } catch (e) {
      throw Exception('Falha na pesquisa: $e');
    }
  }

  @override
  Future<String> fetchPageContent(String url) async {
    try {
      return await dataSource.fetchPageContent(url);
    } catch (e) {
      throw Exception('Falha ao buscar conteúdo: $e');
    }
  }
}
