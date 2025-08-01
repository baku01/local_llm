import '../../domain/entities/llm_response.dart';

class LlmResponseDto {
  final String response;
  final String model;
  final bool done;
  final String? error;

  const LlmResponseDto({
    required this.response,
    required this.model,
    required this.done,
    this.error,
  });

  factory LlmResponseDto.fromJson(Map<String, dynamic> json) {
    return LlmResponseDto(
      response: json['response'] as String? ?? '',
      model: json['model'] as String? ?? '',
      done: json['done'] as bool? ?? true,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'response': response,
      'model': model,
      'done': done,
      if (error != null) 'error': error,
    };
  }

  LlmResponse toEntity() {
    return LlmResponse(
      content: error ?? response,
      model: model,
      timestamp: DateTime.now(),
      isError: error != null,
    );
  }
}
