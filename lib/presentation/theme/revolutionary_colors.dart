import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Sistema de Cores Revolucionário - Inspirado na luta popular e resistência
class RevolutionaryColors {
  // === CORES PRIMÁRIAS DA REVOLUÇÃO ===
  
  // Vermelho da Revolução - Cor do sangue dos mártires e da luta
  static const Color kRevolutionRed = Color(0xFFDC143C);
  static const Color kRevolutionRedDark = Color(0xFFB71C1C);
  static const Color kRevolutionRedLight = Color(0xFFFF4569);
  
  // Verde da Esperança - Cor da natureza e do futuro
  static const Color kHopeGreen = Color(0xFF2E7D32);
  static const Color kHopeGreenDark = Color(0xFF1B5E20);
  static const Color kHopeGreenLight = Color(0xFF4CAF50);
  
  // Dourado do Povo - Cor da riqueza que pertence ao povo
  static const Color kPeopleGold = Color(0xFFFFB300);
  static const Color kPeopleGoldDark = Color(0xFFFF8F00);
  static const Color kPeopleGoldLight = Color(0xFFFFD54F);
  
  // Azul da Unidade - Cor do céu e da união
  static const Color kUnityBlue = Color(0xFF1565C0);
  static const Color kUnityBlueDark = Color(0xFF0D47A1);
  static const Color kUnityBlueLight = Color(0xFF42A5F5);

  // === CORES DE FUNDO - TEMA ESCURO (Noite da Resistência) ===
  
  // Preto da Resistência - Fundo principal
  static const Color kResistanceBlack = Color(0xFF0A0A0A);
  static const Color kResistanceBlackSoft = Color(0xFF121212);
  static const Color kResistanceBlackCard = Color(0xFF1A1A1A);
  static const Color kResistanceBlackSurface = Color(0xFF242424);
  
  // Cinza da Luta - Tons intermediários
  static const Color kStruggleGray = Color(0xFF2E2E2E);
  static const Color kStruggleGrayLight = Color(0xFF3C3C3C);
  static const Color kStruggleGrayDark = Color(0xFF1C1C1C);
  
  // === CORES DE FUNDO - TEMA CLARO (Amanhecer da Liberdade) ===
  
  // Branco da Liberdade - Fundo principal claro
  static const Color kFreedomWhite = Color(0xFFFAFAFA);
  static const Color kFreedomWhiteSoft = Color(0xFFF5F5F5);
  static const Color kFreedomWhiteCard = Color(0xFFFFFFFF);
  static const Color kFreedomWhiteSurface = Color(0xFFF8F8F8);
  
  // Cinza da Paz - Tons intermediários claros
  static const Color kPeaceGray = Color(0xFFE8E8E8);
  static const Color kPeaceGrayLight = Color(0xFFF0F0F0);
  static const Color kPeaceGrayDark = Color(0xFFDDDDDD);

  // === CORES DE TEXTO ===
  
  // Texto no tema escuro
  static const Color kTextOnDark = Color(0xFFFFFFFF);
  static const Color kTextOnDarkSecondary = Color(0xFFE0E0E0);
  static const Color kTextOnDarkTertiary = Color(0xFFBDBDBD);
  static const Color kTextOnDarkDisabled = Color(0xFF757575);
  
  // Texto no tema claro
  static const Color kTextOnLight = Color(0xFF1C1C1C);
  static const Color kTextOnLightSecondary = Color(0xFF424242);
  static const Color kTextOnLightTertiary = Color(0xFF616161);
  static const Color kTextOnLightDisabled = Color(0xFF9E9E9E);

  // === CORES SEMÂNTICAS ===
  
  // Sucesso - Verde da vitória
  static const Color kSuccess = Color(0xFF388E3C);
  static const Color kSuccessLight = Color(0xFF66BB6A);
  static const Color kSuccessDark = Color(0xFF2E7D32);
  
  // Erro - Vermelho do alerta
  static const Color kError = Color(0xFFD32F2F);
  static const Color kErrorLight = Color(0xFFEF5350);
  static const Color kErrorDark = Color(0xFFC62828);
  
  // Aviso - Laranja da cautela
  static const Color kWarning = Color(0xFFF57C00);
  static const Color kWarningLight = Color(0xFFFFB74D);
  static const Color kWarningDark = Color(0xFFEF6C00);
  
  // Informação - Azul da clareza
  static const Color kInfo = Color(0xFF1976D2);
  static const Color kInfoLight = Color(0xFF64B5F6);
  static const Color kInfoDark = Color(0xFF1565C0);

  // === GRADIENTES REVOLUCIONÁRIOS ===
  
  // Gradiente do Amanhecer Revolucionário
  static const LinearGradient kDawnGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0A0A0A), // Noite
      Color(0xFF1A1A1A), // Aurora
      Color(0xFF2E1A1A), // Primeiro raio
    ],
    stops: [0.0, 0.6, 1.0],
  );
  
  // Gradiente do Entardecer da Resistência
  static const LinearGradient kDuskGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFAFAFA), // Dia
      Color(0xFFF0F0F0), // Crepúsculo  
      Color(0xFFE8E0E0), // Último raio
    ],
    stops: [0.0, 0.6, 1.0],
  );
  
  // Gradiente da Bandeira Vermelha
  static const LinearGradient kRedFlagGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kRevolutionRed, kRevolutionRedDark],
  );
  
  // Gradiente da Esperança Verde
  static const LinearGradient kGreenHopeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kHopeGreen, kHopeGreenDark],
  );
  
  // Gradiente do Ouro Popular
  static const LinearGradient kGoldPeopleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kPeopleGold, kPeopleGoldDark],
  );

  // === GRADIENTES DE CARTÕES ===
  
  // Cartão escuro da resistência
  static const LinearGradient kDarkCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A1A1A),
      Color(0xFF242424),
      Color(0xFF1C1C1C),
    ],
    stops: [0.0, 0.5, 1.0],
  );
  
  // Cartão claro da liberdade
  static const LinearGradient kLightCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF8F8F8),
      Color(0xFFF5F5F5),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // === GRADIENTES DE MENSAGENS ===
  
  // Bolha do usuário - Fogo da revolução
  static const LinearGradient kUserBubbleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFDC143C), // Vermelho revolução
      Color(0xFFB71C1C), // Vermelho escuro
      Color(0xFF8B0000), // Vermelho sangue
    ],
    stops: [0.0, 0.6, 1.0],
  );
  
  // Bolha da IA escura - Sabedoria da noite
  static const LinearGradient kAIBubbleDarkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2E2E2E),
      Color(0xFF242424),
      Color(0xFF1A1A1A),
    ],
    stops: [0.0, 0.5, 1.0],
  );
  
  // Bolha da IA clara - Clareza do dia
  static const LinearGradient kAIBubbleLightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF8F8F8),
      Color(0xFFF0F0F0),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // === MÉTODOS UTILITÁRIOS ===
  
  /// Obtém a cor de fundo baseada no tema
  static Color getBackgroundColor(bool isDark) {
    return isDark ? kResistanceBlack : kFreedomWhite;
  }
  
  /// Obtém a cor de cartão baseada no tema
  static Color getCardColor(bool isDark) {
    return isDark ? kResistanceBlackCard : kFreedomWhiteCard;
  }
  
  /// Obtém a cor de superfície baseada no tema
  static Color getSurfaceColor(bool isDark) {
    return isDark ? kResistanceBlackSurface : kFreedomWhiteSurface;
  }
  
  /// Obtém a cor de texto primária baseada no tema
  static Color getPrimaryTextColor(bool isDark) {
    return isDark ? kTextOnDark : kTextOnLight;
  }
  
  /// Obtém a cor de texto secundária baseada no tema
  static Color getSecondaryTextColor(bool isDark) {
    return isDark ? kTextOnDarkSecondary : kTextOnLightSecondary;
  }
  
  /// Obtém o gradiente de fundo baseado no tema
  static LinearGradient getBackgroundGradient(bool isDark) {
    return isDark ? kDawnGradient : kDuskGradient;
  }
  
  /// Obtém o gradiente de cartão baseado no tema
  static LinearGradient getCardGradient(bool isDark) {
    return isDark ? kDarkCardGradient : kLightCardGradient;
  }
  
  /// Obtém o gradiente de bolha da IA baseado no tema
  static LinearGradient getAIBubbleGradient(bool isDark) {
    return isDark ? kAIBubbleDarkGradient : kAIBubbleLightGradient;
  }

  // === CORES DE SOMBRA REVOLUCIONÁRIAS ===
  
  /// Sombra escura com intensidade variável
  static Color getDarkShadow(double intensity) {
    return Colors.black.withValues(alpha: math.min(intensity * 0.9, 0.8));
  }
  
  /// Sombra clara com intensidade variável
  static Color getLightShadow(double intensity) {
    return const Color(0xFF000000).withValues(alpha: math.min(intensity * 0.2, 0.15));
  }
  
  /// Sombra colorida baseada na cor principal
  static Color getColoredShadow(Color baseColor, double intensity) {
    return baseColor.withValues(alpha: math.min(intensity * 0.4, 0.3));
  }
  
  /// Sombra vermelha revolucionária
  static Color getRevolutionShadow(double intensity) {
    return kRevolutionRed.withValues(alpha: math.min(intensity * 0.5, 0.4));
  }
  
  /// Sombra dourada do povo
  static Color getGoldenShadow(double intensity) {
    return kPeopleGold.withValues(alpha: math.min(intensity * 0.3, 0.25));
  }

  // === CORES COM OPACIDADE ===
  
  /// Cor vermelha com opacidade
  static Color getRevolutionRedWithOpacity(double opacity) {
    return kRevolutionRed.withValues(alpha: math.min(opacity, 1.0));
  }
  
  /// Cor verde com opacidade
  static Color getHopeGreenWithOpacity(double opacity) {
    return kHopeGreen.withValues(alpha: math.min(opacity, 1.0));
  }
  
  /// Cor dourada com opacidade
  static Color getPeopleGoldWithOpacity(double opacity) {
    return kPeopleGold.withValues(alpha: math.min(opacity, 1.0));
  }
  
  /// Cor azul com opacidade
  static Color getUnityBlueWithOpacity(double opacity) {
    return kUnityBlue.withValues(alpha: math.min(opacity, 1.0));
  }

  // === CORES DE ESTADO PARA COMPONENTES ===
  
  /// Cor de hover para botões
  static Color getHoverColor(Color baseColor, bool isDark) {
    if (isDark) {
      return Color.lerp(baseColor, Colors.white, 0.1) ?? baseColor;
    } else {
      return Color.lerp(baseColor, Colors.black, 0.1) ?? baseColor;
    }
  }
  
  /// Cor de pressed para botões
  static Color getPressedColor(Color baseColor, bool isDark) {
    if (isDark) {
      return Color.lerp(baseColor, Colors.black, 0.2) ?? baseColor;
    } else {
      return Color.lerp(baseColor, Colors.white, 0.2) ?? baseColor;
    }
  }
  
  /// Cor de foco para inputs
  static Color getFocusColor(bool isDark) {
    return isDark ? kUnityBlueLight : kUnityBlue;
  }
  
  /// Cor de border para inputs
  static Color getBorderColor(bool isDark, {bool isActive = false}) {
    if (isActive) {
      return isDark ? kUnityBlueLight : kUnityBlue;
    }
    return isDark ? kStruggleGray : kPeaceGray;
  }

  // === PALETA EXTENDIDA PARA VARIAÇÕES ===
  
  // Tons de vermelho revolucionário
  static const List<Color> kRevolutionRedPalette = [
    Color(0xFF8B0000), // Mais escuro
    Color(0xFFB71C1C),
    Color(0xFFDC143C), // Principal
    Color(0xFFFF4569),
    Color(0xFFFF6B93), // Mais claro
  ];
  
  // Tons de verde da esperança
  static const List<Color> kHopeGreenPalette = [
    Color(0xFF1B5E20), // Mais escuro
    Color(0xFF2E7D32),
    Color(0xFF4CAF50), // Principal
    Color(0xFF66BB6A),
    Color(0xFF81C784), // Mais claro
  ];
  
  // Tons de dourado do povo
  static const List<Color> kPeopleGoldPalette = [
    Color(0xFFFF8F00), // Mais escuro
    Color(0xFFFFB300),
    Color(0xFFFFD54F), // Principal
    Color(0xFFFFE082),
    Color(0xFFFFF3C4), // Mais claro
  ];
  
  /// Obtém uma cor da paleta baseada no índice
  static Color getColorFromPalette(List<Color> palette, int index) {
    return palette[index.clamp(0, palette.length - 1)];
  }
}