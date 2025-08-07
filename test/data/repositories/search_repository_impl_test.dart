import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:local_llm/infrastructure/repositories/search_repository_impl.dart';
import 'package:local_llm/infrastructure/datasources/web_search_datasource.dart';
import 'package:local_llm/domain/entities/search_result.dart';
import 'package:local_llm/domain/entities/search_query.dart';

@GenerateMocks([WebSearchDataSource])
import 'search_repository_impl_test.mocks.dart';

void main() {
  group('SearchRepositoryImpl', () {
    late SearchRepositoryImpl repository;
    late MockWebSearchDataSource mockDataSource;

    setUp(() {
      mockDataSource = MockWebSearchDataSource();
      repository = SearchRepositoryImpl(dataSource: mockDataSource);
    });

    group('search', () {
      test('should return search results from data source', () async {
        // Arrange
        const query = SearchQuery(query: 'flutter development');
        final expectedResults = [
          SearchResult(
            title: 'Flutter Documentation',
            url: 'https://flutter.dev',
            snippet: 'Official Flutter documentation',
            timestamp: DateTime.now(),
          ),
          SearchResult(
            title: 'Flutter Tutorial',
            url: 'https://flutter.dev/tutorial',
            snippet: 'Learn Flutter step by step',
            timestamp: DateTime.now(),
          ),
        ];

        when(mockDataSource.search(query))
            .thenAnswer((_) async => expectedResults);

        // Act
        final results = await repository.search(query);

        // Assert
        expect(results, expectedResults);
        verify(mockDataSource.search(query)).called(1);
      });

      test('should handle empty search results', () async {
        // Arrange
        const query = SearchQuery(query: 'nonexistent topic');
        when(mockDataSource.search(query)).thenAnswer((_) async => []);

        // Act
        final results = await repository.search(query);

        // Assert
        expect(results, isEmpty);
        verify(mockDataSource.search(query)).called(1);
      });

      test('should throw exception when data source fails', () async {
        // Arrange
        const query = SearchQuery(query: 'error query');
        when(mockDataSource.search(query))
            .thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () async => await repository.search(query),
          throwsA(
            predicate((e) =>
                e is Exception && e.toString().contains('Falha na pesquisa')),
          ),
        );

        verify(mockDataSource.search(query)).called(1);
      });

      test('should handle different query types', () async {
        // Arrange
        const newsQuery = SearchQuery(
          query: 'latest news',
          type: SearchType.news,
          maxResults: 10,
        );

        final newsResults = [
          SearchResult(
            title: 'Breaking News',
            url: 'https://news.com/breaking',
            snippet: 'Latest breaking news',
            timestamp: DateTime.now(),
          ),
        ];

        when(mockDataSource.search(newsQuery))
            .thenAnswer((_) async => newsResults);

        // Act
        final results = await repository.search(newsQuery);

        // Assert
        expect(results, newsResults);
        verify(mockDataSource.search(newsQuery)).called(1);
      });

      test('should handle query with site filter', () async {
        // Arrange
        final siteQuery = SearchQuery(
          query: 'dart programming',
          domains: ['dart.dev'],
          maxResults: 5,
        );

        final siteResults = [
          SearchResult(
            title: 'Dart Language Tour',
            url: 'https://dart.dev/guides/language/language-tour',
            snippet: 'A comprehensive guide to Dart',
            timestamp: DateTime.now(),
          ),
        ];

        when(mockDataSource.search(siteQuery))
            .thenAnswer((_) async => siteResults);

        // Act
        final results = await repository.search(siteQuery);

        // Assert
        expect(results, siteResults);
        expect(siteQuery.formattedQuery, 'dart programming site:dart.dev');
        verify(mockDataSource.search(siteQuery)).called(1);
      });
    });

    group('fetchPageContent', () {
      test('should return page content from data source', () async {
        // Arrange
        const url = 'https://example.com';
        const expectedContent = '<html><body>Example content</body></html>';

        when(mockDataSource.fetchPageContent(url))
            .thenAnswer((_) async => expectedContent);

        // Act
        final content = await repository.fetchPageContent(url);

        // Assert
        expect(content, expectedContent);
        verify(mockDataSource.fetchPageContent(url)).called(1);
      });

      test('should handle empty page content', () async {
        // Arrange
        const url = 'https://empty.com';
        when(mockDataSource.fetchPageContent(url)).thenAnswer((_) async => '');

        // Act
        final content = await repository.fetchPageContent(url);

        // Assert
        expect(content, isEmpty);
        verify(mockDataSource.fetchPageContent(url)).called(1);
      });

      test('should throw exception when fetching content fails', () async {
        // Arrange
        const url = 'https://error.com';
        when(mockDataSource.fetchPageContent(url))
            .thenThrow(Exception('HTTP 404 Not Found'));

        // Act & Assert
        expect(
          () async => await repository.fetchPageContent(url),
          throwsA(
            predicate((e) =>
                e is Exception &&
                e.toString().contains('Falha ao buscar conteúdo')),
          ),
        );

        verify(mockDataSource.fetchPageContent(url)).called(1);
      });

      test('should handle various URL formats', () async {
        // Arrange
        final urls = [
          'https://example.com',
          'http://example.com',
          'https://example.com/path?query=value',
          'https://subdomain.example.com/deep/path',
        ];

        for (final url in urls) {
          when(mockDataSource.fetchPageContent(url))
              .thenAnswer((_) async => 'Content for $url');
        }

        // Act & Assert
        for (final url in urls) {
          final content = await repository.fetchPageContent(url);
          expect(content, 'Content for $url');
          verify(mockDataSource.fetchPageContent(url)).called(1);
        }
      });

      test('should handle large content pages', () async {
        // Arrange
        const url = 'https://large-content.com';
        final largeContent = 'x' * 1000000; // 1MB of content

        when(mockDataSource.fetchPageContent(url))
            .thenAnswer((_) async => largeContent);

        // Act
        final content = await repository.fetchPageContent(url);

        // Assert
        expect(content, largeContent);
        verify(mockDataSource.fetchPageContent(url)).called(1);
      });
    });

    group('error handling', () {
      test('should wrap data source exceptions appropriately', () async {
        // Arrange
        const query = SearchQuery(query: 'test');
        when(mockDataSource.search(query))
            .thenThrow(ArgumentError('Invalid query'));

        // Act & Assert
        try {
          await repository.search(query);
          fail('Should have thrown an exception');
        } catch (e) {
          expect(e, isA<Exception>());
          expect(e.toString(), contains('Falha na pesquisa'));
          expect(e.toString(), contains('Invalid query'));
        }
      });

      test('should handle timeout exceptions', () async {
        // Arrange
        const url = 'https://slow-site.com';
        when(mockDataSource.fetchPageContent(url)).thenThrow(
            TimeoutException('Request timeout', const Duration(seconds: 30)));

        // Act & Assert
        expect(
          () async => await repository.fetchPageContent(url),
          throwsA(
            predicate((e) =>
                e is Exception &&
                e.toString().contains('Falha ao buscar conteúdo') &&
                e.toString().contains('Request timeout')),
          ),
        );
      });

      test('should preserve original error information', () async {
        // Arrange
        const query = SearchQuery(query: 'test');
        final originalError = StateError('Data source is not initialized');
        when(mockDataSource.search(query)).thenThrow(originalError);

        // Act & Assert
        try {
          await repository.search(query);
          fail('Should have thrown an exception');
        } catch (e) {
          expect(e, isA<Exception>());
          expect(e.toString(), contains('Data source is not initialized'));
        }
      });
    });
  });
}
