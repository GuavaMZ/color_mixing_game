import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../color_mixer_game.dart';

/// Enhanced particles that appear when drops mix in the beaker
class MixParticles extends PositionComponent
    with HasGameReference<ColorMixerGame> {
  final Color dropColor;
  final Vector2 mixPosition;
  final List<_MixParticle> _particles = [];
  final Random _random = Random();
  double _lifetime = 0;
  final double maxLifetime = 1.5;

  final Paint _particlePaint = Paint()..style = PaintingStyle.fill;
  final Paint _glowPaint = Paint()..style = PaintingStyle.fill;
  Shader? _glowShader;

  MixParticles({required this.dropColor, required this.mixPosition})
    : super(position: mixPosition);

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Create a generic glow shader for the particles
    // We base it on a normalized size and scale the canvas later
    const double baseRadius = 10.0;
    _glowShader = RadialGradient(
      colors: [
        dropColor.withValues(alpha: 0.8),
        dropColor.withValues(alpha: 0.3),
        dropColor.withValues(alpha: 0),
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: baseRadius));
    _glowPaint.shader = _glowShader;

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
      particle.update(dt, game.isGravityFlux);
    }

    if (_lifetime >= maxLifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final bool skipGlow = game.reducedMotionEnabled;
    for (var particle in _particles) {
      particle.render(canvas, _particlePaint, _glowPaint, skipGlow);
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

  void render(
    Canvas canvas,
    Paint particlePaint,
    Paint glowPaint,
    bool skipGlow,
  ) {
    if (age >= lifetime) return;

    final progress = (1 - age / lifetime).clamp(0.0, 1.0);
    final currentSize = size * (1 - age / lifetime * 0.5);

    particlePaint.color = color.withValues(alpha: progress);
    canvas.drawCircle(
      Offset(position.x, position.y),
      currentSize,
      particlePaint,
    );

    // Glow effect - Using radial gradient shader instead of MaskFilter.blur
    if (!skipGlow) {
      canvas.save();
      canvas.translate(position.x, position.y);
      // Scale based on particle size relative to baseRadius(10)
      final scale = (currentSize * 2.5) / 10.0;
      canvas.scale(scale);

      glowPaint.color = Colors.white.withValues(alpha: progress * 0.4);
      canvas.drawCircle(Offset.zero, 10.0, glowPaint);
      canvas.restore();
    }
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
