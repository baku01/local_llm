/// Widget otimizado para exibição de mensagens em streaming sem flickering.
/// 
/// Implementa várias técnicas de otimização:
/// - ValueNotifier para atualizações isoladas
/// - RepaintBoundary para evitar repaints desnecessários
/// - Throttling de atualizações para reduzir frequência
/// - AnimatedSwitcher suave para transições
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Widget otimizado para streaming de texto sem flickering.
class OptimizedStreamingMessage extends StatefulWidget {
  /// Stream de chunks de texto que chegam incrementalmente
  final Stream<String> textStream;
  
  /// Estilo do texto
  final TextStyle? style;
  
  /// Padding interno
  final EdgeInsets? padding;
  
  /// Decoração do container
  final BoxDecoration? decoration;
  
  /// Callback chamado quando o streaming termina
  final VoidCallback? onStreamComplete;
  
  /// Intervalo mínimo entre atualizações (throttling)
  final Duration throttleDuration;
  
  /// Se deve mostrar cursor piscando durante digitação
  final bool showCursor;

  const OptimizedStreamingMessage({
    super.key,
    required this.textStream,
    this.style,
    this.padding,
    this.decoration,
    this.onStreamComplete,
    this.throttleDuration = const Duration(milliseconds: 50),
    this.showCursor = true,
  });

  @override
  State<OptimizedStreamingMessage> createState() => _OptimizedStreamingMessageState();
}

class _OptimizedStreamingMessageState extends State<OptimizedStreamingMessage>
    with TickerProviderStateMixin {
  
  /// ValueNotifier para texto atual - permite updates isolados
  late final ValueNotifier<String> _textNotifier;
  
  /// Controlador para animação do cursor
  late final AnimationController _cursorController;
  
  /// Timer para throttling de atualizações
  Timer? _throttleTimer;
  
  /// Buffer para acumular chunks antes de atualizar UI
  final StringBuffer _textBuffer = StringBuffer();
  
  /// Subscription do stream
  StreamSubscription<String>? _streamSubscription;
  
  /// Flag para controlar se ainda está recebendo dados
  bool _isStreaming = false;
  
  /// Último texto renderizado (para evitar updates desnecessários)
  String _lastRenderedText = '';

  @override
  void initState() {
    super.initState();
    
    _textNotifier = ValueNotifier<String>('');
    
    _cursorController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _setupStream();
  }

  void _setupStream() {
    _isStreaming = true;
    _cursorController.repeat(reverse: true);
    
    _streamSubscription = widget.textStream.listen(
      _onChunkReceived,
      onDone: _onStreamComplete,
      onError: _onStreamError,
    );
  }

  /// Processa chunks recebidos com throttling
  void _onChunkReceived(String chunk) {
    _textBuffer.write(chunk);
    
    // Throttling: só atualiza UI no máximo a cada X ms
    _throttleTimer?.cancel();
    _throttleTimer = Timer(widget.throttleDuration, _updateUI);
  }

  /// Atualiza a UI apenas se houve mudança real
  void _updateUI() {
    final newText = _textBuffer.toString();
    
    // Só atualiza se o texto realmente mudou
    if (newText != _lastRenderedText) {
      _lastRenderedText = newText;
      
      // Use SchedulerBinding para garantir que update aconteça no próximo frame
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _textNotifier.value = newText;
        }
      });
    }
  }

  void _onStreamComplete() {
    _isStreaming = false;
    _throttleTimer?.cancel();
    
    // Update final garantindo que todo o texto seja exibido
    _updateUI();
    
    _cursorController.stop();
    _cursorController.value = 0.0; // Hide cursor
    
    widget.onStreamComplete?.call();
  }

  void _onStreamError(Object error) {
    _isStreaming = false;
    _throttleTimer?.cancel();
    _cursorController.stop();
    
    debugPrint('Streaming error: $error');
  }

  @override
  void dispose() {
    _throttleTimer?.cancel();
    _streamSubscription?.cancel();
    _textNotifier.dispose();
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        padding: widget.padding,
        decoration: widget.decoration,
        child: ValueListenableBuilder<String>(
          valueListenable: _textNotifier,
          builder: (context, text, child) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 100),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: _buildTextWithCursor(text),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextWithCursor(String text) {
    if (!widget.showCursor || !_isStreaming) {
      return Text(
        text,
        style: widget.style,
        key: ValueKey(text.length), // Key para AnimatedSwitcher
      );
    }

    return AnimatedBuilder(
      animation: _cursorController,
      builder: (context, child) {
        return RichText(
          key: ValueKey('${text.length}_cursor'),
          text: TextSpan(
            style: widget.style,
            children: [
              TextSpan(text: text),
              TextSpan(
                text: '|',
                style: widget.style?.copyWith(
                  color: widget.style?.color?.withValues(alpha: _cursorController.value),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Extension para facilitar uso com streams de strings
extension StreamingTextExtension on Stream<String> {
  Widget toOptimizedStreamingWidget({
    TextStyle? style,
    EdgeInsets? padding,
    BoxDecoration? decoration,
    VoidCallback? onComplete,
    Duration throttleDuration = const Duration(milliseconds: 50),
    bool showCursor = true,
  }) {
    return OptimizedStreamingMessage(
      textStream: this,
      style: style,
      padding: padding,
      decoration: decoration,
      onStreamComplete: onComplete,
      throttleDuration: throttleDuration,
      showCursor: showCursor,
    );
  }
}