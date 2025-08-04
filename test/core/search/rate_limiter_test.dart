import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm/core/search/rate_limiter.dart';

void main() {
  group('RateLimiter', () {
    late RateLimiter rateLimiter;

    setUp(() {
      rateLimiter = RateLimiter(
        'test',
        const RateLimiterConfig(
          maxRequests: 5,
          windowMs: 1000,
          initialTokens: 3,
          refillRate: 1.0,
        ),
      );
    });

    test('should allow requests when tokens are available', () async {
      expect(rateLimiter.name, 'test');

      // Should allow requests up to initial tokens
      expect(await rateLimiter.tryAcquire(), true);
      expect(await rateLimiter.tryAcquire(), true);
      expect(await rateLimiter.tryAcquire(), true);
    });

    test('should deny requests when no tokens available', () async {
      // Consume all tokens
      for (int i = 0; i < 3; i++) {
        expect(await rateLimiter.tryAcquire(), true);
      }

      // Should deny next request
      expect(await rateLimiter.tryAcquire(), false);
    });

    test('should respect sliding window limit', () async {
      final limiter = RateLimiter(
        'window-test',
        const RateLimiterConfig(
          maxRequests: 2,
          windowMs: 1000,
          initialTokens: 10, // High token count
          refillRate: 10.0, // High refill rate
        ),
      );

      // Even with many tokens, sliding window should limit
      expect(await limiter.tryAcquire(), true);
      expect(await limiter.tryAcquire(), true);
      expect(await limiter.tryAcquire(), false); // Window limit reached
    });

    test('should refill tokens over time', () async {
      final limiter = RateLimiter(
        'refill-test',
        const RateLimiterConfig(
          maxRequests: 10,
          windowMs: 5000,
          initialTokens: 1,
          refillRate: 2.0, // 2 tokens per second
        ),
      );

      // Consume initial token
      expect(await limiter.tryAcquire(), true);
      expect(await limiter.tryAcquire(), false);

      // Wait for refill (0.6 seconds should give at least 1 token)
      await Future.delayed(const Duration(milliseconds: 600));

      expect(await limiter.tryAcquire(), true);
    });

    test('should reset sliding window after time passes', () async {
      final limiter = RateLimiter(
        'window-reset-test',
        const RateLimiterConfig(
          maxRequests: 2,
          windowMs: 500,
          initialTokens: 10,
          refillRate: 10.0,
        ),
      );

      // Fill window
      expect(await limiter.tryAcquire(), true);
      expect(await limiter.tryAcquire(), true);
      expect(await limiter.tryAcquire(), false);

      // Wait for window to reset
      await Future.delayed(const Duration(milliseconds: 600));

      // Should allow requests again
      expect(await limiter.tryAcquire(), true);
      expect(await limiter.tryAcquire(), true);
    });

    test('should provide correct statistics', () {
      final stats = rateLimiter.getStatistics();

      expect(stats['name'], 'test');
      expect(stats['available_tokens'], isA<String>());
      expect(stats['requests_in_window'], isA<int>());
      expect(stats['max_requests_per_window'], 5);
      expect(stats['window_ms'], 1000);
      expect(stats['refill_rate'], 1.0);
    });

    test('should reset rate limiter', () async {
      // Consume tokens
      await rateLimiter.tryAcquire();
      await rateLimiter.tryAcquire();

      // Reset should restore initial state
      rateLimiter.reset();

      final stats = rateLimiter.getStatistics();
      expect(double.parse(stats['available_tokens']), 3.0);
      expect(stats['requests_in_window'], 0);
    });

    test('should handle concurrent requests properly', () async {
      final limiter = RateLimiter(
        'concurrent-test',
        const RateLimiterConfig(
          maxRequests: 10,
          windowMs: 2000,
          initialTokens: 5,
          refillRate: 1.0,
        ),
      );

      final futures = <Future<bool>>[];

      // Start 8 concurrent requests (more than tokens available)
      for (int i = 0; i < 8; i++) {
        futures.add(limiter.tryAcquire());
      }

      final results = await Future.wait(futures);
      final successCount = results.where((result) => result).length;
      final failureCount = results.where((result) => !result).length;

      // Should allow exactly 5 (initial tokens) and deny 3
      expect(successCount, 5);
      expect(failureCount, 3);
    });

    test('should block until token available with acquire', () async {
      final limiter = RateLimiter(
        'acquire-test',
        const RateLimiterConfig(
          maxRequests: 10,
          windowMs: 2000,
          initialTokens: 1,
          refillRate: 2.0, // Fast refill for testing
        ),
      );

      // Consume initial token
      await limiter.acquire();

      final stopwatch = Stopwatch()..start();

      // This should wait for a token to be available
      await limiter.acquire();

      stopwatch.stop();

      // Should have waited at least some time for refill
      expect(stopwatch.elapsedMilliseconds, greaterThan(100));
    });

    test('should handle edge cases gracefully', () async {
      // Zero initial tokens
      final zeroTokenLimiter = RateLimiter(
        'zero-test',
        const RateLimiterConfig(
          maxRequests: 1,
          windowMs: 1000,
          initialTokens: 0,
          refillRate: 1.0,
        ),
      );

      expect(await zeroTokenLimiter.tryAcquire(), false);

      // Very high refill rate
      final highRefillLimiter = RateLimiter(
        'high-refill',
        const RateLimiterConfig(
          maxRequests: 10,
          windowMs: 1000,
          initialTokens: 1,
          refillRate: 100.0,
        ),
      );

      await highRefillLimiter.tryAcquire(); // Consume initial
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
          await highRefillLimiter.tryAcquire(), true); // Should have refilled
    });
  });
}
