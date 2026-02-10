import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

class EchoParticles extends Component {
  final Vector2 position;
  final Color color;

  EchoParticles({required this.position, required this.color});

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final particleComponent = ParticleSystemComponent(
      position: position,
      particle: Particle.generate(
        count: 15,
        lifespan: 1.5,
        generator: (i) {
          final random = Random();
          final angle = random.nextDouble() * pi * 2;
          final speed = 40 + random.nextDouble() * 60;

          return AcceleratedParticle(
            acceleration: Vector2(0, -20), // Float upwards
            speed: Vector2(cos(angle) * speed, sin(angle) * speed),
            position: Vector2.zero(),
            child: ComputedParticle(
              lifespan: 1.5,
              renderer: (canvas, particle) {
                final progress = particle.progress;
                final opacity = (1 - progress).clamp(0.0, 1.0);
                final size = (1 - progress) * 8;

                final paint = Paint()
                  ..color = color.withValues(alpha: opacity * 0.8)
                  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

                // Bioluminescent core
                canvas.drawCircle(Offset.zero, size / 2, paint);

                // Outer glow
                final glowPaint = Paint()
                  ..color = color.withValues(alpha: opacity * 0.3)
                  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
                canvas.drawCircle(Offset.zero, size, glowPaint);
              },
            ),
          );
        },
      ),
    );

    add(particleComponent);

    Future.delayed(const Duration(milliseconds: 1500), () {
      removeFromParent();
    });
  }
}
