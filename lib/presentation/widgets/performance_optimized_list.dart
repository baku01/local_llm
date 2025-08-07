import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Performance-optimized list widget with intelligent rendering
class PerformanceOptimizedList extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final double? itemExtent;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final bool reverse;
  final Axis scrollDirection;

  const PerformanceOptimizedList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.itemExtent,
    this.controller,
    this.padding,
    this.reverse = false,
    this.scrollDirection = Axis.vertical,
  });

  @override
  State<PerformanceOptimizedList> createState() =>
      _PerformanceOptimizedListState();
}

class _PerformanceOptimizedListState extends State<PerformanceOptimizedList>
    with AutomaticKeepAliveClientMixin {
  late ScrollController _scrollController;
  bool _isScrolling = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    final isScrolling = _scrollController.position.isScrollingNotifier.value;
    if (_isScrolling != isScrolling) {
      setState(() {
        _isScrolling = isScrolling;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification is ScrollStartNotification) {
          setState(() => _isScrolling = true);
        } else if (notification is ScrollEndNotification) {
          setState(() => _isScrolling = false);
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        itemCount: widget.itemCount,
        itemExtent: widget.itemExtent,
        padding: widget.padding,
        reverse: widget.reverse,
        scrollDirection: widget.scrollDirection,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        itemBuilder: (context, index) {
          return _OptimizedListItem(
            key: ValueKey('item_$index'),
            index: index,
            isScrolling: _isScrolling,
            builder: widget.itemBuilder,
          );
        },
      ),
    );
  }
}

class _OptimizedListItem extends StatefulWidget {
  final int index;
  final bool isScrolling;
  final Widget Function(BuildContext context, int index) builder;

  const _OptimizedListItem({
    super.key,
    required this.index,
    required this.isScrolling,
    required this.builder,
  });

  @override
  State<_OptimizedListItem> createState() => _OptimizedListItemState();
}

class _OptimizedListItemState extends State<_OptimizedListItem>
    with AutomaticKeepAliveClientMixin {
  Widget? _cachedWidget;
  bool _isVisible = false;

  @override
  bool get wantKeepAlive => _isVisible;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return VisibilityDetector(
      key: widget.key!,
      onVisibilityChanged: (visibilityInfo) {
        final wasVisible = _isVisible;
        _isVisible = visibilityInfo.visibleFraction > 0.1;

        if (_isVisible != wasVisible) {
          updateKeepAlive();
        }

        if (_isVisible && _cachedWidget == null) {
          setState(() {
            _cachedWidget = widget.builder(context, widget.index);
          });
        }
      },
      child: RepaintBoundary(
        child: _isVisible && _cachedWidget != null
            ? AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: _cachedWidget,
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

/// Custom visibility detector for performance optimization
class VisibilityDetector extends StatefulWidget {
  final Key key;
  final Widget child;
  final Function(VisibilityInfo) onVisibilityChanged;

  const VisibilityDetector({
    required this.key,
    required this.child,
    required this.onVisibilityChanged,
  }) : super(key: key);

  @override
  State<VisibilityDetector> createState() => _VisibilityDetectorState();
}

class _VisibilityDetectorState extends State<VisibilityDetector> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null && renderBox.hasSize) {
            final position = renderBox.localToGlobal(Offset.zero);
            final size = renderBox.size;
            final screenSize = MediaQuery.of(context).size;

            final visibleHeight = _calculateVisibleHeight(
              position,
              size,
              screenSize,
            );

            final visibleFraction = visibleHeight / size.height;

            widget.onVisibilityChanged(
              VisibilityInfo(
                key: widget.key,
                size: size,
                visibleBounds: Rect.fromLTWH(
                  position.dx,
                  position.dy,
                  size.width,
                  visibleHeight,
                ),
                visibleFraction: visibleFraction.clamp(0.0, 1.0),
              ),
            );
          }
        });

        return widget.child;
      },
    );
  }

  double _calculateVisibleHeight(Offset position, Size size, Size screenSize) {
    final top = position.dy;
    final bottom = position.dy + size.height;

    if (bottom <= 0 || top >= screenSize.height) {
      return 0.0;
    }

    final visibleTop = top < 0 ? 0.0 : top;
    final visibleBottom =
        bottom > screenSize.height ? screenSize.height : bottom;

    return (visibleBottom - visibleTop).clamp(0.0, size.height);
  }
}

/// Visibility information for performance optimization
class VisibilityInfo {
  final Key key;
  final Size size;
  final Rect visibleBounds;
  final double visibleFraction;

  const VisibilityInfo({
    required this.key,
    required this.size,
    required this.visibleBounds,
    required this.visibleFraction,
  });
}

/// Smart refresh indicator with enhanced animations
class SmartRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? color;
  final Color? backgroundColor;

  const SmartRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? theme.colorScheme.primary,
      backgroundColor: backgroundColor ?? theme.colorScheme.surface,
      strokeWidth: 3,
      displacement: 60,
      child: child,
    );
  }
}

/// Performance-optimized scroll behavior
class OptimizedScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    switch (getPlatform(context)) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return child;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return GlowingOverscrollIndicator(
          axisDirection: details.direction,
          color: Theme.of(context).colorScheme.primary,
          child: child,
        );
    }
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }
}
