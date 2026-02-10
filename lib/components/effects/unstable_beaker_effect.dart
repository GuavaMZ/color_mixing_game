import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Unstable beaker visual effect for Chaos Lab Mode
/// Adds pulsing glow, color shifting, and bubbling animation
class UnstableBeakerEffect extends Component {
  final Random _random = Random();
  double _pulseTimer = 0;
  double _colorShiftTimer = 0;
  double _bubbleTimer = 0;
  final List<_Bubble> _bubbles = [];

  Color _currentGlowColor = Colors.red;
  final List<Color> _chaosColors = [
    Colors.red,
    Colors.orange,
    const Color(0xFFFF0099), // Magenta
    const Color(0xFF00F0FF), // Cyan
    const Color(0xFFFAFF00), // Yellow
    Colors.purple,
    Colors.green,
  ];

  @override
  void update(double dt) {
    super.update(dt);

    _pulseTimer += dt * 3; // Pulse speed
    _colorShiftTimer += dt;
    _bubbleTimer += dt;

    // Shift glow color periodically
    if (_colorShiftTimer >= 0.8) {
      _currentGlowColor = _chaosColors[_random.nextInt(_chaosColors.length)];
      _colorShiftTimer = 0;
    }

    // Spawn bubbles
    if (_bubbleTimer >= 0.15) {
      if (parent != null) {
        final beakerWidth = 180.0;
        _bubbles.add(
          _Bubble(
            x: -beakerWidth / 2 + _random.nextDouble() * beakerWidth,
            y: 0,
            size: 3 + _random.nextDouble() * 8,
            speed: 30 + _random.nextDouble() * 40,
          ),
        );
      }
      _bubbleTimer = 0;
    }

    // Update bubbles
    _bubbles.removeWhere((b) => b.isDead);
    for (var bubble in _bubbles) {
      bubble.update(dt);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (parent == null) return;

    final pulseIntensity = (sin(_pulseTimer) + 1) / 2; // 0 to 1

    // Outer glow (pulsing)
    final glowPaint = Paint()
      ..color = _currentGlowColor.withValues(alpha: 0.3 * pulseIntensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);

    canvas.drawCircle(Offset.zero, 100 + pulseIntensity * 20, glowPaint);

    // Inner glow
    final innerGlowPaint = Paint()
      ..color = _currentGlowColor.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    canvas.drawCircle(Offset.zero, 60, innerGlowPaint);

    // Render bubbles
    final bubblePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    for (var bubble in _bubbles) {
      canvas.drawCircle(Offset(bubble.x, bubble.y), bubble.size, bubblePaint);

      // Bubble highlight
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.6);
      canvas.drawCircle(
        Offset(bubble.x - bubble.size * 0.3, bubble.y - bubble.size * 0.3),
        bubble.size * 0.3,
        highlightPaint,
      );
    }
  }
}

class _Bubble {
  double x;
  double y;
  final double size;
  final double speed;
  double lifetime = 0;
  final double maxLifetime = 3.0;

  _Bubble({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
  });

  void update(double dt) {
    y -= speed * dt;
    lifetime += dt;

    // Wobble sideways
    x += (Random().nextDouble() - 0.5) * 10 * dt;
  }

  bool get isDead => lifetime >= maxLifetime || y < -150;
}
