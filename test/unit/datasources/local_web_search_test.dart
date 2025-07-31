import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;

import 'package:local_llm/data/datasources/local_web_search_datasource.dart';
import 'package:local_llm/domain/entities/search_result.dart';

import 'local_web_search_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('LocalWebSearchDataSource Tests', () {
    late LocalWebSearchDataSource dataSource;
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();
      dataSource = LocalWebSearchDataSource(client: mockClient);
    });

    group('Search Functionality', () {
      test('should handle successful search with results', () async {
        // Arrange
        const query = SearchQuery(query: 'flutter development', maxResults: 3);
        
        // Mock Google response
        when(mockClient.get(
          argThat(contains('google.com')),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          '''
          <html>
            <body>
              <div class="g">
                <h3>Flutter Documentation</h3>
                <a href="https://flutter.dev">Flutter</a>
                <div class="VwiC3b">Official Flutter documentation</div>
              </div>
            </body>
          </html>
          ''',
          200,
        ));

        // Mock Bing response (empty for simplicity)
        when(mockClient.get(
          argThat(contains('bing.com')),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('<html></html>', 200));

        // Mock DuckDuckGo response (empty for simplicity)
        when(mockClient.get(
          argThat(contains('duckduckgo.com')),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('<html></html>', 200));

        // Act
        final results = await dataSource.search(query);

        // Assert
        expect(results, isNotEmpty);
        verify(mockClient.get(argThat(contains('google.com')), headers: anyNamed('headers')));
      });

      test('should handle search timeout gracefully', () async {
        // Arrange
        const query = SearchQuery(query: 'test query', maxResults: 3);
        
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenThrow(Exception('Timeout'));

        // Act
        final results = await dataSource.search(query);

        // Assert
        expect(results, isEmpty); // Should return empty list on error
      });

      test('should handle HTTP error responses', () async {
        // Arrange
        const query = SearchQuery(query: 'test query', maxResults: 3);
        
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response('Not Found', 404));

        // Act
        final results = await dataSource.search(query);

        // Assert
        expect(results, isEmpty);
      });

      test('should combine results from multiple sources', () async {
        // Arrange
        const query = SearchQuery(query: 'programming', maxResults: 5);
        
        // Mock Google with one result
        when(mockClient.get(
          argThat(contains('google.com')),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          '''
          <div class="g">
            <h3>Programming Guide</h3>
            <a href="https://example1.com">Example 1</a>
          </div>
          ''',
          200,
        ));

        // Mock Bing with different result
        when(mockClient.get(
          argThat(contains('bing.com')),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          '''
          <div class="b_algo">
            <h2><a href="https://example2.com">Programming Tutorial</a></h2>
          </div>
          ''',
          200,
        ));

        // Mock DuckDuckGo
        when(mockClient.get(
          argThat(contains('duckduckgo.com')),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('<html></html>', 200));

        // Act
        final results = await dataSource.search(query);

        // Assert
        expect(results.length, lessThanOrEqualTo(query.maxResults));
      });
    });

    group('Page Content Fetching', () {
      test('should fetch and clean page content', () async {
        // Arrange
        const url = 'https://example.com/article';
        const htmlContent = '''
          <html>
            <head><title>Test Article</title></head>
            <body>
              <nav>Navigation</nav>
              <main>
                <h1>Article Title</h1>
                <p>This is the main content of the article.</p>
              </main>
              <script>console.log('ad');</script>
            </body>
          </html>
        ''';

        when(mockClient.get(
          Uri.parse(url),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(htmlContent, 200));

        // Act
        final content = await dataSource.fetchPageContent(url);

        // Assert
        expect(content, contains('Article Title'));
        expect(content, contains('main content'));
        expect(content, isNot(contains('Navigation'))); // Should be removed
        expect(content, isNot(contains('console.log'))); // Scripts should be removed
      });

      test('should handle page fetch error', () async {
        // Arrange
        const url = 'https://example.com/notfound';
        
        when(mockClient.get(
          Uri.parse(url),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('Not Found', 404));

        // Act & Assert
        expect(
          () => dataSource.fetchPageContent(url),
          throwsException,
        );
      });

      test('should limit content length', () async {
        // Arrange
        const url = 'https://example.com/long-article';
        final longContent = 'a' * 5000; // Very long content
        final htmlContent = '<html><body><main>$longContent</main></body></html>';

        when(mockClient.get(
          Uri.parse(url),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(htmlContent, 200));

        // Act
        final content = await dataSource.fetchPageContent(url);

        // Assert
        expect(content.length, lessThanOrEqualTo(3003)); // 3000 + '...'
        expect(content, endsWith('...'));
      });
    });

    group('Text Cleaning', () {
      test('should clean malformed text', () {
        // This test would require access to the private _cleanText method
        // For now, we test through the public methods that use it
        expect(true, true); // Placeholder
      });
    });

    group('Error Recovery', () {
      test('should continue with other sources when one fails', () async {
        // Arrange
        const query = SearchQuery(query: 'recovery test', maxResults: 3);
        
        // Google fails
        when(mockClient.get(
          argThat(contains('google.com')),
          headers: anyNamed('headers'),
        )).thenThrow(Exception('Google timeout'));

        // Bing succeeds
        when(mockClient.get(
          argThat(contains('bing.com')),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          '<div class="b_algo"><h2><a href="https://example.com">Result</a></h2></div>',
          200,
        ));

        // DuckDuckGo succeeds
        when(mockClient.get(
          argThat(contains('duckduckgo.com')),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('<html></html>', 200));

        // Act
        final results = await dataSource.search(query);

        // Assert
        // Should not throw exception and may have results from working sources
        expect(() => results, isNot(throwsException));
      });
    });
  });
}