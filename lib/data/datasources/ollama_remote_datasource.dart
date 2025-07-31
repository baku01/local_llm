import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/llm_model_dto.dart';
import '../models/llm_response_dto.dart';

abstract class OllamaRemoteDataSource {
  Future<List<LlmModelDto>> getAvailableModels();
  Future<LlmResponseDto> generateResponse({
    required String prompt,
    required String modelName,
    bool stream = false,
  });
  
  Stream<String> generateResponseStream({
    required String prompt,
    required String modelName,
  });
}

class OllamaRemoteDataSourceImpl implements OllamaRemoteDataSource {
  final Dio dio;
  final String baseUrl;

  const OllamaRemoteDataSourceImpl({
    required this.dio,
    this.baseUrl = 'http://localhost:11434',
  });

  @override
  Future<List<LlmModelDto>> getAvailableModels() async {
    try {
      final response = await dio.get('$baseUrl/api/tags');
      
      if (response.statusCode != 200) {
        throw Exception('Falha ao carregar modelos: ${response.statusCode}');
      }

      final data = response.data as Map<String, dynamic>;
      final models = data['models'] as List<dynamic>;
      
      return models
          .map((model) => LlmModelDto.fromJson(model as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception('Erro de rede ao buscar modelos: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado ao buscar modelos: $e');
    }
  }

  @override
  Future<LlmResponseDto> generateResponse({
    required String prompt,
    required String modelName,
    bool stream = false,
  }) async {
    try {
      final response = await dio.post(
        '$baseUrl/api/generate',
        options: Options(
          headers: {'Content-Type': 'application/json'},
          receiveTimeout: const Duration(minutes: 5),
        ),
        data: {
          'model': modelName,
          'prompt': prompt,
          'stream': stream,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Falha ao gerar resposta: ${response.statusCode}');
      }

      return LlmResponseDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Erro de rede ao gerar resposta: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado ao gerar resposta: $e');
    }
  }

  @override
  Stream<String> generateResponseStream({
    required String prompt,
    required String modelName,
  }) async* {
    try {
      final response = await dio.post(
        '$baseUrl/api/generate',
        options: Options(
          headers: {'Content-Type': 'application/json'},
          receiveTimeout: const Duration(minutes: 5),
          responseType: ResponseType.stream,
        ),
        data: {
          'model': modelName,
          'prompt': prompt,
          'stream': true,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Falha ao gerar resposta stream: ${response.statusCode}');
      }

      final stream = response.data as ResponseBody;
      String buffer = '';
      
      await for (final chunk in stream.stream) {
        final chunkStr = utf8.decode(chunk);
        buffer += chunkStr;
        
        while (buffer.contains('\n')) {
          final lineEnd = buffer.indexOf('\n');
          final line = buffer.substring(0, lineEnd).trim();
          buffer = buffer.substring(lineEnd + 1);
          
          if (line.isNotEmpty) {
            try {
              final jsonData = json.decode(line);
              final content = jsonData['response'] as String?;
              if (content != null && content.isNotEmpty) {
                yield content;
              }
              
              // Verifica se é o último chunk
              final done = jsonData['done'] as bool? ?? false;
              if (done) {
                return;
              }
            } catch (e) {
              // Ignora chunks mal formados
              continue;
            }
          }
        }
      }
    } on DioException catch (e) {
      throw Exception('Erro de rede ao gerar resposta stream: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado ao gerar resposta stream: $e');
    }
  }
}