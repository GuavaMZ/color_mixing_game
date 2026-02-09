import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../color_mixer_game.dart';

class InvertedControlsEffect extends PositionComponent
    with HasGameRef<ColorMixerGame> {
  double _time = 0;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Position relative to game screen, maybe top-center?
    // Or maybe near the buttons?
    // Let's go with a semi-transparent "SWAP" overlay in the middle of the screen.

    anchor = Anchor.center;
    position = Vector2(gameRef.size.x / 2, gameRef.size.y * 0.45);
    size = Vector2(200, 100);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final paint = Paint()
      ..color = Colors.orange.withValues(
        alpha: 0.3 + sin(_time * 5).abs() * 0.4,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw a "Double Arrow" or "Swap" icon manually
    final center = Offset(size.x / 2, size.y / 2);

    // Left arrow
    canvas.drawLine(
      center + const Offset(-40, -10),
      center + const Offset(40, -10),
      paint,
    );
    canvas.drawLine(
      center + const Offset(40, -10),
      center + const Offset(30, -20),
      paint,
    );
    canvas.drawLine(
      center + const Offset(40, -10),
      center + const Offset(30, 0),
      paint,
    );

    // Right arrow
    canvas.drawLine(
      center + const Offset(40, 10),
      center + const Offset(-40, 10),
      paint,
    );
    canvas.drawLine(
      center + const Offset(-40, 10),
      center + const Offset(-30, 20),
      paint,
    );
    canvas.drawLine(
      center + const Offset(-40, 10),
      center + const Offset(-30, 0),
      paint,
    );

    // Text "CONTROLS SWAPPED"
    final textPaint = TextPaint(
      style: TextStyle(
        color: Colors.orange.withValues(alpha: 0.8),
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
        shadows: [Shadow(color: Colors.black, blurRadius: 4)],
      ),
    );

    textPaint.render(
      canvas,
      "CONTROLS SWAPPED",
      Vector2(size.x / 2, size.y + 20),
      anchor: Anchor.center,
    );
  }
}
