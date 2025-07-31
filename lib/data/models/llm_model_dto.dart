import '../../domain/entities/llm_model.dart';

class LlmModelDto {
  final String name;
  final String? description;
  final String? modifiedAt;
  final int? size;

  const LlmModelDto({
    required this.name,
    this.description,
    this.modifiedAt,
    this.size,
  });

  factory LlmModelDto.fromJson(Map<String, dynamic> json) {
    return LlmModelDto(
      name: json['name'] as String,
      description: json['description'] as String?,
      modifiedAt: json['modified_at'] as String?,
      size: json['size'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (size != null) 'size': size,
    };
  }

  LlmModel toEntity() {
    return LlmModel(
      name: name,
      description: description,
      modifiedAt: modifiedAt != null ? DateTime.tryParse(modifiedAt!) : null,
      size: size,
    );
  }
}