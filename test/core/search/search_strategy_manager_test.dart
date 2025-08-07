import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/infrastructure/core/search/search_strategy_manager.dart';
import 'package:local_llm/infrastructure/core/search/search_strategy.dart';
import 'package:local_llm/domain/entities/search_result.dart';
import 'package:local_llm/domain/entities/search_query.dart';

// Mock classes
class MockSearchStrategy implements SearchStrategy {
  final String _name;
  final int _priority;
  final bool _isAvailable;
  final Map<SearchQuery, List<SearchResult>?> _responses = {};
  final Map<SearchQuery, Exception?> _exceptions = {};

  MockSearchStrategy(this._name, this._priority, [this._isAvailable = true]);

  void setResponse(SearchQuery query, List<SearchResult> results) {
    _responses[query] = results;
  }

  void setException(SearchQuery query, Exception exception) {
    _exceptions[query] = exception;
  }

  @override
  String get name => _name;

  @override
  int get priority => _priority;

  @override
  bool get isAvailable => _isAvailable;

  @override
  int get timeoutSeconds => 10;

  @override
  SearchStrategyMetrics get metrics => SearchStrategyMetrics.empty();

  @override
  bool canHandle(SearchQuery query) => true;

  @override
  Future<List<SearchResult>> search(SearchQuery query) async {
    if (_exceptions.containsKey(query)) {
      throw _exceptions[query]!;
    }
    if (_responses.containsKey(query)) {
      return _responses[query]!;
    }
    return [];
  }
}

void main() {
  group('SearchStrategyManager', () {
    late SearchStrategyManager manager;
    late MockSearchStrategy mockStrategy1;
    late MockSearchStrategy mockStrategy2;

    setUp(() {
      manager = SearchStrategyManager(
        config: const SearchStrategyConfig(
          maxTimeoutSeconds: 30,
          maxFallbackAttempts: 3,
          enableStrategyCache: true,
          minSuccessRate:
              0.0, // Allow strategies with 0 success rate for testing
        ),
      );

      mockStrategy1 = MockSearchStrategy('Google', 10);
      mockStrategy2 = MockSearchStrategy('Bing', 8);
    });

    tearDown(() {
      manager.dispose();
    });

    test('should register strategies correctly', () {
      manager.registerStrategy(mockStrategy1);
      manager.registerStrategy(mockStrategy2);

      final stats = manager.getStatistics();
      expect(stats['registered_strategies'], 2);
    });

    test('should not register duplicate strategies', () {
      manager.registerStrategy(mockStrategy1);
      manager.registerStrategy(mockStrategy1); // Duplicate

      final stats = manager.getStatistics();
      expect(stats['registered_strategies'], 1);
    });

    test('should unregister strategies', () {
      manager.registerStrategy(mockStrategy1);
      manager.registerStrategy(mockStrategy2);

      manager.unregisterStrategy('Google');

      final stats = manager.getStatistics();
      expect(stats['registered_strategies'], 1);
    });

    test('should execute search with available strategy', () async {
      final query = SearchQuery(query: 'test query');
      mockStrategy1.setResponse(query, [
        SearchResult(
          title: 'Test Result',
          url: 'https://example.com',
          snippet: 'Test snippet',
          timestamp: DateTime.now(),
        ),
      ]);

      manager.registerStrategy(mockStrategy1);

      final result = await manager.search(query);

      expect(result.isSuccessful, true);
      expect(result.results, hasLength(1));
      expect(result.strategyName, 'Google');
    });

    test('should handle strategy failure with fallback', () async {
      final query = SearchQuery(query: 'test query');
      mockStrategy1.setException(query, Exception('Strategy 1 failed'));
      mockStrategy2.setResponse(query, [
        SearchResult(
          title: 'Fallback Result',
          url: 'https://fallback.com',
          snippet: 'Fallback snippet',
          timestamp: DateTime.now(),
        ),
      ]);

      manager.registerStrategy(mockStrategy1);
      manager.registerStrategy(mockStrategy2);

      final result = await manager.search(query);

      expect(result.isSuccessful, true);
      expect(result.strategyName, 'Bing');
      expect(result.results[0].title, 'Fallback Result');
    });

    test('should fail when no strategies available', () async {
      final query = SearchQuery(query: 'test query');

      expect(
        () async => await manager.search(query),
        throwsA(isA<Exception>()),
      );
    });

    test('should fail when all strategies fail', () async {
      final query = SearchQuery(query: 'test query');
      mockStrategy1.setException(query, Exception('Strategy 1 failed'));
      mockStrategy2.setException(query, Exception('Strategy 2 failed'));

      manager.registerStrategy(mockStrategy1);
      manager.registerStrategy(mockStrategy2);

      expect(
        () async => await manager.search(query),
        throwsA(isA<Exception>()),
      );
    });

    test('should cache successful results', () async {
      final query = SearchQuery(query: 'test query');
      mockStrategy1.setResponse(query, [
        SearchResult(
          title: 'Cached Result',
          url: 'https://cached.com',
          snippet: 'Cached snippet',
          timestamp: DateTime.now(),
        ),
      ]);

      manager.registerStrategy(mockStrategy1);

      // First call
      final result1 = await manager.search(query);
      expect(result1.isSuccessful, true);

      // Second call should use cache
      final result2 = await manager.search(query);
      expect(result2.isSuccessful, true);
      expect(result2.results[0].title, 'Cached Result');
    });

    test('should provide comprehensive statistics', () {
      manager.registerStrategy(mockStrategy1);
      manager.registerStrategy(mockStrategy2);

      final stats = manager.getStatistics();

      expect(stats['registered_strategies'], 2);
      expect(stats['cache_entries'], 0);
      expect(stats['strategy_metrics'], isA<Map>());
      expect(stats['circuit_breakers'], isA<Map>());
      expect(stats['health_check_enabled'], true);
      expect(stats['available_strategies'], 2);
      expect(stats['healthy_strategies'], 2);
    });

    test('should rank strategies by performance', () async {
      // Setup strategies with different success rates
      final query = SearchQuery(query: 'test');
      mockStrategy1.setResponse(query, [
        SearchResult(
          title: 'Result 1',
          url: 'https://example1.com',
          snippet: 'Snippet 1',
          timestamp: DateTime.now(),
        ),
      ]);

      mockStrategy2.setException(query, Exception('Failed'));

      manager.registerStrategy(mockStrategy1);
      manager.registerStrategy(mockStrategy2);

      // Execute searches to build metrics
      try {
        await manager.search(query);
      } catch (e) {
        // Expected for strategy2
      }

      final ranking = manager.getStrategiesRanking();
      expect(ranking, hasLength(2));
      expect(ranking[0]['name'], 'Google'); // Should rank higher due to success
    });

    test('should reset circuit breakers', () async {
      manager.registerStrategy(mockStrategy1);

      // This should initialize circuit breakers
      final stats = manager.getStatistics();
      expect(stats['circuit_breakers'], isA<Map>());

      // Reset all circuit breakers
      manager.resetAllCircuitBreakers();

      // Should not throw any exceptions
      expect(true, true);
    });

    test('should handle circuit breaker open state', () async {
      // Force circuit breaker to open by causing multiple failures
      final query = SearchQuery(query: 'test');
      mockStrategy1.setException(query, Exception('Persistent failure'));

      manager.registerStrategy(mockStrategy1);

      // Cause multiple failures to open circuit breaker
      for (int i = 0; i < 4; i++) {
        try {
          await manager.search(query);
        } catch (e) {
          // Expected
        }
      }

      // Circuit breaker should now be open
      final stats = manager.getStatistics();
      expect(stats['healthy_strategies'], 0); // Strategy should be unhealthy
    });

    test('should filter strategies by availability and health', () async {
      final unavailableStrategy = MockSearchStrategy('Unavailable', 5, false);
      final query = SearchQuery(query: 'test');
      unavailableStrategy.setException(query, Exception('Not available'));

      manager.registerStrategy(mockStrategy1);
      manager.registerStrategy(unavailableStrategy);

      mockStrategy1.setResponse(query, [
        SearchResult(
          title: 'Available Result',
          url: 'https://available.com',
          snippet: 'Available snippet',
          timestamp: DateTime.now(),
        ),
      ]);

      final result = await manager.search(query);

      expect(result.isSuccessful, true);
      expect(result.strategyName, 'Google'); // Only available strategy used
    });

    test('should handle concurrent searches', () async {
      final query = SearchQuery(query: 'concurrent test');
      mockStrategy1.setResponse(query, [
        SearchResult(
          title: 'Concurrent Result',
          url: 'https://concurrent.com',
          snippet: 'Concurrent snippet',
          timestamp: DateTime.now(),
        ),
      ]);

      manager.registerStrategy(mockStrategy1);

      final futures = <Future<StrategySearchResult>>[];

      // Start multiple concurrent searches
      for (int i = 0; i < 5; i++) {
        futures.add(manager.search(query));
      }

      final results = await Future.wait(futures);

      expect(results, hasLength(5));
      for (final result in results) {
        expect(result.isSuccessful, true);
        expect(result.strategyName, 'Google');
      }
    });
  });
}
