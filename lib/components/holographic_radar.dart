import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../helpers/theme_constants.dart';

class HolographicRadar extends PositionComponent with HasGameRef {
  final double radius;
  double _rotation = 0;
  double _pulse = 0;

  HolographicRadar({required Vector2 position, required this.radius})
    : super(
        position: position,
        size: Vector2.all(radius * 2),
        anchor: Anchor.center,
      );

  @override
  void update(double dt) {
    super.update(dt);
    _rotation += dt * 0.5;
    _pulse = (sin(gameRef.currentTime() * 2) + 1) / 2;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final center = size.toOffset() / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = AppTheme.neonCyan.withValues(alpha: 0.3 + _pulse * 0.2);

    // Outer ring
    canvas.drawCircle(center, radius, paint);

    // Rotating segments
    final segmentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = AppTheme.neonCyan.withValues(alpha: 0.6 + _pulse * 0.4);

    for (int i = 0; i < 4; i++) {
      double startAngle = _rotation + (i * pi / 2);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius + 5),
        startAngle,
        pi / 4,
        false,
        segmentPaint,
      );
    }

    // Inner scanning sweep
    final sweepShader = SweepGradient(
      colors: [
        AppTheme.neonCyan.withValues(alpha: 0),
        AppTheme.neonCyan.withValues(alpha: 0.5),
      ],
      stops: const [0.8, 1.0],
      transform: GradientRotation(_rotation * 2),
    ).createShader(Rect.fromCircle(center: center, radius: radius - 10));

    canvas.drawCircle(
      center,
      radius - 10,
      Paint()
        ..shader = sweepShader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Decorative markers
    final markerPaint = Paint()
      ..color = AppTheme.neonMagenta.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 8; i++) {
      double angle = (i * pi / 4);
      double x = center.dx + cos(angle) * (radius + 15);
      double y = center.dy + sin(angle) * (radius + 15);
      canvas.drawCircle(Offset(x, y), 2, markerPaint);
    }
  }
}
