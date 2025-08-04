import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';

import '../providers/app_providers.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/llm_model.dart';
import '../controllers/llm_controller.dart';
import '../theme/unified_theme.dart';

class ChatInputField extends ConsumerStatefulWidget {
  const ChatInputField({super.key});

  @override
  ConsumerState<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends ConsumerState<ChatInputField> {
  late final TextEditingController _controller;
  bool _isEmpty = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final isEmpty = _controller.text.trim().isEmpty;
    if (_isEmpty != isEmpty) {
      setState(() {
        _isEmpty = isEmpty;
      });
      ref.read(isTextFieldEmptyProvider.notifier).state = isEmpty;
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final selectedModel = ref.read(selectedModelProvider);
    if (selectedModel == null) {
      _showNoModelSelectedSnackBar();
      return;
    }

    // Adicionar mensagem do usuário
    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    ref.read(chatMessagesProvider.notifier).addMessage(userMessage);
    _controller.clear();

    // Usar o controlador LLM integrado
    _generateLLMResponse(text, selectedModel.name);
  }

  void _generateLLMResponse(String userMessage, String modelName) async {
    ref.read(isReplyingProvider.notifier).state = true;

    try {
      final llmController = ref.read(llmControllerProvider);

      // Garantir que o modelo selecionado esteja sincronizado
      final selectedModel = ref.read(selectedModelProvider);
      if (selectedModel != null) {
        // Converter LLMModel para LlmModel (domain)
        final domainModel = LlmModel(
          name: selectedModel.name,
          description: selectedModel.name,
          modifiedAt: selectedModel.modifiedAt,
          size: null, // Será calculado pelo controller se necessário
        );
        llmController.selectModel(domainModel);
        debugPrint('Modelo selecionado: ${selectedModel.name}');
      } else {
        debugPrint('Nenhum modelo selecionado no provider');
        _showNoModelSelectedSnackBar();
        return;
      }

      // Sincronizar configurações
      final webSearchEnabled = ref.read(webSearchEnabledProvider);
      final streamModeEnabled = ref.read(streamModeEnabledProvider);

      debugPrint('Web search enabled: $webSearchEnabled');
      debugPrint('Stream mode enabled: $streamModeEnabled');

      llmController.toggleWebSearch(webSearchEnabled);
      llmController.toggleStreamMode(streamModeEnabled);

      // Usar o método sendMessage do controller que já integra webscraping
      await llmController.sendMessage(userMessage);

      // Sincronizar mensagens do controller com o provider
      _syncMessagesFromController(llmController);
    } catch (e) {
      debugPrint('Erro ao gerar resposta LLM: $e');
      // Em caso de erro, mostrar mensagem de erro
      final errorMessage = ChatMessage(
        text: 'Erro ao gerar resposta: $e',
        isUser: false,
        timestamp: DateTime.now(),
      );
      ref.read(chatMessagesProvider.notifier).addMessage(errorMessage);
    } finally {
      ref.read(isReplyingProvider.notifier).state = false;
    }
  }

  void _syncMessagesFromController(LlmController controller) {
    // Limpar mensagens atuais e sincronizar com o controller
    ref.read(chatMessagesProvider.notifier).clearMessages();

    for (final message in controller.messages) {
      ref.read(chatMessagesProvider.notifier).addMessage(message);
    }
  }

  void _showNoModelSelectedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Por favor, selecione um modelo primeiro'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isReplying = ref.watch(isReplyingProvider);
    final suggestionText = ref.watch(suggestionTextProvider);

    // Aplicar sugestão quando disponível
    if (suggestionText.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.text = suggestionText;
        ref.read(suggestionTextProvider.notifier).state = '';
      });
    }

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.glassEffect(
            isDark: theme.brightness == Brightness.dark,
            opacity: 0.1,
            blur: 20,
          ).copyWith(
            border: Border(
              top: BorderSide(color:
                  theme.colorScheme.outline.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: AppTheme.glassEffect(
                        isDark: theme.brightness == Brightness.dark,
                        opacity: 0.2,
                        blur: 10,
                      ).copyWith(
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color:
                              theme.colorScheme.outline.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _controller,
                        enabled: !isReplying,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.4,
                          color: theme.colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Digite sua mensagem...',
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              RepaintBoundary(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: (_isEmpty || isReplying)
                        ? null
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary,
                            ],
                          ),
                    color: (_isEmpty || isReplying)
                        ? theme.colorScheme.surface
                        : null,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: (_isEmpty || isReplying)
                        ? null
                        : [
                            BoxShadow(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: IconButton(
                    onPressed: (_isEmpty || isReplying) ? null : _sendMessage,
                    icon: isReplying
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          )
                        : Icon(
                            Icons.send_rounded,
                            color: (_isEmpty || isReplying)
                                ? theme.colorScheme.onSurface
                                    .withValues(alpha: 0.3)
                                : Colors.white,
                            size: 24,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
