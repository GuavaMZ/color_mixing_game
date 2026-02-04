import 'dart:ui';
import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:color_mixing_deductive/helpers/audio_manager.dart';
import 'package:color_mixing_deductive/helpers/theme_constants.dart';
import 'package:flutter/material.dart';

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
    "Watch the 'Match %' indicator.\nGet above 95% to win! 🏆",
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Blur background
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.black.withOpacity(0.4)),
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
                  decoration: AppTheme.cosmicGlass(
                    borderRadius: 24,
                    borderColor: AppTheme.neonCyan.withOpacity(0.5),
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
                      Text("Tutorial", style: AppTheme.heading2(context)),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _instructions[_step],
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
                          if (_step < _instructions.length - 1)
                            TextButton(
                              onPressed: _close,
                              child: Text(
                                "Skip",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                            ),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: _nextStep,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.neonCyan,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _step == _instructions.length - 1
                                  ? "Start"
                                  : "Next",
                            ),
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
