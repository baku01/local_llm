/// Controlador principal da aplicação de chat com LLM.
///
/// Este arquivo contém o controlador responsável por gerenciar toda a lógica
/// de interação com modelos de linguagem locais, incluindo pesquisa web,
/// streaming de respostas e cache de conteúdo.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/llm_model.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/entities/search_query.dart';
import '../../domain/usecases/get_available_models.dart';
import '../../domain/usecases/generate_response.dart';
import '../../domain/usecases/generate_response_stream.dart';
import '../../domain/usecases/search_web.dart';
import '../../domain/usecases/process_thinking_response.dart';
import '../../domain/entities/chat_message.dart';

/// Controlador principal que gerencia a interação com modelos LLM.
///
/// Responsabilidades principais:
/// - Gerenciar seleção e carregamento de modelos disponíveis
/// - Processar mensagens do usuário e gerar respostas via LLM
/// - Integrar pesquisa web para enriquecer o contexto das conversas
/// - Gerenciar cache de conteúdo web para otimização de performance
/// - Suportar streaming de respostas para melhor experiência do usuário
/// - Processar modelos com capacidade de "pensamento" (série R1)
class LlmController extends ChangeNotifier {
  /// Caso de uso para obter modelos disponíveis.
  final GetAvailableModels _getAvailableModels;

  /// Caso de uso para gerar resposta única (não streaming).
  final GenerateResponse _generateResponse;

  /// Caso de uso para gerar resposta em streaming.
  final GenerateResponseStream _generateResponseStream;

  /// Caso de uso para realizar pesquisas na web.
  final SearchWeb _searchWeb;

  /// Caso de uso para buscar conteúdo de páginas web.
  final FetchWebContent _fetchWebContent;

  /// Caso de uso para processar respostas com pensamento.
  final ProcessThinkingResponse _processThinkingResponse;

  /// Cache para armazenar conteúdos de páginas web já processadas.
  /// Evita múltiplas requisições para a mesma URL durante uma sessão.
  final Map<String, String> _webPageContents = {};

  /// Timer para throttling de notificações durante streaming.
  Timer? _notificationTimer;

  /// Controla se há uma notificação pendente.
  bool _hasPendingNotification = false;

  /// Construtor do controlador com injeção de dependências.
  ///
  /// Todos os casos de uso são obrigatórios para o funcionamento completo.
  LlmController({
    required GetAvailableModels getAvailableModels,
    required GenerateResponse generateResponse,
    required GenerateResponseStream generateResponseStream,
    required SearchWeb searchWeb,
    required FetchWebContent fetchWebContent,
    required ProcessThinkingResponse processThinkingResponse,
  })  : _getAvailableModels = getAvailableModels,
        _generateResponse = generateResponse,
        _generateResponseStream = generateResponseStream,
        _searchWeb = searchWeb,
        _fetchWebContent = fetchWebContent,
        _processThinkingResponse = processThinkingResponse;

  // Estado dos modelos disponíveis
  List<LlmModel> _models = [];

  /// Lista de modelos LLM disponíveis para uso.
  List<LlmModel> get models => _models;

  LlmModel? _selectedModel;

  /// Modelo atualmente selecionado pelo usuário.
  LlmModel? get selectedModel => _selectedModel;

  // Estado das mensagens do chat
  final List<ChatMessage> _messages = [];

  /// Lista imutável de mensagens do chat atual.
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  // Estado dos resultados de pesquisa
  final List<SearchResult> _searchResults = [];

  /// Lista imutável de resultados da última pesquisa web realizada.
  List<SearchResult> get searchResults => List.unmodifiable(_searchResults);

  // Estados de carregamento e processamento
  bool _isLoading = false;

  /// Indica se uma resposta do LLM está sendo gerada.
  bool get isLoading => _isLoading;

  bool _isSearching = false;

  /// Indica se uma pesquisa web está em andamento.
  bool get isSearching => _isSearching;

  // Configurações funcionais
  bool _webSearchEnabled = false;

  /// Indica se a pesquisa web está habilitada para enriquecer o contexto.
  bool get webSearchEnabled => _webSearchEnabled;

  bool _streamEnabled = true;

  /// Indica se o modo streaming está ativo para respostas em tempo real.
  bool get streamEnabled => _streamEnabled;

  // Estado do processamento de "pensamento" (modelos R1)
  String? _currentThinking;

  /// Texto atual do processo de "pensamento" dos modelos R1.
  String? get currentThinking => _currentThinking;

  bool _isThinking = false;

  /// Indica se o modelo está no processo de "pensamento".
  bool get isThinking => _isThinking;

  // Estado de erro
  String? _errorMessage;

  /// Mensagem de erro atual, se houver.
  String? get errorMessage => _errorMessage;

  /// Atualiza o estado de carregamento e notifica os ouvintes.
  void _setLoading(bool loading) {
    _isLoading = loading;
    // Force immediate notification when stopping loading to ensure tests see the state change
    if (!loading) {
      _notificationTimer?.cancel();
      _hasPendingNotification = false;
      notifyListeners();
    } else {
      _notifyListenersThrottled();
    }
  }

  /// Define uma mensagem de erro e notifica os ouvintes.
  void _setError(String? error) {
    _errorMessage = error;
    _notifyListenersThrottled();
  }

  /// Atualiza o estado de pesquisa web e notifica os ouvintes.
  void _setSearching(bool searching) {
    _isSearching = searching;
    _notifyListenersThrottled();
  }

  /// Atualiza o estado de processamento de pensamento e notifica os ouvintes.
  ///
  /// [thinking] - Se o modelo está pensando
  /// [thinkingText] - Texto opcional do pensamento atual
  void _setThinking(bool thinking, [String? thinkingText]) {
    bool shouldNotify = false;

    if (_isThinking != thinking) {
      _isThinking = thinking;
      shouldNotify = true;
    }

    // Throttling otimizado para eliminar flickering
    if (thinkingText != null &&
        (_currentThinking != thinkingText || shouldNotify)) {
      final currentLength = _currentThinking?.length ?? 0;
      final newLength = thinkingText.length;

      // Critério mais rigoroso para atualizações - reduz flickering significativamente
      if (!_isThinking ||
          shouldNotify ||
          currentLength == 0 ||
          (newLength - currentLength) >=
              50 || // Aumentado para 50 para maior estabilidade
          (newLength > 0 && currentLength == 0)) {
        _currentThinking = thinkingText;
        shouldNotify = true;
      }
    } else if (thinkingText == null && _currentThinking != null) {
      _currentThinking = null;
      shouldNotify = true;
    }

    if (shouldNotify) {
      // Notificação imediata apenas quando para de pensar
      if (!thinking) {
        _notificationTimer?.cancel();
        _hasPendingNotification = false;
        notifyListeners();
      } else {
        _notifyListenersThrottled();
      }
    }
  }

  /// Seleciona um modelo LLM para uso e limpa erros anteriores.
  ///
  /// [model] - O modelo a ser selecionado
  void selectModel(LlmModel model) {
    _selectedModel = model;
    _setError(null);
    _notifyListenersThrottled();
  }

  /// Alterna o estado da pesquisa web.
  ///
  /// [enabled] - Se a pesquisa web deve estar habilitada
  void toggleWebSearch(bool enabled) {
    _webSearchEnabled = enabled;
    _notifyListenersThrottled();
  }

  /// Alterna o modo de streaming de respostas.
  ///
  /// [enabled] - Se o streaming deve estar habilitado
  void toggleStreamMode(bool enabled) {
    _streamEnabled = enabled;
    _notifyListenersThrottled();
  }

  /// Carrega a lista de modelos LLM disponíveis.
  ///
  /// Obtém todos os modelos disponíveis no servidor Ollama e seleciona
  /// automaticamente o primeiro se nenhum estiver selecionado.
  ///
  /// Throws: Define uma mensagem de erro se a operação falhar.
  Future<void> loadAvailableModels() async {
    debugPrint('loadAvailableModels: Starting, setting loading to true');
    _setLoading(true);
    _setError(null);

    try {
      debugPrint('loadAvailableModels: Calling _getAvailableModels');
      _models = await _getAvailableModels();
      debugPrint('loadAvailableModels: Got ${_models.length} models');
      if (_models.isNotEmpty && _selectedModel == null) {
        _selectedModel = _models.first;
      }
    } catch (e) {
      debugPrint('loadAvailableModels: Exception caught: $e');
      _setError('Erro ao carregar modelos: $e');
    } finally {
      debugPrint(
          'loadAvailableModels: In finally block, setting loading to false');
      _setLoading(false);
      _setThinking(false);
      debugPrint('loadAvailableModels: Finally block completed');
    }
  }

  /// Processa e envia uma mensagem do usuário para o modelo LLM.
  ///
  /// Este é o método principal que orquestra todo o fluxo de processamento:
  /// 1. Valida entrada e estado atual
  /// 2. Realiza pesquisa web se habilitada
  /// 3. Enriquece o prompt com contexto web
  /// 4. Gera resposta via streaming ou modo único
  /// 5. Processa respostas de modelos com "pensamento"
  ///
  /// [content] - O texto da mensagem do usuário
  ///
  /// Throws: Define mensagens de erro para validações e falhas de processamento.
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
    final userMessage = ChatMessage(
      text: content.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);
    _notifyListenersThrottled();

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
          finalPrompt =
              '$content\n\nInformações relevantes da web:\n$searchContext';

          // Adicionar mensagem informativa sobre a pesquisa
          final searchInfo = ChatMessage(
            text:
                'Encontrei ${_searchResults.length} resultados relevantes na web e resumi o conteúdo principal para o contexto.',
            isUser: false,
            timestamp: DateTime.now(),
          );
          _messages.add(searchInfo);
          _notifyListenersThrottled();
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

    try {
      if (_streamEnabled) {
        // Usa streaming
        await _handleStreamingResponse(finalPrompt, isThinkingModel);
      } else {
        // Usa resposta única (modo original)
        await _handleSingleResponse(finalPrompt, isThinkingModel);
      }
    } catch (e) {
      // Adiciona mensagem de erro
      final errorMessage = ChatMessage(
        text: 'Erro ao processar mensagem: $e',
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages.add(errorMessage);
      _setError('Erro ao processar mensagem: $e');
    } finally {
      // Garantir que os estados sejam sempre resetados
      _setLoading(false);
      _setThinking(false);
      _setSearching(false);
    }
  }

  Future<void> _handleSingleResponse(
      String prompt, bool isThinkingModel) async {
    try {
      final response = await _generateResponse(
        prompt: prompt,
        modelName: _selectedModel!.name,
      );

      // Processar resposta com pensamento usando o caso de uso
      final processedResponse = _processThinkingResponse(response);

      // Adiciona resposta do LLM com pensamento se disponível
      final llmMessage = ChatMessage(
        text: processedResponse.mainContent,
        isUser: false,
        timestamp: DateTime.now(),
        thinkingText: processedResponse.thinkingContent,
      );
      _messages.add(llmMessage);

      if (processedResponse.originalResponse.isError) {
        _setError(
            'Erro na resposta: ${processedResponse.originalResponse.content}');
      }
    } catch (e) {
      // Adiciona mensagem de erro
      final errorMessage = ChatMessage(
        text: 'Erro ao gerar resposta: $e',
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages.add(errorMessage);
      _setError('Erro ao gerar resposta: $e');
    } finally {
      _setLoading(false);
      _setThinking(false);
      _setSearching(false);
    }
  }

  Future<void> _handleStreamingResponse(
      String prompt, bool isThinkingModel) async {
    final contentBuffer = StringBuffer();
    bool isInThinkingMode = false;
    final thinkingBuffer = StringBuffer();
    ChatMessage? streamingMessage;
    int? messageIndex;

    try {
      await for (final chunk in _generateResponseStream(
        prompt: prompt,
        modelName: _selectedModel!.name,
      )) {
        if (chunk.contains('<think>')) {
          isInThinkingMode = true;
          _setThinking(true, '');
          final thinkStart = chunk.indexOf('<think>');
          if (thinkStart != -1) {
            // Adiciona conteúdo antes da tag <think>
            if (thinkStart > 0) {
              contentBuffer.write(chunk.substring(0, thinkStart));
            }
            // Começa a capturar pensamento
            final thinkContent = chunk.substring(thinkStart + 7);
            thinkingBuffer.write(thinkContent);
          }
        } else if (isInThinkingMode) {
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
                // Cria mensagem apenas quando há conteúdo real
                if (streamingMessage == null) {
                  streamingMessage = ChatMessage(
                    text: '',
                    isUser: false,
                    timestamp: DateTime.now(),
                  );
                  _messages.add(streamingMessage);
                  messageIndex = _messages.length - 1;
                }
              }
              isInThinkingMode = false;
            } else {
              thinkingBuffer.write(chunk);
            }
          } else {
            thinkingBuffer.write(chunk);
            // Throttling otimizado para reduzir flickering
            if (thinkingBuffer.length % 40 == 0 || thinkingBuffer.length < 50) {
              _setThinking(true, thinkingBuffer.toString());
            }
          }
        } else {
          contentBuffer.write(chunk);
          // Cria mensagem apenas quando há conteúdo real
          if (streamingMessage == null) {
            streamingMessage = ChatMessage(
              text: '',
              isUser: false,
              timestamp: DateTime.now(),
            );
            _messages.add(streamingMessage);
            messageIndex = _messages.length - 1;
          }
        }

        // Atualiza a mensagem apenas se ela foi criada
        if (streamingMessage != null && messageIndex != null) {
          _messages[messageIndex] = ChatMessage(
            text: contentBuffer.toString(),
            isUser: false,
            timestamp: streamingMessage.timestamp,
            thinkingText:
                thinkingBuffer.isNotEmpty ? thinkingBuffer.toString() : null,
          );
          _notifyListenersThrottled();
        }
      }

      // Garantir que a mensagem final tenha o pensamento completo
      if (thinkingBuffer.isNotEmpty &&
          messageIndex != null &&
          streamingMessage != null) {
        _messages[messageIndex] = ChatMessage(
          text: contentBuffer.toString(),
          isUser: false,
          timestamp: streamingMessage.timestamp,
          thinkingText: thinkingBuffer.toString(),
        );
        _notifyListenersThrottled();
      }
    } catch (e) {
      // Adiciona mensagem de erro
      final errorMessage = ChatMessage(
        text: 'Erro ao gerar resposta: $e',
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages.add(errorMessage);
      _setError('Erro ao gerar resposta: $e');
    } finally {
      _setLoading(false);
      _setThinking(false);
      _setSearching(false);
    }
  }

  Future<void> _performWebSearch(String query) async {
    _searchResults.clear();

    try {
      final searchQuery = SearchQuery(
        query: query,
        maxResults: 3,
      );

      debugPrint('Iniciando pesquisa web para: $query');
      final results = await _searchWeb(searchQuery);
      debugPrint('Pesquisa web retornou ${results.length} resultados');
      _searchResults.addAll(results);
    } catch (e) {
      debugPrint('Erro na pesquisa web: $e');
      // Não propagar o erro para não interromper o fluxo
    }
  }

  // Busca e armazena o conteúdo das páginas dos resultados de pesquisa
  Future<void> _fetchAndAttachWebContents() async {
    for (final result in _searchResults) {
      if (result.url.isNotEmpty && !_webPageContents.containsKey(result.url)) {
        try {
          final content = await _fetchWebContentFromUrl(result.url);
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

  /// Limpa todo o histórico do chat e dados relacionados.
  ///
  /// Remove todas as mensagens, resultados de pesquisa, cache de páginas web
  /// e limpa qualquer mensagem de erro ativa.
  void clearChat() {
    _messages.clear();
    _searchResults.clear();
    _webPageContents.clear();
    _setError(null);
    _notifyListenersThrottled();
  }

  /// Remove uma mensagem específica do chat pelo índice.
  ///
  /// [index] - Índice da mensagem a ser removida
  void removeMessage(int index) {
    if (index >= 0 && index < _messages.length) {
      _messages.removeAt(index);
      _notifyListenersThrottled();
    }
  }

  /// Limpa apenas os resultados de pesquisa e cache de páginas web.
  ///
  /// Mantém o histórico de mensagens intacto.
  void clearSearchResults() {
    _searchResults.clear();
    _webPageContents.clear();
    _notifyListenersThrottled();
  }

  /// Busca o conteúdo de uma página web usando o caso de uso apropriado.
  ///
  /// [url] - URL da página a ser processada
  ///
  /// Returns: Conteúdo da página ou string vazia se houver erro
  Future<String> _fetchWebContentFromUrl(String url) async {
    try {
      return await _fetchWebContent(url);
    } catch (e) {
      debugPrint('Erro ao buscar conteúdo da página $url: $e');
      return '';
    }
  }

  /// Implementa throttling otimizado para eliminar flickering.
  ///
  /// Durante operações de streaming, agrupa notificações em intervalos estáveis
  /// para melhorar a performance da UI e eliminar flickering.
  void _notifyListenersThrottled() {
    if (_isLoading && _streamEnabled) {
      // Throttling unificado mais estável para eliminar flickering
      const throttleDelay = 250; // Intervalo fixo mais estável

      // Só define nova notificação se não houver uma pendente
      if (!_hasPendingNotification) {
        _hasPendingNotification = true;
        _notificationTimer?.cancel();
        _notificationTimer =
            Timer(const Duration(milliseconds: throttleDelay), () {
          if (_hasPendingNotification) {
            _hasPendingNotification = false;
            notifyListeners();
          }
        });
      }
    } else {
      // Para operações não-streaming, notificar imediatamente
      _notificationTimer?.cancel();
      _hasPendingNotification = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }
}
