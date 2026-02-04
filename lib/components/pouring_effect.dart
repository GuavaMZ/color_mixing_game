import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

class PouringEffect extends PositionComponent {
  final Color color;
  final double targetY;
  final double sourceY;
  double _time = 0;
  final double duration = 0.6; // Slightly longer for better feel

  // Animation states
  bool _hittingSurface = false;

  PouringEffect({
    required Vector2 position,
    required this.targetY,
    required this.color,
    required this.sourceY,
  }) : super(position: position);

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    if (_time > duration) {
      removeFromParent();
      return;
    }

    // Check if stream should be hitting surface
    // Stream falls at say 1000 pixels/sec
    // Total distance = targetY - sourceY
    // It's instantaneous for this simple effect, but let's say it takes 0.1s to fall
    if (_time > 0.05 && _time < duration - 0.1) {
      if (!_hittingSurface) {
        _hittingSurface = true;
      }
      // Add splashes while pouring
      if (Random().nextDouble() < 0.3) {
        _spawnSplash();
      }
    } else {
      _hittingSurface = false;
    }
  }

  void _spawnSplash() {
    // Add splash particles at targetY
    // Relative to this component's position (which is usually x-centered)
    // Actually this component is positioned at the pour source X.

    // We need to add particles to the PARENT (the game world), not this component,
    // unless this component is large enough.
    // Let's assume we add to parent.
    if (parent == null) return;

    final particle = ParticleSystemComponent(
      position: Vector2(position.x, targetY),
      particle: Particle.generate(
        count: 3,
        lifespan: 0.4,
        generator: (i) {
          final rng = Random();
          final speed = 50.0 + rng.nextDouble() * 100.0;
          final angle =
              -pi / 2 + (rng.nextDouble() - 0.5) * 1.5; // Upwards spread

          return AcceleratedParticle(
            position: Vector2.zero(),
            speed: Vector2(cos(angle) * speed, sin(angle) * speed),
            acceleration: Vector2(0, 400), // Gravity
            child: CircleParticle(
              paint: Paint()..color = color.withValues(alpha: 0.8),
              radius: 1.5 + rng.nextDouble() * 1.5,
              lifespan: 0.4,
            ),
          );
        },
      ),
    );
    parent!.add(particle);
  }

  @override
  void render(Canvas canvas) {
    // Simulate stream flow
    // 0.0 -> 0.1: Start falling
    // 0.1 -> 0.5: Full stream
    // 0.5 -> 0.6: Cut off from top

    double progress = _time / duration;

    double endY = targetY - position.y;

    double currentTop = 0;
    double currentBottom = 0;

    // Fall in
    if (progress < 0.2) {
      double fallProgress = progress / 0.2;
      currentTop = 0;
      currentBottom = endY * fallProgress;
    }
    // Sustain
    else if (progress < 0.8) {
      currentTop = 0;
      currentBottom = endY;
    }
    // Fall out / Cut off
    else {
      double cutProgress = (progress - 0.8) / 0.2;
      currentTop = endY * cutProgress;
      currentBottom = endY;
    }

    if (currentTop >= currentBottom) return;

    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    // Draw stream with variable width
    // Top is wider (if coming from bottle) or same
    // Let's make it thinner at bottom due to gravity acceleration
    final path = Path();

    double topWidth = 8.0;
    double bottomWidth = 4.0;

    // Wobble
    double offsetTop = sin(_time * 20) * 1.0;
    double offsetBottom = sin(_time * 25 + 2) * 2.0;

    path.moveTo(-topWidth / 2 + offsetTop, currentTop);
    path.lineTo(topWidth / 2 + offsetTop, currentTop);
    path.lineTo(bottomWidth / 2 + offsetBottom, currentBottom);
    path.lineTo(-bottomWidth / 2 + offsetBottom, currentBottom);
    path.close();

    canvas.drawPath(path, bgPaint);

    // Inner highlight for liquid look
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final highlightPath = Path();
    highlightPath.moveTo(-topWidth / 4 + offsetTop, currentTop);
    highlightPath.lineTo(0 + offsetTop, currentTop);
    highlightPath.lineTo(0 + offsetBottom, currentBottom);
    highlightPath.lineTo(-bottomWidth / 4 + offsetBottom, currentBottom);
    highlightPath.close(); // Approximate highlight

    canvas.drawPath(highlightPath, highlightPaint);
  }
}
