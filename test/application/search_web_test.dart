import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:local_llm/application/search_web.dart';
import 'package:local_llm/domain/repositories/search_repository.dart';
import 'package:local_llm/domain/entities/search_result.dart';
import 'package:local_llm/domain/entities/search_query.dart';

@GenerateMocks([SearchRepository])
import 'search_web_test.mocks.dart';

void main() {
  group('SearchWeb', () {
    late SearchWeb useCase;
    late MockSearchRepository mockRepository;

    setUp(() {
      mockRepository = MockSearchRepository();
      useCase = SearchWeb(mockRepository);
    });

    group('call', () {
      test('should return search results from repository', () async {
        // Arrange
        const query = SearchQuery(query: 'flutter development');
        final expectedResults = [
          SearchResult(
            title: 'Flutter Official Site',
            url: 'https://flutter.dev',
            snippet: 'Build apps for any screen',
            timestamp: DateTime.now(),
          ),
          SearchResult(
            title: 'Flutter Documentation',
            url: 'https://flutter.dev/docs',
            snippet: 'Complete Flutter documentation',
            timestamp: DateTime.now(),
          ),
        ];

        when(mockRepository.search(query))
            .thenAnswer((_) async => expectedResults);

        // Act
        final results = await useCase.call(query);

        // Assert
        expect(results, expectedResults);
        verify(mockRepository.search(query)).called(1);
      });

      test('should handle empty query by throwing ArgumentError', () async {
        // Arrange
        const emptyQuery = SearchQuery(query: '');

        // Act & Assert
        expect(
          () async => await useCase.call(emptyQuery),
          throwsA(
            predicate((e) =>
                e is ArgumentError &&
                e.message == 'Query não pode estar vazia'),
          ),
        );

        verifyNever(mockRepository.search(any));
      });

      test('should handle whitespace-only query by throwing ArgumentError',
          () async {
        // Arrange
        const whitespaceQuery = SearchQuery(query: '   \t  \n  ');

        // Act & Assert
        expect(
          () async => await useCase.call(whitespaceQuery),
          throwsA(isA<ArgumentError>()),
        );

        verifyNever(mockRepository.search(any));
      });

      test('should handle different search types', () async {
        // Arrange
        const newsQuery = SearchQuery(
          query: 'technology news',
          type: SearchType.news,
          maxResults: 15,
        );

        final newsResults = [
          SearchResult(
            title: 'Tech News Today',
            url: 'https://tech-news.com',
            snippet: 'Latest technology updates',
            timestamp: DateTime.now(),
          ),
        ];

        when(mockRepository.search(newsQuery))
            .thenAnswer((_) async => newsResults);

        // Act
        final results = await useCase.call(newsQuery);

        // Assert
        expect(results, newsResults);
        verify(mockRepository.search(newsQuery)).called(1);
      });

      test('should handle academic search type', () async {
        // Arrange
        const academicQuery = SearchQuery(
          query: 'machine learning research',
          type: SearchType.academic,
          maxResults: 10,
        );

        final academicResults = [
          SearchResult(
            title: 'ML Research Paper',
            url: 'https://arxiv.org/abs/123456',
            snippet: 'Deep learning advances in 2024',
            timestamp: DateTime.now(),
          ),
        ];

        when(mockRepository.search(academicQuery))
            .thenAnswer((_) async => academicResults);

        // Act
        final results = await useCase.call(academicQuery);

        // Assert
        expect(results, academicResults);
        verify(mockRepository.search(academicQuery)).called(1);
      });

      test('should handle site-specific queries', () async {
        // Arrange
        final siteQuery = SearchQuery(
          query: 'dart programming',
          domains: ['dart.dev'],
        );

        final siteResults = [
          SearchResult(
            title: 'Dart Language Tour',
            url: 'https://dart.dev/guides/language/language-tour',
            snippet: 'Learn Dart programming language',
            timestamp: DateTime.now(),
          ),
        ];

        when(mockRepository.search(siteQuery))
            .thenAnswer((_) async => siteResults);

        // Act
        final results = await useCase.call(siteQuery);

        // Assert
        expect(results, siteResults);
        expect(siteQuery.formattedQuery, 'dart programming site:dart.dev');
        verify(mockRepository.search(siteQuery)).called(1);
      });

      test('should handle empty results from repository', () async {
        // Arrange
        const query = SearchQuery(query: 'very specific non-existent topic');
        when(mockRepository.search(query)).thenAnswer((_) async => []);

        // Act
        final results = await useCase.call(query);

        // Assert
        expect(results, isEmpty);
        verify(mockRepository.search(query)).called(1);
      });

      test('should propagate repository exceptions', () async {
        // Arrange
        const query = SearchQuery(query: 'network error test');
        when(mockRepository.search(query))
            .thenThrow(Exception('Network connection failed'));

        // Act & Assert
        expect(
          () async => await useCase.call(query),
          throwsA(
            predicate((e) =>
                e is Exception &&
                e.toString().contains('Network connection failed')),
          ),
        );

        verify(mockRepository.search(query)).called(1);
      });

      test('should handle various query lengths', () async {
        // Test short query
        const shortQuery = SearchQuery(query: 'AI');
        when(mockRepository.search(shortQuery)).thenAnswer((_) async => []);

        await useCase.call(shortQuery);
        verify(mockRepository.search(shortQuery)).called(1);

        // Test long query
        const longQuery = SearchQuery(
          query:
              'comprehensive guide to machine learning algorithms for beginners with practical examples and real-world applications',
        );
        when(mockRepository.search(longQuery)).thenAnswer((_) async => []);

        await useCase.call(longQuery);
        verify(mockRepository.search(longQuery)).called(1);
      });

      test('should handle special characters in query', () async {
        // Arrange
        const specialQuery = SearchQuery(
          query: 'C++ programming "advanced concepts" -beginner',
        );

        final specialResults = [
          SearchResult(
            title: 'Advanced C++ Programming',
            url: 'https://cplusplus.com/advanced',
            snippet: 'Master advanced C++ concepts',
            timestamp: DateTime.now(),
          ),
        ];

        when(mockRepository.search(specialQuery))
            .thenAnswer((_) async => specialResults);

        // Act
        final results = await useCase.call(specialQuery);

        // Assert
        expect(results, specialResults);
        verify(mockRepository.search(specialQuery)).called(1);
      });

      test('should handle Unicode characters in query', () async {
        // Arrange
        const unicodeQuery = SearchQuery(query: 'プログラミング 学習 日本語');

        final unicodeResults = [
          SearchResult(
            title: 'Japanese Programming Tutorial',
            url: 'https://example.jp/programming',
            snippet: 'Programming tutorials in Japanese',
            timestamp: DateTime.now(),
          ),
        ];

        when(mockRepository.search(unicodeQuery))
            .thenAnswer((_) async => unicodeResults);

        // Act
        final results = await useCase.call(unicodeQuery);

        // Assert
        expect(results, unicodeResults);
        verify(mockRepository.search(unicodeQuery)).called(1);
      });
    });
  });

  group('FetchWebContent', () {
    late FetchWebContent useCase;
    late MockSearchRepository mockRepository;

    setUp(() {
      mockRepository = MockSearchRepository();
      useCase = FetchWebContent(mockRepository);
    });

    group('call', () {
      test('should return page content from repository', () async {
        // Arrange
        const url = 'https://flutter.dev';
        const expectedContent =
            '<!DOCTYPE html><html><head><title>Flutter</title>';

        when(mockRepository.fetchPageContent(url))
            .thenAnswer((_) async => expectedContent);

        // Act
        final content = await useCase.call(url);

        // Assert
        expect(content, expectedContent);
        verify(mockRepository.fetchPageContent(url)).called(1);
      });

      test('should handle empty URL by throwing ArgumentError', () async {
        // Arrange
        const emptyUrl = '';

        // Act & Assert
        expect(
          () async => await useCase.call(emptyUrl),
          throwsA(
            predicate((e) =>
                e is ArgumentError && e.message == 'URL não pode estar vazia'),
          ),
        );

        verifyNever(mockRepository.fetchPageContent(any));
      });

      test('should handle whitespace-only URL by throwing ArgumentError',
          () async {
        // Arrange
        const whitespaceUrl = '   \t  \n  ';

        // Act & Assert
        expect(
          () async => await useCase.call(whitespaceUrl),
          throwsA(isA<ArgumentError>()),
        );

        verifyNever(mockRepository.fetchPageContent(any));
      });

      test('should handle various URL formats', () async {
        // Arrange
        final urls = [
          'https://example.com',
          'http://example.com',
          'https://subdomain.example.com/path',
          'https://example.com/path?query=value&other=param',
          'https://example.com/path#fragment',
        ];

        for (final url in urls) {
          when(mockRepository.fetchPageContent(url))
              .thenAnswer((_) async => 'Content for $url');
        }

        // Act & Assert
        for (final url in urls) {
          final content = await useCase.call(url);
          expect(content, 'Content for $url');
          verify(mockRepository.fetchPageContent(url)).called(1);
        }
      });

      test('should handle empty content from repository', () async {
        // Arrange
        const url = 'https://empty-page.com';
        when(mockRepository.fetchPageContent(url)).thenAnswer((_) async => '');

        // Act
        final content = await useCase.call(url);

        // Assert
        expect(content, isEmpty);
        verify(mockRepository.fetchPageContent(url)).called(1);
      });

      test('should propagate repository exceptions', () async {
        // Arrange
        const url = 'https://error-site.com';
        when(mockRepository.fetchPageContent(url))
            .thenThrow(Exception('Failed to fetch content'));

        // Act & Assert
        expect(
          () async => await useCase.call(url),
          throwsA(
            predicate((e) =>
                e is Exception &&
                e.toString().contains('Failed to fetch content')),
          ),
        );

        verify(mockRepository.fetchPageContent(url)).called(1);
      });

      test('should handle large content responses', () async {
        // Arrange
        const url = 'https://large-content.com';
        final largeContent = 'Large content: ${'x' * 100000}';

        when(mockRepository.fetchPageContent(url))
            .thenAnswer((_) async => largeContent);

        // Act
        final content = await useCase.call(url);

        // Assert
        expect(content, largeContent);
        expect(content.length, greaterThan(100000));
        verify(mockRepository.fetchPageContent(url)).called(1);
      });

      test('should handle international URLs', () async {
        // Arrange
        const url = 'https://テスト.日本/ページ';
        const expectedContent = 'Japanese website content';

        when(mockRepository.fetchPageContent(url))
            .thenAnswer((_) async => expectedContent);

        // Act
        final content = await useCase.call(url);

        // Assert
        expect(content, expectedContent);
        verify(mockRepository.fetchPageContent(url)).called(1);
      });
    });
  });
}
