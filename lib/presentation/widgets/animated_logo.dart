import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimatedLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const AnimatedLogo({
    super.key,
    this.size = 120,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = color ?? theme.colorScheme.primary;
    
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Círculo de fundo pulsante
          Container(
            width: size * 0.9,
            height: size * 0.9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withValues(alpha: 0.1),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.1, 1.1),
                duration: 2000.ms,
              )
              .then()
              .scale(
                begin: const Offset(1.1, 1.1),
                end: const Offset(1.0, 1.0),
                duration: 2000.ms,
              ),
          
          // Círculos orbitais
          ...List.generate(3, (index) {
            final radius = size * (0.35 + index * 0.1);
            final delay = index * 800;
            
            return SizedBox(
              width: radius * 2,
              height: radius * 2,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.15 - index * 0.03),
                    width: 1,
                  ),
                ),
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .rotate(duration: (4000 + index * 1000).ms, begin: 0, end: 1)
                .fadeIn(delay: delay.ms, duration: 800.ms);
          }),
          
          // Ícone central com efeito de shimmer
          Container(
            width: size * 0.4,
            height: size * 0.4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withValues(alpha: 0.15),
            ),
            child: Icon(
              Icons.psychology_rounded,
              size: size * 0.25,
              color: primaryColor,
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(
                duration: 2500.ms,
                color: primaryColor.withValues(alpha: 0.3),
              )
              .scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.05, 1.05),
                duration: 3000.ms,
              )
              .then()
              .scale(
                begin: const Offset(1.05, 1.05),
                end: const Offset(1.0, 1.0),
                duration: 3000.ms,
              ),
          
          // Partículas flutuantes
          ...List.generate(6, (index) {
            final angle = (index * 60) * (3.14159 / 180);
            final distance = size * 0.45;
            final x = distance * math.cos(angle);
            final y = distance * math.sin(angle);
            
            return Positioned(
              left: size / 2 + x - 3,
              top: size / 2 + y - 3,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withValues(alpha: 0.6),
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat())
                  .fadeIn(
                    delay: (index * 300).ms,
                    duration: 800.ms,
                  )
                  .then()
                  .fadeOut(duration: 800.ms)
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1.2, 1.2),
                    duration: 1600.ms,
                  )
                  .then()
                  .scale(
                    begin: const Offset(1.2, 1.2),
                    end: const Offset(0.5, 0.5),
                    duration: 0.ms,
                  ),
            );
          }),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 800.ms)
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0));
  }
}

