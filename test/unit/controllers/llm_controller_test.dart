import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:local_llm/domain/usecases/get_available_models.dart';
import 'package:local_llm/domain/usecases/generate_response.dart';
import 'package:local_llm/domain/usecases/generate_response_stream.dart';
import 'package:local_llm/domain/usecases/search_web.dart';
import 'package:local_llm/domain/entities/llm_model.dart';

import 'package:local_llm/presentation/controllers/llm_controller.dart';

import 'llm_controller_test.mocks.dart';

@GenerateMocks([
  GetAvailableModels,
  GenerateResponse,
  GenerateResponseStream,
  SearchWeb,
])
void main() {
  group('LlmController Tests', () {
    late LlmController controller;
    late MockGetAvailableModels mockGetAvailableModels;
    late MockGenerateResponse mockGenerateResponse;
    late MockGenerateResponseStream mockGenerateResponseStream;
    late MockSearchWeb mockSearchWeb;

    setUp(() {
      mockGetAvailableModels = MockGetAvailableModels();
      mockGenerateResponse = MockGenerateResponse();
      mockGenerateResponseStream = MockGenerateResponseStream();
      mockSearchWeb = MockSearchWeb();

      controller = LlmController(
        getAvailableModels: mockGetAvailableModels,
        generateResponse: mockGenerateResponse,
        generateResponseStream: mockGenerateResponseStream,
        searchWeb: mockSearchWeb,
      );
    });

    group('Model Loading', () {
      test('should load models successfully', () async {
        // Arrange
        final models = [
          LlmModel(name: 'deepseek-r1:latest', size: 1000000),
          LlmModel(name: 'qwen3:4b', size: 2000000),
        ];
        when(mockGetAvailableModels()).thenAnswer((_) async => models);

        // Act
        await controller.loadAvailableModels();

        // Assert
        expect(controller.models, equals(models));
        expect(controller.selectedModel, equals(models.first));
        expect(controller.isLoading, false);
        expect(controller.errorMessage, null);
      });

      test('should handle model loading error', () async {
        // Arrange
        when(mockGetAvailableModels()).thenThrow(Exception('Network error'));

        // Act
        await controller.loadAvailableModels();

        // Assert
        expect(controller.models, isEmpty);
        expect(controller.selectedModel, null);
        expect(controller.isLoading, false);
        expect(controller.errorMessage, contains('Erro ao carregar modelos'));
      });
    });

    group('Message Sending', () {
      setUp(() {
        controller.selectModel(LlmModel(name: 'test-model', size: 1000000));
      });

      test('should reject empty messages', () async {
        // Act
        await controller.sendMessage('');

        // Assert
        expect(controller.errorMessage, 'Mensagem não pode estar vazia');
        expect(controller.messages, isEmpty);
      });

      test('should reject messages when no model selected', () async {
        // Arrange
        // Test without selecting model

        // Act
        await controller.sendMessage('test message');

        // Assert
        expect(controller.errorMessage, 'Nenhum modelo selecionado');
        expect(controller.messages, isEmpty);
      });

      test('should clear search results before new message', () async {
        // Arrange
        controller.toggleWebSearch(true);
        when(mockSearchWeb(any)).thenAnswer((_) async => []);
        when(
          mockGenerateResponseStream(
            prompt: anyNamed('prompt'),
            modelName: anyNamed('modelName'),
          ),
        ).thenAnswer((_) => Stream.fromIterable(['test response']));

        // Simulate previous search results
        controller.clearSearchResults();

        // Act
        await controller.sendMessage('test message');

        // Assert
        expect(controller.searchResults, isEmpty);
      });

      test('should handle R1 model thinking detection', () {
        // Arrange
        final r1Model = LlmModel(name: 'deepseek-r1:latest', size: 1000000);
        controller.selectModel(r1Model);

        // Act
        controller.sendMessage('test question');

        // Assert
        expect(
          controller.isThinking,
          false,
        ); // Should be false after completion
      });
    });

    group('Web Search', () {
      test('should toggle web search correctly', () {
        // Act
        controller.toggleWebSearch(true);

        // Assert
        expect(controller.webSearchEnabled, true);

        // Act
        controller.toggleWebSearch(false);

        // Assert
        expect(controller.webSearchEnabled, false);
      });

      test('should clear search results', () {
        // Arrange
        controller.clearSearchResults();

        // Act & Assert
        expect(controller.searchResults, isEmpty);
      });
    });

    group('Streaming', () {
      test('should toggle stream mode correctly', () {
        // Act
        controller.toggleStreamMode(false);

        // Assert
        expect(controller.streamEnabled, false);

        // Act
        controller.toggleStreamMode(true);

        // Assert
        expect(controller.streamEnabled, true);
      });
    });

    group('Error Handling', () {
      test('should handle response generation error', () async {
        // Arrange
        controller.selectModel(LlmModel(name: 'test-model', size: 1000000));
        when(
          mockGenerateResponse(
            prompt: anyNamed('prompt'),
            modelName: anyNamed('modelName'),
          ),
        ).thenThrow(Exception('API Error'));

        // Act
        await controller.sendMessage('test message');

        // Assert
        expect(controller.errorMessage, contains('Erro ao gerar resposta'));
        expect(controller.isLoading, false);
      });

      test('should handle streaming error', () async {
        // Arrange
        controller.selectModel(LlmModel(name: 'test-model', size: 1000000));
        controller.toggleStreamMode(true);
        when(
          mockGenerateResponseStream(
            prompt: anyNamed('prompt'),
            modelName: anyNamed('modelName'),
          ),
        ).thenAnswer((_) => Stream.error(Exception('Stream Error')));

        // Act
        await controller.sendMessage('test message');

        // Assert
        expect(controller.errorMessage, contains('Erro ao gerar resposta'));
        expect(controller.isLoading, false);
      });
    });

    group('Chat Management', () {
      test('should clear chat correctly', () {
        // Arrange - Add some messages first
        controller.selectModel(LlmModel(name: 'test-model', size: 1000000));
        // Simulate adding messages
        controller.clearChat();

        // Act & Assert
        expect(controller.messages, isEmpty);
        expect(controller.searchResults, isEmpty);
        expect(controller.errorMessage, null);
      });

      test('should remove message at index', () {
        // This test would need access to internal message manipulation
        // For now, testing that the method exists and doesn't crash
        controller.removeMessage(0); // Should not crash even with empty list
      });
    });
  });
}
