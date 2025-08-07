import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/infrastructure/core/classification/quality_classifier.dart';
import 'package:local_llm/domain/entities/search_result.dart';
import 'package:local_llm/domain/entities/relevance_score.dart';

void main() {
  group('QualityClassifier', () {
    late QualityClassifier classifier;

    setUp(() {
      classifier = QualityClassifier();
    });

    tearDown(() {
      classifier.clearCache();
    });

    group('identifyQueryType', () {
      test('should identify factual queries', () {
        expect(
          classifier.identifyQueryType('O que é Flutter?'),
          equals(QueryType.factual),
        );
        expect(
          classifier.identifyQueryType('What is machine learning?'),
          equals(QueryType.factual),
        );
        expect(
          classifier.identifyQueryType('Quem é o criador do Dart?'),
          equals(QueryType.factual),
        );
      });

      test('should identify technical queries', () {
        expect(
          classifier.identifyQueryType(
              'Como implementar state management no Flutter?'),
          equals(QueryType.technical),
        );
        expect(
          classifier.identifyQueryType('How to configure API endpoints?'),
          equals(QueryType.technical),
        );
        expect(
          classifier.identifyQueryType('Error handling in Dart programming'),
          equals(QueryType.technical),
        );
      });

      test('should identify explanatory queries', () {
        expect(
          classifier.identifyQueryType('Por que usar Flutter?'),
          equals(QueryType.explanatory),
        );
        expect(
          classifier.identifyQueryType('Why is TypeScript better?'),
          equals(QueryType.explanatory),
        );
        expect(
          classifier.identifyQueryType('Explique como funciona o hot reload'),
          equals(QueryType.explanatory),
        );
      });

      test('should identify procedural queries', () {
        expect(
          classifier.identifyQueryType('Como fazer um app Flutter?'),
          equals(QueryType.procedural),
        );
        expect(
          classifier.identifyQueryType('How to install Node.js?'),
          equals(QueryType.procedural),
        );
        expect(
          classifier.identifyQueryType('Tutorial de configuração do ambiente'),
          equals(QueryType.procedural),
        );
      });

      test('should identify comparative queries', () {
        expect(
          classifier.identifyQueryType('Flutter vs React Native'),
          equals(QueryType.comparative),
        );
        expect(
          classifier.identifyQueryType('Compare Angular versus Vue'),
          equals(QueryType.comparative),
        );
        expect(
          classifier.identifyQueryType('Qual é melhor: iOS ou Android?'),
          equals(QueryType.comparative),
        );
      });

      test('should default to general for unclear queries', () {
        expect(
          classifier.identifyQueryType('mobile apps'),
          equals(QueryType.general),
        );
        expect(
          classifier.identifyQueryType('programming'),
          equals(QueryType.general),
        );
      });
    });

    group('classifyQuality', () {
      test('should classify high quality results as satisfactory', () {
        final query = 'O que é Flutter?';
        final results = [
          SearchResult(
            title: 'Flutter - Build apps for any screen',
            snippet:
                'Flutter is Google\'s UI toolkit for building beautiful, natively compiled applications for mobile, web, and desktop from a single codebase.',
            url: 'https://flutter.dev',
            content:
                'Flutter is an open-source UI software development kit created by Google. It is used to develop cross platform applications for Android, iOS, Linux, Mac, Windows, Google Fuchsia, and the web from a single codebase. The first version of Flutter was known as codename "Sky" and ran on the Android operating system. Flutter uses the Dart programming language and provides a rich set of widgets. It allows developers to create beautiful, performative applications with a single codebase that can run on multiple platforms. The framework includes hot reload functionality for faster development.',
            timestamp: DateTime.now(),
          ),
          SearchResult(
            title: 'What is Flutter? - Wikipedia',
            snippet:
                'Flutter is an open-source UI software development kit created by Google.',
            url: 'https://en.wikipedia.org/wiki/Flutter_(software)',
            content:
                'Detailed Wikipedia article about Flutter framework with comprehensive information about its history, features, and usage. Flutter was originally developed by Google and first released in 2017. It has gained significant popularity among developers due to its cross-platform capabilities and excellent performance. The framework supports multiple rendering backends and provides extensive customization options for creating unique user interfaces.',
            timestamp: DateTime.now(),
          ),
        ];

        final relevanceScores = [
          RelevanceScore(
            overallScore: 0.9,
            semanticScore: 0.95,
            keywordScore: 0.9,
            qualityScore: 0.85,
            authorityScore: 0.9,
            scoringFactors: {'test': 1.0},
          ),
          RelevanceScore(
            overallScore: 0.85,
            semanticScore: 0.8,
            keywordScore: 0.85,
            qualityScore: 0.9,
            authorityScore: 0.9,
            scoringFactors: {'test': 1.0},
          ),
        ];

        final assessment = classifier.classifyQuality(
          query: query,
          results: results,
          relevanceScores: relevanceScores,
          queryType: QueryType.factual,
        );

        expect(assessment.isSatisfactory, isTrue);
        expect(assessment.confidenceScore, greaterThan(0.7));
        expect(assessment.authorityScore, greaterThan(0.7));
        expect(assessment.sourceDiversityCount, equals(2));
        expect(assessment.qualityIssues, isEmpty);
        expect(assessment.strengths, isNotEmpty);
      });

      test('should classify low quality results as unsatisfactory', () {
        final query = 'Como configurar environment variables?';
        final results = [
          SearchResult(
            title: 'Click here for more info',
            snippet: 'Get more information about this topic.',
            url: 'https://spam-site.com/page',
            content: 'Very short content without much detail.',
            timestamp: DateTime.now(),
          ),
        ];

        final relevanceScores = [
          RelevanceScore(
            overallScore: 0.3,
            semanticScore: 0.2,
            keywordScore: 0.4,
            qualityScore: 0.2,
            authorityScore: 0.1,
            scoringFactors: {'test': 1.0},
          ),
        ];

        final assessment = classifier.classifyQuality(
          query: query,
          results: results,
          relevanceScores: relevanceScores,
          queryType: QueryType.technical,
        );

        expect(assessment.isSatisfactory, isFalse);
        expect(assessment.confidenceScore, lessThan(0.5));
        expect(assessment.qualityIssues, isNotEmpty);
        expect(
            assessment.qualityIssues
                .any((issue) => issue.contains('autoridade')),
            isTrue);
      });

      test('should require multiple sources for comparative queries', () {
        final query = 'Flutter vs React Native performance';
        final results = [
          SearchResult(
            title: 'Flutter Performance Analysis',
            snippet:
                'Detailed analysis of Flutter performance characteristics.',
            url: 'https://medium.com/flutter-performance',
            content:
                'Long detailed content about Flutter performance with benchmarks and analysis.',
            timestamp: DateTime.now(),
          ),
        ];

        final relevanceScores = [
          RelevanceScore(
            overallScore: 0.8,
            semanticScore: 0.8,
            keywordScore: 0.7,
            qualityScore: 0.8,
            authorityScore: 0.7,
            scoringFactors: {'test': 1.0},
          ),
        ];

        final assessment = classifier.classifyQuality(
          query: query,
          results: results,
          relevanceScores: relevanceScores,
          queryType: QueryType.comparative,
        );

        expect(assessment.isSatisfactory, isFalse);
        expect(
          assessment.qualityIssues.any((issue) => issue.contains('fontes')),
          isTrue,
        );
      });

      test('should cache assessment results', () {
        final query = 'Test query for caching';
        final results = [
          SearchResult(
            title: 'Test Title',
            snippet: 'Test snippet',
            url: 'https://test.com',
            content: 'Test content',
            timestamp: DateTime.now(),
          ),
        ];

        final relevanceScores = [
          RelevanceScore(
            overallScore: 0.7,
            semanticScore: 0.7,
            keywordScore: 0.7,
            qualityScore: 0.7,
            authorityScore: 0.7,
            scoringFactors: {'test': 1.0},
          ),
        ];

        // First call
        final assessment1 = classifier.classifyQuality(
          query: query,
          results: results,
          relevanceScores: relevanceScores,
        );

        // Second call should return cached result
        final assessment2 = classifier.classifyQuality(
          query: query,
          results: results,
          relevanceScores: relevanceScores,
        );

        expect(
            assessment1.confidenceScore, equals(assessment2.confidenceScore));
        expect(assessment1.isSatisfactory, equals(assessment2.isSatisfactory));

        // Verify cache is working
        final stats = classifier.getCacheStats();
        expect(stats['cacheSize'], greaterThan(0));
      });
    });

    group('QualityConfig', () {
      test('should have appropriate defaults for different query types', () {
        final factualConfig = QualityConfig.defaultConfigs[QueryType.factual]!;
        expect(factualConfig.minRelevanceThreshold, equals(0.8));
        expect(factualConfig.requireMultipleSources, isTrue);

        final technicalConfig =
            QualityConfig.defaultConfigs[QueryType.technical]!;
        expect(technicalConfig.minRelevanceThreshold, equals(0.85));
        expect(technicalConfig.minAuthorityScore, equals(0.8));

        final generalConfig = QualityConfig.defaultConfigs[QueryType.general]!;
        expect(generalConfig.minRelevanceThreshold, equals(0.6));
        expect(generalConfig.requireMultipleSources, isFalse);
      });
    });

    group('Edge cases', () {
      test('should handle empty results', () {
        final assessment = classifier.classifyQuality(
          query: 'test query',
          results: [],
          relevanceScores: [],
        );

        expect(assessment.isSatisfactory, isFalse);
        expect(assessment.confidenceScore, equals(0.0));
        expect(assessment.qualityIssues, isNotEmpty);
      });

      test('should handle mismatched results and scores', () {
        final results = [
          SearchResult(
            title: 'Test',
            snippet: 'Test',
            url: 'https://test.com',
            timestamp: DateTime.now(),
          ),
        ];

        final relevanceScores = [
          RelevanceScore(
            overallScore: 0.8,
            semanticScore: 0.8,
            keywordScore: 0.8,
            qualityScore: 0.8,
            authorityScore: 0.8,
            scoringFactors: {'test': 1.0},
          ),
          RelevanceScore(
            overallScore: 0.7,
            semanticScore: 0.7,
            keywordScore: 0.7,
            qualityScore: 0.7,
            authorityScore: 0.7,
            scoringFactors: {'test': 1.0},
          ),
        ];

        expect(
          () => classifier.classifyQuality(
            query: 'test',
            results: results,
            relevanceScores: relevanceScores,
          ),
          returnsNormally,
        );
      });

      test('should handle empty query', () {
        final results = [
          SearchResult(
            title: 'Test',
            snippet: 'Test content',
            url: 'https://test.com',
            timestamp: DateTime.now(),
          ),
        ];

        final relevanceScores = [
          RelevanceScore(
            overallScore: 0.5,
            semanticScore: 0.5,
            keywordScore: 0.5,
            qualityScore: 0.5,
            authorityScore: 0.5,
            scoringFactors: {'test': 1.0},
          ),
        ];

        final assessment = classifier.classifyQuality(
          query: '',
          results: results,
          relevanceScores: relevanceScores,
        );

        expect(assessment.coverageScore, equals(0.0));
      });

      test('should handle very long content', () {
        final longContent = 'A' * 10000; // Very long content
        final results = [
          SearchResult(
            title: 'Test with long content',
            snippet: 'Test snippet',
            url: 'https://test.com',
            content: longContent,
            timestamp: DateTime.now(),
          ),
        ];

        final relevanceScores = [
          RelevanceScore(
            overallScore: 0.8,
            semanticScore: 0.8,
            keywordScore: 0.8,
            qualityScore: 0.8,
            authorityScore: 0.8,
            scoringFactors: {'test': 1.0},
          ),
        ];

        expect(
          () => classifier.classifyQuality(
            query: 'test query',
            results: results,
            relevanceScores: relevanceScores,
          ),
          returnsNormally,
        );
      });
    });

    group('Cache management', () {
      test('should clear cache correctly', () {
        // Add some cached results
        classifier.classifyQuality(
          query: 'test1',
          results: [
            SearchResult(
              title: 'Test',
              snippet: 'Test',
              url: 'https://test.com',
              timestamp: DateTime.now(),
            ),
          ],
          relevanceScores: [
            RelevanceScore(
              overallScore: 0.7,
              semanticScore: 0.7,
              keywordScore: 0.7,
              qualityScore: 0.7,
              authorityScore: 0.7,
              scoringFactors: {'test': 1.0},
            ),
          ],
        );

        var stats = classifier.getCacheStats();
        expect(stats['cacheSize'], greaterThan(0));

        classifier.clearCache();

        stats = classifier.getCacheStats();
        expect(stats['cacheSize'], equals(0));
      });

      test('should provide meaningful cache statistics', () {
        final stats = classifier.getCacheStats();
        expect(stats, contains('cacheSize'));
        expect(stats, contains('memoryUsage'));
        expect(stats['cacheSize'], isA<int>());
        expect(stats['memoryUsage'], isA<int>());
      });
    });

    group('Quality assessment components', () {
      test('should assess coverage correctly', () {
        final query = 'Flutter state management Riverpod';
        final results = [
          SearchResult(
            title: 'Flutter State Management with Riverpod',
            snippet:
                'Complete guide to using Riverpod for state management in Flutter applications.',
            url: 'https://riverpod.dev',
            timestamp: DateTime.now(),
            content:
                'Detailed explanation of Riverpod state management patterns in Flutter development.',
          ),
        ];

        final relevanceScores = [
          RelevanceScore(
            overallScore: 0.9,
            semanticScore: 0.9,
            keywordScore: 0.9,
            qualityScore: 0.8,
            authorityScore: 0.8,
            scoringFactors: {'test': 1.0},
          ),
        ];

        final assessment = classifier.classifyQuality(
          query: query,
          results: results,
          relevanceScores: relevanceScores,
        );

        // Should have good coverage since all query terms are present
        expect(assessment.coverageScore, greaterThan(0.7));
      });

      test('should assess authority correctly', () {
        final results = [
          SearchResult(
            title: 'Official Documentation',
            snippet: 'Official guide',
            url: 'https://docs.flutter.dev/guide',
            timestamp: DateTime.now(),
          ),
          SearchResult(
            title: 'Blog Post',
            snippet: 'Personal blog',
            url: 'https://myblog.com/post',
            timestamp: DateTime.now(),
          ),
        ];

        final relevanceScores = [
          RelevanceScore(
            overallScore: 0.8,
            semanticScore: 0.8,
            keywordScore: 0.8,
            qualityScore: 0.8,
            authorityScore: 0.9, // High authority for official docs
            scoringFactors: {'test': 1.0},
          ),
          RelevanceScore(
            overallScore: 0.6,
            semanticScore: 0.6,
            keywordScore: 0.6,
            qualityScore: 0.6,
            authorityScore: 0.5, // Lower authority for blog
            scoringFactors: {'test': 1.0},
          ),
        ];

        final assessment = classifier.classifyQuality(
          query: 'test query',
          results: results,
          relevanceScores: relevanceScores,
        );

        // Should have good authority score due to official documentation
        expect(assessment.authorityScore, greaterThan(0.6));
      });
    });
  });
}
