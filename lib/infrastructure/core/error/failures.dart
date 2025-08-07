/// Core failure classes for error handling using functional programming approach.
///
/// This module provides a hierarchical system of failure types that integrate
/// with dartz's Either monad for robust error handling throughout the application.
library;

import 'package:equatable/equatable.dart';

/// Base class for all failures in the application.
///
/// All failures extend this base class to provide consistent error handling
/// and debugging information.
abstract class Failure extends Equatable {
  /// Human-readable error message.
  final String message;

  /// Error code for programmatic handling.
  final String? code;

  /// Additional context or metadata about the failure.
  final Map<String, dynamic>? metadata;

  const Failure({
    required this.message,
    this.code,
    this.metadata,
  });

  @override
  List<Object?> get props => [message, code, metadata];
}

/// Failure related to network connectivity issues.
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.code = 'NETWORK_FAILURE',
    super.metadata,
  });
}

/// Failure when server returns an error response.
class ServerFailure extends Failure {
  /// HTTP status code if applicable.
  final int? statusCode;

  const ServerFailure({
    required super.message,
    this.statusCode,
    super.code = 'SERVER_FAILURE',
    super.metadata,
  });

  @override
  List<Object?> get props => [...super.props, statusCode];
}

/// Failure during data parsing or serialization.
class ParsingFailure extends Failure {
  /// The data that failed to parse.
  final dynamic failedData;

  const ParsingFailure({
    required super.message,
    this.failedData,
    super.code = 'PARSING_FAILURE',
    super.metadata,
  });

  @override
  List<Object?> get props => [...super.props, failedData];
}

/// Failure due to invalid input or parameters.
class ValidationFailure extends Failure {
  /// Field or parameter that failed validation.
  final String? field;

  const ValidationFailure({
    required super.message,
    this.field,
    super.code = 'VALIDATION_FAILURE',
    super.metadata,
  });

  @override
  List<Object?> get props => [...super.props, field];
}

/// Failure when a resource is not found.
class NotFoundFailure extends Failure {
  /// The resource that was not found.
  final String? resourceType;

  const NotFoundFailure({
    required super.message,
    this.resourceType,
    super.code = 'NOT_FOUND_FAILURE',
    super.metadata,
  });

  @override
  List<Object?> get props => [...super.props, resourceType];
}

/// Failure due to timeout operations.
class TimeoutFailure extends Failure {
  /// Timeout duration in milliseconds.
  final int? timeoutMs;

  const TimeoutFailure({
    required super.message,
    this.timeoutMs,
    super.code = 'TIMEOUT_FAILURE',
    super.metadata,
  });

  @override
  List<Object?> get props => [...super.props, timeoutMs];
}

/// Failure when authentication is required or invalid.
class AuthenticationFailure extends Failure {
  const AuthenticationFailure({
    required super.message,
    super.code = 'AUTHENTICATION_FAILURE',
    super.metadata,
  });
}

/// Failure when user lacks permission for an operation.
class AuthorizationFailure extends Failure {
  /// Required permission or role.
  final String? requiredPermission;

  const AuthorizationFailure({
    required super.message,
    this.requiredPermission,
    super.code = 'AUTHORIZATION_FAILURE',
    super.metadata,
  });

  @override
  List<Object?> get props => [...super.props, requiredPermission];
}

/// Failure when rate limits are exceeded.
class RateLimitFailure extends Failure {
  /// When the rate limit resets (if known).
  final DateTime? resetTime;

  /// Remaining requests (if known).
  final int? remainingRequests;

  const RateLimitFailure({
    required super.message,
    this.resetTime,
    this.remainingRequests,
    super.code = 'RATE_LIMIT_FAILURE',
    super.metadata,
  });

  @override
  List<Object?> get props => [...super.props, resetTime, remainingRequests];
}

/// Failure for unexpected errors that don't fit other categories.
class UnexpectedFailure extends Failure {
  /// Original exception if available.
  final Object? originalException;

  /// Stack trace if available.
  final StackTrace? stackTrace;

  const UnexpectedFailure({
    required super.message,
    this.originalException,
    this.stackTrace,
    super.code = 'UNEXPECTED_FAILURE',
    super.metadata,
  });

  @override
  List<Object?> get props => [...super.props, originalException];
}

/// Failure related to web search operations.
class SearchFailure extends Failure {
  /// The search query that failed.
  final String? query;

  /// Search provider that failed.
  final String? provider;

  const SearchFailure({
    required super.message,
    this.query,
    this.provider,
    super.code = 'SEARCH_FAILURE',
    super.metadata,
  });

  @override
  List<Object?> get props => [...super.props, query, provider];
}

/// Failure related to LLM operations.
class LLMFailure extends Failure {
  /// LLM model that failed.
  final String? model;

  /// Prompt that caused the failure (truncated for privacy).
  final String? promptPreview;

  const LLMFailure({
    required super.message,
    this.model,
    this.promptPreview,
    super.code = 'LLM_FAILURE',
    super.metadata,
  });

  @override
  List<Object?> get props => [...super.props, model, promptPreview];
}

/// Failure when cache operations fail.
class CacheFailure extends Failure {
  /// Cache key that failed.
  final String? cacheKey;

  const CacheFailure({
    required super.message,
    this.cacheKey,
    super.code = 'CACHE_FAILURE',
    super.metadata,
  });

  @override
  List<Object?> get props => [...super.props, cacheKey];
}
