import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:color_mixing_deductive/components/beaker.dart';

class SurfaceSteam extends PositionComponent with HasGameRef {
  final Beaker beaker;
  final Random _random = Random();
  double _timer = 0;

  SurfaceSteam({required this.beaker}) : super(size: beaker.size);

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;

    if (_timer > 0.1) {
      _timer = 0;
      _spawnSteam();
    }
  }

  void _spawnSteam() {
    // Calculate the Y position of the liquid surface in local coordinates
    // Beaker size is roughly 250x300. Liquid starts from bottom.
    // Liquid level is 0.0 to 1.0.
    // The liquid area is roughly 80% of beaker height.
    final surfaceY = size.y - (size.y * 0.8 * beaker.liquidLevel) - 20;

    // Spread steam across the width of the beaker (local X)
    final xPos = size.x / 2 + (_random.nextDouble() - 0.5) * size.x * 0.7;

    add(
      ParticleSystemComponent(
        particle: Particle.generate(
          count: 1,
          lifespan: 1.5 + _random.nextDouble(),
          generator: (i) => AcceleratedParticle(
            acceleration: Vector2(0, -30),
            speed: Vector2((_random.nextDouble() - 0.5) * 15, -20),
            position: Vector2(xPos, surfaceY),
            child: CircleParticle(
              radius: 4.0 + _random.nextDouble() * 6.0,
              paint: Paint()..color = Colors.white.withValues(alpha: 0.15),
            ),
          ),
        ),
      ),
    );
  }
}
