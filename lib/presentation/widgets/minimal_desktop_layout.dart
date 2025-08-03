/// Biblioteca que define o layout desktop minimalista da aplicação.
///
/// Esta biblioteca contém o widget [MinimalDesktopLayout] que implementa
/// um layout responsivo para desktop com sidebar retrátil, área de conteúdo
/// principal e animações suaves entre estados.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'animated_logo.dart';
import '../../theme/theme.dart';

/// Widget de layout desktop minimalista com sidebar retrátil.
///
/// Este widget implementa um layout moderno para desktop que inclui:
/// - Área de conteúdo principal centralizada
/// - Sidebar retrátil com animações suaves
/// - Botão de toggle flutuante com logo
/// - Design flat com sombras sutis
/// - Bordas arredondadas e espaçamento consistente
///
/// O layout é otimizado para telas grandes e oferece uma experiência
/// de usuário limpa e moderna.
///
/// Exemplo de uso:
/// ```dart
/// MinimalDesktopLayout(
///   sidebar: MySettingsSidebar(),
///   content: MyChatInterface(),
/// )
/// ```
class MinimalDesktopLayout extends StatefulWidget {
  /// Widget que será exibido na sidebar retrátil.
  ///
  /// Geralmente contém configurações, opções ou navegação secundária.
  final Widget sidebar;

  /// Widget principal que será exibido na área de conteúdo central.
  ///
  /// Este é o conteúdo principal da aplicação, como chat, editor, etc.
  final Widget content;

  /// Cria um novo layout desktop minimalista.
  ///
  /// Parâmetros:
  /// - [sidebar]: Widget para a sidebar retrátil
  /// - [content]: Widget para o conteúdo principal
  const MinimalDesktopLayout({
    super.key,
    required this.sidebar,
    required this.content,
  });

  @override
  State<MinimalDesktopLayout> createState() => _MinimalDesktopLayoutState();
}

/// Estado interno do [MinimalDesktopLayout].
///
/// Gerencia as animações da sidebar e o estado de expansão/colapso.
class _MinimalDesktopLayoutState extends State<MinimalDesktopLayout>
    with TickerProviderStateMixin {
  /// Indica se a sidebar está expandida ou colapsada.
  bool _isSidebarExpanded = false;

  /// Controlador de animação para transições da sidebar.
  late AnimationController _sidebarController;

  /// Animação curva para movimento suave da sidebar.
  late Animation<double> _sidebarAnimation;

  /// Inicializa o estado e configura as animações da sidebar.
  ///
  /// Cria o controlador de animação com duração de 250ms e
  /// aplica uma curva suave para transições naturais.
  @override
  void initState() {
    super.initState();
    _sidebarController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _sidebarAnimation = CurvedAnimation(
      parent: _sidebarController,
      curve: Curves.easeInOutCubic,
    );
  }

  /// Limpa os recursos quando o widget é removido da árvore.
  ///
  /// Descarta o controlador de animação para evitar vazamentos de memória.
  @override
  void dispose() {
    _sidebarController.dispose();
    super.dispose();
  }

  /// Alterna o estado da sidebar entre expandida e colapsada.
  ///
  /// Atualiza o estado visual e executa a animação correspondente:
  /// - Se expandindo: executa animação para frente
  /// - Se colapsando: executa animação reversa
  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
    });
    if (_isSidebarExpanded) {
      _sidebarController.forward();
    } else {
      _sidebarController.reverse();
    }
  }

  /// Constrói o layout desktop minimalista completo.
  ///
  /// Organiza os elementos em uma estrutura horizontal:
  /// 1. Painel lateral esquerdo com logo e controles
  /// 2. Área de conteúdo principal centralizada com bordas arredondadas
  /// 3. Sidebar retrátil do lado direito com animação
  ///
  /// O layout utiliza cores e estilos do tema atual para consistência visual.
  ///
  /// Parâmetros:
  /// - [context]: Contexto do widget para acessar tema e outras dependências
  ///
  /// Retorna o widget completo do layout desktop.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Row(
        children: [
          // Minimal floating sidebar toggle
          _buildSidebarToggle(context),

          // Main content area
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
                         child: ClipRRect(
                           borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    decoration: AppTheme.glassEffect(
                      isDark: theme.brightness == Brightness.dark,
                      opacity: 0.1,
                      blur: 15,
                    ).copyWith(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.15),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                          spreadRadius: 0,
                  ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: widget.content,
                      ),
                    ),
                  ),
                ),
            ),
          ),

          // Animated sidebar overlay
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _sidebarAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_isSidebarExpanded ? 0 : 320, 0),
                  child: Container(
                    width: 320,
                    height: double.infinity,
                    margin: const EdgeInsets.only(top: 16, right: 16, bottom: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          decoration: AppTheme.glassEffect(
                            isDark: theme.brightness == Brightness.dark,
                            opacity: 0.15,
                            blur: 15,
                          ).copyWith(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: theme.colorScheme.outline.withValues(alpha: 0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 40,
                                offset: const Offset(-6, 10),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: widget.sidebar,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o painel lateral esquerdo com logo e botão de toggle.
  ///
  /// Este painel contém:
  /// - Logo animado da aplicação no topo
  /// - Botão de toggle da sidebar na parte inferior
  /// - Design minimalista com animações suaves
  ///
  /// Parâmetros:
  /// - [context]: Contexto do widget para acessar o tema
  ///
  /// Retorna um widget com o painel de controle lateral.
  Widget _buildSidebarToggle(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          // Logo/Brand
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: AnimatedLogo(size: 32, color: theme.colorScheme.primary),
          ),

          const Spacer(),

          // Sidebar toggle button
          GestureDetector(
            onTap: _toggleSidebar,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isSidebarExpanded
                    ? theme.colorScheme.primary
                    : theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isSidebarExpanded
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isSidebarExpanded
                        ? theme.colorScheme.primary.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: _isSidebarExpanded ? 16 : 8,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: AnimatedRotation(
                turns: _isSidebarExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  Icons.settings_rounded,
                  color: _isSidebarExpanded
                      ? Colors.white
                      : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  size: 20,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 200.ms),

          const Spacer(),
        ],
      ),
    );
  }
}
