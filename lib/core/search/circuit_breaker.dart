/// Circuit Breaker pattern implementation for search strategies.
///
/// Implements the Circuit Breaker pattern to prevent cascading failures
/// and provide fast failure detection for unreliable search strategies.
library;

import 'dart:async';
import '../utils/logger.dart';

/// Estados do Circuit Breaker.
enum CircuitBreakerState {
  /// Fechado - operações normais
  closed,
  /// Aberto - falhas detectadas, operações bloqueadas
  open,
  /// Meio-aberto - testando se o serviço se recuperou
  halfOpen,
}

/// Configuração do Circuit Breaker.
class CircuitBreakerConfig {
  /// Número de falhas consecutivas antes de abrir o circuito.
  final int failureThreshold;
  
  /// Tempo em milissegundos antes de tentar meio-aberto.
  final int timeoutMs;
  
  /// Número de tentativas de sucesso no estado meio-aberto antes de fechar.
  final int successThreshold;
  
  /// Janela de tempo para resetar contadores (em milissegundos).
  final int resetTimeoutMs;

  const CircuitBreakerConfig({
    this.failureThreshold = 5,
    this.timeoutMs = 30000, // 30 segundos
    this.successThreshold = 2,
    this.resetTimeoutMs = 60000, // 1 minuto
  });
}

/// Circuit Breaker para proteger estratégias de busca.
class CircuitBreaker {
  final String _name;
  final CircuitBreakerConfig _config;
  
  CircuitBreakerState _state = CircuitBreakerState.closed;
  int _failureCount = 0;
  int _successCount = 0;
  DateTime? _lastFailureTime;
  DateTime? _lastResetTime;

  CircuitBreaker(this._name, [CircuitBreakerConfig? config])
      : _config = config ?? const CircuitBreakerConfig();

  /// Estado atual do circuit breaker.
  CircuitBreakerState get state => _state;

  /// Nome do circuit breaker.
  String get name => _name;

  /// Número de falhas consecutivas.
  int get failureCount => _failureCount;

  /// Executa uma operação através do circuit breaker.
  Future<T> execute<T>(Future<T> Function() operation) async {
    if (!_canExecute()) {
      throw CircuitBreakerOpenException(_name);
    }

    try {
      final result = await operation();
      _onSuccess();
      return result;
    } catch (e) {
      _onFailure();
      rethrow;
    }
  }

  /// Verifica se a operação pode ser executada.
  bool _canExecute() {
    final now = DateTime.now();
    
    switch (_state) {
      case CircuitBreakerState.closed:
        return true;
        
      case CircuitBreakerState.open:
        if (_lastFailureTime != null) {
          final timeSinceFailure = now.difference(_lastFailureTime!).inMilliseconds;
          if (timeSinceFailure >= _config.timeoutMs) {
            _transitionToHalfOpen();
            return true;
          }
        }
        return false;
        
      case CircuitBreakerState.halfOpen:
        return true;
    }
  }

  /// Processa uma operação bem-sucedida.
  void _onSuccess() {
    switch (_state) {
      case CircuitBreakerState.closed:
        _resetCounters();
        break;
        
      case CircuitBreakerState.halfOpen:
        _successCount++;
        if (_successCount >= _config.successThreshold) {
          _transitionToClosed();
        }
        break;
        
      case CircuitBreakerState.open:
        // Nunca deveria chegar aqui
        break;
    }
    
    AppLogger.debug(
      'Circuit breaker $_name: Success (state: $_state, failures: $_failureCount)',
      'CircuitBreaker',
    );
  }

  /// Processa uma falha.
  void _onFailure() {
    _lastFailureTime = DateTime.now();
    _failureCount++;
    
    switch (_state) {
      case CircuitBreakerState.closed:
        if (_failureCount >= _config.failureThreshold) {
          _transitionToOpen();
        }
        break;
        
      case CircuitBreakerState.halfOpen:
        _transitionToOpen();
        break;
        
      case CircuitBreakerState.open:
        // Já está aberto
        break;
    }
    
    AppLogger.warning(
      'Circuit breaker $_name: Failure (state: $_state, failures: $_failureCount)',
      'CircuitBreaker',
    );
  }

  /// Transição para estado fechado.
  void _transitionToClosed() {
    _state = CircuitBreakerState.closed;
    _resetCounters();
    AppLogger.info('Circuit breaker $_name: Transitioned to CLOSED', 'CircuitBreaker');
  }

  /// Transição para estado aberto.
  void _transitionToOpen() {
    _state = CircuitBreakerState.open;
    _successCount = 0;
    AppLogger.warning('Circuit breaker $_name: Transitioned to OPEN', 'CircuitBreaker');
  }

  /// Transição para estado meio-aberto.
  void _transitionToHalfOpen() {
    _state = CircuitBreakerState.halfOpen;
    _successCount = 0;
    AppLogger.info('Circuit breaker $_name: Transitioned to HALF-OPEN', 'CircuitBreaker');
  }

  /// Reseta contadores.
  void _resetCounters() {
    _failureCount = 0;
    _successCount = 0;
    _lastResetTime = DateTime.now();
  }

  /// Força o reset do circuit breaker.
  void reset() {
    _transitionToClosed();
    AppLogger.info('Circuit breaker $_name: Manually reset', 'CircuitBreaker');
  }

  /// Obtém estatísticas do circuit breaker.
  Map<String, dynamic> getStatistics() {
    return {
      'name': _name,
      'state': _state.name,
      'failure_count': _failureCount,
      'success_count': _successCount,
      'last_failure_time': _lastFailureTime?.toIso8601String(),
      'last_reset_time': _lastResetTime?.toIso8601String(),
      'config': {
        'failure_threshold': _config.failureThreshold,
        'timeout_ms': _config.timeoutMs,
        'success_threshold': _config.successThreshold,
        'reset_timeout_ms': _config.resetTimeoutMs,
      },
    };
  }
}

/// Exceção lançada quando o circuit breaker está aberto.
class CircuitBreakerOpenException implements Exception {
  final String circuitBreakerName;
  
  const CircuitBreakerOpenException(this.circuitBreakerName);
  
  @override
  String toString() => 'Circuit breaker $circuitBreakerName is OPEN';
}