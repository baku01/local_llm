/// Chat bubble com zero flickering usando streaming incremental de tokens.
/// 
/// Esta implementação garante que:
/// - Apenas novos tokens são adicionados ao widget
/// - Texto anterior permanece intocado
/// - Zero rebuilds do conteúdo existente
/// - Animação suave apenas para novos tokens
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/anti_flicker_llm_controller.dart';
import '../theme/unified_theme.dart';
import 'advanced_markdown_widget.dart';
import 'incremental_text_widget.dart';

/// Chat bubble que elimina completamente o flickering.
class ZeroFlickerChatBubble extends StatefulWidget {
  /// Mensagem de streaming otimizada
  final OptimizedStreamingMessage streamingMessage;
  
  /// Se deve mostrar animação de entrada
  final bool showEntryAnimation;
  
  /// Callback para copiar texto
  final VoidCallback? onCopy;

  const ZeroFlickerChatBubble({
    super.key,
    required this.streamingMessage,
    this.showEntryAnimation = true,
    this.onCopy,
  });

  @override
  State<ZeroFlickerChatBubble> createState() => _ZeroFlickerChatBubbleState();
}

class _ZeroFlickerChatBubbleState extends State<ZeroFlickerChatBubble>
    with TickerProviderStateMixin {
  
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isCopied = false;
  
  // Controllers para texto incremental
  late IncrementalTextController _contentController;
  late IncrementalTextController _thinkingController;
  
  // Animação para entrada suave
  late AnimationController _entryController;
  late Animation<double> _entryAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Inicializar controladores de texto incremental
    _contentController = IncrementalTextController();
    _thinkingController = IncrementalTextController();
    
    // Configurar animação de entrada
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _entryAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    
    // Conectar streams de tokens
    _setupTokenStreams();
    
    // Inicializar com conteúdo existente se houver
    _initializeContent();
    
    if (widget.showEntryAnimation) {
      _entryController.forward();
    } else {
      _entryController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _thinkingController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _setupTokenStreams() {
    // Stream de tokens de conteúdo
    widget.streamingMessage.contentTokenStream.listen(
      (token) {
        _contentController.addChunk(token);
      },
      onDone: () {
        _contentController.complete();
      },
    );
    
    // Stream de tokens de pensamento
    widget.streamingMessage.thinkingTokenStream.listen(
      (token) {
        _thinkingController.addChunk(token);
      },
      onDone: () {
        _thinkingController.complete();
      },
    );
  }

  void _initializeContent() {
    final currentContent = widget.streamingMessage.currentContent.value;
    final currentThinking = widget.streamingMessage.currentThinking.value;
    
    if (currentContent.isNotEmpty) {
      _contentController.setText(currentContent);
    }
    
    if (currentThinking.isNotEmpty) {
      _thinkingController.setText(currentThinking);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _entryAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * _entryAnimation.value),
            alignment: widget.streamingMessage.isUser 
                ? Alignment.centerRight 
                : Alignment.centerLeft,
            child: Opacity(
              opacity: _entryAnimation.value,
              child: _buildBubbleContent(theme, isDark),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBubbleContent(ThemeData theme, bool isDark) {
    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onLongPress: widget.streamingMessage.isUser ? null : _copyToClipboard,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.only(
            left: widget.streamingMessage.isUser ? 64 : 16,
            right: widget.streamingMessage.isUser ? 16 : 64,
            bottom: 12,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _getBubbleColor(theme, isDark),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.05),
                blurRadius: _isHovered ? 12 : 8,
                offset: Offset(0, _isHovered ? 4 : 2),
                spreadRadius: _isHovered ? 1 : 0,
              ),
            ],
            border: Border.all(
              color: _getBorderColor(theme, isDark),
              width: 1,
            ),
          ),
          transform: Matrix4.identity()
            ..translate(0.0, _isPressed ? 1.0 : _isHovered ? -1.0 : 0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.streamingMessage.isUser) ...[
                _buildUserContent(theme),
                const SizedBox(height: 4),
                _buildTimestamp(theme),
              ] else ...[
                _buildAIContent(theme),
                _buildThinkingSection(theme),
                const SizedBox(height: 8),
                _buildBottomRow(theme, isDark),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserContent(ThemeData theme) {
    return RepaintBoundary(
      child: IncrementalTextWidget(
        controller: _contentController,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          height: 1.4,
        ),
        showCursor: false, // Usuário não precisa de cursor
        animateNewTokens: false, // Usuário não precisa de animação
      ),
    );
  }

  Widget _buildAIContent(ThemeData theme) {
    return RepaintBoundary(
      child: ValueListenableBuilder<bool>(
        valueListenable: widget.streamingMessage.isComplete,
        builder: (context, isComplete, child) {
          if (isComplete) {
            // Quando completo, mostrar markdown renderizado
            return AdvancedMarkdownWidget(
              data: widget.streamingMessage.currentContent.value,
              selectable: true,
            );
          } else {
            // Durante streaming, mostrar texto incremental
            return IncrementalTextWidget(
              controller: _contentController,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: theme.colorScheme.onSurface,
              ),
              showCursor: true,
              cursorColor: theme.colorScheme.primary,
              animateNewTokens: true,
            );
          }
        },
      ),
    );
  }

  Widget _buildThinkingSection(ThemeData theme) {
    return RepaintBoundary(
      child: ValueListenableBuilder<String>(
        valueListenable: widget.streamingMessage.currentThinking,
        builder: (context, thinking, child) {
          if (thinking.isEmpty) return const SizedBox.shrink();
          
          return Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.psychology_outlined,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Pensamento',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Texto de pensamento incremental - ZERO FLICKERING!
                IncrementalTextWidget(
                  controller: _thinkingController,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                    height: 1.3,
                    fontFamily: 'monospace',
                  ),
                  showCursor: !widget.streamingMessage.isComplete.value,
                  cursorColor: theme.colorScheme.primary.withValues(alpha: 0.7),
                  animateNewTokens: true,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomRow(ThemeData theme, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildTimestamp(theme),
        if (_isHovered && !widget.streamingMessage.isUser)
          _buildCopyButton(theme, isDark),
      ],
    );
  }

  Widget _buildTimestamp(ThemeData theme) {
    return Text(
      _formatTime(widget.streamingMessage.timestamp),
      style: TextStyle(
        color: widget.streamingMessage.isUser 
            ? Colors.white.withValues(alpha: 0.7) 
            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
        fontSize: 12,
      ),
    );
  }

  Widget _buildCopyButton(ThemeData theme, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: _copyToClipboard,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isCopied ? Icons.check : Icons.copy,
                size: 14,
                color: _isCopied 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              if (_isCopied) ...[
                const SizedBox(width: 4),
                Text(
                  'Copiado',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getBubbleColor(ThemeData theme, bool isDark) {
    if (widget.streamingMessage.isUser) {
      return theme.colorScheme.primary;
    } else {
      return _isHovered 
          ? (isDark ? AppTheme.kDarkSurface : AppTheme.kLightSurface)
          : (isDark ? AppTheme.kDarkCardBg : AppTheme.kLightCardBg);
    }
  }

  Color _getBorderColor(ThemeData theme, bool isDark) {
    if (widget.streamingMessage.isUser) {
      return Colors.transparent;
    } else {
      return _isHovered 
          ? theme.colorScheme.primary.withValues(alpha: 0.3)
          : theme.colorScheme.outline.withValues(alpha: 0.2);
    }
  }

  void _setHovered(bool hovered) {
    if (_isHovered != hovered) {
      setState(() => _isHovered = hovered);
    }
  }

  void _copyToClipboard() {
    final content = widget.streamingMessage.currentContent.value;
    if (content.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: content));
      setState(() => _isCopied = true);
      HapticFeedback.lightImpact();
      
      widget.onCopy?.call();
      
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _isCopied = false);
        }
      });
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}