import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:color_mixing_deductive/components/gameplay/beaker.dart';

class SurfaceSteam extends PositionComponent with HasGameRef {
  final Beaker beaker;
  final Random _random = Random();
  double _timer = 0;
  final List<_SteamParticle> _particles = [];

  final Paint _steamPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.15)
    ..style = PaintingStyle.fill;

  SurfaceSteam({required this.beaker}) : super(size: beaker.size);

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;

    if (_timer > 0.1) {
      _timer = 0;
      _spawnSteam();
    }

    // Update particles
    for (int i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.update(dt);
      if (p.isDead) {
        _particles.removeAt(i);
      }
    }
  }

  void _spawnSteam() {
    // Calculate the Y position of the liquid surface in local coordinates
    final surfaceY = size.y - (size.y * 0.8 * beaker.liquidLevel) - 20;

    // Spread steam across the width of the beaker (local X)
    final xPos = size.x / 2 + (_random.nextDouble() - 0.5) * size.x * 0.7;

    _particles.add(
      _SteamParticle(
        position: Vector2(xPos, surfaceY),
        velocity: Vector2((_random.nextDouble() - 0.5) * 15, -20),
        acceleration: Vector2(0, -30),
        maxLifetime: 1.5 + _random.nextDouble(),
        startRadius: 4.0 + _random.nextDouble() * 6.0,
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    for (final p in _particles) {
      canvas.drawCircle(
        p.position.toOffset(),
        p.radius,
        _steamPaint..color = Colors.white.withValues(alpha: 0.15 * p.opacity),
      );
    }
  }
}

class _SteamParticle {
  Vector2 position;
  Vector2 velocity;
  Vector2 acceleration;
  double lifetime = 0;
  final double maxLifetime;
  final double startRadius;

  _SteamParticle({
    required this.position,
    required this.velocity,
    required this.acceleration,
    required this.maxLifetime,
    required this.startRadius,
  });

  void update(double dt) {
    velocity += acceleration * dt;
    position += velocity * dt;
    lifetime += dt;
  }

  bool get isDead => lifetime >= maxLifetime;
  double get opacity => (1.0 - (lifetime / maxLifetime)).clamp(0.0, 1.0);
  double get radius => startRadius * (1.0 + (lifetime / maxLifetime));
}
