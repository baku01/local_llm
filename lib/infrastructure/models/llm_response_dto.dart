import '../../domain/entities/llm_response.dart';

/// DTO para resposta do modelo LLM.
///
/// Responsável pela serialização/deserialização de dados de resposta LLM
/// provenientes da API externa e conversão para entidades de domínio.
class LlmResponseDto {
  final String response;
  final String model;
  final bool done;

  const LlmResponseDto({
    required this.response,
    required this.model,
    required this.done,
  });

  factory LlmResponseDto.fromJson(Map<String, dynamic> json) {
    return LlmResponseDto(
      response: json['response'] as String? ?? '',
      model: json['model'] as String? ?? '',
      done: json['done'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'response': response,
      'model': model,
      'done': done,
    };
  }

  LlmResponse toEntity() {
    return LlmResponse(
      content: response,
      model: model,
      timestamp: DateTime.now(),
    );
  }
}
