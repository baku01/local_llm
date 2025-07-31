import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ThinkingAnimation extends StatelessWidget {
  final String thinkingText;
  final bool isVisible;
  final VoidCallback? onDismiss;

  const ThinkingAnimation({
    super.key,
    required this.thinkingText,
    required this.isVisible,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 4,
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.psychology_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .shimmer(duration: 2000.ms, color: theme.colorScheme.primary.withValues(alpha: 0.3))
                      .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1))
                      .then()
                      .scale(begin: const Offset(1.1, 1.1), end: const Offset(1, 1)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Modelo pensando...',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (onDismiss != null)
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: onDismiss,
                      color: theme.colorScheme.onSurfaceVariant,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  _cleanThinkingText(thinkingText),
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _AnimatedDot(delay: 0),
                  const SizedBox(width: 4),
                  _AnimatedDot(delay: 200),
                  const SizedBox(width: 4),
                  _AnimatedDot(delay: 400),
                  const Spacer(),
                  Text(
                    'Processando...',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: -0.3, end: 0)
        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }

  String _cleanThinkingText(String text) {
    // Remove as tags <think> e </think>
    return text
        .replaceAll('<think>', '')
        .replaceAll('</think>', '')
        .trim();
  }
}

class _AnimatedDot extends StatelessWidget {
  final int delay;

  const _AnimatedDot({required this.delay});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        shape: BoxShape.circle,
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .fadeIn(delay: delay.ms, duration: 600.ms)
        .then()
        .fadeOut(duration: 600.ms);
  }
}

class ThinkingIndicator extends StatelessWidget {
  final bool isThinking;

  const ThinkingIndicator({
    super.key,
    required this.isThinking,
  });

  @override
  Widget build(BuildContext context) {
    if (!isThinking) return const SizedBox.shrink();

    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.psychology_rounded,
            size: 16,
            color: theme.colorScheme.primary,
          )
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: 2000.ms),
          const SizedBox(width: 6),
          Text(
            'Pensando',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Row(
            children: [
              _AnimatedDot(delay: 0),
              const SizedBox(width: 2),
              _AnimatedDot(delay: 200),
              const SizedBox(width: 2),
              _AnimatedDot(delay: 400),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 200.ms)
        .scale(begin: const Offset(0.8, 0.8));
  }
}