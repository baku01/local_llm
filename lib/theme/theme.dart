import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class AppTheme {
  // Cores primárias com gradientes suaves
  static const Color primaryBlue = Color(0xFF6366F1);
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color accentTeal = Color(0xFF06B6D4);
  
  // Cores do modo claro - Glassmorphism
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightGlassBackground = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightSurface = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  
  // Cores do modo escuro - Glassmorphism
  static const Color darkBackground = Color(0xFF0F0F23);
  static const Color darkGlassBackground = Color(0xFF1E1E2E);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkBorder = Color(0xFF2D2D44);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: primaryPurple,
        tertiary: accentTeal,
        surface: lightSurface,
        onSurface: lightTextPrimary,
        outline: lightBorder,
      ),
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: lightTextPrimary,
        displayColor: lightTextPrimary,
      ),
      cardColor: lightGlassBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: lightGlassBackground.withValues(alpha: 0.8),
        foregroundColor: lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.inter(
          color: lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: primaryBlue.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightGlassBackground.withValues(alpha: 0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: lightBorder.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: lightBorder.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: primaryPurple,
        tertiary: accentTeal,
        surface: darkSurface,
        onSurface: darkTextPrimary,
        outline: darkBorder,
      ),
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: darkTextPrimary,
        displayColor: darkTextPrimary,
      ),
      cardColor: darkGlassBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: darkGlassBackground.withValues(alpha: 0.8),
        foregroundColor: darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.inter(
          color: darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: primaryBlue.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkGlassBackground.withValues(alpha: 0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: darkBorder.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: darkBorder.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
    );
  }
  
  // Método auxiliar para criar efeito de vidro
  static BoxDecoration glassEffect({
    required bool isDark,
    double opacity = 0.1,
    double blur = 10.0,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: isDark 
          ? darkGlassBackground.withValues(alpha: opacity)
          : lightGlassBackground.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: borderColor ?? (isDark ? darkBorder : lightBorder).withValues(alpha: 0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
          blurRadius: blur,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
  
  // Método para criar backdrop filter
  static Widget glassContainer({
    required Widget child,
    required bool isDark,
    double opacity = 0.1,
    double blur = 10.0,
    EdgeInsets? padding,
    BorderRadius? borderRadius,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: glassEffect(
            isDark: isDark,
            opacity: opacity,
            blur: blur,
          ),
          child: child,
        ),
      ),
    );
  }
}