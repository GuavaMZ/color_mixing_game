import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../color_mixer_game.dart';

/// Individual steam particle
class SteamParticle {
  Vector2 position;
  Vector2 velocity;
  double opacity;
  double size;
  double lifetime;
  double maxLifetime;

  SteamParticle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.maxLifetime,
  }) : opacity = 0.6,
       lifetime = 0;

  void update(double dt) {
    position += velocity * dt;
    lifetime += dt;

    // Fade out over lifetime
    opacity = (1 - (lifetime / maxLifetime)) * 0.6;

    // Slow down over time
    velocity *= 0.98;

    // Expand slightly
    size += dt * 10;
  }

  bool get isDead => lifetime >= maxLifetime;
}

/// Steam effect component for Chaos Lab Mode
class SteamEffect extends Component with HasGameRef<ColorMixerGame> {
  final List<SteamParticle> _particles = [];
  final Random _random = Random();
  double _spawnTimer = 0;
  final double _spawnInterval = 0.1;

  final Paint _steamPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

  @override
  void update(double dt) {
    super.update(dt);

    _spawnTimer += dt;

    // Spawn new particles
    if (_spawnTimer >= _spawnInterval) {
      _spawnParticles();
      _spawnTimer = 0;
    }

    // Update existing particles
    _particles.removeWhere((p) => p.isDead);
    for (var particle in _particles) {
      particle.update(dt);
    }
  }

  void _spawnParticles() {
    if (parent == null) return;

    final gameSize = gameRef.size;

    // Spawn from bottom corners (simulating pipes)
    final spawnPoints = [
      Vector2(gameSize.x * 0.15, gameSize.y - 50),
      Vector2(gameSize.x * 0.85, gameSize.y - 50),
    ];

    for (var spawnPoint in spawnPoints) {
      if (_random.nextDouble() < 0.7) {
        _particles.add(
          SteamParticle(
            position: spawnPoint.clone(),
            velocity: Vector2(
              (_random.nextDouble() - 0.5) * 30,
              -50 - _random.nextDouble() * 30,
            ),
            size: 15 + _random.nextDouble() * 20,
            maxLifetime: 2.0 + _random.nextDouble() * 1.5,
          ),
        );
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    for (var particle in _particles) {
      _steamPaint.color = Colors.white.withValues(alpha: particle.opacity);

      canvas.drawCircle(
        particle.position.toOffset(),
        particle.size,
        _steamPaint,
      );
    }
  }
}
