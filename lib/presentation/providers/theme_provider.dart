/// Provider para gerenciamento de temas da aplicação.
///
/// Utiliza o padrão Provider para gerenciar o estado global do tema,
/// oferecendo suporte a modo claro, escuro e seguir o sistema.
library;

import 'package:flutter/material.dart';
import '../theme/unified_theme.dart';

/// Provider responsável pelo gerenciamento de temas da aplicação.
///
/// Oferece três modos de tema:
/// - Claro: Força o tema claro
/// - Escuro: Força o tema escuro
/// - Sistema: Segue a preferência do sistema operacional
///
/// Inclui funcionalidades para alternância cíclica entre os modos
/// e métodos auxiliares para obter ícones e nomes dos temas.
class ThemeProvider extends ChangeNotifier {
  /// Modo de tema atual da aplicação.
  ThemeMode _themeMode = ThemeMode.system;

  /// Retorna o modo de tema atual.
  ThemeMode get themeMode => _themeMode;

  /// Indica se o modo escuro está ativo.
  ///
  /// Considera tanto configurações explícitas quanto preferência do sistema
  /// quando o modo estiver definido como [ThemeMode.system].
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  /// Alterna ciclicamente entre os modos de tema.
  ///
  /// Sequência de alternância:
  /// Claro → Escuro → Sistema → Claro (...)
  ///
  /// Notifica os ouvintes sobre a mudança para atualizar a interface.
  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }

  /// Define explicitamente um modo de tema.
  ///
  /// [mode] - O modo de tema a ser aplicado
  ///
  /// Notifica os ouvintes sobre a mudança.
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  /// Retorna o ícone apropriado para o modo de tema atual.
  ///
  /// Usado na interface para representar visualmente o tema ativo.
  IconData get themeIcon {
    switch (_themeMode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  /// Retorna o nome legível do modo de tema atual.
  ///
  /// Usado para exibir o tema atual na interface do usuário.
  String get themeName {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Escuro';
      case ThemeMode.system:
        return 'Sistema';
    }
  }

  /// Constrói o tema claro da aplicação.
  ThemeData buildLightTheme() {
    return AppTheme.lightTheme;
  }

  /// Constrói o tema escuro da aplicação.
  ThemeData buildDarkTheme() {
    return AppTheme.darkTheme;
  }
}
