import 'dart:async';
import 'package:flutter/material.dart';
import '../../color_mixer_game.dart';
import '../../helpers/theme_constants.dart';
import '../../helpers/visual_effects.dart';

class PremiumSplashOverlay extends StatefulWidget {
  final ColorMixerGame game;
  const PremiumSplashOverlay({super.key, required this.game});

  @override
  State<PremiumSplashOverlay> createState() => _PremiumSplashOverlayState();
}

class _PremiumSplashOverlayState extends State<PremiumSplashOverlay>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _glowController;
  late AnimationController _fadeController;

  late Animation<double> _logoScale;
  late Animation<double> _glowPulse;
  late Animation<double> _opacity;

  final String _brandName = "DvZeyad";
  final List<AnimationController> _letterControllers = [];
  final List<Animation<double>> _letterFades = [];
  final List<Animation<double>> _letterOffsets = [];

  @override
  void initState() {
    super.initState();

    // Fade in/out of the whole screen
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    // Logo Scale
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    // Glow Pulse
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _glowPulse = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Letter Stagger
    for (int i = 0; i < _brandName.length; i++) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
      _letterControllers.add(controller);

      _letterFades.add(
        Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: controller, curve: Curves.easeIn)),
      );

      _letterOffsets.add(
        Tween<double>(begin: 20.0, end: 0.0).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
        ),
      );
    }

    _startSequence();
  }

  Future<void> _startSequence() async {
    _fadeController.forward();
    _logoController.forward();
    _glowController.repeat(reverse: true);

    for (int i = 0; i < _letterControllers.length; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) _letterControllers[i].forward();
    }

    // Hold for a moment then transition
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      await _fadeController.reverse();
      widget.game.overlays.remove('PremiumSplash');
      widget.game.overlays.add('MainMenu');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _glowController.dispose();
    _fadeController.dispose();
    for (var controller in _letterControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Background
            Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.cosmicBackground,
              ),
            ),

            // Particles
            const StarField(starCount: 100, color: Colors.white),

            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Logo
                  ScaleTransition(
                    scale: _logoScale,
                    child: AnimatedBuilder(
                      animation: _glowPulse,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.neonCyan.withValues(
                                  alpha: 0.3 * _glowPulse.value,
                                ),
                                blurRadius: 60,
                                spreadRadius: 10,
                              ),
                              BoxShadow(
                                color: AppTheme.neonMagenta.withValues(
                                  alpha: 0.2 * _glowPulse.value,
                                ),
                                blurRadius: 40,
                                spreadRadius: 5,
                                offset: const Offset(5, 5),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 80,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Brand Name Staggered
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_brandName.length, (index) {
                      return AnimatedBuilder(
                        animation: _letterControllers[index],
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _letterOffsets[index].value),
                            child: Opacity(
                              opacity: _letterFades[index].value,
                              child: Text(
                                _brandName[index],
                                style: AppTheme.heading1(context).copyWith(
                                  fontSize: 48,
                                  color: Colors.white,
                                  letterSpacing: 8,
                                  shadows: [
                                    Shadow(
                                      color: AppTheme.neonCyan,
                                      blurRadius: 15 * _glowPulse.value,
                                    ),
                                    const Shadow(
                                      color: Colors.black54,
                                      offset: Offset(2, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),

                  const SizedBox(height: 16),

                  // Subtitle
                  FadeTransition(
                    opacity: _letterFades.last,
                    child: Text(
                      "PREMIUM STUDIOS",
                      style: AppTheme.caption(context).copyWith(
                        color: Colors.white.withValues(alpha: 0.5),
                        letterSpacing: 6,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom loading hint
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _letterFades.last,
                child: Center(
                  child: Text(
                    "INITIALIZING LAB...",
                    style: AppTheme.caption(context).copyWith(
                      color: AppTheme.neonCyan.withValues(alpha: 0.4),
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
