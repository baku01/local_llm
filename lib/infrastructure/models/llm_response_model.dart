import '../../domain/entities/llm_response.dart';

/// Data Transfer Object for the response from the Ollama API's generate endpoint.
///
/// This model maps directly to the JSON structure returned by the Ollama API
/// for both single and streaming responses. It includes a method to convert
/// this data model into a domain-layer [LlmResponse] entity.
class LlmResponseModel {
  /// The name of the model that generated the response.
  final String model;

  /// The timestamp when the response was created, in ISO 8601 format.
  final String createdAt;

  /// The text content of the response chunk.
  final String response;

  /// A boolean indicating if this is the final response chunk.
  final bool done;

  /// Creates an instance of [LlmResponseModel].
  const LlmResponseModel({
    required this.model,
    required this.createdAt,
    required this.response,
    required this.done,
  });

  /// Creates an [LlmResponseModel] instance from a JSON map.
  ///
  /// This factory is used to deserialize the JSON object received from the
  /// Ollama API.
  ///
  /// [json] - The JSON map, e.g., `{'model': 'llama2', 'created_at': '...', ...}`.
  factory LlmResponseModel.fromJson(Map<String, dynamic> json) {
    return LlmResponseModel(
      model: json['model'] as String,
      createdAt: json['created_at'] as String,
      response: json['response'] as String,
      done: json['done'] as bool,
    );
  }

  /// Converts this data model into a [LlmResponse] domain entity.
  ///
  /// This method performs the transformation from the data layer representation
  /// to the domain layer entity, ensuring the core business logic is decoupled
  /// from the specific data source implementation. It parses the [createdAt]
  /// string into a [DateTime] object.
  LlmResponse toEntity() {
    return LlmResponse(
      content: response,
      model: model,
      timestamp: DateTime.parse(createdAt),
    );
  }
}
