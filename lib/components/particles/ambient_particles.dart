import 'dart:math';
import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Ambient floating particles for a relaxing atmosphere
class AmbientParticles extends Component with HasGameReference<ColorMixerGame> {
  final List<FloatingBubble> bubbles = [];
  final Random random = Random();
  final int particleCount = 15;
  List<Color>? configColors;

  AmbientParticles({this.configColors});

  void updateConfig(List<Color>? newColors) {
    configColors = newColors;
    // Re-color existing bubbles so the change is immediate
    for (final bubble in bubbles) {
      bubble.updateColor(
        configColors != null && configColors!.isNotEmpty
            ? configColors![random.nextInt(configColors!.length)]
            : null,
      );
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Create floating bubbles
    for (int i = 0; i < particleCount; i++) {
      bubbles.add(
        FloatingBubble(
          position: Vector2(
            random.nextDouble() * game.size.x,
            random.nextDouble() * game.size.y,
          ),
          size: 5 + random.nextDouble() * 15,
          speed: 10 + random.nextDouble() * 30,
          color: configColors != null && configColors!.isNotEmpty
              ? configColors![random.nextInt(configColors!.length)]
              : null,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    for (var bubble in bubbles) {
      bubble.update(dt, game.size);
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
  Color? color;

  FloatingBubble({
    required this.position,
    required this.size,
    required this.speed,
    this.color,
  }) : opacity = 0.1 + Random().nextDouble() * 0.2,
       phase = Random().nextDouble() * pi * 2,
       _highlightPaint = Paint()..style = PaintingStyle.fill,
       _gradientPaint = Paint();

  void updateColor(Color? newColor) {
    color = newColor;
  }

  final Paint _highlightPaint;
  final Paint _gradientPaint;

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
    // Determine color base
    final baseColor = color ?? Colors.white;

    // Draw bubble with gradient
    final gradient = RadialGradient(
      colors: [
        baseColor.withValues(alpha: opacity * 0.8),
        baseColor.withValues(alpha: opacity * 0.3),
        baseColor.withValues(alpha: 0),
      ],
      stops: const [0.0, 0.7, 1.0],
    );

    _gradientPaint.shader = gradient.createShader(
      Rect.fromCircle(center: Offset(position.x, position.y), radius: size),
    );

    canvas.drawCircle(Offset(position.x, position.y), size, _gradientPaint);

    // Add highlight
    _highlightPaint.color = Colors.white.withValues(alpha: opacity * 1.5);

    canvas.drawCircle(
      Offset(position.x - size * 0.3, position.y - size * 0.3),
      size * 0.3,
      _highlightPaint,
    );
  }
}
