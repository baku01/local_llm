/// Local LLM Chat Application
///
/// Este é o ponto de entrada principal da aplicação Local LLM Chat.
/// A aplicação fornece uma interface para interagir com modelos de linguagem
/// locais através do Ollama, incluindo funcionalidades de busca na web.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'core/di/injection_container.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/providers/theme_provider.dart';

/// Função principal da aplicação.
///
/// Configura as dependências, inicializa a janela do desktop (quando aplicável)
/// e executa a aplicação.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuração de janela apenas para desktop
  if (!kIsWeb) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1200, 800),
      minimumSize: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      windowButtonVisibility: true,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setTitle(
        'Revolução IA - Ferramenta Popular de Inteligência',
      );
    });
  }

  final di = InjectionContainer();
  di.initialize();

  runApp(MyApp(di));
}

/// Widget principal da aplicação.
///
/// Gerencia o tema, configurações globais e navegação principal.
/// Utiliza o padrão Provider para gerenciamento de estado do tema.
class MyApp extends StatefulWidget {
  /// Container de injeção de dependências.
  final InjectionContainer di;

  const MyApp(this.di, {super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    _themeProvider = ThemeProvider();

    // Set up global keyboard shortcuts
    _setupKeyboardShortcuts();
  }

  /// Configura atalhos de teclado globais.
  ///
  /// Atualmente suporta:
  /// - Cmd/Ctrl + Shift + L: Alterna entre tema claro e escuro
  void _setupKeyboardShortcuts() {
    ServicesBinding.instance.keyboard.addHandler((KeyEvent event) {
      if (event is KeyDownEvent) {
        final pressedKeys = HardwareKeyboard.instance.logicalKeysPressed;

        // Atalho para alternar tema: Cmd/Ctrl + Shift + L
        if ((pressedKeys.contains(LogicalKeyboardKey.metaLeft) ||
                pressedKeys.contains(LogicalKeyboardKey.controlLeft)) &&
            pressedKeys.contains(LogicalKeyboardKey.shiftLeft) &&
            pressedKeys.contains(LogicalKeyboardKey.keyL)) {
          _themeProvider.toggleTheme();
          return true;
        }
      }
      return false;
    });
  }

  /// Constrói o tema claro da aplicação.
  ///
  /// Utiliza Material Design 3 com cores personalizadas inspiradas no iOS.
  /// Retorna um [ThemeData] configurado para o modo claro.
  ThemeData _buildMaterialLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF007AFF),
        secondary: Color(0xFF34C759),
        surface: Color(0xFFFAFAFC),
        onSurface: Color(0xFF1C1C1E),
      ),
      scaffoldBackgroundColor: const Color(0xFFFAFAFC),
      cardColor: const Color(0xFFFFFFFF),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFAFAFC),
        foregroundColor: Color(0xFF1C1C1E),
        elevation: 0,
      ),
    );
  }

  /// Constrói o tema escuro da aplicação.
  ///
  /// Utiliza Material Design 3 com cores personalizadas para modo escuro.
  /// Retorna um [ThemeData] configurado para o modo escuro.
  ThemeData _buildMaterialDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF007AFF),
        secondary: Color(0xFF34C759),
        surface: Color(0xFF0F0F11),
        onSurface: Color(0xFFF2F2F7),
      ),
      scaffoldBackgroundColor: const Color(0xFF0F0F11),
      cardColor: const Color(0xFF1C1C1E),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F0F11),
        foregroundColor: Color(0xFFF2F2F7),
        elevation: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _themeProvider,
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Local LLM Chat',
            theme: themeProvider.buildLightTheme(),
            darkTheme: themeProvider.buildDarkTheme(),
            themeMode: themeProvider.themeMode,
            home: HomePage(
              controller: widget.di.controller,
              themeProvider: themeProvider,
            ),
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              // Configuração global de animações
              return Animate(
                effects: [FadeEffect(duration: 400.ms)],
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
