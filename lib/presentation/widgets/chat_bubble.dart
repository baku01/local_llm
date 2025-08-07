import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../../domain/entities/chat_message.dart';
import '../theme/unified_theme.dart';
import 'advanced_markdown_widget.dart';

class ChatBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isTyping;
  final String? thinkingText;
  final bool showThinking;

  const ChatBubble({
    super.key,
    required this.message,
    this.isTyping = false,
    this.thinkingText,
    this.showThinking = false,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> with TickerProviderStateMixin {
  bool _isHovered = false;
  bool _animationCompleted = false;
  late AnimationController _scaleController;
  late AnimationController _shimmerController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    // Marcar animação como completada após delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _animationCompleted = true);
        if (!widget.message.isUser && widget.message.text.isNotEmpty) {
          _shimmerController.forward();
        }
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = widget.message.isUser;

    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) {
          if (_animationCompleted) {
            setState(() => _isHovered = true);
            _scaleController.forward();
          }
        },
        onExit: (_) {
          if (_animationCompleted) {
            setState(() => _isHovered = false);
            _scaleController.reverse();
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                _buildModernAvatar(context, false),
                const SizedBox(width: 12),
              ],
              Flexible(
                child: AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24).copyWith(
                            bottomLeft: isUser
                                ? const Radius.circular(24)
                                : const Radius.circular(8),
                            bottomRight: isUser
                                ? const Radius.circular(8)
                                : const Radius.circular(24),
                          ),
                          child: isUser
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        theme.colorScheme.primary,
                                        theme.colorScheme.secondary,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.25),
                                        blurRadius:
                                            _animationCompleted && _isHovered
                                                ? 16
                                                : 10,
                                        offset: Offset(
                                            0,
                                            _animationCompleted && _isHovered
                                                ? 6
                                                : 3),
                                        spreadRadius:
                                            _animationCompleted && _isHovered
                                                ? 1
                                                : 0,
                                      ),
                                    ],
                                  ),
                                  child: widget.isTyping
                                      ? _buildTypingIndicator(theme)
                                      : _buildMessageContent(context),
                                )
                              : BackdropFilter(
                                  filter:
                                      ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 16),
                                    decoration: AppTheme.glassEffect(
                                      isDark:
                                          theme.brightness == Brightness.dark,
                                      opacity: 0.15,
                                      blur: _animationCompleted && _isHovered
                                          ? 12
                                          : 8,
                                    ),
                                    child: widget.isTyping
                                        ? _buildTypingIndicator(theme)
                                        : _buildMessageContent(context),
                                  ),
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 12),
                _buildModernAvatar(context, true),
              ],
            ],
          ),
        ),
      ),
    )
        .animate(
          onPlay: (controller) => controller.forward(from: 0),
        )
        .fadeIn(
          duration: 300.ms,
          curve: Curves.easeOut,
        )
        .slideY(
          begin: 0.2,
          end: 0,
          duration: 300.ms,
          curve: Curves.easeOut,
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
            color: (isUser
                    ? theme.colorScheme.primary
                    : theme.colorScheme.tertiary)
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

  Widget _buildMessageContent(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = widget.message.isUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Exibir pensamento se disponível e for modelo R1
        if (widget.showThinking &&
            widget.thinkingText != null &&
            widget.thinkingText!.isNotEmpty) ...[
          RepaintBoundary(
            child: Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
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
                        Icons.psychology_rounded,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Processo de Pensamento',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AdvancedMarkdownWidget(
                    data: widget.thinkingText!,
                    selectable: true,
                  ),
                ],
              ),
            ),
          ),
        ],
        // Conteúdo principal da mensagem
        if (isUser)
          Text(
            widget.message.text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          )
        else
          AdvancedMarkdownWidget(
            data: widget.message.text,
            selectable: true,
          ),
        const SizedBox(height: 8),
        Text(
          _formatTime(widget.message.timestamp),
          style: TextStyle(
            color: isUser
                ? Colors.white.withValues(alpha: 0.7)
                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator(ThemeData theme) {
    return RepaintBoundary(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDot(0, theme),
          const SizedBox(width: 6),
          _buildDot(1, theme),
          const SizedBox(width: 6),
          _buildDot(2, theme),
        ],
      ),
    );
  }

  Widget _buildDot(int index, ThemeData theme) {
    return RepaintBoundary(
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
        ),
      ),
    )
        .animate(
          onPlay: (controller) => controller.repeat(),
        )
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1.1, 1.1),
          duration: 800.ms,
          delay: Duration(milliseconds: index * 150),
          curve: Curves.easeInOut,
        )
        .then()
        .scale(
          begin: const Offset(1.1, 1.1),
          end: const Offset(0.9, 0.9),
          duration: 800.ms,
          curve: Curves.easeInOut,
        );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Agora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}
