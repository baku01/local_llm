/// Rate limiter implementation for search strategies.
///
/// Implements token bucket and sliding window rate limiting algorithms
/// to prevent overwhelming search providers and avoid rate limiting.
library;

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import '../utils/logger.dart';

/// Configuração do rate limiter.
class RateLimiterConfig {
  /// Número máximo de requisições por janela de tempo.
  final int maxRequests;
  
  /// Janela de tempo em milissegundos.
  final int windowMs;
  
  /// Número de tokens inicial no bucket.
  final int initialTokens;
  
  /// Taxa de reposição de tokens por segundo.
  final double refillRate;

  const RateLimiterConfig({
    this.maxRequests = 100,
    this.windowMs = 60000, // 1 minuto
    this.initialTokens = 10,
    this.refillRate = 1.0, // 1 token por segundo
  });
}

/// Rate limiter usando algoritmo Token Bucket + Sliding Window.
class RateLimiter {
  final String _name;
  final RateLimiterConfig _config;
  final Queue<DateTime> _requestTimestamps = Queue<DateTime>();
  
  double _tokens;
  DateTime _lastRefill;

  RateLimiter(this._name, [RateLimiterConfig? config])
      : _config = config ?? const RateLimiterConfig(),
        _tokens = (config ?? const RateLimiterConfig()).initialTokens.toDouble(),
        _lastRefill = DateTime.now();

  /// Nome do rate limiter.
  String get name => _name;

  /// Tenta adquirir permissão para fazer uma requisição.
  Future<bool> tryAcquire() async {
    _refillTokens();
    _cleanOldRequests();

    // Verificar sliding window
    if (_requestTimestamps.length >= _config.maxRequests) {
      AppLogger.debug(
        'Rate limiter $_name: Request denied - sliding window limit reached',
        'RateLimiter',
      );
      return false;
    }

    // Verificar token bucket
    if (_tokens < 1) {
      AppLogger.debug(
        'Rate limiter $_name: Request denied - no tokens available',
        'RateLimiter',
      );
      return false;
    }

    // Consumir token e registrar requisição
    _tokens -= 1;
    _requestTimestamps.add(DateTime.now());

    AppLogger.debug(
      'Rate limiter $_name: Request approved (tokens: ${_tokens.toStringAsFixed(1)}, '
      'requests in window: ${_requestTimestamps.length})',
      'RateLimiter',
    );

    return true;
  }

  /// Aguarda até que uma requisição possa ser feita.
  Future<void> acquire() async {
    while (!await tryAcquire()) {
      // Calcular tempo de espera baseado na próxima reposição de token
      final timeToNextToken = (1000 / _config.refillRate).round();
      final timeToWindowReset = _getTimeToWindowReset();
      final waitTime = math.min(timeToNextToken, timeToWindowReset);
      
      AppLogger.debug(
        'Rate limiter $_name: Waiting ${waitTime}ms for next request',
        'RateLimiter',
      );
      
      await Future.delayed(Duration(milliseconds: waitTime));
    }
  }

  /// Reabastece tokens baseado no tempo decorrido.
  void _refillTokens() {
    final now = DateTime.now();
    final timeDelta = now.difference(_lastRefill).inMilliseconds / 1000.0;
    final tokensToAdd = timeDelta * _config.refillRate;
    
    _tokens = math.min(_config.initialTokens.toDouble(), _tokens + tokensToAdd);
    _lastRefill = now;
  }

  /// Remove requisições antigas da janela deslizante.
  void _cleanOldRequests() {
    final cutoff = DateTime.now().subtract(Duration(milliseconds: _config.windowMs));
    
    while (_requestTimestamps.isNotEmpty && 
           _requestTimestamps.first.isBefore(cutoff)) {
      _requestTimestamps.removeFirst();
    }
  }

  /// Calcula tempo até o reset da janela deslizante.
  int _getTimeToWindowReset() {
    if (_requestTimestamps.isEmpty) return 0;
    
    final oldestRequest = _requestTimestamps.first;
    final windowEnd = oldestRequest.add(Duration(milliseconds: _config.windowMs));
    final timeToReset = windowEnd.difference(DateTime.now()).inMilliseconds;
    
    return math.max(0, timeToReset);
  }

  /// Obtém estatísticas do rate limiter.
  Map<String, dynamic> getStatistics() {
    _refillTokens();
    _cleanOldRequests();
    
    return {
      'name': _name,
      'available_tokens': _tokens.toStringAsFixed(2),
      'requests_in_window': _requestTimestamps.length,
      'max_requests_per_window': _config.maxRequests,
      'window_ms': _config.windowMs,
      'refill_rate': _config.refillRate,
      'time_to_window_reset_ms': _getTimeToWindowReset(),
    };
  }

  /// Reset do rate limiter.
  void reset() {
    _tokens = _config.initialTokens.toDouble();
    _requestTimestamps.clear();
    _lastRefill = DateTime.now();
    
    AppLogger.info('Rate limiter $_name reset', 'RateLimiter');
  }
}