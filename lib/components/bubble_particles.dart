import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class BubbleParticles extends PositionComponent {
  final Random _rnd = Random();
  final List<_Bubble> _bubbles = [];
  double _spawnTimer = 0.0;
  double liquidLevel = 0.0;
  Color color = Colors.white;

  BubbleParticles({required Vector2 size}) : super(size: size);

  @override
  void update(double dt) {
    super.update(dt);

    if (liquidLevel > 0.05) {
      _spawnTimer += dt;
      // Spawn rate based on liquid level? Or constant.
      if (_spawnTimer > 0.1) {
        _spawnTimer = 0;
        if (_bubbles.length < 50) {
          _bubbles.add(_createBubble());
        }
      }
    }

    // Update bubbles
    for (var i = _bubbles.length - 1; i >= 0; i--) {
      final bubble = _bubbles[i];
      bubble.y -= bubble.speed * dt;
      bubble.x += sin(bubble.y * 0.1 + bubble.offset) * 20 * dt; // Wiggle
      bubble.life -= dt;

      // Pop at surface
      final surfaceY = size.y * (1 - liquidLevel);
      if (bubble.y < surfaceY || bubble.life <= 0) {
        _bubbles.removeAt(i);
      }
    }
  }

  _Bubble _createBubble() {
    return _Bubble(
      x: _rnd.nextDouble() * size.x,
      y: size.y,
      radius: _rnd.nextDouble() * 3 + 1,
      speed: _rnd.nextDouble() * 50 + 20,
      life: _rnd.nextDouble() * 3 + 1,
      offset: _rnd.nextDouble() * 100,
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (liquidLevel <= 0.05) return;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    for (final bubble in _bubbles) {
      canvas.drawCircle(Offset(bubble.x, bubble.y), bubble.radius, paint);
    }
  }
}

class _Bubble {
  double x;
  double y;
  double radius;
  double speed;
  double life;
  double offset;

  _Bubble({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.life,
    required this.offset,
  });
}
