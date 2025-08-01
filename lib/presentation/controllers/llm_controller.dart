import 'package:flutter/foundation.dart';
import '../../domain/entities/llm_model.dart';
import '../../domain/entities/llm_response.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/usecases/get_available_models.dart';
import '../../domain/usecases/generate_response.dart';
import '../../domain/usecases/generate_response_stream.dart';
import '../../domain/usecases/search_web.dart';
import '../widgets/chat_interface.dart';

class LlmController extends ChangeNotifier {
  final GetAvailableModels _getAvailableModels;
  final GenerateResponse _generateResponse;
  final GenerateResponseStream _generateResponseStream;
  final SearchWeb _searchWeb;

  // Cache para conteúdos de páginas web
  final Map<String, String> _webPageContents = {};

  LlmController({
    required GetAvailableModels getAvailableModels,
    required GenerateResponse generateResponse,
    required GenerateResponseStream generateResponseStream,
    required SearchWeb searchWeb,
  })  : _getAvailableModels = getAvailableModels,
        _generateResponse = generateResponse,
        _generateResponseStream = generateResponseStream,
        _searchWeb = searchWeb;

  List<LlmModel> _models = [];
  List<LlmModel> get models => _models;

  LlmModel? _selectedModel;
  LlmModel? get selectedModel => _selectedModel;

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  final List<SearchResult> _searchResults = [];
  List<SearchResult> get searchResults => List.unmodifiable(_searchResults);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  bool _webSearchEnabled = false;
  bool get webSearchEnabled => _webSearchEnabled;

  bool _streamEnabled = true;
  bool get streamEnabled => _streamEnabled;

  String? _currentThinking;
  String? get currentThinking => _currentThinking;

  bool _isThinking = false;
  bool get isThinking => _isThinking;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _setSearching(bool searching) {
    _isSearching = searching;
    notifyListeners();
  }

  void _setThinking(bool thinking, [String? thinkingText]) {
    _isThinking = thinking;
    _currentThinking = thinkingText;
    notifyListeners();
  }

  void selectModel(LlmModel model) {
    _selectedModel = model;
    _setError(null);
    notifyListeners();
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

    // Limpar resultados de pesquisa anteriores
    _searchResults.clear();

    // Adiciona mensagem do usuário
    final userMessage = ChatMessage.fromUser(content.trim());
    _messages.add(userMessage);
    notifyListeners();

    String finalPrompt = content.trim();

    // Se pesquisa web estiver habilitada, buscar informações
    if (_webSearchEnabled) {
      _setSearching(true);
      try {
        await _performWebSearch(content.trim());

        if (_searchResults.isNotEmpty) {
          // Buscar conteúdo das páginas principais dos resultados
          await _fetchAndAttachWebContents();

          // Adicionar contexto da pesquisa ao prompt
          final searchContext = _buildSearchContext();
          finalPrompt = '$content\n\nInformações relevantes da web:\n$searchContext';

          // Adicionar mensagem informativa sobre a pesquisa
          final searchInfo = ChatMessage(
            content: 'Encontrei ${_searchResults.length} resultados relevantes na web e resumi o conteúdo principal para o contexto.',
            isUser: false,
            timestamp: DateTime.now(),
            isError: false,
          );
          _messages.add(searchInfo);
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Erro na pesquisa web: $e');
        // Continuar mesmo se a pesquisa falhar
      } finally {
        _setSearching(false);
      }
    }

    _setLoading(true);

    // Verificar se é um modelo que "pensa" (R1 series)
    final isThinkingModel = _selectedModel!.name.toLowerCase().contains('r1');

    if (isThinkingModel) {
      _setThinking(true, 'Analisando a pergunta e estruturando a resposta...');
    }

    if (_streamEnabled) {
      // Usa streaming
      await _handleStreamingResponse(finalPrompt, isThinkingModel);
    } else {
      // Usa resposta única (modo original)
      await _handleSingleResponse(finalPrompt, isThinkingModel);
    }
  }

  Future<void> _handleSingleResponse(String prompt, bool isThinkingModel) async {
    try {
      final response = await _generateResponse(
        prompt: prompt,
        modelName: _selectedModel!.name,
      );

      // Processar resposta com pensamento
      final processedResponse = _processThinkingResponse(response);

      // Adiciona resposta do LLM
      final llmMessage = ChatMessage.fromResponse(processedResponse);
      _messages.add(llmMessage);

      if (processedResponse.isError) {
        _setError('Erro na resposta: ${processedResponse.content}');
      }
    } catch (e) {
      // Adiciona mensagem de erro
      final errorMessage = ChatMessage(
        content: 'Erro ao gerar resposta: $e',
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      );
      _messages.add(errorMessage);
      _setError('Erro ao gerar resposta: $e');
    } finally {
      _setLoading(false);
      _setThinking(false);
    }
  }

  Future<void> _handleStreamingResponse(String prompt, bool isThinkingModel) async {
    // Cria mensagem vazia para streaming
    final streamingMessage = ChatMessage(
      content: '',
      isUser: false,
      timestamp: DateTime.now(),
      isError: false,
    );
    _messages.add(streamingMessage);

    final messageIndex = _messages.length - 1;
    final contentBuffer = StringBuffer();
    bool isInThinkingMode = false;
    final thinkingBuffer = StringBuffer();

    try {
      await for (final chunk in _generateResponseStream(
        prompt: prompt,
        modelName: _selectedModel!.name,
      )) {
        if (isThinkingModel && chunk.contains('<think>')) {
          isInThinkingMode = true;
          final thinkStart = chunk.indexOf('<think>');
          if (thinkStart != -1) {
            // Adiciona conteúdo antes da tag <think>
            if (thinkStart > 0) {
              contentBuffer.write(chunk.substring(0, thinkStart));
            }
            // Começa a capturar pensamento
            thinkingBuffer.write(chunk.substring(thinkStart + 7));
          }
        } else if (isThinkingModel && isInThinkingMode) {
          if (chunk.contains('</think>')) {
            final thinkEnd = chunk.indexOf('</think>');
            if (thinkEnd != -1) {
              // Finaliza pensamento
              thinkingBuffer.write(chunk.substring(0, thinkEnd));
              _setThinking(false, thinkingBuffer.toString());

              // Adiciona conteúdo após a tag </think>
              final remainingContent = chunk.substring(thinkEnd + 8);
              if (remainingContent.isNotEmpty) {
                contentBuffer.write(remainingContent);
              }
              isInThinkingMode = false;
            } else {
              thinkingBuffer.write(chunk);
            }
          } else {
            thinkingBuffer.write(chunk);
            // Atualiza o pensamento em tempo real
            _setThinking(true, thinkingBuffer.toString());
          }
        } else {
          contentBuffer.write(chunk);
        }

        // Atualiza a mensagem com o conteúdo atual
        if (!isInThinkingMode && contentBuffer.isNotEmpty) {
          _messages[messageIndex] = ChatMessage(
            content: contentBuffer.toString(),
            isUser: false,
            timestamp: streamingMessage.timestamp,
            isError: false,
          );
          notifyListeners();
        }
      }
    } catch (e) {
      // Adiciona mensagem de erro
      final errorMessage = ChatMessage(
        content: 'Erro ao gerar resposta: $e',
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      );
      _messages.add(errorMessage);
      _setError('Erro ao gerar resposta: $e');
    } finally {
      _setLoading(false);
      _setThinking(false);
    }
  }

  LlmResponse _processThinkingResponse(LlmResponse response) {
    if (response.content.contains('<think>')) {
      // Extrair o pensamento
      final thinkStart = response.content.indexOf('<think>');
      final thinkEnd = response.content.indexOf('</think>');

      if (thinkStart != -1 && thinkEnd != -1) {
        final thinkingText = response.content.substring(
          thinkStart + 7, // length of '<think>'
          thinkEnd,
        );

        // Mostrar o pensamento por um tempo antes da resposta
        _setThinking(false, thinkingText);

        // Criar mensagem de pensamento
        final thinkingMessage = ChatMessage(
          content: thinkingText,
          isUser: false,
          timestamp: DateTime.now(),
          isError: false,
        );
        _messages.add(thinkingMessage);
        notifyListeners();

        // Remover tags de pensamento da resposta final
        final cleanContent = response.content
            .replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '')
            .trim();

        return LlmResponse(
          content: cleanContent,
          model: response.model,
          timestamp: response.timestamp,
          isError: response.isError,
        );
      }
    }

    return response;
  }

  Future<void> _performWebSearch(String query) async {
    _searchResults.clear();

    final searchQuery = SearchQuery(
      query: query,
      maxResults: 3,
    );

    final results = await _searchWeb(searchQuery);
    _searchResults.addAll(results);
  }

  // Busca e armazena o conteúdo das páginas dos resultados de pesquisa
  Future<void> _fetchAndAttachWebContents() async {
    for (final result in _searchResults) {
      if (result.url.isNotEmpty && !_webPageContents.containsKey(result.url)) {
        try {
          final content = await _fetchWebContent(result.url);
          _webPageContents[result.url] = content;
        } catch (e) {
          _webPageContents[result.url] = '';
        }
      }
    }
  }

  String _buildSearchContext() {
    final buffer = StringBuffer();

    for (int i = 0; i < _searchResults.length; i++) {
      final result = _searchResults[i];
      buffer.writeln('${i + 1}. ${result.title}');
      buffer.writeln('   ${result.snippet}');
      if (result.url.isNotEmpty) {
        buffer.writeln('   Fonte: ${result.url}');
      }
      // Adiciona resumo do conteúdo da página, se disponível
      final pageContent = _webPageContents[result.url];
      if (pageContent != null && pageContent.isNotEmpty) {
        buffer.writeln('   Resumo da página:');
        buffer.writeln('   ${_summarizeContent(pageContent)}');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  // Função simples para resumir o conteúdo da página (pode ser aprimorada)
  String _summarizeContent(String content) {
    // Limita a 3 frases ou 400 caracteres
    final sentences = content.split(RegExp(r'(?<=[.!?])\s+'));
    final summary = sentences.take(3).join(' ');
    if (summary.length > 400) {
      return '${summary.substring(0, 400)}...';
    }
    return summary;
  }

  void clearChat() {
    _messages.clear();
    _searchResults.clear();
    _webPageContents.clear();
    _setError(null);
    notifyListeners();
  }

  void removeMessage(int index) {
    if (index >= 0 && index < _messages.length) {
      _messages.removeAt(index);
      notifyListeners();
    }
  }

  void clearSearchResults() {
    _searchResults.clear();
    _webPageContents.clear();
    notifyListeners();
  }

  // Função para buscar conteúdo da página web usando o datasource padrão
  Future<String> _fetchWebContent(String url) async {
    // Verifica se o dataSource tem o método fetchPageContent
    final dataSource = (_searchWeb as dynamic).dataSource;
    if (dataSource != null && dataSource.fetchPageContent != null) {
      return await dataSource.fetchPageContent(url);
    }
    return '';
  }
}
