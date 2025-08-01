/// DTO (Data Transfer Object) para respostas de modelos LLM.
/// 
/// Responsável pela serialização/deserialização de respostas provenientes
/// de APIs de LLM (como Ollama) e conversão para entidades de domínio.
/// Suporta tanto respostas bem-sucedidas quanto tratamento de erros.
library;

import '../../domain/entities/llm_response.dart';

/// DTO que representa uma resposta de modelo LLM conforme retornada pela API.
/// 
/// Esta classe gerencia a transformação entre o formato JSON da API
/// externa (Ollama) e as entidades de domínio da aplicação, incluindo
/// tratamento de erros e estados de conclusão.
class LlmResponseDto {
  /// Conteúdo da resposta gerada pelo modelo.
  final String response;
  
  /// Nome do modelo que gerou a resposta.
  final String model;
  
  /// Indica se a geração da resposta foi concluída.
  final bool done;
  
  /// Mensagem de erro, se houver.
  final String? error;

  /// Construtor do DTO com os dados brutos da API.
  /// 
  /// [response] - Texto da resposta gerada
  /// [model] - Nome do modelo utilizado
  /// [done] - Se a geração foi concluída
  /// [error] - Mensagem de erro opcional
  const LlmResponseDto({
    required this.response,
    required this.model,
    required this.done,
    this.error,
  });

  /// Factory constructor para criar DTO a partir de JSON.
  /// 
  /// Inclui valores padrão para campos opcionais e trata casos
  /// onde a API pode retornar valores nulos.
  /// 
  /// [json] - Mapa com os dados JSON da API
  /// 
  /// Returns: Instância do DTO com os dados parseados
  factory LlmResponseDto.fromJson(Map<String, dynamic> json) {
    return LlmResponseDto(
      response: json['response'] as String? ?? '',
      model: json['model'] as String? ?? '',
      done: json['done'] as bool? ?? true,
      error: json['error'] as String?,
    );
  }

  /// Converte o DTO para formato JSON.
  /// 
  /// Usado principalmente para debugging ou caching de respostas.
  /// 
  /// Returns: Mapa com os dados no formato JSON
  Map<String, dynamic> toJson() {
    return {
      'response': response,
      'model': model,
      'done': done,
      if (error != null) 'error': error,
    };
  }

  /// Converte o DTO para entidade de domínio.
  /// 
  /// Realiza as transformações necessárias incluindo:
  /// - Uso do erro como conteúdo se presente
  /// - Definição do timestamp atual
  /// - Marcação de estado de erro baseado na presença de mensagem de erro
  /// 
  /// Returns: [LlmResponse] com os dados convertidos para domínio
  LlmResponse toEntity() {
    return LlmResponse(
      content: error ?? response,
      model: model,
      timestamp: DateTime.now(),
      isError: error != null,
    );
  }
}
