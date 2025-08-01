import 'package:flutter/material.dart';

class ThemeColors {
  // Flat Minimal Dark Theme - Primary colors
  static const Color kDarkBg = Color(0xFF0F0F11);
  static const Color kDarkCardBg = Color(0xFF1C1C1E);
  static const Color kDarkSurface = Color(0xFF2C2C2E);
  static const Color kDarkSurfaceVariant = Color(0xFF3A3A3C);
  
  // Flat Minimal Text Colors - Dark Theme
  static const Color kDarkOnPrimary = Color(0xFF0F0F11);
  static const Color kDarkOnSurface = Color(0xFFF2F2F7);
  static const Color kDarkOnSurfaceVariant = Color(0xFFAEAEB2);
  static const Color kDarkOnCard = Color(0xFFE5E5EA);
  
  // Flat Minimal Light Theme - Primary colors
  static const Color kLightBg = Color(0xFFFAFAFC);
  static const Color kLightCardBg = Color(0xFFFFFFFF);
  static const Color kLightSurface = Color(0xFFF7F7F9);
  static const Color kLightSurfaceVariant = Color(0xFFF0F0F2);
  
  // Flat Minimal Text Colors - Light Theme
  static const Color kLightOnPrimary = Color(0xFFFFFFFF);
  static const Color kLightOnSurface = Color(0xFF1C1C1E);
  static const Color kLightOnSurfaceVariant = Color(0xFF8E8E93);
  static const Color kLightOnCard = Color(0xFF2C2C2E);

  // Minimal Accent Colors
  static const Color kAccent = Color(0xFF007AFF); // Clean blue
  static const Color kAccentDark = Color(0xFF0051D6);
  static const Color kAccentLight = Color(0xFF5AC8FA);
  static const Color kSecondaryAccent = Color(0xFF34C759); // Clean green
  
  // Minimal Functional Colors
  static const Color kMuted = Color(0xFF8E8E93);
  static const Color kMutedLight = Color(0xFFAEAEB2);
  static const Color kBorder = Color(0xFF38383A);
  static const Color kBorderLight = Color(0xFFE5E5EA);
  
  // Clean Semantic colors
  static const Color kError = Color(0xFFFF3B30);
  static const Color kErrorLight = Color(0xFFFF6961);
  static const Color kWarning = Color(0xFFFF9500);
  static const Color kSuccess = Color(0xFF34C759);
  static const Color kInfo = Color(0xFF5AC8FA);

  // Minimal flat gradients with subtle depth
  static const LinearGradient kDarkBgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0F0F11),
      Color(0xFF1C1C1E),
    ],
  );

  static const LinearGradient kLightBgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFAFAFC),
      Color(0xFFF7F7F9),
    ],
  );

  static const LinearGradient kCardGradientDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1C1C1E),
      Color(0xFF2C2C2E),
    ],
  );

  static const LinearGradient kCardGradientLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF7F7F9),
    ],
  );

  // Clean Message Bubble Colors
  static const LinearGradient kUserBubbleGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [kAccent, kAccent],
  );

  static const LinearGradient kAiBubbleGradientDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF2C2C2E),
      Color(0xFF2C2C2E),
    ],
  );

  static const LinearGradient kAiBubbleGradientLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFFFFFFF),
    ],
  );

  // Minimal Shadow Colors for flat design
  static Color getDarkShadow(double opacity) => 
      Colors.black.withValues(alpha: opacity * 0.3);
      
  static Color getLightShadow(double opacity) => 
      const Color(0xFF000000).withValues(alpha: opacity * 0.08);

  // Accent variations for different states
  static Color getAccentWithOpacity(double opacity) =>
      kAccent.withValues(alpha: opacity);
      
  static Color getErrorWithOpacity(double opacity) =>
      kError.withValues(alpha: opacity);

  // Utility methods for theme-aware colors
  static Color getOnSurface(bool isDark) =>
      isDark ? kDarkOnSurface : kLightOnSurface;
      
  static Color getSurface(bool isDark) =>
      isDark ? kDarkSurface : kLightSurface;
      
  static Color getCardBg(bool isDark) =>
      isDark ? kDarkCardBg : kLightCardBg;
      
  static Color getBg(bool isDark) =>
      isDark ? kDarkBg : kLightBg;
      
  static LinearGradient getBgGradient(bool isDark) =>
      isDark ? kDarkBgGradient : kLightBgGradient;
      
  static LinearGradient getCardGradient(bool isDark) =>
      isDark ? kCardGradientDark : kCardGradientLight;
}