import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'settings_popup.dart';
import '../../domain/entities/llm_model.dart';
import '../providers/theme_provider.dart';

class ResponsiveLayout extends StatefulWidget {
  final Widget content;
  final Widget? floatingActionButton;

  // Settings data
  final List<LlmModel> models;
  final LlmModel? selectedModel;
  final ValueChanged<LlmModel?> onModelSelected;
  final bool isLoading;
  final VoidCallback onRefreshModels;
  final String? errorMessage;
  final bool webSearchEnabled;
  final ValueChanged<bool> onWebSearchToggle;
  final bool isSearching;
  final bool streamEnabled;
  final ValueChanged<bool> onStreamToggle;
  final VoidCallback? onClearChat;
  final ThemeProvider themeProvider;

  const ResponsiveLayout({
    super.key,
    required this.content,
    this.floatingActionButton,
    required this.models,
    required this.selectedModel,
    required this.onModelSelected,
    this.isLoading = false,
    required this.onRefreshModels,
    this.errorMessage,
    required this.webSearchEnabled,
    required this.onWebSearchToggle,
    this.isSearching = false,
    required this.streamEnabled,
    required this.onStreamToggle,
    this.onClearChat,
    required this.themeProvider,
  });

  @override
  State<ResponsiveLayout> createState() => _ResponsiveLayoutState();
}

class _ResponsiveLayoutState extends State<ResponsiveLayout>
    with TickerProviderStateMixin {
  late AnimationController _contentController;

  @override
  void initState() {
    super.initState();
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _contentController.forward();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBreakpoints.builder(
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: _buildSimpleLayout(context),
            floatingActionButton: widget.floatingActionButton,
          );
        },
      ),
      breakpoints: [
        const Breakpoint(start: 0, end: 450, name: MOBILE),
        const Breakpoint(start: 451, end: 800, name: TABLET),
        const Breakpoint(start: 801, end: 1920, name: DESKTOP),
        const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
      ],
    );
  }

  Widget _buildSimpleLayout(BuildContext context) {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(child: _buildContentContainer()),
      ],
    );
  }

  Widget _buildTopBar() {
    final theme = Theme.of(context);

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),

          // Title
          Text(
            'Local LLM Chat',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          const Spacer(),

          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => _showSettingsPopup(context),
          icon: const Icon(Icons.settings),
          tooltip: 'Configurações',
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: widget.themeProvider.toggleTheme,
          icon: Icon(widget.themeProvider.themeIcon),
          tooltip: 'Tema: ${widget.themeProvider.themeName}',
        ),
      ],
    );
  }

  void _showSettingsPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SettingsPopup(
        models: widget.models,
        selectedModel: widget.selectedModel,
        onModelSelected: widget.onModelSelected,
        isLoading: widget.isLoading,
        onRefreshModels: widget.onRefreshModels,
        errorMessage: widget.errorMessage,
        webSearchEnabled: widget.webSearchEnabled,
        onWebSearchToggle: widget.onWebSearchToggle,
        isSearching: widget.isSearching,
        streamEnabled: widget.streamEnabled,
        onStreamToggle: widget.onStreamToggle,
        onClearChat: widget.onClearChat,
      ),
    );
  }

  Widget _buildContentContainer() {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _contentController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: widget.content,
          ),
        );
      },
    );
  }
}

class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final EdgeInsets padding;

  const ResponsiveGridView({
    super.key,
    required this.children,
    this.spacing = 16,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBreakpoints.builder(
      child: Builder(
        builder: (context) {
          final isMobile = ResponsiveBreakpoints.of(context).isMobile;
          final isTablet = ResponsiveBreakpoints.of(context).isTablet;

          int crossAxisCount;
          if (isMobile) {
            crossAxisCount = 1;
          } else if (isTablet) {
            crossAxisCount = 2;
          } else {
            crossAxisCount = 3;
          }

          return Padding(
            padding: padding,
            child: MasonryGridView.count(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              itemCount: children.length,
              itemBuilder: (context, index) {
                return children[index]
                    .animate(delay: (index * 50).ms)
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
              },
            ),
          );
        },
      ),
      breakpoints: [
        const Breakpoint(start: 0, end: 450, name: MOBILE),
        const Breakpoint(start: 451, end: 800, name: TABLET),
        const Breakpoint(start: 801, end: 1920, name: DESKTOP),
        const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
      ],
    );
  }
}

class ResponsiveCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final bool elevated;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.elevated = true,
  });

  @override
  State<ResponsiveCard> createState() => _ResponsiveCardState();
}

class _ResponsiveCardState extends State<ResponsiveCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? theme.colorScheme.primary.withValues(alpha: 0.3)
                : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: widget.elevated
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: _isHovered ? 0.1 : 0.05,
                    ),
                    blurRadius: _isHovered ? 12 : 8,
                    offset: Offset(0, _isHovered ? 6 : 4),
                  ),
                ]
              : null,
        ),
        transform: Matrix4.identity()..translate(0.0, _isHovered ? -2.0 : 0.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: widget.padding ?? const EdgeInsets.all(16),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
