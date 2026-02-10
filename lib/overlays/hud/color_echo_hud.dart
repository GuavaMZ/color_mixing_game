import 'package:flutter/material.dart';
import '../../../color_mixer_game.dart';
import '../../helpers/theme_constants.dart';
import '../../helpers/audio_manager.dart';

class ColorEchoHUD extends StatelessWidget {
  final ColorMixerGame game;
  const ColorEchoHUD({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Exit button
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 20, top: 10),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppTheme.neonCyan,
                  ),
                  onPressed: () {
                    AudioManager().playButton();
                    game.transitionTo('ColorEchoHUD', 'MainMenu');
                  },
                ),
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
                            Shadow(color: AppTheme.neonCyan, blurRadius: 10),
                            Shadow(
                              color: AppTheme.neonMagenta,
                              blurRadius: 2,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Digital track
                      Container(
                        width: 200,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 200 * (match / 100),
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppTheme.neonCyan,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.neonCyan.withValues(
                                    alpha: 0.5,
                                  ),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
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
              padding: const EdgeInsets.only(bottom: 40, left: 24, right: 24),
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
                  IconButton(
                    icon: const Icon(
                      Icons.undo_rounded,
                      color: AppTheme.neonMagenta,
                    ),
                    onPressed: () {
                      AudioManager().playButton();
                      game.undoLastDrop();
                    },
                  ),
                  const SizedBox(width: 40),
                  IconButton(
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: AppTheme.neonMagenta,
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
    );
  }
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
          return Transform.translate(
            offset: Offset(_controller.value * 2, _controller.value * -2),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.1),
                border: Border.all(
                  color: widget.color.withValues(alpha: 0.5),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  if (_controller.value > 0.5)
                    BoxShadow(
                      color: widget.color,
                      blurRadius: 10,
                      spreadRadius: -2,
                    ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    fontFamily: 'monospace',
                    shadows: [Shadow(color: widget.color, blurRadius: 4)],
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
