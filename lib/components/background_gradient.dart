import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../color_mixer_game.dart';

class BackgroundGradient extends PositionComponent with HasGameReference {
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final isEcho = (game as ColorMixerGame).currentMode == GameMode.colorEcho;

    // Cosmic Gradient
    final rect = Rect.fromLTWH(0, 0, game.size.x, game.size.y);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isEcho
            ? [
                const Color(0xFF101030), // Deep Indigo
                const Color(0xFF1A1B4B), // Laboratory Core
                const Color(0xFF0A0A20),
              ]
            : [
                const Color(0xFF0F1525), // Void
                const Color(0xFF1F1835), // Deep Purple Haze
                const Color(0xFF0B0E14), // Void
              ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, paint);

    if (isEcho) {
      // Misty atmosphere
      final mistPaint = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50)
        ..color = const Color(0xFFCCFF00).withValues(alpha: 0.02);

      canvas.drawCircle(
        Offset(game.size.x * 0.2, game.size.y * 0.8),
        300,
        mistPaint,
      );
      canvas.drawCircle(
        Offset(game.size.x * 0.8, game.size.y * 0.2),
        250,
        mistPaint..color = const Color(0xFFFF007F).withValues(alpha: 0.02),
      );
    }

    // Ambient Glow (Corner)
    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100)
      ..color = (isEcho ? const Color(0xFFCCFF00) : const Color(0xFF00F0FF))
          .withValues(alpha: 0.05);

    canvas.drawCircle(Offset(game.size.x, 0), 200, glowPaint);
  }
}
