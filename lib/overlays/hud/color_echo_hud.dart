import 'package:flutter/material.dart';
import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:color_mixing_deductive/helpers/theme_constants.dart';
import 'package:color_mixing_deductive/helpers/audio_manager.dart';
import 'package:color_mixing_deductive/helpers/visual_effects.dart'; // StarField
import 'package:color_mixing_deductive/components/ui/responsive_components.dart'; // ResponsiveIconButton

class ColorEchoHUD extends StatelessWidget {
  final ColorMixerGame game;
  const ColorEchoHUD({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background - Grid Distortion Effect (Simulated with grid painter)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [const Color(0xFF000022), const Color(0xFF110033)],
              ),
            ),
          ),
          Positioned.fill(
            child: StarField(starCount: 30, color: AppTheme.neonCyan),
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
                    ],
                  ),
                ),

                // Top HUD: Syncing Status
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: ValueListenableBuilder<double>(
                    valueListenable: game.matchPercentage,
                    builder: (context, match, child) {
                      return Column(
                        children: [
                          Text(
                            "SYNCING... ${match.toStringAsFixed(1)}%",
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
                          game.addDrop('red');
                        },
                        label: "R",
                        color: Colors.redAccent,
                      ),
                      _GlitchButton(
                        onTap: () {
                          AudioManager().playButton();
                          game.addDrop('green');
                        },
                        label: "G",
                        color: Colors.greenAccent,
                      ),
                      _GlitchButton(
                        onTap: () {
                          AudioManager().playButton();
                          game.addDrop('blue');
                        },
                        label: "B",
                        color: Colors.blueAccent,
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

  const _GlitchButton({
    required this.onTap,
    required this.label,
    required this.color,
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
              width: 70,
              height: 70,
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
