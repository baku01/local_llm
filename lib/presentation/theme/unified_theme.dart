/// Sistema unificado de tema para a aplicação
import 'package:flutter/material.dart';
import 'typography.dart';

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
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: kPrimary,
        secondary: kSecondary,
        surface: kLightSurface,
        onSurface: Colors.black87,
      ),
      textTheme: AppTypography.buildTextTheme(ThemeData.light().textTheme),
      cardColor: kLightCardBg,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: kPrimary,
        secondary: kSecondary,
        surface: kDarkSurface,
        onSurface: Colors.white,
      ),
      textTheme: AppTypography.buildTextTheme(ThemeData.dark().textTheme),
      cardColor: kDarkCardBg,
    );
  }
}