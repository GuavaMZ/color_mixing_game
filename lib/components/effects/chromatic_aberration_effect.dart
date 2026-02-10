import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../color_mixer_game.dart';

/// A post-processing-like effect that simulates chromatic aberration
/// by drawing overlapping shifted layers (simplified version).
class ChromaticAberrationEffect extends Component
    with HasGameRef<ColorMixerGame> {
  double _timer = 0;
  double _intensity = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
    // Pulse intensity
    _intensity = (sin(_timer * 8) + 1) / 2 * 5.0;
  }

  @override
  void render(Canvas canvas) {
    // This is tricky in Flame because we're in a component.
    // Real Chromatic Aberration needs to capture the screen.
    // Simplified version: We can draw an overlay that looks glitchy.

    final rect = Rect.fromLTWH(0, 0, gameRef.size.x, gameRef.size.y);

    // Draw red shift
    canvas.save();
    canvas.translate(_intensity, 0);
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.red.withValues(alpha: 0.05)
        ..blendMode = BlendMode.screen,
    );
    canvas.restore();

    // Draw blue shift
    canvas.save();
    canvas.translate(-_intensity, 0);
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.blue.withValues(alpha: 0.05)
        ..blendMode = BlendMode.screen,
    );
    canvas.restore();
  }

  // To truly make this "next level", we would override renderTree in the Game,
  // but for a component, we can use ScreenHitbox/ScreenWrapper if we had one.
  // Let's stick to this subtle shifting overlay for now.
}
