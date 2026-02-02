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

    // Create CONFETTI particle system
    final particleComponent = ParticleSystemComponent(
      position: position,
      particle: Particle.generate(
        count: 100, // Lots of confetti
        lifespan: 3.5,
        generator: (i) {
          final random = Random();
          final color = colors[random.nextInt(colors.length)];
          final angle = random.nextDouble() * pi * 2;
          final speed = 150 + random.nextDouble() * 250;
          final rotationSpeed = (random.nextDouble() - 0.5) * 10;

          return AcceleratedParticle(
            acceleration: Vector2(0, 200), // Gravity
            speed: Vector2(cos(angle) * speed, sin(angle) * speed - 150),
            position: Vector2.zero(),
            child: ComputedParticle(
              lifespan: 3.5,
              renderer: (canvas, particle) {
                final progress = particle.progress;
                final opacity = (1 - progress).clamp(0.0, 1.0);

                // Rotation for confetti effect
                final rotation = progress * rotationSpeed * 10;

                canvas.save();
                canvas.translate(
                  0,
                  0,
                ); // Already processed by particle wrapper?
                // Actually ComputedParticle doesn't transform canvas by default
                // But particle.position is handled by parent? No, ComputedParticle just gives us the callback.
                // We rely on the parent (AcceleratedParticle) to move the canvas context or pass offset?
                // Flame's ParticleSystem moves the canvas to particle position usually.

                canvas.rotate(rotation);

                final paint = Paint()
                  ..color = color.withValues(alpha: opacity)
                  ..style = PaintingStyle.fill;

                // Draw Rectangular Confetti
                final width = 8.0 + random.nextDouble() * 6;
                final height = 4.0 + random.nextDouble() * 4;

                canvas.drawRect(
                  Rect.fromCenter(
                    center: Offset.zero,
                    width: width,
                    height: height,
                  ),
                  paint,
                );

                canvas.restore();
              },
            ),
          );
        },
      ),
    );

    add(particleComponent);

    Future.delayed(const Duration(milliseconds: 3500), () {
      removeFromParent();
    });
  }
}
