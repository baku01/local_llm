class SearchResult {
  final String title;
  final String url;
  final String snippet;
  final DateTime timestamp;

  const SearchResult({
    required this.title,
    required this.url,
    required this.snippet,
    required this.timestamp,
  });

  @override
  String toString() => 'SearchResult(title: $title, url: $url)';
}

class SearchQuery {
  final String query;
  final String? site;
  final SearchType type;
  final int maxResults;

  const SearchQuery({
    required this.query,
    this.site,
    this.type = SearchType.general,
    this.maxResults = 5,
  });

  String get formattedQuery {
    var formatted = query;
    if (site != null) {
      formatted += ' site:$site';
    }
    return formatted;
  }
}

enum SearchType {
  general,
  news,
  academic,
  images,
}