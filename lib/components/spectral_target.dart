import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../helpers/theme_constants.dart';

class SpectralGhostTarget extends PositionComponent {
  final Color targetColor;
  double _time = 0;

  SpectralGhostTarget({required Vector2 position, required this.targetColor})
    : super(position: position, size: Vector2(100, 100), anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final center = size.toOffset() / 2;
    final pulse = (sin(_time * 3) + 1) / 2;

    // Spectral glow
    final glowPaint = Paint()
      ..color = targetColor.withValues(alpha: 0.2 + pulse * 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(center, 30 + pulse * 10, glowPaint);

    // Outline
    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = targetColor.withValues(alpha: 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 5);

    // Draw a "ghostly" shape (simplified beaker silhouette)
    final path = Path()
      ..moveTo(center.dx - 20, center.dy - 30)
      ..lineTo(center.dx + 20, center.dy - 30)
      ..lineTo(center.dx + 25, center.dy + 30)
      ..lineTo(center.dx - 25, center.dy + 30)
      ..close();

    canvas.drawPath(path, outlinePaint);

    // Glitch lines
    if (Random().nextDouble() > 0.8) {
      final glitchPaint = Paint()
        ..color = AppTheme.neonCyan.withValues(alpha: 0.5)
        ..strokeWidth = 1;
      double lineY = center.dy - 30 + Random().nextDouble() * 60;
      canvas.drawLine(
        Offset(center.dx - 35, lineY),
        Offset(center.dx + 35, lineY),
        glitchPaint,
      );
    }
  }
}
