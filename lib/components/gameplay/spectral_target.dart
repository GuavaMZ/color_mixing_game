import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors;

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
    final glitch = (sin(_time * 25) > 0.8) ? (sin(_time * 40) * 3) : 0.0;

    canvas.save();
    canvas.translate(glitch, 0);

    // 1. Ghostly Glow
    final glowPaint = Paint()
      ..color = targetColor.withValues(alpha: 0.2 + pulse * 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    // Draw an elliptical glow behind
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: 80 + pulse * 10,
        height: 100 + pulse * 10,
      ),
      glowPaint,
    );

    // 2. Beaker Silhouette Path
    final path = Path();
    final w = 50.0;
    final h = 70.0;
    final topY = center.dy - h / 2;
    final bottomY = center.dy + h / 2;
    final leftX = center.dx - w / 2;
    final rightX = center.dx + w / 2;

    path.moveTo(leftX + 10, topY); // Top rim
    path.lineTo(rightX - 10, topY);
    path.lineTo(rightX - 8, topY + 10); // Neck
    path.lineTo(rightX, bottomY - 5); // Body
    path.quadraticBezierTo(
      rightX,
      bottomY,
      rightX - 10,
      bottomY,
    ); // Bottom right
    path.lineTo(leftX + 10, bottomY); // Bottom
    path.quadraticBezierTo(leftX, bottomY, leftX, bottomY - 5); // Bottom left
    path.lineTo(leftX + 8, topY + 10); // Neck
    path.close();

    // 3. Draw Silhouette
    final silhouettePaint = Paint()
      ..color = targetColor.withValues(alpha: 0.6 + pulse * 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, silhouettePaint);

    // 4. Inner Liquid Core (Classic Circle)
    final corePaint = Paint()
      ..color = targetColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 15, corePaint);

    // 5. Glitch Lines
    if (sin(_time * 15) > 0.7) {
      final linePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(leftX - 10, center.dy + sin(_time * 20) * 30),
        Offset(rightX + 10, center.dy + sin(_time * 20) * 30),
        linePaint,
      );
    }

    canvas.restore();
  }
}
