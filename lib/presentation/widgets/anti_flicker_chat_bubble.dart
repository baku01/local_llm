/// Widget de chat bubble otimizado para eliminar flickering durante streaming.
/// 
/// Implementa técnicas avançadas de otimização:
/// - ValueNotifier para updates isolados
/// - Debounce de atualizações de texto
/// - RepaintBoundary para evitar rebuilds desnecessários
/// - Separação de streams para conteúdo e pensamento
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/chat_message.dart';
import '../theme/unified_theme.dart';
import 'advanced_markdown_widget.dart';
import 'optimized_thinking_widget.dart';

/// Chat bubble otimizado para streaming sem flickering.
class AntiFlickerChatBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isTyping;
  final Stream<String>? contentStream;
  final Stream<String>? thinkingStream;
  final bool showThinking;

  const AntiFlickerChatBubble({
    super.key,
    required this.message,
    this.isTyping = false,
    this.contentStream,
    this.thinkingStream,
    this.showThinking = false,
  });

  @override
  State<AntiFlickerChatBubble> createState() => _AntiFlickerChatBubbleState();
}

class _AntiFlickerChatBubbleState extends State<AntiFlickerChatBubble>
    with TickerProviderStateMixin {
  
  // ValueNotifiers para updates isolados
  late final ValueNotifier<String> _contentNotifier;
  late final ValueNotifier<String> _thinkingNotifier;
  late final ValueNotifier<bool> _isStreamingNotifier;
  
  // Controladores de animação
  late final AnimationController _cursorController;
  late final AnimationController _hoverController;
  
  // Timers para debounce
  Timer? _contentDebounceTimer;
  Timer? _thinkingDebounceTimer;
  
  // Buffers para acumular chunks
  final StringBuffer _contentBuffer = StringBuffer();
  final StringBuffer _thinkingBuffer = StringBuffer();
  
  // Subscriptions dos streams
  StreamSubscription<String>? _contentSubscription;
  StreamSubscription<String>? _thinkingSubscription;
  
  // Estado de hover
  bool _isHovered = false;
  
  // Configurações de debounce
  static const Duration _contentDebounceDuration = Duration(milliseconds: 50);
  static const Duration _thinkingDebounceDuration = Duration(milliseconds: 100);
  
  @override
  void initState() {
    super.initState();
    
    // Inicializar ValueNotifiers
    _contentNotifier = ValueNotifier<String>(widget.message.text);
    _thinkingNotifier = ValueNotifier<String>(widget.message.thinkingText ?? '');
    _isStreamingNotifier = ValueNotifier<bool>(widget.contentStream != null);
    
    // Inicializar controladores de animação
    _cursorController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    // Configurar streams se disponíveis
    _setupStreams();
  }
  
  void _setupStreams() {
    // Stream de conteúdo
    if (widget.contentStream != null) {
      _isStreamingNotifier.value = true;
      _cursorController.repeat(reverse: true);
      
      _contentSubscription = widget.contentStream!.listen(
        _onContentChunk,
        onDone: _onContentStreamComplete,
        onError: _onStreamError,
      );
    }
    
    // Stream de pensamento
    if (widget.thinkingStream != null) {
      _thinkingSubscription = widget.thinkingStream!.listen(
        _onThinkingChunk,
        onDone: _onThinkingStreamComplete,
        onError: _onStreamError,
      );
    }
  }
  
  void _onContentChunk(String chunk) {
    _contentBuffer.write(chunk);
    
    // Debounce das atualizações de conteúdo
    _contentDebounceTimer?.cancel();
    _contentDebounceTimer = Timer(_contentDebounceDuration, () {
      if (mounted) {
        _contentNotifier.value = _contentBuffer.toString();
      }
    });
  }
  
  void _onThinkingChunk(String chunk) {
    _thinkingBuffer.write(chunk);
    
    // Debounce das atualizações de pensamento
    _thinkingDebounceTimer?.cancel();
    _thinkingDebounceTimer = Timer(_thinkingDebounceDuration, () {
      if (mounted) {
        _thinkingNotifier.value = _thinkingBuffer.toString();
      }
    });
  }
  
  void _onContentStreamComplete() {
    _contentDebounceTimer?.cancel();
    if (mounted) {
      _contentNotifier.value = _contentBuffer.toString();
      _isStreamingNotifier.value = false;
      _cursorController.stop();
    }
  }
  
  void _onThinkingStreamComplete() {
    _thinkingDebounceTimer?.cancel();
    if (mounted) {
      _thinkingNotifier.value = _thinkingBuffer.toString();
    }
  }
  
  void _onStreamError(dynamic error) {
    debugPrint('Stream error: $error');
    if (mounted) {
      _isStreamingNotifier.value = false;
      _cursorController.stop();
    }
  }
  
  @override
  void dispose() {
    _contentDebounceTimer?.cancel();
    _thinkingDebounceTimer?.cancel();
    _contentSubscription?.cancel();
    _thinkingSubscription?.cancel();
    
    _contentNotifier.dispose();
    _thinkingNotifier.dispose();
    _isStreamingNotifier.dispose();
    
    _cursorController.dispose();
    _hoverController.dispose();
    
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = widget.message.isUser;
    
    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => _onHoverChanged(true),
        onExit: (_) => _onHoverChanged(false),
        child: AnimatedBuilder(
          animation: _hoverController,
          builder: (context, child) {
            return Container(
              margin: EdgeInsets.only(
                left: isUser ? 50 : 0,
                right: isUser ? 0 : 50,
                bottom: 16,
              ),
              child: Row(
                mainAxisAlignment: isUser 
                    ? MainAxisAlignment.end 
                    : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser) ...[
                    _buildModernAvatar(context, false),
                    const SizedBox(width: 12),
                  ],
                  Flexible(
                    child: _buildMessageContainer(context, theme, isUser),
                  ),
                  if (isUser) ...[
                    const SizedBox(width: 12),
                    _buildModernAvatar(context, true),
                  ],
                ],
              ),
            );
          },
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(
        begin: 0.3,
        end: 0,
        duration: 400.ms,
        curve: Curves.easeOutCubic,
      ),
    );
  }
  
  void _onHoverChanged(bool isHovered) {
    if (_isHovered != isHovered) {
      setState(() {
        _isHovered = isHovered;
      });
      
      if (isHovered) {
        _hoverController.forward();
      } else {
        _hoverController.reverse();
      }
    }
  }
  
  Widget _buildMessageContainer(BuildContext context, ThemeData theme, bool isUser) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: _buildContainerDecoration(theme, isUser),
      child: widget.isTyping 
          ? _buildTypingIndicator(theme) 
          : _buildOptimizedMessageContent(context),
    );
  }
  
  BoxDecoration _buildContainerDecoration(ThemeData theme, bool isUser) {
    if (isUser) {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: _isHovered ? 20 : 12,
            offset: Offset(0, _isHovered ? 8 : 4),
            spreadRadius: _isHovered ? 2 : 0,
          ),
        ],
      );
    } else {
      return AppTheme.glassEffect(
        isDark: theme.brightness == Brightness.dark,
        opacity: 0.15,
        blur: _isHovered ? 15 : 10,
      ).copyWith(
        borderRadius: BorderRadius.circular(20),
      );
    }
  }
  
  Widget _buildOptimizedMessageContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Seção de pensamento otimizada
        if (widget.showThinking) 
          _buildOptimizedThinkingSection(context),
        
        // Conteúdo principal otimizado
        _buildOptimizedContentSection(context),
      ],
    );
  }
  
  Widget _buildOptimizedThinkingSection(BuildContext context) {
    return OptimizedThinkingWidget(
      thinkingNotifier: _thinkingNotifier,
      isVisible: true,
      debounceDuration: const Duration(milliseconds: 150), // Debounce mais longo para evitar flickering
    );
  }
  
  Widget _buildOptimizedContentSection(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = widget.message.isUser;
    
    return ValueListenableBuilder<String>(
      valueListenable: _contentNotifier,
      builder: (context, content, child) {
        return RepaintBoundary(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: isUser
                    ? Text(
                        content,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      )
                    : AdvancedMarkdownWidget(
                        data: content,
                        selectable: true,
                      ),
              ),
              // Cursor animado para streaming
              ValueListenableBuilder<bool>(
                valueListenable: _isStreamingNotifier,
                builder: (context, isStreaming, child) {
                  if (!isStreaming) return const SizedBox.shrink();
                  
                  return AnimatedBuilder(
                    animation: _cursorController,
                    builder: (context, child) {
                      return Container(
                        width: 2,
                        height: 16,
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          color: (isUser ? Colors.white : theme.colorScheme.primary)
                              .withValues(alpha: _cursorController.value),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildTypingIndicator(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Pensando...',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
  
  Widget _buildModernAvatar(BuildContext context, bool isUser) {
    final theme = Theme.of(context);
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: isUser 
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.tertiary,
                  theme.colorScheme.primary,
                ],
              ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isUser ? theme.colorScheme.primary : theme.colorScheme.tertiary)
                .withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        isUser ? Icons.person_rounded : Icons.auto_awesome_rounded,
        size: 20,
        color: Colors.white,
      ),
    );
  }
}