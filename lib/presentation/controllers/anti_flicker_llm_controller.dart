/// Controlador LLM otimizado para eliminar flickering durante streaming.
/// 
/// Implementa técnicas avançadas:
/// - Throttling de notificações com duração adaptativa
/// - Streams isolados para cada mensagem
/// - Debounce de atualizações de pensamento
/// - Separação de concerns entre conteúdo e pensamento
/// - Redução de atualizações desnecessárias durante streaming
/// - Controle inteligente de estado de pensamento
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/llm_model.dart';
import '../../domain/entities/llm_response.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/usecases/get_available_models.dart';
import '../../domain/usecases/generate_response.dart';
import '../../domain/usecases/generate_response_stream.dart';
import '../../domain/usecases/search_web.dart';
import '../../models/chat_message.dart';

/// Modelo para mensagem em streaming otimizada com streams incrementais.
class OptimizedStreamingMessage {
  final String id;
  final bool isUser;
  final DateTime timestamp;
  final StreamController<String> contentController;
  final StreamController<String> thinkingController;
  final ValueNotifier<bool> isComplete;
  final ValueNotifier<String> currentContent;
  final ValueNotifier<String> currentThinking;
  
  // Controladores para streaming incremental de tokens
  final StreamController<String> contentTokenController;
  final StreamController<String> thinkingTokenController;
  
  OptimizedStreamingMessage({
    required this.id,
    required this.isUser,
    required this.timestamp,
    String initialContent = '',
  }) : contentController = StreamController<String>.broadcast(),
       thinkingController = StreamController<String>.broadcast(),
       contentTokenController = StreamController<String>.broadcast(),
       thinkingTokenController = StreamController<String>.broadcast(),
       isComplete = ValueNotifier<bool>(false),
       currentContent = ValueNotifier<String>(initialContent),
       currentThinking = ValueNotifier<String>('');

  Stream<String> get contentStream => contentController.stream;
  Stream<String> get thinkingStream => thinkingController.stream;
  
  // Streams incrementais para tokens
  Stream<String> get contentTokenStream => contentTokenController.stream;
  Stream<String> get thinkingTokenStream => thinkingTokenController.stream;

  void addContent(String chunk) {
    if (!contentController.isClosed) {
      contentController.add(chunk);
      currentContent.value += chunk;
    }
  }

  void addThinking(String chunk) {
    if (!thinkingController.isClosed) {
      thinkingController.add(chunk);
      currentThinking.value += chunk;
    }
  }

  // Métodos para streaming incremental de tokens
  void addContentToken(String token) {
    if (!contentTokenController.isClosed) {
      contentTokenController.add(token);
      currentContent.value += token;
    }
  }

  void addThinkingToken(String token) {
    if (!thinkingTokenController.isClosed) {
      thinkingTokenController.add(token);
      currentThinking.value += token;
    }
  }
  
  void setContent(String content) {
    currentContent.value = content;
  }
  
  void setThinking(String thinking) {
    currentThinking.value = thinking;
  }

  void complete() {
    isComplete.value = true;
    contentController.close();
    thinkingController.close();
    contentTokenController.close();
    thinkingTokenController.close();
  }

  void dispose() {
    if (!contentController.isClosed) contentController.close();
    if (!thinkingController.isClosed) thinkingController.close();
    if (!contentTokenController.isClosed) contentTokenController.close();
    if (!thinkingTokenController.isClosed) thinkingTokenController.close();
    isComplete.dispose();
    currentContent.dispose();
    currentThinking.dispose();
  }
  
  ChatMessage toChatMessage() {
    return ChatMessage(
      text: currentContent.value,
      isUser: isUser,
      timestamp: timestamp,
      thinkingText: currentThinking.value.isNotEmpty ? currentThinking.value : null,
    );
  }
}

/// Controlador LLM otimizado para reduzir flickering.
class AntiFlickerLlmController extends ChangeNotifier {
  final GetAvailableModels _getAvailableModels;
  final GenerateResponse _generateResponse;
  final GenerateResponseStream _generateResponseStream;
  final SearchWeb _searchWeb;

  AntiFlickerLlmController({
    required GetAvailableModels getAvailableModels,
    required GenerateResponse generateResponse,
    required GenerateResponseStream generateResponseStream,
    required SearchWeb searchWeb,
  }) : _getAvailableModels = getAvailableModels,
       _generateResponse = generateResponse,
       _generateResponseStream = generateResponseStream,
       _searchWeb = searchWeb;

  // Estado dos modelos disponíveis
  List<LlmModel> _models = [];
  List<LlmModel> get models => _models;

  LlmModel? _selectedModel;
  LlmModel? get selectedModel => _selectedModel;

  // Estado das mensagens otimizadas
  final List<OptimizedStreamingMessage> _streamingMessages = [];
  List<OptimizedStreamingMessage> get streamingMessages => List.unmodifiable(_streamingMessages);

  // Cache para mensagens convertidas (compatibilidade)
  final List<ChatMessage> _cachedMessages = [];
  List<ChatMessage> get messages => List.unmodifiable(_cachedMessages);

  // Estados de carregamento
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  // Configurações
  bool _webSearchEnabled = false;
  bool get webSearchEnabled => _webSearchEnabled;

  bool _streamEnabled = true;
  bool get streamEnabled => _streamEnabled;

  // Estado de erro
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Estados de pensamento (compatibilidade com ChatPage)
  bool _isThinking = false;
  bool get isThinking => _isThinking;
  
  String? _currentThinking;
  String? get currentThinking => _currentThinking;

  // Throttling de notificações
  Timer? _notificationThrottle;
  static const Duration _throttleDuration = Duration(milliseconds: 100);
  
  // Debounce para atualizações de cache
  Timer? _cacheUpdateDebounce;
  static const Duration _cacheUpdateDuration = Duration(milliseconds: 200);
  
  // Flag para evitar notificações excessivas durante streaming
  bool _isStreamingActive = false;

  /// Atualiza o estado de carregamento com throttling.
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      _throttledNotify();
    }
  }

  /// Define uma mensagem de erro com throttling.
  void _setError(String? error) {
    if (_errorMessage != error) {
      _errorMessage = error;
      _throttledNotify();
    }
  }

  /// Atualiza o estado de pesquisa com throttling.
  void _setSearching(bool searching) {
    if (_isSearching != searching) {
      _isSearching = searching;
      _throttledNotify();
    }
  }
  
  /// Atualiza o estado de pensamento com throttling.
  void _setThinking(bool thinking, [String? thinkingText]) {
    // Evita atualizações desnecessárias durante streaming de pensamento
    bool shouldUpdate = false;
    
    // Só atualiza se o estado de thinking mudou
    if (_isThinking != thinking) {
      _isThinking = thinking;
      shouldUpdate = true;
    }
    
    // Para texto de pensamento, só atualiza se mudou significativamente
    // ou se o estado de thinking mudou
    if (thinkingText != null && (_currentThinking != thinkingText || shouldUpdate)) {
      // Durante streaming, só atualiza se a diferença for significativa
      // para reduzir flickering
      if (!_isThinking || shouldUpdate || 
          (_currentThinking?.length ?? 0) == 0 ||
          (thinkingText.length - (_currentThinking?.length ?? 0)) > 10) {
        _currentThinking = thinkingText;
        shouldUpdate = true;
      }
    } else if (thinkingText == null && _currentThinking != null) {
      _currentThinking = null;
      shouldUpdate = true;
    }
    
    if (shouldUpdate) {
      _throttledNotify();
    }
  }
  
  /// Notifica listeners com throttling para evitar updates excessivos.
  void _throttledNotify() {
    _notificationThrottle?.cancel();
    
    // Durante streaming ativo, usa throttling mais agressivo
    final effectiveThrottleDuration = _isStreamingActive 
        ? const Duration(milliseconds: 200) 
        : _throttleDuration;
    
    _notificationThrottle = Timer(effectiveThrottleDuration, () {
      if (hasListeners) {
        notifyListeners();
      }
    });
  }
  
  /// Atualiza o cache de mensagens com debounce.
  void _updateCachedMessages() {
    _cacheUpdateDebounce?.cancel();
    _cacheUpdateDebounce = Timer(_cacheUpdateDuration, () {
      _cachedMessages.clear();
      _cachedMessages.addAll(
        _streamingMessages.map((msg) => msg.toChatMessage()),
      );
      _throttledNotify();
    });
  }

  /// Seleciona um modelo LLM.
  void selectModel(LlmModel model) {
    if (_selectedModel != model) {
      _selectedModel = model;
      _throttledNotify();
    }
  }

  /// Alterna a pesquisa web.
  void toggleWebSearch(bool enabled) {
    if (_webSearchEnabled != enabled) {
      _webSearchEnabled = enabled;
      _throttledNotify();
    }
  }

  /// Alterna o modo de streaming.
  void toggleStreamMode(bool enabled) {
    if (_streamEnabled != enabled) {
      _streamEnabled = enabled;
      _throttledNotify();
    }
  }

  /// Carrega a lista de modelos disponíveis.
  Future<void> loadAvailableModels() async {
    _setLoading(true);
    _setError(null);

    try {
      _models = await _getAvailableModels();
      if (_models.isNotEmpty && _selectedModel == null) {
        _selectedModel = _models.first;
      }
    } catch (e) {
      _setError('Erro ao carregar modelos: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Envia mensagem com streaming otimizado.
  Future<void> sendMessage(String content) async {
    if (_selectedModel == null) {
      _setError('Nenhum modelo selecionado');
      return;
    }

    if (content.trim().isEmpty) {
      _setError('Mensagem não pode estar vazia');
      return;
    }

    _setError(null);

    // Criar mensagem do usuário
    final userMessage = OptimizedStreamingMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      isUser: true,
      timestamp: DateTime.now(),
      initialContent: content.trim(),
    );
    
    userMessage.complete();
    _streamingMessages.add(userMessage);
    _updateCachedMessages();

    String finalPrompt = content.trim();

    // Pesquisa web se habilitada
    if (_webSearchEnabled) {
      _setSearching(true);
      try {
        final searchResults = await _performWebSearch(content.trim());
        if (searchResults.isNotEmpty) {
          final searchContext = _buildSearchContext(searchResults);
          finalPrompt = '$content\n\nInformações relevantes da web:\n$searchContext';
        }
      } catch (e) {
        debugPrint('Erro na pesquisa web: $e');
      } finally {
        _setSearching(false);
      }
    }

    _setLoading(true);

    // Criar mensagem da IA para streaming
    final aiMessage = OptimizedStreamingMessage(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      isUser: false,
      timestamp: DateTime.now(),
    );
    
    _streamingMessages.add(aiMessage);
    _updateCachedMessages();

    final isThinkingModel = _selectedModel!.name.toLowerCase().contains('r1');

    if (_streamEnabled) {
      await _handleOptimizedStreamingResponse(finalPrompt, aiMessage, isThinkingModel);
    } else {
      await _handleSingleResponse(finalPrompt, aiMessage, isThinkingModel);
    }
  }
  
  /// Manipula resposta em streaming otimizada com tokens incrementais.
  Future<void> _handleOptimizedStreamingResponse(
    String prompt, 
    OptimizedStreamingMessage aiMessage, 
    bool isThinkingModel
  ) async {
    final contentBuffer = StringBuffer();
    final thinkingBuffer = StringBuffer();
    bool isInThinkingMode = false;
    
    // Timer para debounce de atualizações de pensamento
    Timer? thinkingUpdateTimer;
    
    void updateThinkingWithDebounce() {
      thinkingUpdateTimer?.cancel();
      thinkingUpdateTimer = Timer(const Duration(milliseconds: 150), () {
        if (isInThinkingMode && thinkingBuffer.isNotEmpty) {
          _setThinking(true, thinkingBuffer.toString());
        }
      });
    }

    try {
      _isStreamingActive = true;
      
      await for (final chunk in _generateResponseStream(
        prompt: prompt,
        modelName: _selectedModel!.name,
      )) {
        if (isThinkingModel && chunk.contains('<think>')) {
          isInThinkingMode = true;
          _setThinking(true, 'Iniciando análise...');
          final thinkStart = chunk.indexOf('<think>');
          if (thinkStart != -1) {
            // Adiciona conteúdo antes da tag <think> como tokens
            if (thinkStart > 0) {
              final contentChunk = chunk.substring(0, thinkStart);
              contentBuffer.write(contentChunk);
              
              // Enviar chunk como token incremental
              aiMessage.addContentToken(contentChunk);
            }
            // Começa a capturar pensamento
            final thinkContent = chunk.substring(thinkStart + 7);
            thinkingBuffer.write(thinkContent);
            
            // Enviar pensamento como token incremental
            if (thinkContent.isNotEmpty) {
              aiMessage.addThinkingToken(thinkContent);
              updateThinkingWithDebounce();
            }
          }
        } else if (isInThinkingMode) {
          if (chunk.contains('</think>')) {
            final thinkEnd = chunk.indexOf('</think>');
            if (thinkEnd != -1) {
              // Finalizar pensamento com token final
              final finalThinkingChunk = chunk.substring(0, thinkEnd);
              if (finalThinkingChunk.isNotEmpty) {
                thinkingBuffer.write(finalThinkingChunk);
                aiMessage.addThinkingToken(finalThinkingChunk);
              }
              
              // Cancelar timer pendente e finalizar estado de pensamento
              thinkingUpdateTimer?.cancel();
              _setThinking(false, thinkingBuffer.toString());

              // Adicionar conteúdo após a tag </think> como tokens
              final remainingContent = chunk.substring(thinkEnd + 8);
              if (remainingContent.isNotEmpty) {
                contentBuffer.write(remainingContent);
                aiMessage.addContentToken(remainingContent);
              }
              isInThinkingMode = false;
            } else {
              // Continuar pensamento como tokens incrementais
              thinkingBuffer.write(chunk);
              aiMessage.addThinkingToken(chunk);
              updateThinkingWithDebounce();
            }
          } else {
            // Adicionar chunk ao pensamento como token incremental
            thinkingBuffer.write(chunk);
            aiMessage.addThinkingToken(chunk);
            updateThinkingWithDebounce();
          }
        } else {
          // Adicionar chunk ao conteúdo como token incremental
          contentBuffer.write(chunk);
          aiMessage.addContentToken(chunk);
        }
      }
      
      // Finalizar streaming de tokens
      aiMessage.setContent(contentBuffer.toString());
      if (thinkingBuffer.isNotEmpty) {
        aiMessage.setThinking(thinkingBuffer.toString());
      }
      
    } catch (e) {
      _setError('Erro ao gerar resposta: $e');
      aiMessage.addContentToken('Erro ao gerar resposta: $e');
    } finally {
      // Limpar timer de debounce e estado de pensamento
      thinkingUpdateTimer?.cancel();
      _isStreamingActive = false;
      _setThinking(false, null);
      aiMessage.complete();
      _setLoading(false);
      _updateCachedMessages();
    }
  }
  
  /// Manipula resposta única (não streaming).
  Future<void> _handleSingleResponse(
    String prompt, 
    OptimizedStreamingMessage aiMessage, 
    bool isThinkingModel
  ) async {
    try {
      if (isThinkingModel) {
        _setThinking(true, 'Processando...');
      }
      
      final response = await _generateResponse(
        prompt: prompt,
        modelName: _selectedModel!.name,
      );
      
      if (isThinkingModel) {
        final processedResponse = _processThinkingResponse(response);
        aiMessage.setContent(processedResponse.content);
        if (processedResponse.thinking != null) {
          aiMessage.setThinking(processedResponse.thinking!);
        }
      } else {
        aiMessage.setContent(response.content);
      }
      
    } catch (e) {
      _setError('Erro ao gerar resposta: $e');
      aiMessage.setContent('Erro ao gerar resposta: $e');
    } finally {
      // Limpar estado de pensamento
      _setThinking(false, null);
      aiMessage.complete();
      _setLoading(false);
      _updateCachedMessages();
    }
  }
  
  /// Processa resposta de modelos com pensamento.
  ({String content, String? thinking}) _processThinkingResponse(LlmResponse response) {
    if (response.content.contains('<think>')) {
      final thinkStart = response.content.indexOf('<think>');
      final thinkEnd = response.content.indexOf('</think>');
      
      if (thinkStart != -1 && thinkEnd != -1) {
        final thinking = response.content.substring(thinkStart + 7, thinkEnd);
        final content = response.content.substring(0, thinkStart) + 
                       response.content.substring(thinkEnd + 8);
        
        return (content: content.trim(), thinking: thinking.trim());
      }
    }
    
    return (content: response.content, thinking: null);
  }
  
  /// Realiza pesquisa web.
  Future<List<SearchResult>> _performWebSearch(String query) async {
    try {
      final searchQuery = SearchQuery(
        query: query,
        maxResults: 5,
      );
      return await _searchWeb(searchQuery);
    } catch (e) {
      debugPrint('Erro na pesquisa web: $e');
      return [];
    }
  }
  
  /// Constrói contexto de pesquisa web.
  String _buildSearchContext(List<SearchResult> results) {
    final buffer = StringBuffer();
    
    for (int i = 0; i < results.length && i < 3; i++) {
      final result = results[i];
      buffer.writeln('${i + 1}. ${result.title}');
      buffer.writeln('   ${result.snippet}');
      buffer.writeln('   Fonte: ${result.url}');
      buffer.writeln();
    }
    
    return buffer.toString();
  }

  /// Limpa o chat.
  void clearChat() {
    for (final msg in _streamingMessages) {
      msg.dispose();
    }
    _streamingMessages.clear();
    _cachedMessages.clear();
    _setError(null);
    _setThinking(false, null);
    _throttledNotify();
  }

  /// Remove uma mensagem.
  void removeMessage(int index) {
    if (index >= 0 && index < _streamingMessages.length) {
      _streamingMessages[index].dispose();
      _streamingMessages.removeAt(index);
      _updateCachedMessages();
    }
  }
  
  /// Obtém mensagem de streaming por ID.
  OptimizedStreamingMessage? getStreamingMessage(String id) {
    try {
      return _streamingMessages.firstWhere((msg) => msg.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _notificationThrottle?.cancel();
    _cacheUpdateDebounce?.cancel();
    
    for (final msg in _streamingMessages) {
      msg.dispose();
    }
    
    super.dispose();
  }
}