import '../entities/search_result.dart';

abstract class SearchRepository {
  Future<List<SearchResult>> search(SearchQuery query);
  Future<String> fetchPageContent(String url);
}
