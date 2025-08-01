import '../entities/search_result.dart';
import '../repositories/search_repository.dart';

class SearchWeb {
  final SearchRepository repository;

  const SearchWeb(this.repository);

  Future<List<SearchResult>> call(SearchQuery query) async {
    if (query.query.trim().isEmpty) {
      throw ArgumentError('Query não pode estar vazia');
    }

    return await repository.search(query);
  }
}

class FetchWebContent {
  final SearchRepository repository;

  const FetchWebContent(this.repository);

  Future<String> call(String url) async {
    if (url.trim().isEmpty) {
      throw ArgumentError('URL não pode estar vazia');
    }

    return await repository.fetchPageContent(url);
  }
}
