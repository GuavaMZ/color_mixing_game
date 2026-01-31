import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

class WinningParticles extends Component {
  final Vector2 position;
  final List<Color> colors;

  WinningParticles({required this.position, required this.colors});

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Create elegant particle system
    final particleComponent = ParticleSystemComponent(
      position: position,
      particle: Particle.generate(
        count: 150,
        lifespan: 2.0,
        generator: (i) {
          final random = Random();
          final color = colors[random.nextInt(colors.length)];
          final angle = random.nextDouble() * pi * 2;
          final speed = 100 + random.nextDouble() * 200;

          return AcceleratedParticle(
            acceleration: Vector2(0, 80),
            speed: Vector2(cos(angle) * speed, sin(angle) * speed - 100),
            position: Vector2.zero(),
            child: ComputedParticle(
              lifespan: 2.0,
              renderer: (canvas, particle) {
                final progress = particle.progress;
                final opacity = (1 - progress).clamp(0.0, 1.0);
                final size = 8 + random.nextDouble() * 12;

                // Draw particle with glow
                final glowPaint = Paint()
                  ..color = color.withOpacity(opacity * 0.3)
                  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

                canvas.drawCircle(Offset.zero, size * 1.5, glowPaint);

                // Draw main particle
                final paint = Paint()
                  ..color = color.withOpacity(opacity)
                  ..style = PaintingStyle.fill;

                canvas.drawCircle(Offset.zero, size, paint);

                // Add highlight
                final highlightPaint = Paint()
                  ..color = Colors.white.withOpacity(opacity * 0.6);

                canvas.drawCircle(
                  Offset(-size * 0.3, -size * 0.3),
                  size * 0.4,
                  highlightPaint,
                );
              },
            ),
          );
        },
      ),
    );

    add(particleComponent);

    Future.delayed(const Duration(milliseconds: 2500), () {
      removeFromParent();
    });
  }
}
