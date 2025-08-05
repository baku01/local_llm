/// Mixin para validação de modelo selecionado.
///
/// Fornece funcionalidades comuns para validar se um modelo
/// está selecionado antes de executar operações que dependem dele.
library;

import 'package:flutter/material.dart';
import '../controllers/llm_controller.dart';

/// Mixin que fornece validação de modelo selecionado.
///
/// Usado por widgets que precisam verificar se há um modelo
/// selecionado antes de executar operações de chat.
mixin ModelValidationMixin {
  /// Valida se há um modelo selecionado.
  ///
  /// Retorna true se válido, false caso contrário.
  /// Exibe SnackBar com mensagem de erro se necessário.
  ///
  /// Parâmetros:
  /// - [context]: Contexto do widget para exibir SnackBar
  /// - [controller]: Controller do LLM para verificar modelo
  bool validateSelectedModel(
    BuildContext context,
    LlmController controller,
  ) {
    if (controller.selectedModel == null) {
      _showNoModelSelectedSnackBar(context);
      return false;
    }
    return true;
  }

  /// Exibe SnackBar informando que nenhum modelo foi selecionado.
  void _showNoModelSelectedSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
            ),
            SizedBox(width: 12),
            Text('Por favor, selecione um modelo primeiro'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Selecionar',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Implementar navegação para seletor de modelo
            // Pode ser feito via callback ou Navigator
          },
        ),
      ),
    );
  }
}
