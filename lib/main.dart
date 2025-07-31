import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/di/injection_container.dart';
import 'presentation/pages/home_page.dart';

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
      await windowManager.setTitle('Revolução IA - Ferramenta Popular de Inteligência');
    });
  }

  final di = InjectionContainer();
  di.initialize();
  
  runApp(MyApp(di));
}

class MyApp extends StatelessWidget {
  final InjectionContainer di;

  const MyApp(this.di, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Revolução IA - Ferramenta Popular',
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.system,
      home: HomePage(controller: di.controller),
      debugShowCheckedModeBanner: false,
    );
  }

  ThemeData _buildLightTheme() {
    // Tema Revolucionário Marxista Brasileiro - Cores da revolução
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFCC0000), // Vermelho revolucionário
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFFCC0000), // Vermelho da bandeira
      secondary: const Color(0xFFFFD700), // Dourado/Amarelo do trabalho
      tertiary: const Color(0xFF228B22), // Verde da esperança
      surface: const Color(0xFFFFF8DC), // Bege suave (cor do papel antigo)
      primaryContainer: const Color(0xFFFFE4E1), 
      secondaryContainer: const Color(0xFFFFFACD),
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      textTheme: GoogleFonts.crimsonTextTextTheme(), // Fonte mais revolucionária
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: GoogleFonts.crimsonText(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    // Tema Noturno da Revolução - Cores da luta noturna
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFDC143C), // Vermelho mais intenso
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFFDC143C), // Vermelho intenso
      secondary: const Color(0xFFFFD700), // Dourado brilhante
      tertiary: const Color(0xFF32CD32), // Verde mais vibrante
      surface: const Color(0xFF1A0000), // Vermelho muito escuro
      primaryContainer: const Color(0xFF4A0000),
      secondaryContainer: const Color(0xFF4A4A00),
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      textTheme: GoogleFonts.crimsonTextTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: GoogleFonts.crimsonText(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
      ),
    );
  }
}
