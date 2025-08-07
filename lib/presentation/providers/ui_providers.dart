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
import '../../application/get_available_models.dart';

// Presentation
import '../controllers/llm_controller.dart';
import '../../infrastructure/core/di/injection_container.dart';

// =============================================================================
// DEPENDENCY INJECTION
// =============================================================================

/// Provider para o container de injeção de dependências.
final injectionContainerProvider = Provider<InjectionContainer>((ref) {
  final container = InjectionContainer();
  container.initialize();
  return container;
});

/// Provider para o controlador LLM via DI container.
final llmControllerProvider = ChangeNotifierProvider<LlmController>((ref) {
  final container = ref.watch(injectionContainerProvider);
  return container.controller;
});

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
class AvailableModelsNotifier
    extends StateNotifier<AsyncValue<List<LlmModel>>> {
  final GetAvailableModels _getAvailableModels;

  AvailableModelsNotifier(this._getAvailableModels)
      : super(const AsyncValue.loading()) {
    loadModels();
  }

  /// Carrega os modelos disponíveis.
  Future<void> loadModels() async {
    state = const AsyncValue.loading();
    try {
      final models = await _getAvailableModels();
      state = AsyncValue.data(models);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Recarrega os modelos.
  Future<void> refresh() async {
    await loadModels();
  }
}

/// Provider para os modelos disponíveis via DI.
final availableModelsProvider =
    StateNotifierProvider<AvailableModelsNotifier, AsyncValue<List<LlmModel>>>(
        (ref) {
  final container = ref.watch(injectionContainerProvider);
  return AvailableModelsNotifier(container.getAvailableModels);
});
