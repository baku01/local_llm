/// Biblioteca que define o widget de animação de "pensamento" da IA.
///
/// Esta biblioteca contém o widget [ThinkingAnimation] que exibe
/// uma animação visual indicando que a IA está processando uma resposta,
/// com efeitos shimmer, rotação e texto dinâmico.
/// Otimizado para eliminar flickering e rebuilds excessivos.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'elegant_loading_widget.dart';

/// Widget que exibe uma animação de "pensamento" da IA otimizada.
///
/// Versão otimizada que elimina flickering através de:
/// - Throttling estável de atualizações
/// - Uso de ValueNotifier para reduzir rebuilds
/// - RepaintBoundary estratégicos
/// - Animações mais suaves e controladas
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
  late AnimationController _neuralController;
  late AnimationController _fadeController;
  late ValueNotifier<String> _textNotifier;

  String _lastText = '';
  bool _wasVisible = false;

  @override
  void initState() {
    super.initState();

    _neuralController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _textNotifier = ValueNotifier<String>('');

    if (widget.isVisible) {
      _show();
    }
  }

  @override
  void didUpdateWidget(ThinkingAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Controle de visibilidade mais estável
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible && !_wasVisible) {
        _show();
      } else if (!widget.isVisible && _wasVisible) {
        _hide();
      }
    }

    // Atualização de texto com throttling estável
    if (widget.thinkingText != oldWidget.thinkingText) {
      _updateTextThrottled(widget.thinkingText);
    }
  }

  void _show() {
    _wasVisible = true;
    _fadeController.forward();
    _neuralController.repeat();
    _updateTextThrottled(widget.thinkingText);
  }

  void _hide() {
    _wasVisible = false;
    _fadeController.reverse();
    _neuralController.stop();
  }

  void _updateTextThrottled(String newText) {
    // Throttling mais estável - só atualiza se houve mudança significativa
    if (newText != _lastText &&
        (newText.length - _lastText.length > 25 ||
            newText.isEmpty ||
            _lastText.isEmpty)) {
      _lastText = newText;
      _textNotifier.value = _cleanThinkingText(newText);
    }
  }

  @override
  void dispose() {
    _neuralController.dispose();
    _fadeController.dispose();
    _textNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        if (_fadeController.value == 0.0) {
          return const SizedBox.shrink();
        }

        return Opacity(
          opacity: _fadeController.value,
          child: Transform.scale(
            scale: 0.9 + (_fadeController.value * 0.1),
            child: _buildContent(context),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);

    return RepaintBoundary(
      child: Container(
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
            _buildHeader(theme),
            ValueListenableBuilder<String>(
              valueListenable: _textNotifier,
              builder: (context, text, child) {
                if (text.isEmpty) return const SizedBox.shrink();

                return Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildThinkingContent(theme, text),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return RepaintBoundary(
      child: Row(
        children: [
          // Novo loading elegante
          CompactLoadingWidget(
            size: 32,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Processando pensamento...',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                )
                    .animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    )
                    .shimmer(
                      duration: 2000.ms,
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                const SizedBox(height: 4),
                TypingIndicator(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  size: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThinkingContent(ThemeData theme, String text) {
    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(
          maxHeight: 150, // Limit height to prevent overflow
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: SingleChildScrollView(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              height: 1.5,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }

  String _cleanThinkingText(String text) {
    return text.replaceAll('<think>', '').replaceAll('</think>', '').trim();
  }
}

/// Widget otimizado para pontos animados sem flickering
class _AnimatedDots extends StatefulWidget {
  final Color color;

  const _AnimatedDots({required this.color});

  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final dotCount = (_controller.value * 4).floor() % 4;
          final dots = '.' * dotCount;
          return Text(
            'Analisando contexto$dots',
            style: TextStyle(
              fontSize: 12,
              color: widget.color,
              fontWeight: FontWeight.w500,
            ),
          );
        },
      ),
    );
  }
}

/// Painter otimizado para a animação neural sem flickering
class OptimizedNeuralPainter extends CustomPainter {
  final double progress;
  final Color color;

  OptimizedNeuralPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final nodePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    // Desenhar nós neurais com animação suave
    const nodeCount = 6;
    final nodes = <Offset>[];

    for (int i = 0; i < nodeCount; i++) {
      final angle = (i / nodeCount) * 2 * math.pi + progress * math.pi;
      final nodeRadius =
          radius * (0.8 + 0.2 * math.sin(progress * 2 * math.pi + i * 0.5));
      final offset = Offset(
        center.dx + nodeRadius * math.cos(angle),
        center.dy + nodeRadius * math.sin(angle),
      );
      nodes.add(offset);

      // Desenhar nós com pulsação suave
      final nodeSize = 2.5 + math.sin(progress * 3 * math.pi + i * 0.8) * 0.8;
      canvas.drawCircle(offset, nodeSize, nodePaint);
    }

    // Desenhar conexões com opacidade animada
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final connectionProgress = (progress + i * 0.1 + j * 0.1) % 1.0;
        final opacity = (math.sin(connectionProgress * math.pi * 1.5) + 1) / 3;

        paint.color = color.withValues(alpha: opacity * 0.4);
        canvas.drawLine(nodes[i], nodes[j], paint);
      }
    }

    // Núcleo central pulsante
    final coreRadius = 4.0 + math.sin(progress * 2.5 * math.pi) * 1.5;
    canvas.drawCircle(center, coreRadius, nodePaint);
  }

  @override
  bool shouldRepaint(OptimizedNeuralPainter oldDelegate) {
    return (oldDelegate.progress - progress).abs() > 0.01;
  }
}

/// Indicador de pensamento simples sem flickering
class ThinkingIndicator extends StatefulWidget {
  final bool isThinking;

  const ThinkingIndicator({super.key, required this.isThinking});

  @override
  State<ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<ThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    if (widget.isThinking) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ThinkingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isThinking != oldWidget.isThinking) {
      if (widget.isThinking) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isThinking) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return RepaintBoundary(
      child: SizedBox(
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
      ),
    );
  }
}

/// Painter otimizado para pontos de pensamento
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
      final delay = i * 0.25;
      final dotProgress = ((progress - delay) % 1.0).clamp(0.0, 1.0);
      final opacity = (math.sin(dotProgress * math.pi * 2) + 1) / 2;
      final scale = 0.6 + 0.4 * opacity;

      paint.color = color.withValues(alpha: opacity * 0.8);

      final center = Offset(startX + i * spacing, size.height / 2);
      canvas.drawCircle(center, dotRadius * scale, paint);
    }
  }

  @override
  bool shouldRepaint(ThinkingDotsPainter oldDelegate) {
    return (oldDelegate.progress - progress).abs() > 0.02;
  }
}
