import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/core/search/circuit_breaker.dart';

void main() {
  group('CircuitBreaker', () {
    late CircuitBreaker circuitBreaker;

    setUp(() {
      circuitBreaker = CircuitBreaker(
        'test',
        const CircuitBreakerConfig(
          failureThreshold: 3,
          timeoutMs: 1000,
          successThreshold: 2,
        ),
      );
    });

    test('should start in closed state', () {
      expect(circuitBreaker.state, CircuitBreakerState.closed);
      expect(circuitBreaker.failureCount, 0);
    });

    test('should execute operation when closed', () async {
      var executed = false;
      await circuitBreaker.execute(() async {
        executed = true;
        return 'success';
      });

      expect(executed, true);
      expect(circuitBreaker.state, CircuitBreakerState.closed);
    });

    test('should open circuit after failure threshold', () async {
      // Simulate failures
      for (int i = 0; i < 3; i++) {
        try {
          await circuitBreaker.execute(() async {
            throw Exception('Test failure');
          });
        } catch (e) {
          // Expected
        }
      }

      expect(circuitBreaker.state, CircuitBreakerState.open);
      expect(circuitBreaker.failureCount, 3);
    });

    test('should reject operations when open', () async {
      // Force circuit to open
      for (int i = 0; i < 3; i++) {
        try {
          await circuitBreaker.execute(() async {
            throw Exception('Test failure');
          });
        } catch (e) {
          // Expected
        }
      }

      // Now circuit should be open and reject operations
      expect(
        () async => await circuitBreaker.execute(() async => 'test'),
        throwsA(isA<CircuitBreakerOpenException>()),
      );
    });

    test('should transition to half-open after timeout', () async {
      // Force circuit to open
      for (int i = 0; i < 3; i++) {
        try {
          await circuitBreaker.execute(() async {
            throw Exception('Test failure');
          });
        } catch (e) {
          // Expected
        }
      }

      expect(circuitBreaker.state, CircuitBreakerState.open);

      // Wait for timeout (simulate with manual time manipulation)
      await Future.delayed(const Duration(milliseconds: 1100));

      // Next execution should transition to half-open
      var executed = false;
      await circuitBreaker.execute(() async {
        executed = true;
        return 'success';
      });

      expect(executed, true);
      expect(circuitBreaker.state, CircuitBreakerState.halfOpen);
    });

    test('should close circuit after successful operations in half-open', () async {
      final testCircuitBreaker = CircuitBreaker(
        'test-half-open',
        const CircuitBreakerConfig(
          failureThreshold: 1,
          timeoutMs: 100,
          successThreshold: 2,
        ),
      );

      // Force to open
      try {
        await testCircuitBreaker.execute(() async {
          throw Exception('Failure');
        });
      } catch (e) {
        // Expected
      }

      expect(testCircuitBreaker.state, CircuitBreakerState.open);

      // Wait for timeout
      await Future.delayed(const Duration(milliseconds: 150));

      // Execute successful operations to close circuit
      await testCircuitBreaker.execute(() async => 'success1');
      expect(testCircuitBreaker.state, CircuitBreakerState.halfOpen);

      await testCircuitBreaker.execute(() async => 'success2');
      expect(testCircuitBreaker.state, CircuitBreakerState.closed);
    });

    test('should provide correct statistics', () {
      final stats = circuitBreaker.getStatistics();

      expect(stats['name'], 'test');
      expect(stats['state'], 'closed');
      expect(stats['failure_count'], 0);
      expect(stats['success_count'], 0);
      expect(stats['config'], isA<Map<String, dynamic>>());
    });

    test('should reset circuit breaker', () async {
      // Force failures to open circuit
      for (int i = 0; i < 3; i++) {
        try {
          await circuitBreaker.execute(() async {
            throw Exception('Test failure');
          });
        } catch (e) {
          // Expected
        }
      }

      expect(circuitBreaker.state, CircuitBreakerState.open);
      expect(circuitBreaker.failureCount, 3);

      // Reset should close circuit and clear counters
      circuitBreaker.reset();

      expect(circuitBreaker.state, CircuitBreakerState.closed);
      expect(circuitBreaker.failureCount, 0);
    });

    test('should handle concurrent operations', () async {
      final futures = <Future>[];

      // Execute multiple operations concurrently
      for (int i = 0; i < 10; i++) {
        futures.add(
          circuitBreaker.execute(() async {
            await Future.delayed(const Duration(milliseconds: 10));
            return 'success$i';
          }),
        );
      }

      final results = await Future.wait(futures);
      expect(results, hasLength(10));
      expect(circuitBreaker.state, CircuitBreakerState.closed);
    });
  });
}