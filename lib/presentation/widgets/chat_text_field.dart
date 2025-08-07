/// Widget especializado para o campo de entrada de texto do chat.
///
/// Este widget encapsula toda a lógica de entrada de texto,
/// incluindo validação, formatação e callbacks de eventos.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

/// Widget de campo de texto especializado para chat.
///
/// Responsabilidades:
/// - Gerenciar entrada de texto
/// - Sincronizar com provider de sugestões
/// - Notificar mudanças de estado (vazio/preenchido)
/// - Permitir envio via Enter ou callback
class ChatTextField extends ConsumerStatefulWidget {
  /// Callback executado quando o texto é enviado.
  /// Recebe o texto e uma referência do WidgetRef.
  final void Function(String text, WidgetRef ref) onSubmitted;

  /// Callback para mudanças de foco.
  final void Function(bool hasFocus)? onFocusChanged;

  /// Callback para quando o botão de envio é pressionado.
  final VoidCallback? onSendPressed;

  /// Texto inicial do campo.
  final String initialText;

  /// Se o campo deve estar habilitado.
  final bool enabled;

  /// Hint text a ser exibido.
  final String hintText;

  /// Construtor do campo de texto do chat.
  const ChatTextField({
    super.key,
    required this.onSubmitted,
    this.onFocusChanged,
    this.onSendPressed,
    this.initialText = '',
    this.enabled = true,
    this.hintText = 'Digite sua mensagem...',
  });

  @override
  ConsumerState<ChatTextField> createState() => _ChatTextFieldState();
}

class _ChatTextFieldState extends ConsumerState<ChatTextField>
    with TickerProviderStateMixin {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late AnimationController _sendButtonController;
  late Animation<double> _sendButtonAnimation;
  bool _isEmpty = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _focusNode = FocusNode();
    _isEmpty = widget.initialText.trim().isEmpty;
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);

    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _sendButtonAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sendButtonController,
      curve: Curves.elasticOut,
    ));

    if (!_isEmpty) {
      _sendButtonController.forward();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    _sendButtonController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final isEmpty = _controller.text.trim().isEmpty;
    if (_isEmpty != isEmpty) {
      setState(() {
        _isEmpty = isEmpty;
      });
      // Animar botão de envio
      if (isEmpty) {
        _sendButtonController.reverse();
      } else {
        _sendButtonController.forward();
      }
      // Notificar provider sobre mudança de estado
      ref.read(isTextFieldEmptyProvider.notifier).state = isEmpty;
    }
  }

  void _onFocusChanged() {
    widget.onFocusChanged?.call(_focusNode.hasFocus);
  }

  void _handleSubmitted() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && widget.enabled) {
      widget.onSendPressed?.call();
      widget.onSubmitted(text, ref);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Observar sugestões para preencher automaticamente
    ref.listen(suggestionTextProvider, (previous, next) {
      if (next.isNotEmpty && mounted) {
        _controller.text = next;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
        // Limpar sugestão após uso
        Future.microtask(() {
          if (mounted) {
            ref.read(suggestionTextProvider.notifier).state = '';
          }
        });
      }
    });

    return Container(
      constraints: const BoxConstraints(
        minHeight: 56,
        maxHeight: 120,
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        maxLines: null,
        textInputAction: TextInputAction.send,
        onSubmitted: (_) => _handleSubmitted(),
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.7),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          suffixIcon: AnimatedBuilder(
            animation: _sendButtonAnimation,
            builder: (context, child) {
              if (_sendButtonAnimation.value == 0.0) {
                return const SizedBox.shrink();
              }

              return Transform.scale(
                scale: _sendButtonAnimation.value,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _handleSubmitted,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.send_rounded,
                          size: 20,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
