/// Controlador LLM otimizado para reduzir flickering durante streaming.
/// 
/// Implementa padrões de otimização:
/// - Streams isolados para cada mensagem
/// - Debounce de notificações
/// - Separação de concerns para thinking vs content
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/llm_model.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/usecases/get_available_models.dart';
import '../../domain/usecases/generate_response.dart';
import '../../domain/usecases/generate_response_stream.dart';
import '../../domain/usecases/search_web.dart';
import '../../models/chat_message.dart';

/// Modelo para mensagem em streaming
class StreamingMessage {
  final String id;
  final bool isUser;
  final DateTime timestamp;
  final StreamController<String> contentController;
  final StreamController<String> thinkingController;
  final ValueNotifier<bool> isComplete;
  
  StreamingMessage({
    required this.id,
    required this.isUser,
    required this.timestamp,
  }) : contentController = StreamController<String>.broadcast(),
       thinkingController = StreamController<String>.broadcast(),
       isComplete = ValueNotifier<bool>(false);

  Stream<String> get contentStream => contentController.stream;
  Stream<String> get thinkingStream => thinkingController.stream;

  void addContent(String chunk) {
    if (!contentController.isClosed) {
      contentController.add(chunk);
    }
  }

  void addThinking(String chunk) {
    if (!thinkingController.isClosed) {
      thinkingController.add(chunk);
    }
  }

  void complete() {
    isComplete.value = true;
    contentController.close();
    thinkingController.close();
  }

  void dispose() {
    if (!contentController.isClosed) contentController.close();
    if (!thinkingController.isClosed) thinkingController.close();
    isComplete.dispose();
  }
}

/// Controlador LLM otimizado anti-flickering
class OptimizedLlmController extends ChangeNotifier {
  final GetAvailableModels _getAvailableModels;
  final GenerateResponse _generateResponse;
  final GenerateResponseStream _generateResponseStream;
  final SearchWeb _searchWeb;

  OptimizedLlmController({
    required GetAvailableModels getAvailableModels,
    required GenerateResponse generateResponse,
    required GenerateResponseStream generateResponseStream,
    required SearchWeb searchWeb,
  })  : _getAvailableModels = getAvailableModels,
        _generateResponse = generateResponse,
        _generateResponseStream = generateResponseStream,
        _searchWeb = searchWeb;

  // Estado dos modelos disponíveis
  List<LlmModel> _models = [];
  List<LlmModel> get models => _models;

  LlmModel? _selectedModel;
  LlmModel? get selectedModel => _selectedModel;

  // Estado das mensagens - agora com streams otimizados
  final List<StreamingMessage> _streamingMessages = [];
  List<StreamingMessage> get streamingMessages => List.unmodifiable(_streamingMessages);

  // Cache para mensagens convertidas (para compatibilidade)
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

  // Debounce para notificações
  Timer? _notificationDebounce;
  static const Duration _debounceDuration = Duration(milliseconds: 100);

  /// Notifica listeners com debounce para reduzir rebuilds
  void _debouncedNotify() {
    _notificationDebounce?.cancel();
    _notificationDebounce = Timer(_debounceDuration, () {
      if (!disposed) notifyListeners();
    });
  }

  bool disposed = false;

  @override
  void dispose() {
    disposed = true;
    _notificationDebounce?.cancel();
    
    // Limpar streams de mensagens
    for (final msg in _streamingMessages) {
      msg.dispose();
    }
    _streamingMessages.clear();
    
    super.dispose();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    _debouncedNotify();
  }

  void _setError(String? error) {
    _errorMessage = error;
    _debouncedNotify();
  }

  void _setSearching(bool searching) {
    _isSearching = searching;
    _debouncedNotify();
  }

  void selectModel(LlmModel model) {
    _selectedModel = model;
    _setError(null);
    notifyListeners(); // Notificação imediata para mudança de modelo
  }

  void toggleWebSearch(bool enabled) {
    _webSearchEnabled = enabled;
    notifyListeners();
  }

  void toggleStreamMode(bool enabled) {
    _streamEnabled = enabled;
    notifyListeners();
  }

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

  /// Envia mensagem com streaming otimizado
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
    final userMessage = StreamingMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      isUser: true,
      timestamp: DateTime.now(),
    );
    
    // Adicionar conteúdo completo imediatamente para mensagens do usuário
    userMessage.addContent(content.trim());
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
    final aiMessage = StreamingMessage(
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

  /// Streaming otimizado que não causa rebuilds excessivos
  Future<void> _handleOptimizedStreamingResponse(
    String prompt, 
    StreamingMessage aiMessage, 
    bool isThinkingModel
  ) async {
    final contentBuffer = StringBuffer();
    final thinkingBuffer = StringBuffer();
    bool isInThinkingMode = false;

    try {
      await for (final chunk in _generateResponseStream(
        prompt: prompt,
        modelName: _selectedModel!.name,
      )) {
        
        if (chunk.contains('<think>')) {
          isInThinkingMode = true;
          final thinkStart = chunk.indexOf('<think>');
          
          if (thinkStart > 0) {
            final preThinkContent = chunk.substring(0, thinkStart);
            contentBuffer.write(preThinkContent);
            aiMessage.addContent(preThinkContent);
          }
          
          final thinkContent = chunk.substring(thinkStart + 7);
          thinkingBuffer.write(thinkContent);
          aiMessage.addThinking(thinkingBuffer.toString());
          
        } else if (isInThinkingMode) {
          if (chunk.contains('</think>')) {
            final thinkEnd = chunk.indexOf('</think>');
            
            // Finalizar pensamento
            thinkingBuffer.write(chunk.substring(0, thinkEnd));
            aiMessage.addThinking(thinkingBuffer.toString());
            
            // Conteúdo após pensamento
            final remainingContent = chunk.substring(thinkEnd + 8);
            if (remainingContent.isNotEmpty) {
              contentBuffer.write(remainingContent);
              aiMessage.addContent(remainingContent);
            }
            
            isInThinkingMode = false;
          } else {
            // Ainda dentro do pensamento
            thinkingBuffer.write(chunk);
            aiMessage.addThinking(thinkingBuffer.toString());
          }
        } else {
          // Conteúdo normal
          contentBuffer.write(chunk);
          aiMessage.addContent(chunk);
        }
      }
      
      aiMessage.complete();
      
    } catch (e) {
      aiMessage.addContent('\n\nErro ao gerar resposta: $e');
      aiMessage.complete();
      _setError('Erro ao gerar resposta: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _handleSingleResponse(
    String prompt, 
    StreamingMessage aiMessage, 
    bool isThinkingModel
  ) async {
    try {
      final response = await _generateResponse(
        prompt: prompt,
        modelName: _selectedModel!.name,
      );

      // Processar resposta com pensamento se necessário
      if (response.content.contains('<think>')) {
        final thinkStart = response.content.indexOf('<think>');
        final thinkEnd = response.content.indexOf('</think>');
        
        if (thinkStart != -1 && thinkEnd != -1) {
          final thinkingText = response.content.substring(thinkStart + 7, thinkEnd);
          aiMessage.addThinking(thinkingText);
          
          final cleanContent = response.content
              .replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '')
              .trim();
          aiMessage.addContent(cleanContent);
        } else {
          aiMessage.addContent(response.content);
        }
      } else {
        aiMessage.addContent(response.content);
      }

      aiMessage.complete();

      if (response.isError) {
        _setError('Erro na resposta: ${response.content}');
      }
    } catch (e) {
      aiMessage.addContent('Erro ao gerar resposta: $e');
      aiMessage.complete();
      _setError('Erro ao gerar resposta: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Atualiza cache de mensagens para compatibilidade com UI existente
  void _updateCachedMessages() {
    _cachedMessages.clear();
    
    for (final streamingMsg in _streamingMessages) {
      _cachedMessages.add(ChatMessage(
        text: '', // Será preenchido pelo stream
        isUser: streamingMsg.isUser,
        timestamp: streamingMsg.timestamp,
      ));
    }
    
    // Notificação debounced para não sobrecarregar UI
    _debouncedNotify();
  }

  Future<List<SearchResult>> _performWebSearch(String query) async {
    try {
      final searchQuery = SearchQuery(query: query, maxResults: 3);
      return await _searchWeb(searchQuery);
    } catch (e) {
      debugPrint('Erro na pesquisa web: $e');
      return [];
    }
  }

  String _buildSearchContext(List<SearchResult> results) {
    final buffer = StringBuffer();
    for (int i = 0; i < results.length; i++) {
      final result = results[i];
      buffer.writeln('${i + 1}. ${result.title}');
      buffer.writeln('   ${result.snippet}');
      if (result.url.isNotEmpty) {
        buffer.writeln('   Fonte: ${result.url}');
      }
      buffer.writeln();
    }
    return buffer.toString();
  }

  void clearChat() {
    for (final msg in _streamingMessages) {
      msg.dispose();
    }
    _streamingMessages.clear();
    _cachedMessages.clear();
    _setError(null);
    notifyListeners();
  }

  void removeMessage(int index) {
    if (index >= 0 && index < _streamingMessages.length) {
      _streamingMessages[index].dispose();
      _streamingMessages.removeAt(index);
      _updateCachedMessages();
    }
  }
}