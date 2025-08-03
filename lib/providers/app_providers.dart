import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../models/llm_model.dart';
import '../data/datasources/ollama_remote_datasource.dart';
import '../data/datasources/fixed_web_search_datasource.dart';
import '../data/repositories/llm_repository_impl.dart';
import '../data/repositories/search_repository_impl.dart';
import '../domain/usecases/get_available_models.dart';
import '../domain/usecases/generate_response.dart';
import '../domain/usecases/generate_response_stream.dart';
import '../domain/usecases/search_web.dart';
import '../presentation/controllers/llm_controller.dart';

// Theme Mode Provider
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

// Chat Messages Provider
final chatMessagesProvider = StateNotifierProvider<ChatMessagesNotifier, List<ChatMessage>>((ref) {
  return ChatMessagesNotifier();
});

class ChatMessagesNotifier extends StateNotifier<List<ChatMessage>> {
  ChatMessagesNotifier() : super([]);

  void addMessage(ChatMessage message) {
    state = [...state, message];
  }

  void clearMessages() {
    state = [];
  }

  void updateLastMessage(String text) {
    if (state.isNotEmpty) {
      final lastMessage = state.last;
      final updatedMessage = lastMessage.copyWith(text: text);
      state = [...state.take(state.length - 1), updatedMessage];
    }
  }
}

// Selected Model Provider
final selectedModelProvider = StateProvider<LLMModel?>((ref) => null);

// Datasource Providers
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  dio.options.connectTimeout = const Duration(seconds: 30);
  dio.options.receiveTimeout = const Duration(minutes: 5);
  return dio;
});

final httpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

final ollamaDataSourceProvider = Provider<OllamaRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  final apiUrl = ref.watch(apiUrlProvider);
  return OllamaRemoteDataSourceImpl(
    dio: dio,
    baseUrl: apiUrl,
  );
});

final webScraperProvider = Provider<FixedWebSearchDataSource>((ref) {
  final client = ref.watch(httpClientProvider);
  return FixedWebSearchDataSource(client: client);
});

// Repository Providers
final llmRepositoryProvider = Provider<LlmRepositoryImpl>((ref) {
  final dataSource = ref.watch(ollamaDataSourceProvider);
  return LlmRepositoryImpl(remoteDataSource: dataSource);
});

final searchRepositoryProvider = Provider<SearchRepositoryImpl>((ref) {
  final webScraper = ref.watch(webScraperProvider);
  return SearchRepositoryImpl(dataSource: webScraper);
});

// Use Case Providers
final getAvailableModelsProvider = Provider<GetAvailableModels>((ref) {
  final repository = ref.watch(llmRepositoryProvider);
  return GetAvailableModels(repository);
});

final generateResponseProvider = Provider<GenerateResponse>((ref) {
  final repository = ref.watch(llmRepositoryProvider);
  return GenerateResponse(repository);
});

final generateResponseStreamProvider = Provider<GenerateResponseStream>((ref) {
  final repository = ref.watch(llmRepositoryProvider);
  return GenerateResponseStream(repository);
});

final searchWebProvider = Provider<SearchWeb>((ref) {
  final repository = ref.watch(searchRepositoryProvider);
  return SearchWeb(repository);
});

// LLM Controller Provider
final llmControllerProvider = ChangeNotifierProvider<LlmController>((ref) {
  final getAvailableModels = ref.watch(getAvailableModelsProvider);
  final generateResponse = ref.watch(generateResponseProvider);
  final generateResponseStream = ref.watch(generateResponseStreamProvider);
  final searchWeb = ref.watch(searchWebProvider);
  
  return LlmController(
    getAvailableModels: getAvailableModels,
    generateResponse: generateResponse,
    generateResponseStream: generateResponseStream,
    searchWeb: searchWeb,
  );
});

// Available Models Provider (updated to use real implementation)
final availableModelsProvider = StateNotifierProvider<AvailableModelsNotifier, AsyncValue<List<LLMModel>>>((ref) {
  final getAvailableModels = ref.watch(getAvailableModelsProvider);
  return AvailableModelsNotifier(getAvailableModels);
});

class AvailableModelsNotifier extends StateNotifier<AsyncValue<List<LLMModel>>> {
  final GetAvailableModels _getAvailableModels;
  
  AvailableModelsNotifier(this._getAvailableModels) : super(const AsyncValue.loading()) {
    loadModels();
  }

  Future<void> loadModels() async {
    state = const AsyncValue.loading();
    try {
      final domainModels = await _getAvailableModels();
      
      // Convert domain models to presentation models
      final models = domainModels.map((domainModel) => LLMModel(
        name: domainModel.name,
        displayName: domainModel.description ?? domainModel.name,
        size: domainModel.size != null ? '${(domainModel.size! / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB' : 'Desconhecido',
        modifiedAt: domainModel.modifiedAt,
      )).toList();
      
      state = AsyncValue.data(models);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void refresh() {
    loadModels();
  }
}

// Is Replying Provider
final isReplyingProvider = StateProvider<bool>((ref) => false);

// API URL Provider
final apiUrlProvider = StateProvider<String>((ref) => 'http://localhost:11434');

// Text Input Controller Provider
final textInputControllerProvider = Provider<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

// Is Text Field Empty Provider
final isTextFieldEmptyProvider = StateProvider<bool>((ref) => true);

// Web Search Enabled Provider
final webSearchEnabledProvider = StateProvider<bool>((ref) => true);

// Stream Mode Enabled Provider
final streamModeEnabledProvider = StateProvider<bool>((ref) => true);

// Suggestion Text Provider
final suggestionTextProvider = StateProvider<String?>((ref) => null);