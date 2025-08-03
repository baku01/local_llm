/// Biblioteca para gerenciamento de estado do tema da aplicação.
///
/// Esta biblioteca contém o [ThemeStore] e [ThemeStoreProvider] que
/// gerenciam o estado do tema da aplicação, permitindo alternância
/// entre modos claro, escuro e automático.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Store para gerenciamento do estado do tema da aplicação.
///
/// Esta classe estende [ChangeNotifier] e gerencia o modo de tema
/// da aplicação, permitindo alternância entre claro, escuro e
/// automático (seguindo o sistema).
///
/// Funcionalidades:
/// - Alternar entre temas claro e escuro
/// - Seguir automaticamente o tema do sistema
/// - Feedback háptico nas mudanças de tema
/// - Notificação de ouvintes quando o tema muda
///
/// Exemplo de uso:
/// ```dart
/// final themeStore = ThemeStore();
///
/// // Alternar tema
/// themeStore.toggleTheme();
///
/// // Definir tema específico
/// themeStore.setThemeMode(ThemeMode.dark);
///
/// // Verificar se está no modo escuro
/// if (themeStore.isDarkMode) {
///   // Lógica para tema escuro
/// }
/// ```
class ThemeStore extends ChangeNotifier {
  /// O modo de tema atual da aplicação.
  ///
  /// Valores possíveis:
  /// - [ThemeMode.light]: Tema claro
  /// - [ThemeMode.dark]: Tema escuro
  /// - [ThemeMode.system]: Segue o sistema (padrão)
  ThemeMode _themeMode = ThemeMode.system;

  /// Obtém o modo de tema atual.
  ///
  /// Retorna o [ThemeMode] atualmente configurado.
  ThemeMode get themeMode => _themeMode;

  /// Verifica se o tema escuro está ativo.
  ///
  /// Este getter considera tanto o modo manual quanto o automático:
  /// - Se [themeMode] for [ThemeMode.system], verifica o tema do sistema
  /// - Caso contrário, retorna true apenas se for [ThemeMode.dark]
  ///
  /// Retorna true se o tema escuro estiver ativo, false caso contrário.
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  /// Alterna entre os temas claro e escuro.
  ///
  /// Este método alterna apenas entre [ThemeMode.light] e [ThemeMode.dark],
  /// não incluindo o modo [ThemeMode.system]. Se o tema atual for system,
  /// ele será alterado para dark.
  ///
  /// Fornece feedback háptico e notifica os ouvintes sobre a mudança.
  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    HapticFeedback.lightImpact();
    notifyListeners();
  }

  /// Define um modo de tema específico.
  ///
  /// Este método permite definir qualquer [ThemeMode] válido,
  /// incluindo [ThemeMode.system] para seguir automaticamente
  /// as preferências do sistema.
  ///
  /// Parâmetros:
  /// - [mode]: O novo modo de tema a ser aplicado.
  ///
  /// Só executa a mudança se o novo modo for diferente do atual,
  /// fornecendo feedback háptico e notificando os ouvintes.
  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      HapticFeedback.lightImpact();
      notifyListeners();
    }
  }
}

/// Provider para disponibilizar o [ThemeStore] na árvore de widgets.
///
/// Esta classe estende [InheritedNotifier] para fornecer acesso ao
/// [ThemeStore] para todos os widgets descendentes, permitindo que
/// eles escutem mudanças no tema e se reconstruam automaticamente.
///
/// Uso recomendado no topo da árvore de widgets:
/// ```dart
/// ThemeStoreProvider(
///   themeStore: ThemeStore(),
///   child: MaterialApp(
///     // ... configuração do app
///   ),
/// )
/// ```
class ThemeStoreProvider extends InheritedNotifier<ThemeStore> {
  /// Cria um novo [ThemeStoreProvider].
  ///
  /// Parâmetros:
  /// - [key]: Chave opcional para o widget.
  /// - [themeStore]: A instância do [ThemeStore] a ser fornecida.
  /// - [child]: O widget filho que terá acesso ao store.
  const ThemeStoreProvider({
    super.key,
    required ThemeStore themeStore,
    required super.child,
  }) : super(notifier: themeStore);

  /// Obtém a instância do [ThemeStore] a partir do contexto.
  ///
  /// Este método busca o [ThemeStoreProvider] mais próximo na
  /// árvore de widgets e retorna o [ThemeStore] associado.
  ///
  /// Parâmetros:
  /// - [context]: O contexto do widget que solicita o store.
  ///
  /// Retorna a instância do [ThemeStore] ou null se não encontrada.
  ///
  /// Exemplo de uso:
  /// ```dart
  /// final themeStore = ThemeStoreProvider.of(context);
  /// if (themeStore != null) {
  ///   themeStore.toggleTheme();
  /// }
  /// ```
  static ThemeStore? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ThemeStoreProvider>()
        ?.notifier;
  }
}
