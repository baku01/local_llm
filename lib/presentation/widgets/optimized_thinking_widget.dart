/// Widget de pensamento otimizado para eliminar flickering.
/// 
/// Implementa:
/// - Debounce de atualizações de texto
/// - RepaintBoundary para isolar pinturas
/// - ValueListenableBuilder para updates seletivos
/// - Animações controladas sem interferir no conteúdo
library;

import 'dart:async';
import 'package:flutter/material.dart';

/// Widget otimizado para exibir pensamento da IA sem flickering.
class OptimizedThinkingWidget extends StatefulWidget {
  /// Notifier para o texto de pensamento em tempo real
  final ValueNotifier<String?> thinkingNotifier;
  
  /// Se o widget deve estar visível
  final bool isVisible;
  
  /// Duração do debounce para atualizações
  final Duration debounceDuration;

  const OptimizedThinkingWidget({
    super.key,
    required this.thinkingNotifier,
    required this.isVisible,
    this.debounceDuration = const Duration(milliseconds: 100),
  });

  @override
  State<OptimizedThinkingWidget> createState() => _OptimizedThinkingWidgetState();
}

class _OptimizedThinkingWidgetState extends State<OptimizedThinkingWidget>
    with TickerProviderStateMixin {
  
  // Controllers para animações
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  
  // Timer para debounce
  Timer? _debounceTimer;
  
  // Estado local para evitar rebuilds desnecessários
  String _displayedText = '';
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    
    // Inicializar controladores
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Escutar mudanças com debounce
    widget.thinkingNotifier.addListener(_onThinkingChanged);
    
    // Inicializar estado
    _updateVisibility();
  }

  @override
  void didUpdateWidget(OptimizedThinkingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.thinkingNotifier != widget.thinkingNotifier) {
      oldWidget.thinkingNotifier.removeListener(_onThinkingChanged);
      widget.thinkingNotifier.addListener(_onThinkingChanged);
    }
    
    if (oldWidget.isVisible != widget.isVisible) {
      _updateVisibility();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    widget.thinkingNotifier.removeListener(_onThinkingChanged);
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onThinkingChanged() {
    // Debounce das atualizações para reduzir flickering
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () {
      if (mounted) {
        final newText = widget.thinkingNotifier.value ?? '';
        if (newText != _displayedText) {
          setState(() {
            _displayedText = newText;
          });
        }
      }
    });
  }

  void _updateVisibility() {
    if (widget.isVisible) {
      _fadeController.forward();
      _pulseController.repeat();
    } else {
      _fadeController.reverse();
      _pulseController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _fadeController,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeController.value,
            child: Transform.translate(
              offset: Offset(0, (1 - _fadeController.value) * 20),
              child: _buildThinkingContainer(theme),
            ),
          );
        },
      ),
    );
  }

  Widget _buildThinkingContainer(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.05),
            theme.colorScheme.secondary.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          if (_displayedText.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildThinkingContent(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        RepaintBoundary(
          child: SizedBox(
            width: 24,
            height: 24,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return CustomPaint(
                  painter: OptimizedThinkingPainter(
                    progress: _pulseController.value,
                    color: theme.colorScheme.primary,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Processando pensamento',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                'Analisando contexto...',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        if (_displayedText.isNotEmpty)
          IconButton(
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            icon: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            tooltip: _isExpanded ? 'Recolher' : 'Expandir',
          ),
      ],
    );
  }

  Widget _buildThinkingContent(ThemeData theme) {
    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: BoxConstraints(
          maxHeight: _isExpanded ? double.infinity : 100,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: SingleChildScrollView(
            child: OptimizedTextDisplay(
              text: _cleanThinkingText(_displayedText),
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                height: 1.4,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _cleanThinkingText(String text) {
    return text
        .replaceAll('<think>', '')
        .replaceAll('</think>', '')
        .trim();
  }
}

/// Widget de texto otimizado que minimiza rebuilds.
class OptimizedTextDisplay extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const OptimizedTextDisplay({
    super.key,
    required this.text,
    this.style,
  });

  @override
  State<OptimizedTextDisplay> createState() => _OptimizedTextDisplayState();
}

class _OptimizedTextDisplayState extends State<OptimizedTextDisplay> {
  String _lastText = '';

  @override
  Widget build(BuildContext context) {
    // Evita rebuild se o texto não mudou
    if (widget.text == _lastText) {
      return Text(
        widget.text,
        style: widget.style,
      );
    }

    _lastText = widget.text;
    
    return RepaintBoundary(
      child: Text(
        widget.text,
        style: widget.style,
      ),
    );
  }
}

/// Painter otimizado para o indicador de pensamento.
class OptimizedThinkingPainter extends CustomPainter {
  final double progress;
  final Color color;

  OptimizedThinkingPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const dotCount = 3;
    final dotRadius = size.width * 0.15;
    final spacing = size.width * 0.3;
    final startX = (size.width - (dotCount - 1) * spacing) / 2;

    for (int i = 0; i < dotCount; i++) {
      final delay = i * 0.3;
      final adjustedProgress = ((progress - delay) % 1.0).clamp(0.0, 1.0);
      
      // Suavizar a animação
      final opacity = (0.3 + 0.7 * (0.5 + 0.5 * 
          (adjustedProgress < 0.5 
              ? adjustedProgress * 2 
              : 2 - adjustedProgress * 2))).clamp(0.0, 1.0);
      
      final scale = 0.7 + 0.3 * opacity;

      paint.color = color.withValues(alpha: opacity);

      final center = Offset(
        startX + i * spacing,
        size.height / 2,
      );

      canvas.drawCircle(center, dotRadius * scale, paint);
    }
  }

  @override
  bool shouldRepaint(OptimizedThinkingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Widget compacto para indicar pensamento em linha.
class InlineThinkingIndicator extends StatefulWidget {
  final bool isThinking;
  final Color? color;

  const InlineThinkingIndicator({
    super.key,
    required this.isThinking,
    this.color,
  });

  @override
  State<InlineThinkingIndicator> createState() => _InlineThinkingIndicatorState();
}

class _InlineThinkingIndicatorState extends State<InlineThinkingIndicator>
    with SingleTickerProviderStateMixin {
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
  void didUpdateWidget(InlineThinkingIndicator oldWidget) {
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
    if (!widget.isThinking) return const SizedBox.shrink();

    final effectiveColor = widget.color ?? 
        Theme.of(context).colorScheme.primary;

    return RepaintBoundary(
      child: SizedBox(
        width: 20,
        height: 16,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: OptimizedThinkingPainter(
                progress: _controller.value,
                color: effectiveColor,
              ),
            );
          },
        ),
      ),
    );
  }
}