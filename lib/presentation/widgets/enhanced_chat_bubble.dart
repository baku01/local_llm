import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../domain/entities/chat_message.dart';
import '../theme/unified_theme.dart';
import 'advanced_markdown_widget.dart';

/// Enhanced chat bubble with advanced animations and micro-interactions
class EnhancedChatBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isTyping;
  final String? thinkingText;
  final bool showThinking;
  final VoidCallback? onCopy;
  final VoidCallback? onRegenerateResponse;

  const EnhancedChatBubble({
    super.key,
    required this.message,
    this.isTyping = false,
    this.thinkingText,
    this.showThinking = false,
    this.onCopy,
    this.onRegenerateResponse,
  });

  @override
  State<EnhancedChatBubble> createState() => _EnhancedChatBubbleState();
}

class _EnhancedChatBubbleState extends State<EnhancedChatBubble>
    with TickerProviderStateMixin {
  bool _isHovered = false;
  bool _animationCompleted = false;
  bool _isPressed = false;
  bool _showActionButtons = false;
  bool _isCopied = false;
  
  late AnimationController _entranceController;
  late AnimationController _hoverController;
  late AnimationController _pressController;
  late AnimationController _glowController;
  late AnimationController _bounceController;
  late AnimationController _shimmerController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _actionButtonAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startEntranceAnimation();
  }

  void _setupAnimations() {
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    ));

    _actionButtonAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _startEntranceAnimation() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        _entranceController.forward().then((_) {
          if (mounted) {
            setState(() => _animationCompleted = true);
            if (!widget.message.isUser) {
              _shimmerController.repeat(reverse: true);
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _hoverController.dispose();
    _pressController.dispose();
    _glowController.dispose();
    _bounceController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _handleHoverEnter() {
    if (_animationCompleted) {
      setState(() {
        _isHovered = true;
        _showActionButtons = !widget.message.isUser;
      });
      _hoverController.forward();
      _glowController.forward();
    }
  }

  void _handleHoverExit() {
    if (_animationCompleted) {
      setState(() {
        _isHovered = false;
        _showActionButtons = false;
      });
      _hoverController.reverse();
      _glowController.reverse();
    }
  }

  void _handleTapDown() {
    if (_animationCompleted) {
      setState(() => _isPressed = true);
      _pressController.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp() {
    if (_animationCompleted) {
      setState(() => _isPressed = false);
      _pressController.reverse();
    }
  }

  void _handleCopyMessage() {
    Clipboard.setData(ClipboardData(text: widget.message.text));
    _bounceController.forward().then((_) => _bounceController.reverse());
    HapticFeedback.mediumImpact();
    setState(() => _isCopied = true);
    
    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Mensagem copiada!'),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isCopied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = widget.message.isUser;

    return AnimatedBuilder(
      animation: Listenable.merge([_slideAnimation, _fadeAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: _slideAnimation.value * 20,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: RepaintBoundary(
              child: MouseRegion(
                onEnter: (_) => _handleHoverEnter(),
                onExit: (_) => _handleHoverExit(),
                child: GestureDetector(
                  onTapDown: (_) => _handleTapDown(),
                  onTapUp: (_) => _handleTapUp(),
                  onTapCancel: () => _handleTapUp(),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Stack(
                      children: [
                        Row(
                          mainAxisAlignment: isUser 
                              ? MainAxisAlignment.end 
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isUser) ...[
                              _buildEnhancedAvatar(context, false),
                              const SizedBox(width: 12),
                            ],
                            Flexible(
                              child: _buildMessageContainer(context, theme, isUser),
                            ),
                            if (isUser) ...[
                              const SizedBox(width: 12),
                              _buildEnhancedAvatar(context, true),
                            ],
                          ],
                        ),
                        if (_showActionButtons && !widget.message.isUser)
                          _buildActionButtons(context, theme),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageContainer(BuildContext context, ThemeData theme, bool isUser) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _scaleAnimation, 
        _glowAnimation, 
        _bounceAnimation,
        _pressController,
      ]),
      builder: (context, child) {
        final pressScale = _isPressed ? 0.98 : 1.0;
        final totalScale = _scaleAnimation.value * _bounceAnimation.value * pressScale;
        
        return Transform.scale(
          scale: totalScale,
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
                  ? _buildUserMessage(theme)
                  : _buildBotMessage(theme),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserMessage(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                .withValues(alpha: 0.25 + (_glowAnimation.value * 0.15)),
            blurRadius: _isHovered
                ? 20 + (_glowAnimation.value * 10)
                : 10,
            offset: Offset(
              0,
              _isHovered
                  ? 8 + (_glowAnimation.value * 4)
                  : 3,
            ),
            spreadRadius: _isHovered ? 2 + (_glowAnimation.value * 2) : 0,
          ),
          if (_glowAnimation.value > 0)
            BoxShadow(
              color: theme.colorScheme.secondary
                  .withValues(alpha: _glowAnimation.value * 0.3),
              blurRadius: 30 * _glowAnimation.value,
              spreadRadius: 5 * _glowAnimation.value,
            ),
        ],
      ),
      child: widget.isTyping
          ? _buildTypingIndicator(theme)
          : _buildMessageContent(context, Colors.white),
    );
  }

  Widget _buildBotMessage(ThemeData theme) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: AppTheme.glassEffect(
            isDark: theme.brightness == Brightness.dark,
            opacity: 0.15 + (_glowAnimation.value * 0.1),
            blur: _isHovered ? 12 + (_glowAnimation.value * 6) : 8,
          ).copyWith(
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary
                    .withValues(alpha: 0.1 + (_glowAnimation.value * 0.15)),
                blurRadius: 15 + (_glowAnimation.value * 10),
                offset: const Offset(0, 4),
                spreadRadius: _glowAnimation.value * 2,
              ),
              if (_glowAnimation.value > 0)
                BoxShadow(
                  color: theme.colorScheme.tertiary
                      .withValues(alpha: _glowAnimation.value * 0.2),
                  blurRadius: 25 * _glowAnimation.value,
                  spreadRadius: 3 * _glowAnimation.value,
                ),
              if (_shimmerController.isAnimating)
                BoxShadow(
                  color: theme.colorScheme.primary
                      .withValues(alpha: 0.1 * math.sin(_shimmerController.value * math.pi)),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: widget.isTyping
              ? _buildTypingIndicator(theme)
              : _buildMessageContent(context, null),
        );
      },
    );
  }

  Widget _buildEnhancedAvatar(BuildContext context, bool isUser) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
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
                    .withValues(alpha: 0.4 + (_glowAnimation.value * 0.2)),
                blurRadius: 12 + (_glowAnimation.value * 8),
                offset: const Offset(0, 4),
                spreadRadius: _glowAnimation.value * 2,
              ),
            ],
          ),
          child: Icon(
            isUser ? Icons.person_rounded : Icons.auto_awesome_rounded,
            size: 20,
            color: Colors.white,
          ),
        ).animate(
          onPlay: (controller) => controller.repeat(reverse: true),
        ).shimmer(
          duration: 2000.ms,
          color: Colors.white.withValues(alpha: 0.1),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    return Positioned(
      right: widget.message.isUser ? 60 : 0,
      top: 8,
      child: AnimatedBuilder(
        animation: _actionButtonAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _actionButtonAnimation.value,
            child: Transform.translate(
              offset: Offset((1 - _actionButtonAnimation.value) * 20, 0),
              child: Opacity(
                opacity: _actionButtonAnimation.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildActionButton(
                        icon: _isCopied ? Icons.check : Icons.content_copy_rounded,
                        onPressed: _handleCopyMessage,
                        theme: theme,
                        isActive: _isCopied,
                      ),
                      if (widget.onRegenerateResponse != null)
                        _buildActionButton(
                          icon: Icons.refresh_rounded,
                          onPressed: widget.onRegenerateResponse!,
                          theme: theme,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required ThemeData theme,
    bool isActive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 16,
            color: isActive 
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    ).animate()
      .scale(duration: 200.ms, curve: Curves.easeOutCubic)
      .then()
      .shimmer(duration: 1000.ms, color: theme.colorScheme.primary.withValues(alpha: 0.1));
  }

  Widget _buildMessageContent(BuildContext context, Color? textColor) {
    final theme = Theme.of(context);
    final isUser = widget.message.isUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        if (isUser)
          Text(
            widget.message.text,
            style: TextStyle(
              color: textColor ?? Colors.white,
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
          _buildTypingDot(0, theme),
          const SizedBox(width: 6),
          _buildTypingDot(1, theme),
          const SizedBox(width: 6),
          _buildTypingDot(2, theme),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index, ThemeData theme) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: widget.message.isUser 
            ? Colors.white.withValues(alpha: 0.8)
            : theme.colorScheme.primary,
        shape: BoxShape.circle,
      ),
    ).animate(
      onPlay: (controller) => controller.repeat(),
    ).scale(
      begin: const Offset(0.9, 0.9),
      end: const Offset(1.2, 1.2),
      duration: 800.ms,
      delay: Duration(milliseconds: index * 150),
      curve: Curves.easeInOut,
    ).then().scale(
      begin: const Offset(1.2, 1.2),
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
