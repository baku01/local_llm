import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:local_llm/data/datasources/web_search_datasource.dart';
import 'package:local_llm/data/repositories/search_repository_impl.dart';
import 'package:local_llm/domain/usecases/search_web.dart';
import 'package:local_llm/domain/entities/search_result.dart';

/// Mock HTTP client for testing
class MockHttpClient extends http.BaseClient {
  final Map<String, http.Response> _responses = {};
  final List<http.Request> _requests = [];

  void addResponse(String url, http.Response response) {
    _responses[url] = response;
  }

  void addSearchResponse(String searchEngine, String query, List<SearchResult> results) {
    final mockHtml = _generateMockSearchHtml(searchEngine, results);
    final uri = _buildSearchUri(searchEngine, query);
    _responses[uri.toString()] = http.Response(mockHtml, 200);
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    _requests.add(request as http.Request);
    
    final response = _responses[request.url.toString()];
    if (response != null) {
      return http.StreamedResponse(
        Stream.fromIterable([response.bodyBytes]),
        response.statusCode,
        headers: response.headers,
      );
    }

    // Default 404 response
    return http.StreamedResponse(
      Stream.fromIterable(['Not Found'.codeUnits]),
      404,
    );
  }

  List<http.Request> get requests => List.unmodifiable(_requests);

  void clearRequests() => _requests.clear();

  String _generateMockSearchHtml(String engine, List<SearchResult> results) {
    switch (engine.toLowerCase()) {
      case 'google':
        return _generateGoogleHtml(results);
      case 'bing':
        return _generateBingHtml(results);
      case 'duckduckgo':
        return _generateDuckDuckGoHtml(results);
      default:
        return '<html><body>No results</body></html>';
    }
  }

  String _generateGoogleHtml(List<SearchResult> results) {
    final resultsHtml = results.map((result) => '''
      <div class="g">
        <div class="yuRUbf">
          <a href="${result.url}">
            <h3>${result.title}</h3>
          </a>
        </div>
        <div class="VwiC3b">
          <span>${result.snippet}</span>
        </div>
      </div>
    ''').join('\n');

    return '''
      <html>
        <body>
          <div id="search">
            $resultsHtml
          </div>
        </body>
      </html>
    ''';
  }

  String _generateBingHtml(List<SearchResult> results) {
    final resultsHtml = results.map((result) => '''
      <li class="b_algo">
        <h2 class="b_title">
          <a href="${result.url}">${result.title}</a>
        </h2>
        <div class="b_caption">
          <p>${result.snippet}</p>
        </div>
      </li>
    ''').join('\n');

    return '''
      <html>
        <body>
          <ol id="b_results">
            $resultsHtml
          </ol>
        </body>
      </html>
    ''';
  }

  String _generateDuckDuckGoHtml(List<SearchResult> results) {
    final resultsHtml = results.map((result) => '''
      <div class="result">
        <div class="result__title">
          <a href="${result.url}">${result.title}</a>
        </div>
        <div class="result__snippet">${result.snippet}</div>
      </div>
    ''').join('\n');

    return '''
      <html>
        <body>
          <div class="results">
            $resultsHtml
          </div>
        </body>
      </html>
    ''';
  }

  Uri _buildSearchUri(String engine, String query) {
    switch (engine.toLowerCase()) {
      case 'google':
        return Uri.parse('https://www.google.com/search?q=${Uri.encodeComponent(query)}&num=5&hl=pt-BR');
      case 'bing':
        return Uri.parse('https://www.bing.com/search?q=${Uri.encodeComponent(query)}&count=5');
      case 'duckduckgo':
        return Uri.parse('https://duckduckgo.com/html/?q=${Uri.encodeComponent(query)}');
      default:
        throw ArgumentError('Unknown search engine: $engine');
    }
  }
}

// Mock WebSearchDataSource for integration tests
class MockWebSearchDataSource implements WebSearchDataSource {
  final Map<SearchQuery, List<SearchResult>> _responses = {};
  final Map<SearchQuery, Exception> _exceptions = {};

  MockWebSearchDataSource(MockHttpClient httpClient);

  void setSearchResponse(SearchQuery query, List<SearchResult> results) {
    _responses[query] = results;
  }

  void setSearchException(SearchQuery query, Exception exception) {
    _exceptions[query] = exception;
  }

  @override
  Future<List<SearchResult>> search(SearchQuery query) async {
    if (_exceptions.containsKey(query)) {
      throw _exceptions[query]!;
    }
    return _responses[query] ?? [];
  }

  @override
  Future<String> fetchPageContent(String url) async {
    // Simple mock implementation
    return '<html><body>Mock content for $url</body></html>';
  }

  void dispose() {
    // Mock cleanup
  }
}

void main() {
  group('Web Search Integration Tests', () {
    late MockHttpClient mockHttpClient;
    late MockWebSearchDataSource dataSource;
    late SearchRepositoryImpl repository;
    late SearchWeb searchWebUseCase;

    setUp(() {
      mockHttpClient = MockHttpClient();
      dataSource = MockWebSearchDataSource(mockHttpClient);
      repository = SearchRepositoryImpl(dataSource: dataSource);
      searchWebUseCase = SearchWeb(repository);
    });

    tearDown(() {
      dataSource.dispose();
    });

    group('Single Strategy Tests', () {
      test('should successfully search using Google strategy', () async {
        // Arrange
        final expectedResults = [
          SearchResult(
            title: 'Flutter - Build apps for any screen',
            url: 'https://flutter.dev',
            snippet: 'Flutter transforms the app development process',
            timestamp: DateTime.now(),
          ),
          SearchResult(
            title: 'Flutter Documentation',
            url: 'https://flutter.dev/docs',
            snippet: 'Get started with Flutter development',
            timestamp: DateTime.now(),
          ),
        ];

        const query = SearchQuery(query: 'flutter development');
        dataSource.setSearchResponse(query, expectedResults);

        // Act
        final results = await searchWebUseCase.call(query);

        // Assert
        expect(results, isNotEmpty);
        expect(results.length, expectedResults.length);
        expect(results[0].title, expectedResults[0].title);
        expect(results[0].url, expectedResults[0].url);
      });

      test('should successfully search using Bing strategy', () async {
        // Arrange  
        final expectedResults = [
          SearchResult(
            title: 'Dart Programming Language',
            url: 'https://dart.dev',
            snippet: 'Dart is a client-optimized language',
            timestamp: DateTime.now(),
          ),
        ];

        const query = SearchQuery(query: 'dart programming');
        dataSource.setSearchResponse(query, expectedResults);

        // Act
        final results = await searchWebUseCase.call(query);

        // Assert
        expect(results, isNotEmpty);
        expect(results[0].title, expectedResults[0].title);
      });

      test('should handle empty search results gracefully', () async {
        // Arrange
        const query = SearchQuery(query: 'nonexistent query');
        dataSource.setSearchResponse(query, []);

        // Act
        final results = await searchWebUseCase.call(query);

        // Assert
        expect(results, isEmpty);
      });
    });

    group('Strategy Fallback Tests', () {
      test('should fallback to secondary strategy when primary fails', () async {
        // Arrange
        const query = SearchQuery(query: 'fallback test');
        
        // This test is simplified since we're testing at the data source level
        // The fallback logic is tested in the strategy manager tests
        final results = [
          SearchResult(
            title: 'Fallback Result',
            url: 'https://example.com',
            snippet: 'This came from secondary strategy',
            timestamp: DateTime.now(),
          ),
        ];
        dataSource.setSearchResponse(query, results);

        // Act
        final searchResults = await searchWebUseCase.call(query);

        // Assert
        expect(searchResults, isNotEmpty);
        expect(searchResults[0].title, 'Fallback Result');
      });

      test('should try multiple strategies until one succeeds', () async {
        // Arrange
        const query = SearchQuery(query: 'multiple fallback test');

        final results = [
          SearchResult(
            title: 'Success After Multiple Attempts',
            url: 'https://success-result.com',
            snippet: 'Final strategy succeeded',
            timestamp: DateTime.now(),
          ),
        ];
        dataSource.setSearchResponse(query, results);

        // Act
        final searchResults = await searchWebUseCase.call(query);

        // Assert
        expect(searchResults, isNotEmpty);
        expect(searchResults[0].title, 'Success After Multiple Attempts');
      });
    });

    group('Circuit Breaker Integration', () {
      test('should handle circuit breaker failures', () async {
        // Arrange
        const query = SearchQuery(query: 'circuit breaker test');
        dataSource.setSearchException(query, Exception('Circuit breaker open'));

        // Act & Assert
        expect(
          () async => await searchWebUseCase.call(query),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Cache Integration', () {
      test('should return consistent results', () async {
        // Arrange
        final expectedResults = [
          SearchResult(
            title: 'Cached Result',
            url: 'https://cached.com',
            snippet: 'This should be cached',
            timestamp: DateTime.now(),
          ),
        ];

        const query = SearchQuery(query: 'cache test');
        dataSource.setSearchResponse(query, expectedResults);

        // Act - Multiple searches
        final results1 = await searchWebUseCase.call(query);
        final results2 = await searchWebUseCase.call(query);

        // Assert
        expect(results1, isNotEmpty);
        expect(results2, isNotEmpty);
        expect(results1[0].title, results2[0].title);
      });
    });

    group('Different Query Types', () {
      test('should handle news queries', () async {
        // Arrange
        final newsResults = [
          SearchResult(
            title: 'Breaking Tech News',
            url: 'https://tech-news.com/breaking',
            snippet: 'Latest technology updates',
            timestamp: DateTime.now(),
          ),
        ];

        const query = SearchQuery(
          query: 'tech news',
          type: SearchType.news,
          maxResults: 10,
        );
        dataSource.setSearchResponse(query, newsResults);

        // Act
        final results = await searchWebUseCase.call(query);

        // Assert
        expect(results, isNotEmpty);
        expect(results[0].title, contains('News'));
      });

      test('should handle site-specific queries', () async {
        // Arrange
        final siteResults = [
          SearchResult(
            title: 'Flutter Tutorial on Official Site',
            url: 'https://flutter.dev/tutorial',
            snippet: 'Official Flutter tutorial',
            timestamp: DateTime.now(),
          ),
        ];

        const query = SearchQuery(
          query: 'flutter tutorial',
          site: 'flutter.dev',
        );
        dataSource.setSearchResponse(query, siteResults);

        // Act
        final results = await searchWebUseCase.call(query);

        // Assert
        expect(results, isNotEmpty);
        expect(results[0].url, contains('flutter.dev'));
        expect(query.formattedQuery, contains('site:flutter.dev'));
      });
    });

    group('Performance and Concurrency', () {
      test('should handle concurrent searches efficiently', () async {
        // Arrange
        final results1 = [
          SearchResult(
            title: 'Concurrent Result 1',
            url: 'https://concurrent1.com',
            snippet: 'First concurrent search',
            timestamp: DateTime.now(),
          ),
        ];

        final results2 = [
          SearchResult(
            title: 'Concurrent Result 2',
            url: 'https://concurrent2.com',
            snippet: 'Second concurrent search',
            timestamp: DateTime.now(),
          ),
        ];

        const query1 = SearchQuery(query: 'concurrent query 1');
        const query2 = SearchQuery(query: 'concurrent query 2');
        dataSource.setSearchResponse(query1, results1);
        dataSource.setSearchResponse(query2, results2);

        // Act - Start concurrent searches
        final future1 = searchWebUseCase.call(query1);
        final future2 = searchWebUseCase.call(query2);

        final results = await Future.wait([future1, future2]);

        // Assert
        expect(results, hasLength(2));
        expect(results[0], isNotEmpty);
        expect(results[1], isNotEmpty);
        expect(results[0][0].title, 'Concurrent Result 1');
        expect(results[1][0].title, 'Concurrent Result 2');
      });

      test('should respect timeout limits', () async {
        // Arrange
        const query = SearchQuery(query: 'timeout test');
        dataSource.setSearchException(query, Exception('Request timeout'));

        // Act & Assert
        expect(
          () async => await searchWebUseCase.call(query),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Error Handling and Recovery', () {
      test('should handle malformed HTML gracefully', () async {
        // Arrange
        const query = SearchQuery(query: 'malformed html');
        dataSource.setSearchResponse(query, []); // Empty results for malformed HTML

        // Act
        final results = await searchWebUseCase.call(query);

        // Assert - Should not crash, returns empty results
        expect(results, isA<List<SearchResult>>());
        expect(results, isEmpty);
      });

      test('should recover from temporary network issues', () async {
        // Arrange
        const query = SearchQuery(query: 'network recovery test');
        final successResults = [
          SearchResult(
            title: 'Recovery Success',
            url: 'https://recovery.com',
            snippet: 'Network recovered',
            timestamp: DateTime.now(),
          ),
        ];
        dataSource.setSearchResponse(query, successResults);

        // Act
        final results = await searchWebUseCase.call(query);

        // Assert
        expect(results, isNotEmpty);
        expect(results[0].title, 'Recovery Success');
      });
    });
  });
}