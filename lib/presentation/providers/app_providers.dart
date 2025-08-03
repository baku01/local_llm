/// Providers centralizados da aplicação seguindo Clean Architecture.
/// 
/// Este arquivo contém todos os providers necessários para injeção de dependência,
/// organizados por camadas: Data Sources, Repositories, Use Cases e Controllers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

// Domain
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/llm_model.dart';
import '../../domain/repositories/llm_repository.dart';
import '../../domain/repositories/search_repository.dart';
import '../../domain/usecases/get_available_models.dart';
import '../../domain/usecases/generate_response.dart';
import '../../domain/usecases/generate_response_stream.dart';
import '../../domain/usecases/search_web.dart';

// Data
import '../../data/datasources/ollama_remote_datasource.dart';
import '../../data/datasources/intelligent_web_search_datasource.dart';
import '../../data/repositories/llm_repository_impl.dart';
import '../../data/repositories/search_repository_impl.dart';

// Presentation
import '../controllers/llm_controller.dart';

// =============================================================================
// CONFIGURATION PROVIDERS
// =============================================================================

/// Provider para a URL base da API do Ollama.
final apiUrlProvider = StateProvider<String>((ref) => 'http://localhost:11434');

// =============================================================================
// INFRASTRUCTURE PROVIDERS
// =============================================================================

/// Provider para o cliente HTTP Dio.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  dio.options.connectTimeout = const Duration(seconds: 30);
  dio.options.receiveTimeout = const Duration(minutes: 5);
  return dio;
});

/// Provider para o cliente HTTP padrão.
final httpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

// =============================================================================
// DATA SOURCE PROVIDERS
// =============================================================================

/// Provider para o data source do Ollama.
final ollamaDataSourceProvider = Provider<OllamaRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  final apiUrl = ref.watch(apiUrlProvider);
  return OllamaRemoteDataSourceImpl(
    dio: dio,
    baseUrl: apiUrl,
  );
});

/// Provider para o data source de busca web inteligente.
final webSearchDataSourceProvider = Provider<IntelligentWebSearchDataSource>((ref) {
  final client = ref.watch(httpClientProvider);
  return IntelligentWebSearchDataSource(
    client: client,
    config: const IntelligentSearchConfig(
      maxResultsPerProvider: 5,
      minRelevanceThreshold: 0.4,
      fetchFullContent: true,
      requestTimeoutSeconds: 15,
      enableCaching: true,
      cacheLifetimeMinutes: 30,
    ),
  );
});

// =============================================================================
// REPOSITORY PROVIDERS
// =============================================================================

/// Provider para o repositório de LLM.
final llmRepositoryProvider = Provider<LlmRepository>((ref) {
  final dataSource = ref.watch(ollamaDataSourceProvider);
  return LlmRepositoryImpl(remoteDataSource: dataSource);
});

/// Provider para o repositório de busca.
final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final dataSource = ref.watch(webSearchDataSourceProvider);
  return SearchRepositoryImpl(dataSource: dataSource);
});

// =============================================================================
// USE CASE PROVIDERS
// =============================================================================

/// Provider para o caso de uso de obter modelos disponíveis.
final getAvailableModelsProvider = Provider<GetAvailableModels>((ref) {
  final repository = ref.watch(llmRepositoryProvider);
  return GetAvailableModels(repository);
});

/// Provider para o caso de uso de gerar resposta.
final generateResponseProvider = Provider<GenerateResponse>((ref) {
  final repository = ref.watch(llmRepositoryProvider);
  return GenerateResponse(repository);
});

/// Provider para o caso de uso de gerar resposta em stream.
final generateResponseStreamProvider = Provider<GenerateResponseStream>((ref) {
  final repository = ref.watch(llmRepositoryProvider);
  return GenerateResponseStream(repository);
});

/// Provider para o caso de uso de busca web.
final searchWebProvider = Provider<SearchWeb>((ref) {
  final repository = ref.watch(searchRepositoryProvider);
  return SearchWeb(repository);
});

// =============================================================================
// PRESENTATION PROVIDERS
// =============================================================================

/// Provider para o modo de tema da aplicação.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// Provider para o modelo LLM selecionado.
final selectedModelProvider = StateProvider<LlmModel?>((ref) => null);

/// Provider para as mensagens do chat.
final chatMessagesProvider = StateNotifierProvider<ChatMessagesNotifier, List<ChatMessage>>((ref) {
  return ChatMessagesNotifier();
});

/// Provider para o controlador LLM.
final llmControllerProvider = ChangeNotifierProvider<LlmController>((ref) {
  final getModels = ref.watch(getAvailableModelsProvider);
  final generateResponse = ref.watch(generateResponseProvider);
  final generateStream = ref.watch(generateResponseStreamProvider);
  final searchWeb = ref.watch(searchWebProvider);
  
  return LlmController(
    getAvailableModels: getModels,
    generateResponse: generateResponse,
    generateResponseStream: generateStream,
    searchWeb: searchWeb,
  );
});

/// Provider para os modelos disponíveis.
final availableModelsProvider = StateNotifierProvider<AvailableModelsNotifier, AsyncValue<List<LlmModel>>>((ref) {
  final getModels = ref.watch(getAvailableModelsProvider);
  return AvailableModelsNotifier(getModels);
});

/// Provider para o estado de busca web habilitada.
final webSearchEnabledProvider = StateProvider<bool>((ref) => false);

/// Provider para o estado de modo stream habilitado.
final streamModeEnabledProvider = StateProvider<bool>((ref) => true);

/// Provider para verificar se o campo de texto está vazio.
final isTextFieldEmptyProvider = StateProvider<bool>((ref) => true);

/// Provider para verificar se está respondendo.
final isReplyingProvider = StateProvider<bool>((ref) => false);

/// Provider para o texto de sugestão.
final suggestionTextProvider = StateProvider<String>((ref) => '');

// =============================================================================
// STATE NOTIFIERS
// =============================================================================

/// Notifier para gerenciar o estado das mensagens do chat.
class ChatMessagesNotifier extends StateNotifier<List<ChatMessage>> {
  ChatMessagesNotifier() : super([]);

  /// Adiciona uma nova mensagem ao chat.
  void addMessage(ChatMessage message) {
    state = [...state, message];
  }

  /// Limpa todas as mensagens do chat.
  void clearMessages() {
    state = [];
  }

  /// Atualiza o texto da última mensagem.
  void updateLastMessage(String text) {
    if (state.isNotEmpty) {
      final lastMessage = state.last;
      final updatedMessage = lastMessage.copyWith(text: text);
      state = [...state.take(state.length - 1), updatedMessage];
    }
  }

  /// Atualiza o texto de pensamento da última mensagem.
  void updateLastMessageThinking(String? thinkingText) {
    if (state.isNotEmpty) {
      final lastMessage = state.last;
      final updatedMessage = lastMessage.copyWith(thinkingText: thinkingText);
      state = [...state.take(state.length - 1), updatedMessage];
    }
  }
}

/// Notifier para gerenciar o estado dos modelos disponíveis.
class AvailableModelsNotifier extends StateNotifier<AsyncValue<List<LlmModel>>> {
  final GetAvailableModels _getAvailableModels;

  AvailableModelsNotifier(this._getAvailableModels) : super(const AsyncValue.loading()) {
    loadModels();
  }

  /// Carrega os modelos disponíveis.
  Future<void> loadModels() async {
    state = const AsyncValue.loading();
    try {
      final models = await _getAvailableModels();
      state = AsyncValue.data(models);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Recarrega os modelos disponíveis.
  Future<void> refresh() async {
    await loadModels();
  }
}