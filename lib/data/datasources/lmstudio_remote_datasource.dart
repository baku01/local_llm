/// DataSource para comunicação com a API OpenAI‑compatível do LM Studio.
///
/// Esta implementação consome o endpoint `/v1/chat/completions` do LM Studio
/// que é compatível com a API da OpenAI. O objetivo é permitir que a
/// aplicação converse com modelos servidos pelo LM Studio da mesma forma que
/// faz com o Ollama.
library;

import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/llm_model_dto.dart';
import '../models/llm_response_dto.dart';
import 'llm_remote_datasource.dart';

/// Implementação de [LlmRemoteDataSource] que utiliza o LM Studio.
///
/// Traduz as chamadas para o formato esperado pela API do LM Studio,
/// permitindo que o restante da aplicação permaneça desacoplado do backend
/// utilizado.
class LmStudioRemoteDataSource implements LlmRemoteDataSource {
  /// Cliente HTTP usado para realizar as requisições.
  final Dio dio;

  /// URL base do servidor LM Studio.
  final String baseUrl;

  /// Cria uma instância do datasource para o LM Studio.
  const LmStudioRemoteDataSource({
    required this.dio,
    this.baseUrl = 'http://localhost:1234',
  });

  @override
  Future<List<LlmModelDto>> getAvailableModels() async {
    final response = await dio.get('$baseUrl/v1/models');
    if (response.statusCode != 200) {
      throw Exception('Falha ao carregar modelos do LM Studio');
    }

    final data = response.data as Map<String, dynamic>;
    final models = data['data'] as List<dynamic>;
    return models
        .map((model) =>
            LlmModelDto(name: model['id'] as String? ?? 'unknown'))
        .toList();
  }

  @override
  Future<LlmResponseDto> generateResponse({
    required String prompt,
    required String modelName,
    bool stream = false,
  }) async {
    final response = await dio.post(
      '$baseUrl/v1/chat/completions',
      options: Options(headers: {
        'Content-Type': 'application/json',
      }),
      data: {
        'model': modelName,
        'stream': stream,
        'messages': [
          {
            'role': 'user',
            'content': prompt,
          }
        ],
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Falha ao gerar resposta: ${response.statusCode}');
    }

    final content = (response.data['choices'] as List).first['message']
            ['content'] as String? ??
    final choices = response.data['choices'] as List;
    final content = choices.isNotEmpty
        ? (choices.first['message']['content'] as String? ?? '')
        : '';
    return LlmResponseDto(response: content, model: modelName, done: true);
  }

  @override
  Stream<String> generateResponseStream({
    required String prompt,
    required String modelName,
  }) async* {
    final response = await dio.post(
      '$baseUrl/v1/chat/completions',
      options: Options(
        headers: {'Content-Type': 'application/json'},
        responseType: ResponseType.stream,
      ),
      data: {
        'model': modelName,
        'stream': true,
        'messages': [
          {
            'role': 'user',
            'content': prompt,
          }
        ],
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Falha ao gerar resposta stream: ${response.statusCode}');
    }

    final stream = response.data as ResponseBody;
    await for (final chunk in stream.stream) {
      final lines = utf8.decode(chunk).split('\n');
      for (final line in lines) {
        if (line.isEmpty) continue;
        if (line.startsWith('data: ')) {
          final payload = line.substring(6).trim();
          if (payload == '[DONE]') {
            return;
          }
          try {
            final jsonData = json.decode(payload);
            final content = jsonData['choices'][0]['delta']['content'] as String?;
            if (content != null) {
            final choices = jsonData['choices'];
            if (choices is List && choices.isNotEmpty) {
              final content = choices[0]['delta']['content'] as String?;
              if (content != null) {
                yield content;
              }
            }
          } catch (_) {
            // Ignora erros de parsing de chunks individuais
            continue;
          }
        }
      }
    }
  }
}
