import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import '../../color_mixer_game.dart';

/// A disaster effect that pushes drops and shows wind particles.
class WindForceEffect extends Component with HasGameRef<ColorMixerGame> {
  final Random _random = Random();
  double _particleTimer = 0;
  double _forceDirection = 1.0; // 1.0 for right, -1.0 for left
  double _timer = 0;

  @override
  void onMount() {
    super.onMount();
    gameRef.hasWind = true;
    _forceDirection = _random.nextBool() ? 1.0 : -1.0;
  }

  @override
  void onRemove() {
    gameRef.hasWind = false;
    gameRef.windForce = 0;
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
    _particleTimer += dt;

    // Change wind direction occasionally
    if (_timer > 4.0) {
      _timer = 0;
      _forceDirection *= -1;
    }

    // Apply force to game
    gameRef.windForce = _forceDirection * (50.0 + _random.nextDouble() * 30.0);

    // Spawn wind particles
    if (_particleTimer > 0.05) {
      _particleTimer = 0;
      _spawnWindParticle();
    }
  }

  void _spawnWindParticle() {
    final gameSize = gameRef.size;
    final startX = _forceDirection > 0 ? -20.0 : gameSize.x + 20.0;
    final y = _random.nextDouble() * gameSize.y;

    gameRef.add(
      ParticleSystemComponent(
        particle: Particle.generate(
          count: 1,
          lifespan: 1.0,
          generator: (i) => AcceleratedParticle(
            position: Vector2(startX, y),
            speed: Vector2(
              _forceDirection * 400,
              (_random.nextDouble() - 0.5) * 50,
            ),
            child: ComponentParticle(
              component: RectangleComponent(
                size: Vector2(20 + _random.nextDouble() * 30, 2),
                paint: Paint()..color = Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
