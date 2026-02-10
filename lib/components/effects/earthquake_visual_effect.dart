import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../color_mixer_game.dart';

class EarthquakeVisualEffect extends Component with HasGameRef<ColorMixerGame> {
  final Random _random = Random();
  final List<_DustParticle> _particles = [];

  @override
  void update(double dt) {
    super.update(dt);

    // Spawn dust
    if (_random.nextDouble() < 0.2) {
      _particles.add(
        _DustParticle(
          position: Vector2(_random.nextDouble() * gameRef.size.x, -10),
          velocity: Vector2(
            (_random.nextDouble() - 0.5) * 50,
            100 + _random.nextDouble() * 200,
          ),
          size: 1 + _random.nextDouble() * 3,
          life: 1.0 + _random.nextDouble() * 1.5,
        ),
      );
    }

    _particles.removeWhere((p) => p.age >= p.life);
    for (var p in _particles) {
      p.update(dt);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final dustPaint = Paint()
      ..color = Colors.brown.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    for (var p in _particles) {
      dustPaint.color = Colors.grey.withValues(
        alpha: (1 - p.age / p.life) * 0.3,
      );
      canvas.drawCircle(p.position.toOffset(), p.size, dustPaint);
    }

    // Occasional "crack" flicker
    if (_random.nextDouble() < 0.05) {
      final crackPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      // Draw a random jagged line to simulate a glass crack flicker
      final start = Offset(
        _random.nextDouble() * gameRef.size.x,
        _random.nextDouble() * gameRef.size.y,
      );
      final path = Path()..moveTo(start.dx, start.dy);
      for (int i = 0; i < 3; i++) {
        path.lineTo(
          start.dx + (_random.nextDouble() - 0.5) * 100,
          start.dy + (_random.nextDouble() - 0.5) * 100,
        );
      }
      canvas.drawPath(path, crackPaint);
    }
  }
}

class _DustParticle {
  Vector2 position;
  Vector2 velocity;
  double size;
  double life;
  double age = 0;

  _DustParticle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.life,
  });

  void update(double dt) {
    age += dt;
    position += velocity * dt;
    velocity.x *= 0.99; // Horizontal friction
  }
}
