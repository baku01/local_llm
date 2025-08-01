import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ThemeStore extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    HapticFeedback.lightImpact();
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      HapticFeedback.lightImpact();
      notifyListeners();
    }
  }
}

class ThemeStoreProvider extends InheritedNotifier<ThemeStore> {
  const ThemeStoreProvider({
    super.key,
    required ThemeStore themeStore,
    required super.child,
  }) : super(notifier: themeStore);

  static ThemeStore? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ThemeStoreProvider>()
        ?.notifier;
  }
}
