import 'package:flutter/material.dart';

class DesktopLayout extends StatelessWidget {
  final Widget sidebar;
  final Widget content;
  final double sidebarWidth;

  const DesktopLayout({
    super.key,
    required this.sidebar,
    required this.content,
    this.sidebarWidth = 300,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: sidebarWidth,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(
              right: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: sidebar,
        ),
        Expanded(
          child: content,
        ),
      ],
    );
  }
}