import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/app_providers.dart';
import 'chat_text_field.dart';
import 'model_validation_mixin.dart';
import 'chat_configuration_sync.dart';

class ChatInputField extends ConsumerStatefulWidget with ModelValidationMixin {
  const ChatInputField({super.key});

  @override
  ConsumerState<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends ConsumerState<ChatInputField>
    with TickerProviderStateMixin, ModelValidationMixin {
  late AnimationController _bounceController;
  late AnimationController _focusController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _focusAnimation;

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _focusController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    _focusAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _focusController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _focusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(
      llmControllerProvider.select((controller) => controller.isLoading),
    );
    final isTextFieldEmpty = ref.watch(isTextFieldEmptyProvider);
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        boxShadow: [
          if (!isTextFieldEmpty)
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
        ],
      ),
      child: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([_bounceAnimation, _focusAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _bounceAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    if (_focusAnimation.value > 0)
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(
                          0.2 * _focusAnimation.value,
                        ),
                        blurRadius: 12 * _focusAnimation.value,
                        spreadRadius: 2 * _focusAnimation.value,
                      ),
                  ],
                ),
                child: ChatTextField(
                  enabled: !isLoading,
                  onSubmitted: (text, ref) =>
                      _handleMessageSubmissionWithContext(
                    text,
                    ref,
                    context,
                  ),
                  onFocusChanged: _handleFocusChanged,
                  onSendPressed: _handleSendPressed,
                  hintText: isLoading
                      ? 'Aguarde a resposta...'
                      : 'Digite sua mensagem...',
                ),
              ),
            );
          },
        ),
      ),
    )
        .animate()
        .slideY(
          begin: 1.0,
          end: 0.0,
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        )
        .fadeIn(duration: 300.ms);
  }

  void _handleFocusChanged(bool hasFocus) {
    if (hasFocus) {
      _focusController.forward();
    } else {
      _focusController.reverse();
    }
  }

  void _handleSendPressed() {
    _bounceController.forward().then((_) {
      _bounceController.reverse();
    });
  }

  /// Processa o envio de uma mensagem com contexto adequado.
  ///
  /// Valida se há modelo selecionado, sincroniza configurações
  /// e delega o envio para o LlmController.
  void _handleMessageSubmissionWithContext(
    String text,
    WidgetRef ref,
    BuildContext context,
  ) {
    if (text.trim().isEmpty) return;

    final llmController = ref.read(llmControllerProvider);

    // Validar modelo selecionado
    if (!validateSelectedModel(context, llmController)) {
      return;
    }

    // Sincronizar configurações antes do envio
    ChatConfigurationSync.syncConfigurations(ref, llmController);

    // Enviar mensagem via controller
    llmController.sendMessage(text.trim());
  }
}
