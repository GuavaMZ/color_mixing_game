import 'dart:math';
import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Ambient floating particles for a relaxing atmosphere
class AmbientParticles extends Component with HasGameRef<ColorMixerGame> {
  final List<FloatingBubble> bubbles = [];
  final Random random = Random();
  final int particleCount = 15;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Create floating bubbles
    for (int i = 0; i < particleCount; i++) {
      bubbles.add(
        FloatingBubble(
          position: Vector2(
            random.nextDouble() * gameRef.size.x,
            random.nextDouble() * gameRef.size.y,
          ),
          size: 5 + random.nextDouble() * 15,
          speed: 10 + random.nextDouble() * 30,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    for (var bubble in bubbles) {
      bubble.update(dt, gameRef.size);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    for (var bubble in bubbles) {
      bubble.render(canvas);
    }
  }
}

class FloatingBubble {
  Vector2 position;
  double size;
  double speed;
  double opacity;
  double phase;

  FloatingBubble({
    required this.position,
    required this.size,
    required this.speed,
  }) : opacity = 0.1 + Random().nextDouble() * 0.2,
       phase = Random().nextDouble() * pi * 2;

  void update(double dt, Vector2 screenSize) {
    // Float upward
    position.y -= speed * dt;

    // Gentle horizontal sway
    position.x += sin(position.y * 0.01 + phase) * 20 * dt;

    // Reset when off screen
    if (position.y < -size) {
      position.y = screenSize.y + size;
      position.x = Random().nextDouble() * screenSize.x;
    }

    // Keep within horizontal bounds
    if (position.x < -size) position.x = screenSize.x + size;
    if (position.x > screenSize.x + size) position.x = -size;
  }

  void render(Canvas canvas) {
    // Draw bubble with gradient
    final gradient = RadialGradient(
      colors: [
        Colors.white.withOpacity(opacity * 0.8),
        Colors.white.withOpacity(opacity * 0.3),
        Colors.white.withOpacity(0),
      ],
      stops: const [0.0, 0.7, 1.0],
    );

    final gradientPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: Offset(position.x, position.y), radius: size),
      );

    canvas.drawCircle(Offset(position.x, position.y), size, gradientPaint);

    // Add highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(opacity * 1.5)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(position.x - size * 0.3, position.y - size * 0.3),
      size * 0.3,
      highlightPaint,
    );
  }
}
