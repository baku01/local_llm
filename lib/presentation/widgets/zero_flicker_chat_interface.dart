/// Interface de chat com zero flickering usando streaming incremental.
/// 
/// Implementa:
/// - ListView otimizada com keys estáveis
/// - Widgets que apenas adicionam tokens novos
/// - Zero rebuilds do conteúdo existente
/// - Performance máxima durante streaming
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../controllers/anti_flicker_llm_controller.dart';
import 'zero_flicker_chat_bubble.dart';
import 'animated_logo.dart';

/// Interface de chat que elimina completamente o flickering.
class ZeroFlickerChatInterface extends StatefulWidget {
  /// Controller anti-flickering
  final AntiFlickerLlmController controller;
  
  /// Controlador do campo de texto
  final TextEditingController textController;
  
  /// Callback para enviar mensagem
  final VoidCallback onSendMessage;

  const ZeroFlickerChatInterface({
    super.key,
    required this.controller,
    required this.textController,
    required this.onSendMessage,
  });

  @override
  State<ZeroFlickerChatInterface> createState() => _ZeroFlickerChatInterfaceState();
}

class _ZeroFlickerChatInterfaceState extends State<ZeroFlickerChatInterface> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    
    // Auto-scroll quando novas mensagens chegarem
    widget.controller.addListener(_autoScrollToBottom);
  }
  
  @override
  void dispose() {
    widget.controller.removeListener(_autoScrollToBottom);
    _scrollController.dispose();
    super.dispose();
  }
  
  void _autoScrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          Expanded(
            child: _buildOptimizedMessageList(context),
          ),
          _buildOptimizedStatusIndicators(context),
          _buildInputArea(context),
        ],
      ),
    );
  }

  Widget _buildOptimizedMessageList(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        final streamingMessages = widget.controller.streamingMessages;
        
        if (streamingMessages.isEmpty) {
          return _buildEmptyState(context);
        }
        
        return RepaintBoundary(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: streamingMessages.length,
            // Key estável baseada no ID da mensagem - ESSENCIAL para zero flickering
            itemBuilder: (context, index) {
              final streamingMessage = streamingMessages[index];
              
              return ZeroFlickerChatBubble(
                key: ValueKey(streamingMessage.id), // Key estável!
                streamingMessage: streamingMessage,
                showEntryAnimation: index == streamingMessages.length - 1, // Apenas última mensagem anima
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildOptimizedStatusIndicators(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return RepaintBoundary(
          child: Column(
            children: [
              // Indicador de carregamento
              if (widget.controller.isLoading)
                _buildLoadingIndicator(context),
              
              // Indicador de pesquisa
              if (widget.controller.isSearching)
                _buildSearchingIndicator(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Gerando resposta...',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildSearchingIndicator(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Pesquisando na web...',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildInputArea(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -3),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                    spreadRadius: -3,
                  ),
                ],
              ),
              child: TextField(
                controller: widget.textController,
                maxLines: null,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Digite sua mensagem...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 16,
                  ),
                ),
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: theme.colorScheme.onSurface,
                ),
                onSubmitted: (_) => widget.onSendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _buildOptimizedSendButton(context),
        ],
      ),
    );
  }

  Widget _buildOptimizedSendButton(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        final isLoading = widget.controller.isLoading;
        
        return GestureDetector(
          onTap: isLoading ? null : widget.onSendMessage,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: isLoading 
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
              color: isLoading 
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                  : null,
              borderRadius: BorderRadius.circular(20),
              boxShadow: isLoading ? null : [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                  spreadRadius: -3,
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isLoading
                  ? SizedBox(
                      key: const ValueKey('loading'),
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      key: const ValueKey('send'),
                      Icons.send_rounded,
                      size: 22,
                      color: Colors.white,
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 64,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 1),
                  AnimatedLogo(
                    size: 100, 
                    color: theme.colorScheme.primary, 
                    showIntro: true
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Local LLM Chat',
                    style: TextStyle(
                      fontSize: 28,
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  )
                  .animate()
                  .fadeIn(duration: 800.ms, delay: 400.ms)
                  .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                  const SizedBox(height: 12),
                  Text(
                    'Converse com modelos de IA localmente',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  )
                  .animate()
                  .fadeIn(duration: 800.ms, delay: 600.ms)
                  .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}