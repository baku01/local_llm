import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'chat_screen.dart';
import '../widgets/enhanced_page_transitions.dart';

/// Splash screen com animações modernas e responsivas.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _progressController;
  
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    
    // Controladores de animação
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Animações
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotateController,
      curve: Curves.easeInOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    // Iniciar animações
    _pulseController.repeat(reverse: true);
    _rotateController.repeat();
    _progressController.forward();

    _timer = Timer(const Duration(milliseconds: 2800), () {
      if (mounted) {
        // Parar animações antes de navegar
        _pulseController.stop();
        _rotateController.stop();
        _progressController.stop();
        
        // Navigação com transição moderna melhorada
        Navigator.of(context).pushReplacement(
          EnhancedPageTransitions.glassMorphTransition<void>(
            page: const ChatScreen(),
            duration: const Duration(milliseconds: 900),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _rotateController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode 
          ? const Color(0xFF0A0A0A) 
          : const Color(0xFFFAFBFC),
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: isDarkMode
                ? [
                    const Color(0xFF1A1A1A),
                    const Color(0xFF0A0A0A),
                    const Color(0xFF000000),
                  ]
                : [
                    const Color(0xFFFFFFFF),
                    const Color(0xFFF8F9FA),
                    const Color(0xFFE9ECEF),
                  ],
          ),
        ),
        child: Stack(
          children: [
            // Partículas de fundo animadas
            ...List.generate(20, (index) => _buildParticle(index, size, isDarkMode)),
            
            // Conteúdo principal
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo com múltiplas animações
                  AnimatedBuilder(
                    animation: Listenable.merge([_pulseAnimation, _rotateAnimation]),
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Transform.rotate(
                          angle: _rotateAnimation.value * 2 * math.pi * 0.1,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                startAngle: _rotateAnimation.value * 2 * math.pi,
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.secondary,
                                  theme.colorScheme.tertiary,
                                  theme.colorScheme.primary,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withOpacity(0.4),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDarkMode 
                                    ? const Color(0xFF1A1A1A)
                                    : Colors.white,
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                size: 70,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ).animate().fadeIn(duration: 600.ms).scale(
                      begin: const Offset(0.3, 0.3),
                      end: const Offset(1.0, 1.0),
                      duration: 800.ms,
                      curve: Curves.elasticOut,
                    ),

                  const SizedBox(height: 48),

                  // Título com gradiente animado
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                        theme.colorScheme.tertiary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      'Local LLM',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ).animate().fadeIn(duration: 800.ms, delay: 400.ms).slideY(
                      begin: 0.5,
                      end: 0,
                      curve: Curves.easeOutCubic,
                    ),

                  const SizedBox(height: 12),

                  // Subtítulo
                  Text(
                    'Inteligência Artificial Local',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ).animate().fadeIn(duration: 600.ms, delay: 600.ms).slideY(
                      begin: 0.3,
                      end: 0,
                      curve: Curves.easeOutCubic,
                    ),

                  const SizedBox(height: 64),

                  // Progress bar animado
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return Column(
                        children: [
                          Container(
                            width: 240,
                            height: 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: theme.colorScheme.outline.withOpacity(0.2),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _progressAnimation.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.colorScheme.primary,
                                      theme.colorScheme.secondary,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary.withOpacity(0.4),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Inicializando...',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    },
                  ).animate().fadeIn(duration: 400.ms, delay: 800.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticle(int index, Size size, bool isDarkMode) {
    final random = math.Random(index);
    final x = random.nextDouble() * size.width;
    final y = random.nextDouble() * size.height;
    final delay = random.nextInt(2000);
    final duration = 3000 + random.nextInt(2000);

    return Positioned(
      left: x,
      top: y,
      child: Container(
        width: 2 + random.nextDouble() * 4,
        height: 2 + random.nextDouble() * 4,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
      ).animate(
        onPlay: (controller) => controller.repeat(reverse: true),
      ).fadeIn(
        duration: Duration(milliseconds: duration),
        delay: Duration(milliseconds: delay),
      ).moveY(
        begin: 0,
        end: -20 - random.nextDouble() * 30,
        duration: Duration(milliseconds: duration),
      ),
    );
  }
}
