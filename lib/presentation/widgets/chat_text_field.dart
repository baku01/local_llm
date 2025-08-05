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
    this.initialText = '',
    this.enabled = true,
    this.hintText = 'Digite sua mensagem...',
  });

  @override
  ConsumerState<ChatTextField> createState() => _ChatTextFieldState();
}

class _ChatTextFieldState extends ConsumerState<ChatTextField> {
  late final TextEditingController _controller;
  bool _isEmpty = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _isEmpty = widget.initialText.trim().isEmpty;
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final isEmpty = _controller.text.trim().isEmpty;
    if (_isEmpty != isEmpty) {
      setState(() {
        _isEmpty = isEmpty;
      });
      // Notificar provider sobre mudança de estado
      ref.read(isTextFieldEmptyProvider.notifier).state = isEmpty;
    }
  }

  void _handleSubmitted() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && widget.enabled) {
      widget.onSubmitted(text, ref);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
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
        maxHeight: 120, // Limit maximum height to prevent overflow
      ),
      child: TextField(
        controller: _controller,
        enabled: widget.enabled,
        maxLines: null,
        textInputAction: TextInputAction.send,
        onSubmitted: (_) => _handleSubmitted(),
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          filled: true,
          fillColor: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.7),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          suffixIcon: _isEmpty
              ? null
              : IconButton(
                  onPressed: _handleSubmitted,
                  icon: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.send_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
