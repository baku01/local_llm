/// LLM service interface for domain layer following Clean Architecture.
///
/// This interface defines the contract for LLM operations that can be
/// implemented by different LLM providers (Ollama, OpenAI, etc.).
library;

import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';

/// Configuration for LLM generation parameters.
class LLMGenerationConfig {
  /// Maximum number of tokens to generate.
  final int maxTokens;

  /// Temperature for randomness (0.0 to 1.0).
  final double temperature;

  /// Top-p sampling parameter.
  final double topP;

  /// Whether to stream the response.
  final bool stream;

  /// Stop sequences to end generation.
  final List<String>? stopSequences;

  /// System prompt to set context.
  final String? systemPrompt;

  const LLMGenerationConfig({
    this.maxTokens = 1000,
    this.temperature = 0.7,
    this.topP = 0.9,
    this.stream = false,
    this.stopSequences,
    this.systemPrompt,
  });
}

/// Response from LLM text generation.
class LLMTextResponse {
  /// Generated text content.
  final String text;

  /// Model used for generation.
  final String model;

  /// Number of tokens generated.
  final int? tokensGenerated;

  /// Generation time in milliseconds.
  final int? generationTimeMs;

  /// Additional metadata from the provider.
  final Map<String, dynamic>? metadata;

  const LLMTextResponse({
    required this.text,
    required this.model,
    this.tokensGenerated,
    this.generationTimeMs,
    this.metadata,
  });
}

/// Abstract interface for LLM services.
///
/// This interface follows the Repository pattern and provides methods
/// for text generation, embeddings, and model management.
abstract class LLMService {
  /// Generates text based on a prompt.
  ///
  /// Returns Either\<Failure, LLMTextResponse\> where:
  /// - Left: LLMFailure or other error types
  /// - Right: Generated text response
  Future<Either<Failure, LLMTextResponse>> generateText(
    String prompt, {
    String? model,
    LLMGenerationConfig? config,
  });

  /// Generates streaming text response.
  ///
  /// Returns a stream of text chunks as they're generated.
  Stream<Either<Failure, String>> generateTextStream(
    String prompt, {
    String? model,
    LLMGenerationConfig? config,
  });

  /// Gets available models from the LLM provider.
  Future<Either<Failure, List<LLMModelInfo>>> getAvailableModels();

  /// Checks if the LLM service is available/healthy.
  Future<Either<Failure, bool>> isHealthy();

  /// Gets information about a specific model.
  Future<Either<Failure, LLMModelInfo>> getModelInfo(String modelName);

  /// Estimates token count for a given text.
  Future<Either<Failure, int>> estimateTokenCount(String text, {String? model});
}

/// Information about an available LLM model.
class LLMModelInfo {
  /// Model identifier/name.
  final String name;

  /// Human-readable model name.
  final String displayName;

  /// Model description.
  final String? description;

  /// Model size in parameters (if known).
  final String? size;

  /// Maximum context length in tokens.
  final int? contextLength;

  /// Whether the model supports streaming.
  final bool supportsStreaming;

  /// Whether the model is currently available.
  final bool isAvailable;

  /// Model capabilities (text, embeddings, etc.).
  final List<String> capabilities;

  /// Additional model metadata.
  final Map<String, dynamic>? metadata;

  const LLMModelInfo({
    required this.name,
    required this.displayName,
    this.description,
    this.size,
    this.contextLength,
    this.supportsStreaming = false,
    this.isAvailable = true,
    this.capabilities = const ['text'],
    this.metadata,
  });
}

/// Service for generating search queries using LLM.
abstract class LLMQueryService {
  /// Generates optimized search queries from user input.
  Future<Either<Failure, List<String>>> generateSearchQueries(
    String userQuery, {
    int maxQueries = 3,
    String? searchContext,
  });

  /// Refines a search query for better results.
  Future<Either<Failure, String>> refineSearchQuery(
    String originalQuery, {
    List<String>? previousResults,
    String? refinementContext,  
  });
}

/// Service for processing search results using LLM.
abstract class LLMResultService {
  /// Synthesizes search results into a coherent response.
  Future<Either<Failure, String>> synthesizeResults(
    String originalQuery,
    List<SearchResultData> results, {
    String? additionalContext,
  });

  /// Extracts key information from search results.
  Future<Either<Failure, List<String>>> extractKeyInformation(
    List<SearchResultData> results, {
    String? focusArea,
  });

  /// Summarizes a single search result.
  Future<Either<Failure, String>> summarizeResult(
    SearchResultData result, {
    int maxLength = 200,
  });
}

/// Simplified search result data for LLM processing.
class SearchResultData {
  /// Result title.
  final String title;

  /// Result URL.
  final String url;

  /// Result snippet/description.
  final String snippet;

  /// Full content (if available).
  final String? content;

  /// Source domain.
  final String? source;

  const SearchResultData({
    required this.title,
    required this.url,
    required this.snippet,
    this.content,
    this.source,
  });
}