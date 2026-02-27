import 'package:color_mixing_deductive/helpers/string_manager.dart';
import 'package:color_mixing_deductive/helpers/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:color_mixing_deductive/color_mixer_game.dart';

class IntroSplashOverlay extends StatefulWidget {
  final ColorMixerGame game;

  const IntroSplashOverlay({super.key, required this.game});

  @override
  State<IntroSplashOverlay> createState() => _IntroSplashOverlayState();
}

class _IntroSplashOverlayState extends State<IntroSplashOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _textFade;
  late Animation<double> _barFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.8, curve: Curves.easeIn),
      ),
    );

    _barFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          widget.game.overlays.remove('IntroSplash');
          widget.game.overlays.add('MainMenu');
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Deep Blue
      body: Stack(
        children: [
          // Logo + Text in Center
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: SvgPicture.asset(
                      'assets/images/dv-logo.svg',
                      width: 150,
                      height: 150,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Text
                FadeTransition(
                  opacity: _textFade,
                  child: Text(
                    AppStrings.presents.getString(context),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 4.0,
                      fontFamily: 'Roboto',
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Mirror the loading bar at the bottom (Static 100% since loading is done)
          Positioned(
            left: 40,
            right: 40,
            bottom: 60,
            child: FadeTransition(
              opacity: _barFade,
              child: const _StaticPremiumBar(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaticPremiumBar extends StatelessWidget {
  const _StaticPremiumBar();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppStrings.labArchivesInitialized.getString(context).toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            fontFamily: 'Roboto',
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: const LinearGradient(
                    colors: [AppTheme.neonCyan, AppTheme.neonMagenta],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonCyan.withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
