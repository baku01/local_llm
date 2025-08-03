/// DTO (Data Transfer Object) para modelo LLM.
/// 
/// Responsável pela serialização/deserialização de dados de modelos LLM
/// provenientes da API externa e conversão para entidades de domínio.
library;

import '../../domain/entities/llm_model.dart';

/// DTO que representa um modelo LLM conforme retornado pela API.
/// 
/// Esta classe gerencia a transformação entre o formato JSON da API
/// externa e as entidades de domínio da aplicação, isolando as
/// preocupações de serialização da lógica de negócio.
class LlmModelDto {
  /// Nome do modelo conforme fornecido pela API.
  final String name;
  
  /// Descrição opcional do modelo.
  final String? description;
  
  /// Data de modificação em formato string ISO.
  final String? modifiedAt;
  
  /// Tamanho do modelo em bytes.
  final int? size;
  
  /// Hash digest do modelo para verificação de integridade.
  final String? digest;
  
  /// Detalhes adicionais do modelo (formato, parâmetros, etc.).
  final Map<String, dynamic>? details;

  /// Construtor do DTO com os dados brutos da API.
  const LlmModelDto({
    required this.name,
    this.description,
    this.modifiedAt,
    this.size,
    this.digest,
    this.details,
  });

  /// Factory constructor para criar DTO a partir de JSON.
  /// 
  /// [json] - Mapa com os dados JSON da API
  /// 
  /// Returns: Instância do DTO com os dados parseados
  factory LlmModelDto.fromJson(Map<String, dynamic> json) {
    return LlmModelDto(
      name: json['name'] as String,
      description: json['description'] as String?,
      modifiedAt: json['modified_at'] as String?,
      size: json['size'] as int?,
      digest: json['digest'] as String?,
      details: json['details'] as Map<String, dynamic>?,
    );
  }

  /// Converte o DTO para formato JSON.
  /// 
  /// Returns: Mapa com os dados no formato esperado pela API
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (size != null) 'size': size,
      if (digest != null) 'digest': digest,
      if (details != null) 'details': details,
    };
  }

  /// Converte o DTO para entidade de domínio.
  /// 
  /// Realiza as transformações necessárias como parsing de datas
  /// e adequação aos tipos esperados pela camada de domínio.
  /// 
  /// Returns: [LlmModel] com os dados convertidos
  LlmModel toEntity() {
    return LlmModel(
      name: name,
      description: description,
      modifiedAt: modifiedAt != null ? DateTime.tryParse(modifiedAt!) : null,
      size: size,
    );
  }
  
  /// Cria uma cópia do DTO com propriedades opcionalmente modificadas.
  LlmModelDto copyWith({
    String? name,
    String? description,
    String? modifiedAt,
    int? size,
    String? digest,
    Map<String, dynamic>? details,
  }) {
    return LlmModelDto(
      name: name ?? this.name,
      description: description ?? this.description,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      size: size ?? this.size,
      digest: digest ?? this.digest,
      details: details ?? this.details,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LlmModelDto &&
        other.name == name &&
        other.description == description &&
        other.modifiedAt == modifiedAt &&
        other.size == size &&
        other.digest == digest &&
        _mapEquals(other.details, details);
  }
  
  @override
  int get hashCode {
    return Object.hash(
      name,
      description,
      modifiedAt,
      size,
      digest,
      details,
    );
  }
  
  bool _mapEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}
