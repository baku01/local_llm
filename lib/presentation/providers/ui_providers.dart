/// Providers essenciais para estado da UI.
///
/// Este arquivo contém apenas os providers necessários para gerenciar
/// estado da interface do usuário, usando o injection container para
/// dependências de domínio.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

// Domain
import '../../domain/entities/llm_model.dart';

// Presentation
import 'app_providers.dart';

// =============================================================================
// CONTROLLER PROVIDER
// =============================================================================

/// Provider para o controlador LLM.
/// Este provider é importado de app_providers.dart onde está corretamente configurado.

// =============================================================================
// UI STATE PROVIDERS
// =============================================================================

/// Provider para o modo de tema (claro/escuro/sistema).
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// Provider para o modelo LLM selecionado.
final selectedModelProvider = StateProvider<LlmModel?>((ref) => null);

/// Provider para habilitar/desabilitar pesquisa web.
final webSearchEnabledProvider = StateProvider<bool>((ref) => false);

/// Provider para habilitar/desabilitar modo stream.
final streamModeEnabledProvider = StateProvider<bool>((ref) => true);

/// Provider para estado do campo de texto (vazio/preenchido).
final isTextFieldEmptyProvider = StateProvider<bool>((ref) => true);

/// Provider para estado de carregamento (gerando resposta).
final isReplyingProvider = StateProvider<bool>((ref) => false);

/// Provider para texto de sugestão.
final suggestionTextProvider = StateProvider<String>((ref) => '');

// =============================================================================
// MODELS STATE
// =============================================================================

/// Notifier para gerenciar o estado dos modelos disponíveis.
class AvailableModelsNotifier extends AsyncNotifier<List<LlmModel>> {
  @override
  Future<List<LlmModel>> build() async {
    final getAvailableModels = ref.watch(getAvailableModelsProvider);
    return await getAvailableModels();
  }

  /// Recarrega os modelos.
  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final getAvailableModels = ref.watch(getAvailableModelsProvider);
      final models = await getAvailableModels();
      state = AsyncData(models);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}

/// Provider para os modelos disponíveis.
final availableModelsProvider =
    AsyncNotifierProvider<AvailableModelsNotifier, List<LlmModel>>(
  () => AvailableModelsNotifier(),
);
