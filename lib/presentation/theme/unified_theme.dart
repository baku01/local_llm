import 'package:flutter/material.dart';
import 'typography.dart';

/// Tema unificado para a aplicação
///
/// Define cores, estilos e configurações visuais consistentes
/// para toda a aplicação.
class AppTheme {
  // Cores primárias
  static const Color kPrimary = Color(0xFF7F5AF0);
  static const Color kSecondary = Color(0xFF2CB67D);
  static const Color kAccent = Color(0xFFFF8906);

  // Cores de fundo - Tema escuro
  static const Color kDarkBg = Color(0xFF16161A);
  static const Color kDarkCardBg = Color(0xFF242629);
  static const Color kDarkSurface = Color(0xFF2E2F36);

  // Cores de fundo - Tema claro
  static const Color kLightBg = Color(0xFFF9F9FB);
  static const Color kLightCardBg = Color(0xFFFFFFFF);
  static const Color kLightSurface = Color(0xFFEFEFF1);

  // Cores semânticas
  static const Color kSuccess = Color(0xFF2CB67D);
  static const Color kError = Color(0xFFE53170);
  static const Color kWarning = Color(0xFFFF8906);
  static const Color kInfo = Color(0xFF7F5AF0);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: kPrimary,
      brightness: Brightness.light,
      textTheme: AppTypography.buildTextTheme(ThemeData.light().textTheme),
      cardColor: kLightCardBg,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: kPrimary,
      brightness: Brightness.dark,
      textTheme: AppTypography.buildTextTheme(ThemeData.dark().textTheme),
      cardColor: kDarkCardBg,
    );
  }

  /// Cria um efeito de vidro (glass effect) para containers
  static BoxDecoration glassEffect({
    required bool isDark,
    double opacity = 0.1,
    double blur = 10,
  }) {
    return BoxDecoration(
      color: isDark
          ? Colors.white.withValues(alpha: opacity)
          : Colors.black.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.black.withValues(alpha: 0.1),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
          blurRadius: blur,
          offset: const Offset(0, 4),
          spreadRadius: -2,
        ),
      ],
    );
  }
}
