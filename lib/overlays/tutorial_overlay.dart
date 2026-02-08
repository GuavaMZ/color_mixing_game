import 'dart:ui';
import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:color_mixing_deductive/helpers/audio_manager.dart';
import 'package:color_mixing_deductive/helpers/string_manager.dart';
import 'package:color_mixing_deductive/helpers/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

class TutorialOverlay extends StatefulWidget {
  final ColorMixerGame game;
  const TutorialOverlay({super.key, required this.game});

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  int _step = 0;

  final List<String> _instructions = [
    "Welcome to Color Lab! 🧪\nYour goal is to mix colors to match the target.",
    "Tap the Red, Green, and Blue buttons to add drops into the beaker. 🔴🟢🔵",
    "Watch the 'Match %' indicator.\nReach 100% to win! 🏆",
    "Be careful not to overflow! You have a limited number of drops per level. 💧",
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _nextStep() {
    AudioManager().playButton();
    if (_step < _instructions.length - 1) {
      setState(() {
        _step++;
      });
    } else {
      _close();
    }
  }

  void _close() {
    _controller.reverse().then((_) {
      widget.game.overlays.remove('Tutorial');
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<String> instructions = [
      AppStrings.tutorialStep1.getString(context),
      AppStrings.tutorialStep2.getString(context),
      AppStrings.tutorialStep3.getString(context),
      AppStrings.tutorialStep4.getString(context),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Blur background
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.black.withValues(alpha: 0.4)),
            ),
          ),

          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  padding: const EdgeInsets.all(24),
                  decoration: AppTheme.cosmicCard(
                    borderRadius: 24,
                    borderColor: AppTheme.neonCyan.withValues(alpha: 0.5),
                    hasGlow: true,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.tips_and_updates_rounded,
                        size: 48,
                        color: AppTheme.electricYellow,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.tutorial.getString(context),
                        style: AppTheme.heading2(context),
                      ),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          instructions[_step],
                          key: ValueKey(_step),
                          textAlign: TextAlign.center,
                          style: AppTheme.bodyLarge(
                            context,
                          ).copyWith(height: 1.5),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (_step < instructions.length - 1)
                            TextButton(
                              onPressed: _close,
                              child: Text(
                                AppStrings.skip.getString(context),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          const Spacer(),
                          _StepButton(
                            label:
                                (_step == instructions.length - 1
                                        ? AppStrings.start
                                        : AppStrings.next)
                                    .getString(context),
                            onTap: _nextStep,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _StepButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.neonCyan,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label),
    );
  }
}
