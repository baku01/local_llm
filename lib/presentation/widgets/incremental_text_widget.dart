/// Widget que renderiza texto de forma incremental, adicionando tokens
/// sem rebuild completo para eliminar completamente o flickering.
///
/// Implementa:
/// - Lista de tokens que preserva o texto anterior
/// - Apenas o último token é adicionado/atualizado
/// - Zero rebuilds do conteúdo existente
/// - Animação suave apenas para novos tokens
/// - Throttling de notificações para melhor performance
library;

import 'dart:async';
import 'package:flutter/material.dart';

/// Controlador para gerenciar tokens incrementais.
class IncrementalTextController extends ChangeNotifier {
  final List<String> _tokens = [];
  String _lastPartialToken = '';
  bool _isStreaming = false;
  bool _isComplete = false;

  /// Timer para throttling de notificações.
  Timer? _notificationTimer;

  /// Controla se há uma notificação pendente.
  bool _hasPendingNotification = false;

  /// Lista imutável de tokens completos
  List<String> get tokens => List.unmodifiable(_tokens);

  /// Token parcial atual (em formação)
  String get lastPartialToken => _lastPartialToken;

  /// Se está recebendo stream de tokens
  bool get isStreaming => _isStreaming;

  /// Se o streaming foi finalizado
  bool get isComplete => _isComplete;

  /// Texto completo atual
  String get fullText => _tokens.join() + _lastPartialToken;

  /// Adiciona um chunk de texto de forma incremental
  void addChunk(String chunk) {
    if (chunk.isEmpty) return;

    _isStreaming = true;
    _isComplete = false;

    // Detectar tokens completos (palavras separadas por espaço)
    final newContent = _lastPartialToken + chunk;
    final parts = newContent.split(' ');

    if (parts.length > 1) {
      // Adicionar tokens completos
      for (int i = 0; i < parts.length - 1; i++) {
        if (i == 0 && _lastPartialToken.isNotEmpty) {
          // Completar o token parcial anterior
          _tokens.add('${parts[i]} ');
        } else {
          _tokens.add('${parts[i]} ');
        }
      }

      // O último parte vira o novo token parcial
      _lastPartialToken = parts.last;
    } else {
      // Continuar construindo o token parcial
      _lastPartialToken = newContent;
    }

    _notifyListenersThrottled();
  }

  /// Finaliza o streaming
  void complete() {
    if (_lastPartialToken.isNotEmpty) {
      _tokens.add(_lastPartialToken);
      _lastPartialToken = '';
    }

    _isStreaming = false;
    _isComplete = true;
    _notificationTimer?.cancel();
    _hasPendingNotification = false;
    notifyListeners();
  }

  /// Limpa todo o conteúdo
  void clear() {
    _tokens.clear();
    _lastPartialToken = '';
    _isStreaming = false;
    _isComplete = false;
    _notificationTimer?.cancel();
    _hasPendingNotification = false;
    notifyListeners();
  }

  /// Implementa throttling para notificações, reduzindo rebuilds excessivos.
  void _notifyListenersThrottled() {
    if (_isStreaming) {
      // Durante streaming, usar throttling de 50ms
      _hasPendingNotification = true;
      _notificationTimer?.cancel();
      _notificationTimer = Timer(const Duration(milliseconds: 50), () {
        if (_hasPendingNotification) {
          _hasPendingNotification = false;
          notifyListeners();
        }
      });
    } else {
      // Para operações não-streaming, notificar imediatamente
      _notificationTimer?.cancel();
      _hasPendingNotification = false;
      notifyListeners();
    }
  }

  /// Define o texto completo (útil para inicialização)
  void setText(String text) {
    clear();

    if (text.isNotEmpty) {
      // Dividir em tokens e adicionar
      final words = text.split(' ');
      for (int i = 0; i < words.length; i++) {
        if (i == words.length - 1) {
          _lastPartialToken = words[i];
        } else {
          _tokens.add('${words[i]} ');
        }
      }
    }

    _isComplete = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    clear();
    super.dispose();
  }
}

/// Widget que renderiza texto de forma incremental sem flickering.
class IncrementalTextWidget extends StatefulWidget {
  /// Controlador do texto incremental
  final IncrementalTextController controller;

  /// Estilo do texto
  final TextStyle? style;

  /// Se deve mostrar cursor de digitação
  final bool showCursor;

  /// Cor do cursor
  final Color? cursorColor;

  /// Se deve animar novos tokens
  final bool animateNewTokens;

  const IncrementalTextWidget({
    super.key,
    required this.controller,
    this.style,
    this.showCursor = true,
    this.cursorColor,
    this.animateNewTokens = true,
  });

  @override
  State<IncrementalTextWidget> createState() => _IncrementalTextWidgetState();
}

class _IncrementalTextWidgetState extends State<IncrementalTextWidget>
    with TickerProviderStateMixin {
  late AnimationController _cursorController;
  late AnimationController _newTokenController;

  int _lastTokenCount = 0;
  String _lastPartialToken = '';

  @override
  void initState() {
    super.initState();

    _cursorController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _newTokenController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    widget.controller.addListener(_onControllerChanged);
    _updateCursorAnimation();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _cursorController.dispose();
    _newTokenController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    _updateCursorAnimation();

    // Animar apenas novos tokens
    if (widget.animateNewTokens) {
      final currentTokenCount = widget.controller.tokens.length;
      final currentPartialToken = widget.controller.lastPartialToken;

      if (currentTokenCount > _lastTokenCount ||
          currentPartialToken != _lastPartialToken) {
        _newTokenController.forward(from: 0);
      }

      _lastTokenCount = currentTokenCount;
      _lastPartialToken = currentPartialToken;
    }
  }

  void _updateCursorAnimation() {
    if (widget.showCursor && widget.controller.isStreaming) {
      _cursorController.repeat(reverse: true);
    } else {
      _cursorController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return RepaintBoundary(
          child: _buildIncrementalText(),
        );
      },
    );
  }

  Widget _buildIncrementalText() {
    final theme = Theme.of(context);
    final effectiveCursorColor =
        widget.cursorColor ?? theme.colorScheme.primary;

    return RichText(
      text: TextSpan(
        children: [
          // Tokens completos (nunca mudam, zero flickering)
          ..._buildCompletedTokens(),

          // Token parcial atual (apenas este é atualizado)
          if (widget.controller.lastPartialToken.isNotEmpty)
            _buildPartialToken(effectiveCursorColor),

          // Cursor de digitação
          if (widget.showCursor && widget.controller.isStreaming)
            _buildCursor(effectiveCursorColor),
        ],
      ),
    );
  }

  List<TextSpan> _buildCompletedTokens() {
    final tokens = widget.controller.tokens;
    final spans = <TextSpan>[];

    for (int i = 0; i < tokens.length; i++) {
      spans.add(
        TextSpan(
          text: tokens[i],
          style: widget.style,
        ),
      );
    }

    return spans;
  }

  InlineSpan _buildPartialToken(Color cursorColor) {
    if (!widget.animateNewTokens) {
      return TextSpan(
        text: widget.controller.lastPartialToken,
        style: widget.style,
      );
    }

    // Animar apenas o token parcial
    return WidgetSpan(
      child: AnimatedBuilder(
        animation: _newTokenController,
        builder: (context, child) {
          return Transform.scale(
            scale: 0.9 + (0.1 * _newTokenController.value),
            alignment: Alignment.centerLeft,
            child: Opacity(
              opacity: 0.7 + (0.3 * _newTokenController.value),
              child: Text(
                widget.controller.lastPartialToken,
                style: widget.style,
              ),
            ),
          );
        },
      ),
    );
  }

  InlineSpan _buildCursor(Color cursorColor) {
    return WidgetSpan(
      child: AnimatedBuilder(
        animation: _cursorController,
        builder: (context, child) {
          return Opacity(
            opacity: _cursorController.value,
            child: Container(
              width: 2,
              height: (widget.style?.fontSize ?? 14) * 1.2,
              margin: const EdgeInsets.only(left: 1),
              decoration: BoxDecoration(
                color: cursorColor,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Widget de pensamento que usa streaming incremental.
class IncrementalThinkingWidget extends StatefulWidget {
  /// Stream de chunks de texto
  final Stream<String>? textStream;

  /// Texto inicial (se não for streaming)
  final String? initialText;

  /// Se o widget deve estar visível
  final bool isVisible;

  /// Estilo do texto
  final TextStyle? textStyle;

  /// Callback quando o streaming termina
  final VoidCallback? onStreamComplete;

  const IncrementalThinkingWidget({
    super.key,
    this.textStream,
    this.initialText,
    required this.isVisible,
    this.textStyle,
    this.onStreamComplete,
  });

  @override
  State<IncrementalThinkingWidget> createState() =>
      _IncrementalThinkingWidgetState();
}

class _IncrementalThinkingWidgetState extends State<IncrementalThinkingWidget>
    with TickerProviderStateMixin {
  late IncrementalTextController _textController;
  late AnimationController _visibilityController;
  StreamSubscription<String>? _streamSubscription;

  @override
  void initState() {
    super.initState();

    _textController = IncrementalTextController();

    _visibilityController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _setupInitialState();
    _updateVisibility();
  }

  @override
  void didUpdateWidget(IncrementalThinkingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isVisible != widget.isVisible) {
      _updateVisibility();
    }

    if (oldWidget.textStream != widget.textStream) {
      _setupStream();
    }

    if (oldWidget.initialText != widget.initialText &&
        widget.initialText != null) {
      _textController.setText(widget.initialText!);
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _textController.dispose();
    _visibilityController.dispose();
    super.dispose();
  }

  void _setupInitialState() {
    if (widget.initialText != null) {
      _textController.setText(widget.initialText!);
    } else {
      _setupStream();
    }
  }

  void _setupStream() {
    _streamSubscription?.cancel();

    if (widget.textStream != null) {
      _textController.clear();

      _streamSubscription = widget.textStream!.listen(
        (chunk) {
          _textController.addChunk(chunk);
        },
        onDone: () {
          _textController.complete();
          widget.onStreamComplete?.call();
        },
        onError: (error) {
          _textController.complete();
          widget.onStreamComplete?.call();
        },
      );
    }
  }

  void _updateVisibility() {
    if (widget.isVisible) {
      _visibilityController.forward();
    } else {
      _visibilityController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _visibilityController,
      builder: (context, child) {
        if (_visibilityController.value == 0.0) {
          return const SizedBox.shrink();
        }

        return Opacity(
          opacity: _visibilityController.value,
          child: Transform.translate(
            offset: Offset(0, (1 - _visibilityController.value) * 20),
            child: _buildThinkingContainer(theme),
          ),
        );
      },
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
          const SizedBox(height: 12),
          _buildIncrementalContent(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Processando pensamento...',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildIncrementalContent(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: IncrementalTextWidget(
        controller: _textController,
        style: widget.textStyle ??
            TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              height: 1.4,
              fontFamily: 'monospace',
            ),
        showCursor: true,
        animateNewTokens: true,
      ),
    );
  }
}
