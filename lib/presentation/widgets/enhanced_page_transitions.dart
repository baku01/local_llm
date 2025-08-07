import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';

/// Custom page transitions with enhanced animations
class EnhancedPageTransitions {
  /// Slide transition with fade effect
  static PageRouteBuilder<T> slideTransition<T>({
    required Widget page,
    required AxisDirection direction,
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeOutCubic,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        Offset begin;
        switch (direction) {
          case AxisDirection.left:
            begin = const Offset(-1.0, 0.0);
            break;
          case AxisDirection.right:
            begin = const Offset(1.0, 0.0);
            break;
          case AxisDirection.up:
            begin = const Offset(0.0, -1.0);
            break;
          case AxisDirection.down:
            begin = const Offset(0.0, 1.0);
            break;
        }

        const end = Offset.zero;

        final slideTween = Tween(begin: begin, end: end);
        final slideAnimation = animation.drive(
          slideTween.chain(CurveTween(curve: curve)),
        );

        final fadeTween = Tween<double>(begin: 0.0, end: 1.0);
        final fadeAnimation = animation.drive(
          fadeTween.chain(CurveTween(curve: Curves.easeIn)),
        );

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// Scale transition with rotation
  static PageRouteBuilder<T> scaleTransition<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 600),
    Curve curve = Curves.elasticOut,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleTween = Tween<double>(begin: 0.0, end: 1.0);
        final scaleAnimation = animation.drive(
          scaleTween.chain(CurveTween(curve: curve)),
        );

        final rotationTween = Tween<double>(begin: 0.0, end: 2 * math.pi * 0.1);
        final rotationAnimation = animation.drive(
          rotationTween.chain(CurveTween(curve: Curves.easeOutCubic)),
        );

        final fadeTween = Tween<double>(begin: 0.0, end: 1.0);
        final fadeAnimation = animation.drive(
          fadeTween.chain(CurveTween(curve: Curves.easeIn)),
        );

        return Transform.rotate(
          angle: rotationAnimation.value,
          child: Transform.scale(
            scale: scaleAnimation.value,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// Morphing transition effect
  static PageRouteBuilder<T> morphTransition<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 800),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;

        final slideTween = Tween(begin: begin, end: end);
        final slideAnimation = animation.drive(
          slideTween.chain(CurveTween(curve: Curves.easeOutCubic)),
        );

        final scaleTween = Tween<double>(begin: 0.8, end: 1.0);
        final scaleAnimation = animation.drive(
          scaleTween.chain(CurveTween(curve: Curves.easeOutBack)),
        );

        final fadeTween = Tween<double>(begin: 0.0, end: 1.0);
        final fadeAnimation = animation.drive(
          fadeTween.chain(CurveTween(curve: const Interval(0.3, 1.0))),
        );

        return SlideTransition(
          position: slideAnimation,
          child: Transform.scale(
            scale: scaleAnimation.value,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// Ripple effect transition
  static PageRouteBuilder<T> rippleTransition<T>({
    required Widget page,
    Offset? center,
    Duration duration = const Duration(milliseconds: 700),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return ClipPath(
              clipper: RippleClipper(
                progress: animation.value,
                center: center,
              ),
              child: child,
            );
          },
          child: child,
        );
      },
    );
  }

  /// Glass morphism transition
  static PageRouteBuilder<T> glassMorphTransition<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 600),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideTween = Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        );
        final slideAnimation = animation.drive(
          slideTween.chain(CurveTween(curve: Curves.easeOutCubic)),
        );

        final blurTween = Tween<double>(begin: 20.0, end: 0.0);
        final blurAnimation = animation.drive(
          blurTween.chain(CurveTween(curve: Curves.easeOut)),
        );

        final scaleTween = Tween<double>(begin: 0.9, end: 1.0);
        final scaleAnimation = animation.drive(
          scaleTween.chain(CurveTween(curve: Curves.easeOutBack)),
        );

        return SlideTransition(
          position: slideAnimation,
          child: Transform.scale(
            scale: scaleAnimation.value,
            child: AnimatedBuilder(
              animation: blurAnimation,
              builder: (context, animatedChild) {
                return BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: blurAnimation.value,
                    sigmaY: blurAnimation.value,
                  ),
                  child: animatedChild,
                );
              },
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Custom clipper for ripple transition
class RippleClipper extends CustomClipper<Path> {
  final double progress;
  final Offset? center;

  RippleClipper({
    required this.progress,
    this.center,
  });

  @override
  Path getClip(Size size) {
    final effectiveCenter = center ?? Offset(size.width / 2, size.height / 2);
    final maxRadius = math.max(
      math.max(
        effectiveCenter.dx,
        size.width - effectiveCenter.dx,
      ),
      math.max(
        effectiveCenter.dy,
        size.height - effectiveCenter.dy,
      ),
    );

    final currentRadius = maxRadius * progress;

    final path = Path();
    path.addOval(
      Rect.fromCircle(
        center: effectiveCenter,
        radius: currentRadius,
      ),
    );

    return path;
  }

  @override
  bool shouldReclip(covariant RippleClipper oldClipper) {
    return oldClipper.progress != progress || oldClipper.center != center;
  }
}

/// Custom page transition with particle effects
class ParticleTransition<T> extends PageRouteBuilder<T> {
  final Widget child;

  ParticleTransition({
    required this.child,
    Duration duration = const Duration(milliseconds: 800),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, animationChild) {
                return Stack(
                  children: [
                    // Background particles
                    ...List.generate(20, (index) {
                      final random = math.Random(index);
                      final x = random.nextDouble();
                      final y = random.nextDouble();
                      final delay = random.nextDouble() * 0.5;

                      return Positioned(
                        left: MediaQuery.of(context).size.width * x,
                        top: MediaQuery.of(context).size.height * y,
                        child: AnimatedBuilder(
                          animation: animation,
                          builder: (context, particleChild) {
                            final particleProgress =
                                ((animation.value - delay) / (1 - delay))
                                    .clamp(0.0, 1.0);
                            final opacity =
                                particleProgress * (1 - particleProgress) * 4;
                            final scale = 0.5 + particleProgress * 0.5;

                            return Transform.scale(
                              scale: scale,
                              child: Opacity(
                                opacity: opacity,
                                child: Container(
                                  width: 4 + random.nextDouble() * 8,
                                  height: 4 + random.nextDouble() * 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.6),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }),

                    // Main content with fade and scale
                    Transform.scale(
                      scale: 0.8 + (animation.value * 0.2),
                      child: Opacity(
                        opacity: animation.value,
                        child: child,
                      ),
                    ),
                  ],
                );
              },
              child: child,
            );
          },
        );
}
