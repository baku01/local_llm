import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tipografia minimalista com foco na legibilidade e hierarquia visual
class AppTypography {
  static TextTheme buildTextTheme(TextTheme base) {
    return base.copyWith(
      // Títulos principais - utilizando Inter Bold para impacto minimalista
      displayLarge: GoogleFonts.inter(
        fontSize: 40,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.5,
        height: 1.2,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        height: 1.25,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.3,
      ),

      // Títulos de seções
      headlineLarge: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        height: 1.35,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.4,
      ),

      // Títulos de componentes
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.45,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.5,
      ),

      // Textos do corpo - espaçamento generoso para respiração
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.75, // Espaçamento generoso para leitura
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.7,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.6,
      ),

      // Labels e botões
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.4,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.3,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.2,
      ),
    );
  }

  /// Estilos especiais para o design minimalista
  static TextStyle get codeStyle => GoogleFonts.jetBrainsMono(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        height: 1.6,
      );

  static TextStyle get buttonTextStyle => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.75,
      );

  static TextStyle get captionStyle => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.3,
      );
}
