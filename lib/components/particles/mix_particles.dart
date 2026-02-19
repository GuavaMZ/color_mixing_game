import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../color_mixer_game.dart';

/// Enhanced particles that appear when drops mix in the beaker
class MixParticles extends PositionComponent with HasGameRef<ColorMixerGame> {
  final Color dropColor;
  final Vector2 mixPosition;
  final List<_MixParticle> _particles = [];
  final Random _random = Random();
  double _lifetime = 0;
  final double maxLifetime = 1.5;

  final Paint _particlePaint = Paint()..style = PaintingStyle.fill;
  final Paint _glowPaint = Paint()
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

  MixParticles({required this.dropColor, required this.mixPosition})
    : super(position: mixPosition);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Create splash particles
    for (int i = 0; i < 20; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 50 + _random.nextDouble() * 100;
      final velocity = Vector2(
        cos(angle) * speed,
        sin(angle) * speed - 50, // Upward bias
      );

      _particles.add(
        _MixParticle(
          position: Vector2.zero(),
          velocity: velocity,
          color: dropColor,
          size: 3 + _random.nextDouble() * 4,
          lifetime: 0.8 + _random.nextDouble() * 0.7,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _lifetime += dt;

    for (var particle in _particles) {
      particle.update(dt, gameRef.isGravityFlux);
    }

    if (_lifetime >= maxLifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    for (var particle in _particles) {
      particle.render(canvas, _particlePaint, _glowPaint);
    }
  }
}

class _MixParticle {
  Vector2 position;
  Vector2 velocity;
  Color color;
  double size;
  double lifetime;
  double age = 0;

  _MixParticle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.lifetime,
  });

  void update(double dt, bool isGravityFlux) {
    age += dt;
    position += velocity * dt;

    if (isGravityFlux) {
      velocity.y -= 100 * dt; // Upward drift
      velocity *= 0.98;
    } else {
      velocity.y += 200 * dt; // Gravity
      velocity *= 0.95; // Air resistance
    }
  }

  void render(Canvas canvas, Paint particlePaint, Paint glowPaint) {
    if (age >= lifetime) return;

    final progress = (1 - age / lifetime).clamp(0.0, 1.0);

    particlePaint.color = color.withValues(alpha: progress);
    canvas.drawCircle(
      Offset(position.x, position.y),
      size * (1 - age / lifetime * 0.5),
      particlePaint,
    );

    // Glow effect
    glowPaint.color = color.withValues(alpha: progress * 0.3);
    canvas.drawCircle(Offset(position.x, position.y), size * 2, glowPaint);
  }
}

/// Shimmer effect for perfect matches
class ShimmerEffect extends PositionComponent {
  final Vector2 targetPosition;
  final Color targetColor;
  double _time = 0;
  final double duration = 2.0;

  final Paint _ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;

  final Paint _sparklePaint = Paint()..style = PaintingStyle.fill;

  ShimmerEffect({required this.targetPosition, required this.targetColor})
    : super(position: targetPosition);

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    if (_time >= duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final progress = _time / duration;
    final alpha = (1 - progress).clamp(0.0, 1.0);

    // Expanding rings
    for (int i = 0; i < 3; i++) {
      final ringProgress = (progress * 3 - i).clamp(0.0, 1.0);
      final radius = ringProgress * 100;
      final ringAlpha = alpha * (1 - ringProgress);

      _ringPaint.color = targetColor.withValues(alpha: ringAlpha * 0.3);
      canvas.drawCircle(Offset.zero, radius, _ringPaint);
    }

    // Sparkles
    final sparkleCount = 12;
    for (int i = 0; i < sparkleCount; i++) {
      final angle = (i / sparkleCount) * 2 * pi + _time * 2;
      final distance = 40 + sin(_time * 4 + i) * 20;
      final x = cos(angle) * distance;
      final y = sin(angle) * distance;

      _sparklePaint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), 2, _sparklePaint);
    }
  }
}
