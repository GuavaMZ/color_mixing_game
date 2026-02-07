import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

class Fireworks extends PositionComponent {
  final Random _rnd = Random();
  double _timer = 0;

  Fireworks({Vector2? size}) : super(size: size);

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
    if (_timer > 0.5) {
      _timer = 0;
      _launchFirework();
    }
  }

  void _launchFirework() {
    // Random position
    final x = _rnd.nextDouble() * (size.x);
    final y = _rnd.nextDouble() * (size.y * 0.5); // Top half

    final color = HSLColor.fromAHSL(
      1.0,
      _rnd.nextDouble() * 360,
      1.0,
      0.5,
    ).toColor();

    add(
      ParticleSystemComponent(
        particle: Particle.generate(
          count: 50,
          lifespan: 1.5,
          generator: (i) {
            final angle = _rnd.nextDouble() * 2 * pi;
            final speed = _rnd.nextDouble() * 100 + 50;
            final velocity = Vector2(cos(angle), sin(angle)) * speed;
            return AcceleratedParticle(
              position: Vector2(x, y),
              speed: velocity,
              acceleration: Vector2(0, 100), // Gravity
              child: CircleParticle(
                paint: Paint()..color = color,
                radius: 2,
                lifespan: 1.5,
              ),
            );
          },
        ),
      ),
    );
  }
}
