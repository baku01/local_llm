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

  /// Construtor do DTO com os dados brutos da API.
  const LlmModelDto({
    required this.name,
    this.description,
    this.modifiedAt,
    this.size,
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
}
