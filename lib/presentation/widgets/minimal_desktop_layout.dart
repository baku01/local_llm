import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'animated_logo.dart';

class MinimalDesktopLayout extends StatefulWidget {
  final Widget sidebar;
  final Widget content;

  const MinimalDesktopLayout({
    super.key,
    required this.sidebar,
    required this.content,
  });

  @override
  State<MinimalDesktopLayout> createState() => _MinimalDesktopLayoutState();
}

class _MinimalDesktopLayoutState extends State<MinimalDesktopLayout>
    with TickerProviderStateMixin {
  bool _isSidebarExpanded = false;
  late AnimationController _sidebarController;
  late Animation<double> _sidebarAnimation;

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

  @override
  void dispose() {
    _sidebarController.dispose();
    super.dispose();
  }

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
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
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

          // Animated sidebar overlay
          AnimatedBuilder(
            animation: _sidebarAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  _isSidebarExpanded ? 0 : 320,
                  0,
                ),
                child: Container(
                  width: 320,
                  height: double.infinity,
                  margin: const EdgeInsets.only(top: 16, right: 16, bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 32,
                        offset: const Offset(-4, 8),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: widget.sidebar,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

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