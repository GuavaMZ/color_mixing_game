import 'dart:math';
import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Animated gradient background component for a calming, relaxing atmosphere
class BackgroundGradient extends Component with HasGameRef<ColorMixerGame> {
  double _animationTime = 0.0;
  final double animationSpeed = 0.3;

  // Calming color palette for relaxation
  final List<Color> gradientColors = [
    const Color(0xFF667eea), // Soft purple
    const Color(0xFF764ba2), // Deep purple
    const Color(0xFF48c6ef), // Sky blue
    const Color(0xFF6f86d6), // Periwinkle
    const Color(0xFF4facfe), // Light blue
  ];

  @override
  void update(double dt) {
    super.update(dt);
    _animationTime += dt * animationSpeed;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Calculate animated gradient positions
    final t = sin(_animationTime) * 0.5 + 0.5; // Oscillate between 0 and 1
    final t2 = cos(_animationTime * 0.7) * 0.5 + 0.5;

    // Create animated gradient
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(gradientColors[0], gradientColors[1], t)!,
        Color.lerp(gradientColors[2], gradientColors[3], t2)!,
        Color.lerp(gradientColors[3], gradientColors[4], 1 - t)!,
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, gameRef.size.x, gameRef.size.y),
      );

    canvas.drawRect(Rect.fromLTWH(0, 0, gameRef.size.x, gameRef.size.y), paint);
  }
}
