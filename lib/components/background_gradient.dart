import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class BackgroundGradient extends PositionComponent with HasGameReference {
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Cosmic Gradient
    final rect = Rect.fromLTWH(0, 0, game.size.x, game.size.y);
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0F1525), // Void
          Color(0xFF1F1835), // Deep Purple Haze
          Color(0xFF0B0E14), // Void
        ],
        stops: [0.0, 0.4, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, paint);

    // Ambient Glow (Corner)
    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100)
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.05); // Cyan glow

    canvas.drawCircle(Offset(game.size.x, 0), 200, glowPaint);
  }
}
