import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:flutter/material.dart';

/// Full screen overlay for the Blackout event.
/// Obscures the entire UI except for a small "flashlight" area around the beaker/center.
class BlackoutOverlay extends StatelessWidget {
  final ColorMixerGame game;

  const BlackoutOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true, // Allow clicks to pass through? No, blackout means DARK.
      // Actually, if it's pitch black, user can't see buttons.
      // But maybe they should still be able to tap if they remember where they are?
      // "IgnorePointer: true" allows interaction with buttons underneath.
      // "IgnorePointer: false" blocks interaction.
      // Let's allow interaction (true) so they can try to play blind!
      child: Stack(
        children: [
          // Dark gradient mesh
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.98),
                ],
                stops: const [0.2, 0.8],
              ),
            ),
          ),
          // Pitch black corners
          Container(color: Colors.black.withValues(alpha: 0.3)),
        ],
      ),
    );
  }
}
