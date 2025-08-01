/// Biblioteca que define o widget de logo animado da aplicação.
/// 
/// Esta biblioteca contém o widget [AnimatedLogo] que exibe o logo
/// da aplicação com animações suaves usando Rive, incluindo opções
/// de tamanho, cor e animação de introdução.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart'; // Unused
import 'package:rive/rive.dart';
import '../theme/theme_colors.dart';

/// Widget de logo animado com suporte a Rive e customização visual.
/// 
/// Este widget exibe o logo da aplicação com animações suaves e
/// permite personalização de:
/// - Tamanho do logo
/// - Cor personalizada
/// - Animação de introdução
/// - Integração com animações Rive
/// 
/// Exemplo de uso:
/// ```dart
/// AnimatedLogo(
///   size: 64,
///   color: Colors.blue,
///   showIntro: true,
/// )
/// ```
class AnimatedLogo extends StatefulWidget {
  final double size;
  final Color? color;
  final bool showIntro;

  const AnimatedLogo({
    super.key,
    this.size = 120,
    this.color,
    this.showIntro = false,
  });

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with TickerProviderStateMixin {
  Artboard? _riveArtboard;
  StateMachineController? _stateMachineController;
  SMIInput<bool>? _introTrigger;
  SMIInput<bool>? _idleTrigger;
  late AnimationController _fallbackController;
  bool _useRive = false;

  @override
  void initState() {
    super.initState();
    _setupFallbackAnimation();
    _loadRiveFile();
  }

  void _setupFallbackAnimation() {
    _fallbackController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  void _loadRiveFile() async {
    // Try to load Rive file from assets
    try {
      final riveFile = await RiveFile.asset('assets/rive/logo.riv');
      final artboard = riveFile.mainArtboard;

      final controller = StateMachineController.fromArtboard(
        artboard,
        'State Machine 1',
      );

      if (controller != null) {
        artboard.addController(controller);
        _introTrigger = controller.findInput<bool>('intro');
        _idleTrigger = controller.findInput<bool>('idle');

        setState(() {
          _riveArtboard = artboard;
          _stateMachineController = controller;
          _useRive = true;
        });

        // Trigger intro if requested
        if (widget.showIntro) {
          _triggerIntro();
        } else {
          _triggerIdle();
        }
      }
    } catch (e) {
      // Rive file not found or error loading, use fallback
      _useRive = false;
    }
  }

  void _triggerIntro() {
    _introTrigger?.value = true;
    // After 1.5 seconds, switch to idle
    Future.delayed(const Duration(milliseconds: 1500), () {
      _triggerIdle();
    });
  }

  void _triggerIdle() {
    _idleTrigger?.value = true;
  }

  @override
  void dispose() {
    _fallbackController.dispose();
    _stateMachineController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = widget.color ?? ThemeColors.kAccent;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: _useRive && _riveArtboard != null
          ? Rive(artboard: _riveArtboard!, fit: BoxFit.contain)
          : _buildFallbackLogo(primaryColor, isDark),
    );
  }

  Widget _buildFallbackLogo(Color primaryColor, bool isDark) {
    return AnimatedBuilder(
      animation: _fallbackController,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: LogoPainter(
            progress: _fallbackController.value,
            color: primaryColor,
            isDark: isDark,
          ),
        );
      },
    );
  }
}

class LogoPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isDark;

  LogoPainter({
    required this.progress,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw breathing outer ring
    final breathe = math.sin(progress * 2 * math.pi) * 0.1 + 1.0;
    paint.strokeWidth = 1.5;
    paint.color = color.withValues(alpha: 0.3);
    canvas.drawCircle(center, radius * breathe, paint);

    // Draw rotating segments
    const segmentCount = 8;
    for (int i = 0; i < segmentCount; i++) {
      final angle = (i / segmentCount) * 2 * math.pi + progress * 2 * math.pi;
      final segmentOpacity = (math.sin(progress * 4 * math.pi + i) + 1) / 2;

      final start = Offset(
        center.dx + (radius * 0.6) * math.cos(angle),
        center.dy + (radius * 0.6) * math.sin(angle),
      );

      final end = Offset(
        center.dx + radius * 0.9 * math.cos(angle),
        center.dy + radius * 0.9 * math.sin(angle),
      );

      paint.color = color.withValues(alpha: segmentOpacity * 0.8);
      paint.strokeWidth = 3.0;
      canvas.drawLine(start, end, paint);
    }

    // Draw central core with pulsing effect
    final coreSize =
        radius * 0.3 * (1.0 + math.sin(progress * 4 * math.pi) * 0.2);
    fillPaint.color = color;
    canvas.drawCircle(center, coreSize, fillPaint);

    // Draw inner highlight
    fillPaint.color = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.2);
    canvas.drawCircle(center, coreSize * 0.4, fillPaint);

    // Draw orbiting particles
    const particleCount = 3;
    for (int i = 0; i < particleCount; i++) {
      final orbitRadius = radius * 0.8;
      final particleAngle = (progress + i / particleCount) * 2 * math.pi;
      final particlePos = Offset(
        center.dx + orbitRadius * math.cos(particleAngle),
        center.dy + orbitRadius * math.sin(particleAngle),
      );

      fillPaint.color = color.withValues(alpha: 0.7);
      canvas.drawCircle(particlePos, 3.0, fillPaint);
    }
  }

  @override
  bool shouldRepaint(LogoPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
