/// Biblioteca que define o sistema de cores minimalista da aplicação.
/// 
/// Esta biblioteca contém a classe [ThemeColors] que implementa
/// um sistema de cores flat e minimalista com paletas para temas
/// claro e escuro, cores semânticas, gradientes suaves e métodos
/// utilitários para gerenciamento de temas.
/// 
/// O sistema foca em:
/// - Design flat e minimalista
/// - Cores limpas e modernas
/// - Gradientes sutis
/// - Boa legibilidade em ambos os temas
/// - Cores semânticas consistentes
library;

import 'package:flutter/material.dart';

/// Sistema de cores minimalista flat para a aplicação.
/// 
/// Esta classe fornece um conjunto completo de cores organizadas
/// para criar uma interface flat e minimalista. Inclui cores para
/// temas claro e escuro, cores de destaque, cores semânticas e
/// gradientes sutis.
/// 
/// Características:
/// - Design flat com profundidade sutil
/// - Cores inspiradas no design moderno iOS/Material
/// - Alta legibilidade em ambos os temas
/// - Gradientes mínimos para profundidade
/// 
/// Exemplo de uso:
/// ```dart
/// // Obter cores baseadas no tema
/// final bgColor = ThemeColors.getBg(isDark);
/// final textColor = ThemeColors.getOnSurface(isDark);
/// 
/// // Usar gradientes
/// Container(
///   decoration: BoxDecoration(
///     gradient: ThemeColors.getBgGradient(isDark),
///   ),
/// )
/// 
/// // Cores semânticas
/// Text(
///   'Sucesso',
///   style: TextStyle(color: ThemeColors.kSuccess),
/// )
/// ```
class ThemeColors {
  // === TEMA ESCURO MINIMALISTA ===
  
  /// Cor de fundo principal do tema escuro.
  /// Um preto quase puro com leve tonalidade azulada para suavidade.
  static const Color kDarkBg = Color(0xFF0F0F11);
  
  /// Cor de fundo para cartões no tema escuro.
  /// Ligeiramente mais clara que o fundo para criar separação visual.
  static const Color kDarkCardBg = Color(0xFF1C1C1E);
  
  /// Cor de superfíie para elementos elevados no tema escuro.
  static const Color kDarkSurface = Color(0xFF2C2C2E);
  
  /// Variação da cor de superfíie para elementos interativos.
  static const Color kDarkSurfaceVariant = Color(0xFF3A3A3C);
  
  // === CORES DE TEXTO - TEMA ESCURO ===
  
  /// Cor de texto sobre elementos primários no tema escuro.
  static const Color kDarkOnPrimary = Color(0xFF0F0F11);
  
  /// Cor de texto principal sobre superfícies no tema escuro.
  /// Branco quase puro para máxima legibilidade.
  static const Color kDarkOnSurface = Color(0xFFF2F2F7);
  
  /// Cor de texto secundária sobre superfícies no tema escuro.
  /// Cinza claro para texto menos importante.
  static const Color kDarkOnSurfaceVariant = Color(0xFFAEAEB2);
  
  /// Cor de texto sobre cartões no tema escuro.
  static const Color kDarkOnCard = Color(0xFFE5E5EA);
  
  // === TEMA CLARO MINIMALISTA ===
  
  /// Cor de fundo principal do tema claro.
  /// Branco ligeiramente azulado para reduzir o cansaço visual.
  static const Color kLightBg = Color(0xFFFAFAFC);
  
  /// Cor de fundo para cartões no tema claro.
  /// Branco puro para máximo contraste.
  static const Color kLightCardBg = Color(0xFFFFFFFF);
  
  /// Cor de superfíie para elementos elevados no tema claro.
  static const Color kLightSurface = Color(0xFFF7F7F9);
  
  /// Variação da cor de superfíie para elementos interativos.
  static const Color kLightSurfaceVariant = Color(0xFFF0F0F2);
  
  // === CORES DE TEXTO - TEMA CLARO ===
  
  /// Cor de texto sobre elementos primários no tema claro.
  static const Color kLightOnPrimary = Color(0xFFFFFFFF);
  
  /// Cor de texto principal sobre superfícies no tema claro.
  /// Preto quase puro para máxima legibilidade.
  static const Color kLightOnSurface = Color(0xFF1C1C1E);
  
  /// Cor de texto secundária sobre superfícies no tema claro.
  /// Cinza médio para texto menos importante.
  static const Color kLightOnSurfaceVariant = Color(0xFF8E8E93);
  
  /// Cor de texto sobre cartões no tema claro.
  static const Color kLightOnCard = Color(0xFF2C2C2E);

  // === CORES DE DESTAQUE MINIMALISTAS ===
  
  /// Cor de destaque principal - azul limpo inspirado no iOS.
  static const Color kAccent = Color(0xFF007AFF);
  
  /// Variação escura da cor de destaque.
  static const Color kAccentDark = Color(0xFF0051D6);
  
  /// Variação clara da cor de destaque.
  static const Color kAccentLight = Color(0xFF5AC8FA);
  
  /// Cor de destaque secundária - verde limpo para ações positivas.
  static const Color kSecondaryAccent = Color(0xFF34C759);
  
  // === CORES FUNCIONAIS MINIMALISTAS ===
  
  /// Cor neutra para elementos menos importantes.
  static const Color kMuted = Color(0xFF8E8E93);
  
  /// Variação mais clara da cor neutra.
  static const Color kMutedLight = Color(0xFFAEAEB2);
  
  /// Cor de borda para tema escuro.
  static const Color kBorder = Color(0xFF38383A);
  
  /// Cor de borda para tema claro.
  static const Color kBorderLight = Color(0xFFE5E5EA);
  
  // === CORES SEMÂNTICAS LIMPAS ===
  
  /// Cor para indicar erros - vermelho vibrante mas não agressivo.
  static const Color kError = Color(0xFFFF3B30);
  
  /// Variação mais clara da cor de erro.
  static const Color kErrorLight = Color(0xFFFF6961);
  
  /// Cor para avisos - laranja equilibrado.
  static const Color kWarning = Color(0xFFFF9500);
  
  /// Cor para sucesso - verde natural e confiável.
  static const Color kSuccess = Color(0xFF34C759);
  
  /// Cor para informações - azul suave e não intrusivo.
  static const Color kInfo = Color(0xFF5AC8FA);

  // === GRADIENTES MINIMALISTAS COM PROFUNDIDADE SUTIL ===
  
  /// Gradiente de fundo para tema escuro.
  /// Cria uma transição sutil de cima para baixo com profundidade mínima.
  static const LinearGradient kDarkBgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0F0F11),
      Color(0xFF1C1C1E),
    ],
  );

  /// Gradiente de fundo para tema claro.
  /// Cria uma transição sutil que adiciona profundidade sem chamar atenção.
  static const LinearGradient kLightBgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFAFAFC),
      Color(0xFFF7F7F9),
    ],
  );

  /// Gradiente para cartões no tema escuro.
  /// Proporciona elevação visual sutil mantendo o design flat.
  static const LinearGradient kCardGradientDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1C1C1E),
      Color(0xFF2C2C2E),
    ],
  );

  /// Gradiente para cartões no tema claro.
  /// Adiciona profundidade mínima para destacar conteúdo do fundo.
  static const LinearGradient kCardGradientLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF7F7F9),
    ],
  );

  // === GRADIENTES PARA BOLHAS DE MENSAGEM ===
  
  /// Gradiente para bolhas de mensagem do usuário.
  /// Usa cor sólida para manter consistência com o design flat.
  static const LinearGradient kUserBubbleGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [kAccent, kAccent],
  );

  /// Gradiente para bolhas de mensagem da IA no tema escuro.
  /// Mantém consistência visual com cores sólidas.
  static const LinearGradient kAiBubbleGradientDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF2C2C2E),
      Color(0xFF2C2C2E),
    ],
  );

  /// Gradiente para bolhas de mensagem da IA no tema claro.
  /// Usa branco sólido para máximo contraste e legibilidade.
  static const LinearGradient kAiBubbleGradientLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFFFFFFF),
    ],
  );

  // === CORES DE SOMBRA MINIMALISTAS ===
  
  /// Gera cor de sombra para tema escuro com opacidade ajustável.
  /// 
  /// Parâmetros:
  /// - [opacity]: Opacidade da sombra (0.0 a 1.0).
  /// 
  /// Retorna uma cor preta com opacidade reduzida para design flat.
  static Color getDarkShadow(double opacity) => 
      Colors.black.withValues(alpha: opacity * 0.3);
      
  /// Gera cor de sombra para tema claro com opacidade ajustável.
  /// 
  /// Parâmetros:
  /// - [opacity]: Opacidade da sombra (0.0 a 1.0).
  /// 
  /// Retorna uma sombra sutil adequada para o design flat claro.
  static Color getLightShadow(double opacity) => 
      const Color(0xFF000000).withValues(alpha: opacity * 0.08);

  // === VARIAÇÕES DE CORES COM OPACIDADE ===
  
  /// Obtém a cor de destaque com opacidade personalizada.
  /// 
  /// Parâmetros:
  /// - [opacity]: Nível de opacidade (0.0 a 1.0).
  /// 
  /// Útil para estados de hover, pressed ou elementos semi-transparentes.
  static Color getAccentWithOpacity(double opacity) =>
      kAccent.withValues(alpha: opacity);
      
  /// Obtém a cor de erro com opacidade personalizada.
  /// 
  /// Parâmetros:
  /// - [opacity]: Nível de opacidade (0.0 a 1.0).
  /// 
  /// Útil para fundos de erro sutis ou elementos de validação.
  static Color getErrorWithOpacity(double opacity) =>
      kError.withValues(alpha: opacity);

  // === MÉTODOS UTILITÁRIOS PARA CORES TEMÁTICAS ===
  
  /// Obtém a cor de texto sobre superfície baseada no tema.
  /// 
  /// Parâmetros:
  /// - [isDark]: Se true, retorna cor para tema escuro.
  static Color getOnSurface(bool isDark) =>
      isDark ? kDarkOnSurface : kLightOnSurface;
      
  /// Obtém a cor de superfície baseada no tema.
  /// 
  /// Parâmetros:
  /// - [isDark]: Se true, retorna cor para tema escuro.
  static Color getSurface(bool isDark) =>
      isDark ? kDarkSurface : kLightSurface;
      
  /// Obtém a cor de fundo de cartão baseada no tema.
  /// 
  /// Parâmetros:
  /// - [isDark]: Se true, retorna cor para tema escuro.
  static Color getCardBg(bool isDark) =>
      isDark ? kDarkCardBg : kLightCardBg;
      
  /// Obtém a cor de fundo principal baseada no tema.
  /// 
  /// Parâmetros:
  /// - [isDark]: Se true, retorna cor para tema escuro.
  static Color getBg(bool isDark) =>
      isDark ? kDarkBg : kLightBg;
      
  /// Obtém o gradiente de fundo baseado no tema.
  /// 
  /// Parâmetros:
  /// - [isDark]: Se true, retorna gradiente para tema escuro.
  static LinearGradient getBgGradient(bool isDark) =>
      isDark ? kDarkBgGradient : kLightBgGradient;
      
  /// Obtém o gradiente de cartão baseado no tema.
  /// 
  /// Parâmetros:
  /// - [isDark]: Se true, retorna gradiente para tema escuro.
  static LinearGradient getCardGradient(bool isDark) =>
      isDark ? kCardGradientDark : kCardGradientLight;
}