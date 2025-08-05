import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import 'chat_text_field.dart';
import 'model_validation_mixin.dart';
import 'chat_configuration_sync.dart';

class ChatInputField extends ConsumerWidget with ModelValidationMixin {
  const ChatInputField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      llmControllerProvider.select((controller) => controller.isLoading),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: Builder(
          builder: (context) => ChatTextField(
            enabled: !isLoading,
            onSubmitted: (text, ref) => _handleMessageSubmissionWithContext(
              text,
              ref,
              context,
            ),
            hintText:
                isLoading ? 'Aguarde a resposta...' : 'Digite sua mensagem...',
          ),
        ),
      ),
    );
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
