import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/theme/unified_theme.dart';
import 'presentation/providers/app_providers.dart';
import 'presentation/pages/splash_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: LocalLLMApp(),
    ),
  );
}

class LocalLLMApp extends ConsumerWidget {
  const LocalLLMApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Local LLM Chat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const SplashScreen(),
    );
  }
}
