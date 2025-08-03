/// Biblioteca que define o widget de animação de "pensamento" da IA.
/// 
/// Esta biblioteca contém o widget [ThinkingAnimation] que exibe
/// uma animação visual indicando que a IA está processando uma resposta,
/// com efeitos shimmer, rotação e texto dinâmico.
/// Otimizado para reduzir flickering e rebuilds excessivos.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';

/// Widget que exibe uma animação de "pensamento" da IA.
/// 
/// Este widget mostra uma animação visual elegante quando a IA está
/// processando uma resposta, incluindo:
/// - Texto de status dinâmico
/// - Efeitos shimmer e rotação
/// - Transições suaves de entrada/saída
/// - Opção de dismissão pelo usuário
/// 
/// Exemplo de uso:
/// ```dart
/// ThinkingAnimation(
///   thinkingText: 'Analisando sua pergunta...',
///   isVisible: isAIThinking,
///   onDismiss: () => setState(() => isAIThinking = false),
/// )
/// ```
class ThinkingAnimation extends StatefulWidget {
  final String thinkingText;
  final bool isVisible;
  final VoidCallback? onDismiss;

  const ThinkingAnimation({
    super.key,
    required this.thinkingText,
    required this.isVisible,
    this.onDismiss,
  });

  @override
  State<ThinkingAnimation> createState() => _ThinkingAnimationState();
}

class _ThinkingAnimationState extends State<ThinkingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _textController;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.08),
            theme.colorScheme.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with enhanced animation
          Row(
            children: [
              RepaintBoundary(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: NeuralLatticePainter(
                          progress: _controller.value,
                          color: theme.colorScheme.primary,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Shimmer.fromColors(
                      baseColor: theme.colorScheme.primary.withValues(alpha: 0.6),
                      highlightColor: theme.colorScheme.primary,
                      child: Text(
                        'Processando pensamento...',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: _textController,
                        builder: (context, child) {
                          final dotCount = (_textController.value * 4).floor() % 4;
                          final dots = '.' * dotCount;
                          return Text(
                            'Analisando contexto$dots',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Enhanced thinking text display with typewriter effect
          if (widget.thinkingText.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: _TypewriterText(
                text: _cleanThinkingText(widget.thinkingText),
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  height: 1.5,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0).scale(
      begin: const Offset(0.95, 0.95),
      end: const Offset(1.0, 1.0),
      curve: Curves.easeOutBack,
    );
  }

  String _cleanThinkingText(String text) {
    return text.replaceAll('<think>', '').replaceAll('</think>', '').trim();
  }
}

/// Widget que cria um efeito de máquina de escrever para o texto.
class _TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const _TypewriterText({
    required this.text,
    this.style,
  });

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText>
    with TickerProviderStateMixin {
  late AnimationController _typewriterController;
  late AnimationController _cursorController;
  String _displayedText = '';
  String _previousText = '';

  @override
  void initState() {
    super.initState();
    _typewriterController = AnimationController(
      duration: Duration(milliseconds: widget.text.length * 15 + 300),
      vsync: this,
    );
    
    _cursorController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _updateText();
  }

  @override
  void didUpdateWidget(_TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text && widget.text != _previousText) {
      _updateText();
    }
  }

  void _updateText() {
    if (widget.text != _previousText && widget.text.isNotEmpty) {
      _previousText = widget.text;
      _typewriterController.reset();
      _cursorController.stop();
      
      // Usar ValueNotifier para evitar setState excessivos
      final animation = Tween<double>(
        begin: _displayedText.length.toDouble(),
        end: widget.text.length.toDouble(),
      ).animate(CurvedAnimation(
        parent: _typewriterController,
        curve: Curves.easeOut,
      ));

      // Throttle de atualizações para reduzir flickering
      DateTime lastUpdate = DateTime.now();
      animation.addListener(() {
        final now = DateTime.now();
        if (now.difference(lastUpdate).inMilliseconds < 50) return; // Throttle de 50ms
        lastUpdate = now;
        
        final charCount = animation.value.floor().clamp(0, widget.text.length);
        if (mounted) {
          setState(() {
            _displayedText = widget.text.substring(0, charCount);
          });
        }
      });

      _typewriterController.forward().then((_) {
        if (mounted) {
          _cursorController.repeat(reverse: true);
        }
      });
    } else if (widget.text.isEmpty) {
      setState(() {
        _displayedText = '';
        _previousText = '';
      });
    }
  }

  @override
  void dispose() {
    _typewriterController.dispose();
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_typewriterController, _cursorController]),
        builder: (context, child) {
          final shouldShowCursor = _typewriterController.isAnimating || _cursorController.isAnimating;
          final cursorOpacity = _typewriterController.isAnimating 
              ? 0.9 
              : _cursorController.value;
          
          return RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: _displayedText,
                  style: widget.style,
                ),
                if (shouldShowCursor)
                  TextSpan(
                    text: '|',
                    style: widget.style?.copyWith(
                      color: widget.style?.color?.withValues(alpha: cursorOpacity),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ThinkingIndicator extends StatefulWidget {
  final bool isThinking;

  const ThinkingIndicator({super.key, required this.isThinking});

  @override
  State<ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<ThinkingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    if (widget.isThinking) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ThinkingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isThinking && !oldWidget.isThinking) {
      _controller.repeat();
    } else if (!widget.isThinking && oldWidget.isThinking) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: 24,
      height: 24,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: ThinkingDotsPainter(
              progress: _controller.value,
              color: theme.colorScheme.primary,
            ),
          );
        },
      ),
    );
  }
}

class NeuralLatticePainter extends CustomPainter {
  final double progress;
  final Color color;

  NeuralLatticePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final nodePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    // Draw neural nodes
    const nodeCount = 6;
    final nodes = <Offset>[];

    for (int i = 0; i < nodeCount; i++) {
      final angle = (i / nodeCount) * 2 * math.pi + progress * 2 * math.pi;
      final nodeRadius =
          radius * (0.7 + 0.3 * math.sin(progress * 2 * math.pi + i));
      final offset = Offset(
        center.dx + nodeRadius * math.cos(angle),
        center.dy + nodeRadius * math.sin(angle),
      );
      nodes.add(offset);

      // Draw pulsing nodes
      final nodeSize = 2.0 + math.sin(progress * 4 * math.pi + i) * 1.0;
      canvas.drawCircle(offset, nodeSize, nodePaint);
    }

    // Draw connections between nodes with animated opacity
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final connectionProgress = (progress + i * 0.1 + j * 0.1) % 1.0;
        final opacity = (math.sin(connectionProgress * math.pi * 2) + 1) / 2;

        paint.color = color.withValues(alpha: opacity * 0.6);
        canvas.drawLine(nodes[i], nodes[j], paint);
      }
    }

    // Draw central pulsing core
    final coreRadius = 3.0 + math.sin(progress * 4 * math.pi) * 2.0;
    canvas.drawCircle(center, coreRadius, nodePaint);
  }

  @override
  bool shouldRepaint(NeuralLatticePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class ThinkingDotsPainter extends CustomPainter {
  final double progress;
  final Color color;

  ThinkingDotsPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const dotCount = 3;
    final dotRadius = size.width * 0.08;
    final spacing = size.width * 0.25;
    final startX = (size.width - (dotCount - 1) * spacing) / 2;

    for (int i = 0; i < dotCount; i++) {
      final delay = i * 0.2;
      final dotProgress = ((progress - delay) % 1.0).clamp(0.0, 1.0);
      final opacity = (math.sin(dotProgress * math.pi * 2) + 1) / 2;
      final scale = 0.5 + 0.5 * opacity;

      paint.color = color.withValues(alpha: opacity);

      final center = Offset(startX + i * spacing, size.height / 2);

      canvas.drawCircle(center, dotRadius * scale, paint);
    }
  }

  @override
  bool shouldRepaint(ThinkingDotsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
