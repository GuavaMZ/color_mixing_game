import 'package:flutter/material.dart';
import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:color_mixing_deductive/helpers/theme_constants.dart';
import 'package:color_mixing_deductive/helpers/audio_manager.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:color_mixing_deductive/helpers/string_manager.dart';
import 'package:color_mixing_deductive/helpers/visual_effects.dart'; // StarField
import 'package:color_mixing_deductive/components/ui/responsive_components.dart'; // ResponsiveIconButton
import 'package:color_mixing_deductive/core/color_science.dart';

class ColorEchoHUD extends StatelessWidget {
  final ColorMixerGame game;
  const ColorEchoHUD({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background - Semi-transparent overlay to keep the "spectral" feel
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF000022).withValues(alpha: 0.4),
            ),
          ),
          Positioned.fill(
            child: StarField(
              starCount: 30,
              color: AppTheme.neonCyan.withValues(alpha: 0.3),
            ),
          ),

          // Grid Overlay
          Positioned.fill(child: CustomPaint(painter: EchoGridPainter())),

          SafeArea(
            child: Column(
              children: [
                // Header with Back Button
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      ResponsiveIconButton(
                        onPressed: () {
                          AudioManager().playButton();
                          game.transitionTo('ColorEchoHUD', 'MainMenu');
                        },
                        icon: Icons.arrow_back_ios_new_rounded,
                        color: AppTheme.neonCyan,
                        backgroundColor: AppTheme.neonCyan.withValues(
                          alpha: 0.1,
                        ),
                        borderColor: AppTheme.neonCyan.withValues(alpha: 0.3),
                      ),
                      const Spacer(),
                      // Round and Score
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "${AppStrings.echoRound.getString(context)}: ${game.echoRound + 1}",
                            style: const TextStyle(
                              color: AppTheme.neonCyan,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Text(
                            "${AppStrings.echoScore.getString(context)}: ${game.echoScore.toInt()}",
                            style: const TextStyle(
                              color: AppTheme.neonMagenta,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Top HUD: Syncing Status
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: ValueListenableBuilder<double>(
                    valueListenable: game.matchPercentage,
                    builder: (context, match, child) {
                      final wavelength = ColorScience.estimateWavelength(
                        game.targetColor,
                      );
                      final region = ColorScience.getSpectralRegion(wavelength);

                      return Column(
                        children: [
                          Text(
                            "${AppStrings.syncing.getString(context)} ${match.toStringAsFixed(1)}%",
                            style: const TextStyle(
                              color: AppTheme.neonCyan,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              letterSpacing: 4,
                              shadows: [
                                Shadow(
                                  color: AppTheme.neonCyan,
                                  blurRadius: 10,
                                ),
                                Shadow(
                                  color: AppTheme.neonMagenta,
                                  blurRadius: 2,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Wavelength and Almost Status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "λ ${wavelength.toInt()}nm · $region",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  letterSpacing: 1.5,
                                ),
                              ),
                              ValueListenableBuilder<bool>(
                                valueListenable: game.echoAlmostSync,
                                builder: (context, almost, child) {
                                  if (!almost) return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: _AlmostPulseIndicator(),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Digital track
                          Container(
                            width: 250,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: AppTheme.neonCyan.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Stack(
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: 250 * (match / 100),
                                    height: 4,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.neonCyan,
                                      borderRadius: BorderRadius.circular(2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.neonCyan.withValues(
                                            alpha: 0.8,
                                          ),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const Spacer(),

                // Bottom Glitch Controls
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 40,
                    left: 24,
                    right: 24,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _GlitchButton(
                        onTap: () {
                          AudioManager().playButton();
                          game.addDrop('white');
                        },
                        label: "W",
                        color: Colors.white,
                        size: 55,
                      ),
                      _GlitchButton(
                        onTap: () {
                          AudioManager().playButton();
                          game.addDrop('red');
                        },
                        label: "R",
                        color: Colors.redAccent,
                        size: 55,
                      ),
                      _GlitchButton(
                        onTap: () {
                          AudioManager().playButton();
                          game.addDrop('green');
                        },
                        label: "G",
                        color: Colors.greenAccent,
                        size: 55,
                      ),
                      _GlitchButton(
                        onTap: () {
                          AudioManager().playButton();
                          game.addDrop('blue');
                        },
                        label: "B",
                        color: Colors.blueAccent,
                        size: 55,
                      ),
                      _GlitchButton(
                        onTap: () {
                          AudioManager().playButton();
                          game.addDrop('black');
                        },
                        label: "K",
                        color: Colors.grey[800]!,
                        size: 55,
                      ),
                    ],
                  ),
                ),

                // Undo/Reset
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ResponsiveIconButton(
                        icon: Icons.undo_rounded,
                        color: AppTheme.neonMagenta,
                        backgroundColor: AppTheme.neonMagenta.withValues(
                          alpha: 0.1,
                        ),
                        borderColor: AppTheme.neonMagenta.withValues(
                          alpha: 0.3,
                        ),
                        onPressed: () {
                          AudioManager().playButton();
                          game.undoLastDrop();
                        },
                      ),
                      const SizedBox(width: 40),
                      ResponsiveIconButton(
                        icon: Icons.refresh_rounded,
                        color: AppTheme.neonMagenta,
                        backgroundColor: AppTheme.neonMagenta.withValues(
                          alpha: 0.1,
                        ),
                        borderColor: AppTheme.neonMagenta.withValues(
                          alpha: 0.3,
                        ),
                        onPressed: () {
                          AudioManager().playButton();
                          game.resetMixing();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EchoGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.neonCyan.withValues(alpha: 0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const gridSize = 40.0;

    // Draw vertical lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _GlitchButton extends StatefulWidget {
  final VoidCallback onTap;
  final String label;
  final Color color;
  final double size;

  const _GlitchButton({
    required this.onTap,
    required this.label,
    required this.color,
    this.size = 70,
  });

  @override
  State<_GlitchButton> createState() => _GlitchButtonState();
}

class _GlitchButtonState extends State<_GlitchButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Glitch displacement effect
          double offsetX = _controller.value > 0
              ? (_controller.value *
                    5 *
                    (DateTime.now().millisecond % 2 == 0 ? 1 : -1))
              : 0;
          double offsetY = _controller.value > 0
              ? (_controller.value *
                    5 *
                    (DateTime.now().millisecond % 2 == 0 ? -1 : 1))
              : 0;

          return Transform.translate(
            offset: Offset(offsetX, offsetY),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.1),
                border: Border.all(
                  color: widget.color.withValues(alpha: 0.5),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(
                      alpha: 0.2 + _controller.value * 0.4,
                    ),
                    blurRadius: 10 + _controller.value * 20,
                    spreadRadius: _controller.value * 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    fontFamily: 'monospace',
                    shadows: [Shadow(color: widget.color, blurRadius: 8)],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AlmostPulseIndicator extends StatefulWidget {
  @override
  State<_AlmostPulseIndicator> createState() => _AlmostPulseIndicatorState();
}

class _AlmostPulseIndicatorState extends State<_AlmostPulseIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.neonMagenta.withValues(alpha: 0.2),
          border: Border.all(color: AppTheme.neonMagenta, width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          AppStrings.almost.getString(context).toUpperCase(),
          style: const TextStyle(
            color: AppTheme.neonMagenta,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
