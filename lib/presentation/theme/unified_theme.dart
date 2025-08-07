import 'package:flutter/material.dart';
import 'typography.dart';

/// Tema unificado minimalista para a aplicação
///
/// Define uma paleta preto/branco com tons neutros para criar
/// uma interface fluida e focada no conteúdo essencial.
class AppTheme {
  // Paleta minimalista - preto puro, branco puro e tons de cinza
  static const Color kPrimary = Color(0xFF000000); // Preto puro
  static const Color kSecondary = Color(0xFF404040); // Cinza escuro
  static const Color kAccent = Color(0xFF606060); // Cinza médio

  // Cores de fundo - Tema escuro
  static const Color kDarkBg = Color(0xFF000000); // Preto puro
  static const Color kDarkCardBg = Color(0xFF1A1A1A); // Cinza muito escuro
  static const Color kDarkSurface = Color(0xFF2A2A2A); // Cinza escuro

  // Cores de fundo - Tema claro
  static const Color kLightBg = Color(0xFFFFFFFF); // Branco puro
  static const Color kLightCardBg = Color(0xFFF8F8F8); // Cinza muito claro
  static const Color kLightSurface = Color(0xFFE8E8E8); // Cinza claro

  // Cores semânticas em tons neutros
  static const Color kSuccess = Color(0xFF404040); // Cinza escuro
  static const Color kError = Color(0xFF000000); // Preto para destaque
  static const Color kWarning = Color(0xFF606060); // Cinza médio
  static const Color kInfo = Color(0xFF808080); // Cinza

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: kLightBg,
      colorScheme: const ColorScheme.light(
        primary: kPrimary,
        secondary: kSecondary,
        surface: kLightSurface,
        onSurface: kPrimary,
        background: kLightBg,
        onBackground: kPrimary,
        onPrimary: kLightBg,
        onSecondary: kLightBg,
        outline: Color(0xFFBBBBBB),
      ),
      textTheme: AppTypography.buildTextTheme(ThemeData.light().textTheme),
      cardColor: kLightCardBg,
      cardTheme: const CardThemeData(
        color: kLightCardBg,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(
            color: Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        margin: EdgeInsets.all(8),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: kLightBg,
        foregroundColor: kPrimary,
        elevation: 0,
        shadowColor: Colors.transparent,
        centerTitle: true,
      ),
      dividerColor: const Color(0xFFE0E0E0),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: kDarkBg,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFFFFFF),
        secondary: Color(0xFFBBBBBB),
        surface: kDarkSurface,
        onSurface: Color(0xFFFFFFFF),
        background: kDarkBg,
        onBackground: Color(0xFFFFFFFF),
        onPrimary: kDarkBg,
        onSecondary: kDarkBg,
        outline: Color(0xFF404040),
      ),
      textTheme: AppTypography.buildTextTheme(ThemeData.dark().textTheme),
      cardColor: kDarkCardBg,
      cardTheme: const CardThemeData(
        color: kDarkCardBg,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(
            color: Color(0xFF333333),
            width: 1,
          ),
        ),
        margin: EdgeInsets.all(8),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: kDarkBg,
        foregroundColor: Color(0xFFFFFFFF),
        elevation: 0,
        shadowColor: Colors.transparent,
        centerTitle: true,
      ),
      dividerColor: const Color(0xFF333333),
    );
  }

  /// Cria um container minimalista com bordas sutis
  static BoxDecoration minimalContainer({
    required bool isDark,
    double borderRadius = 12,
    bool withBorder = true,
  }) {
    return BoxDecoration(
      color: isDark ? kDarkCardBg : kLightCardBg,
      borderRadius: BorderRadius.circular(borderRadius),
      border: withBorder
          ? Border.all(
              color: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
              width: 1,
            )
          : null,
    );
  }

  /// Espaçamento padrão da aplicação seguindo design minimalista
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 24.0;
  static const double spaceXL = 32.0;
  static const double spaceXXL = 48.0;

  /// Margens responsivas baseadas no tamanho da tela
  static EdgeInsets responsiveMargin(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth > 1200) {
      return const EdgeInsets.symmetric(
          horizontal: spaceXXL, vertical: spaceLG);
    } else if (screenWidth > 800) {
      return const EdgeInsets.symmetric(horizontal: spaceXL, vertical: spaceMD);
    } else {
      return const EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM);
    }
  }

  /// Padding responsivo baseado no tamanho da tela
  static EdgeInsets responsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth > 1200) {
      return const EdgeInsets.all(spaceXL);
    } else if (screenWidth > 800) {
      return const EdgeInsets.all(spaceLG);
    } else {
      return const EdgeInsets.all(spaceMD);
    }
  }

  /// Cria efeito de vidro minimalista (compatibilidade com componentes existentes)
  static BoxDecoration glassEffect({
    required bool isDark,
    double opacity = 0.1,
    double blur = 10,
  }) {
    return minimalContainer(isDark: isDark);
  }
}
