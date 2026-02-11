import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../color_mixer_game.dart';

class BackgroundGradient extends PositionComponent with HasGameReference {
  final List<Color>? configColors;

  BackgroundGradient({this.configColors});

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final isEcho = (game as ColorMixerGame).currentMode == GameMode.colorEcho;

    // Use configured colors if available, otherwise default to mode-specific colors
    final List<Color> colors = configColors != null && configColors!.isNotEmpty
        ? configColors!
        : (isEcho
              ? [
                  const Color(0xFF101030), // Deep Indigo
                  const Color(0xFF1A1B4B), // Laboratory Core
                  const Color(0xFF0A0A20),
                ]
              : [
                  const Color(0xFF0F1525), // Void
                  const Color(0xFF1F1835), // Deep Purple Haze
                  const Color(0xFF0B0E14), // Void
                ]);

    // Cosmic Gradient
    final rect = Rect.fromLTWH(0, 0, game.size.x, game.size.y);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
        // Adjust stops based on number of colors
        stops: colors.length == 3
            ? const [0.0, 0.4, 1.0]
            : colors.length == 2
            ? const [0.0, 1.0]
            : null,
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
    // Use the primary color of the upgrade for the glow if available
    final glowColor = configColors != null && configColors!.isNotEmpty
        ? configColors!.first
        : (isEcho ? const Color(0xFFCCFF00) : const Color(0xFF00F0FF));

    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100)
      ..color = glowColor.withValues(alpha: 0.05);

    canvas.drawCircle(Offset(game.size.x, 0), 200, glowPaint);
  }
}
