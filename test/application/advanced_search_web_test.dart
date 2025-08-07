import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:local_llm/domain/entities/search_result.dart';
import 'package:local_llm/domain/entities/search_query.dart';
import 'package:local_llm/domain/repositories/search_repository.dart';
import 'package:local_llm/application/search_web.dart';

@GenerateMocks([SearchRepository])
import 'advanced_search_web_test.mocks.dart';

void main() {
  late SearchWeb useCase;
  late MockSearchRepository mockRepository;

  setUp(() {
    mockRepository = MockSearchRepository();
    useCase = SearchWeb(mockRepository);
  });

  const testQuery = SearchQuery(
    query: 'flutter clean architecture',
    maxResults: 3,
    type: SearchType.general,
  );

  final testResults = [
    SearchResult(
      title: 'Flutter Clean Architecture Guide',
      url: 'https://example.com/flutter-clean-architecture',
      snippet:
          'A comprehensive guide to implementing Clean Architecture in Flutter applications.',
      timestamp: DateTime.now(),
    ),
    SearchResult(
      title: 'Flutter Clean Architecture Example',
      url: 'https://example.com/flutter-clean-architecture-example',
      snippet:
          'An example of Clean Architecture implemented in a Flutter project.',
      timestamp: DateTime.now(),
    ),
  ];

  group('SearchWeb UseCase', () {
    test('should get search results from the repository', () async {
      // Arrange
      when(mockRepository.search(testQuery))
          .thenAnswer((_) async => testResults);

      // Act
      final result = await useCase(testQuery);

      // Assert
      expect(result, testResults);
      verify(mockRepository.search(testQuery));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should throw ArgumentError when query is empty', () async {
      // Arrange
      const emptyQuery = SearchQuery(
        query: '',
        maxResults: 3,
      );

      // Act & Assert
      expect(() => useCase(emptyQuery), throwsArgumentError);
      verifyZeroInteractions(mockRepository);
    });

    test('should throw Exception when repository fails', () async {
      // Arrange
      when(mockRepository.search(testQuery))
          .thenThrow(Exception('Repository failure'));

      // Act & Assert
      expect(() => useCase(testQuery), throwsException);
      verify(mockRepository.search(testQuery));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should respect maxResults parameter', () async {
      // Arrange
      const limitedQuery = SearchQuery(
        query: 'flutter clean architecture',
        maxResults: 1,
      );

      final limitedResults = [testResults.first];

      when(mockRepository.search(limitedQuery))
          .thenAnswer((_) async => limitedResults);

      // Act
      final result = await useCase(limitedQuery);

      // Assert
      expect(result.length, 1);
      expect(result, limitedResults);
      verify(mockRepository.search(limitedQuery));
      verifyNoMoreInteractions(mockRepository);
    });
  });

  group('SearchQuery Entity', () {
    test('should format query correctly without site parameter', () {
      // Arrange
      const query = SearchQuery(
        query: 'flutter clean architecture',
      );

      // Act & Assert
      expect(query.formattedQuery, 'flutter clean architecture');
    });

    test('should format query correctly with site parameter', () {
      // Arrange
      final query = SearchQuery(
        query: 'flutter clean architecture',
        domains: ['flutter.dev'],
      );

      // Act & Assert
      expect(
          query.formattedQuery, 'flutter clean architecture site:flutter.dev');
    });

    test('should have default values for optional parameters', () {
      // Arrange
      const query = SearchQuery(
        query: 'flutter',
      );

      // Act & Assert
      expect(query.maxResults, 5);
      expect(query.type, SearchType.general);
      expect(query.domains, null);
    });
  });
}
