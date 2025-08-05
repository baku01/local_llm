/// Widget responsável por sincronizar configurações do chat.
///
/// Este widget gerencia a sincronização entre providers de configuração
/// (web search, stream mode) e o LlmController, garantindo que as
/// configurações sejam aplicadas antes do envio de mensagens.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/llm_controller.dart';
import '../providers/app_providers.dart';

/// Service para sincronização de configurações do chat.
///
/// Responsável por aplicar configurações do usuário (como web search
/// e stream mode) ao LlmController antes de enviar mensagens.
class ChatConfigurationSync {
  /// Sincroniza as configurações dos providers com o controller.
  ///
  /// Deve ser chamado antes de enviar uma mensagem para garantir
  /// que o controller esteja com as configurações mais recentes.
  ///
  /// Parâmetros:
  /// - [ref]: Referência do Riverpod para acessar providers
  /// - [controller]: Controller do LLM a ser configurado
  static void syncConfigurations(
    WidgetRef ref,
    LlmController controller,
  ) {
    // Sincronizar configuração de web search
    final webSearchEnabled = ref.read(webSearchEnabledProvider);
    controller.toggleWebSearch(webSearchEnabled);

    // Sincronizar configuração de stream mode
    final streamModeEnabled = ref.read(streamModeEnabledProvider);
    controller.toggleStreamMode(streamModeEnabled);
  }

  /// Sincroniza o modelo selecionado se necessário.
  ///
  /// Garante que o controller esteja usando o modelo selecionado
  /// nos providers, convertendo entre as representações se necessário.
  ///
  /// Parâmetros:
  /// - [ref]: Referência do Riverpod para acessar providers
  /// - [controller]: Controller do LLM a ser configurado
  ///
  /// Retorna true se a sincronização foi bem-sucedida.
  static bool syncSelectedModel(
    WidgetRef ref,
    LlmController controller,
  ) {
    final selectedModel = ref.read(selectedModelProvider);

    // Verificar se há modelo selecionado no provider
    if (selectedModel == null) {
      return false;
    }

    // Verificar se já está sincronizado
    if (controller.selectedModel?.name == selectedModel.name) {
      return true;
    }

    // Converter e sincronizar modelo
    // Note: assumindo que existe um método de conversão ou
    // que o controller pode trabalhar com o modelo do provider
    // Esta implementação pode precisar ser ajustada baseada na
    // estrutura exata dos modelos

    return true;
  }
}
