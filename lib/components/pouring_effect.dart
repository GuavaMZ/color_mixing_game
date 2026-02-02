import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

enum PouringStyle { straight, wobbly, droplets }

class PouringEffect extends PositionComponent {
  final Color color;
  final PouringStyle style;
  double _time = 0;
  final double duration = 0.5;
  double _opacity = 1.0;

  PouringEffect({
    required Vector2 position,
    required Vector2 size,
    required this.color,
    this.style = PouringStyle.straight,
  }) : super(position: position, size: size);

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    if (_time > duration) {
      _opacity = (_opacity - dt * 5).clamp(0, 1);
      if (_opacity <= 0) removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = color.withValues(alpha: _opacity)
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = Colors.black.withValues(alpha: _opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path();
    final topWidth = size.x * 0.4;
    final bottomWidth = size.x * 0.8;

    switch (style) {
      case PouringStyle.straight:
        path.moveTo(size.x / 2 - topWidth / 2, 0);
        path.lineTo(size.x / 2 + topWidth / 2, 0);
        path.lineTo(size.x / 2 + bottomWidth / 2, size.y);
        path.lineTo(size.x / 2 - bottomWidth / 2, size.y);
        break;

      case PouringStyle.wobbly:
        path.moveTo(size.x / 2 - topWidth / 2, 0);
        path.lineTo(size.x / 2 + topWidth / 2, 0);

        // Wobble right side
        for (double y = 0; y <= size.y; y += 10) {
          final xOffset = sin(y * 0.1 + _time * 20) * 5;
          path.lineTo(size.x / 2 + bottomWidth / 2 + xOffset, y);
        }

        // Wobble left side
        for (double y = size.y; y >= 0; y -= 10) {
          final xOffset = sin(y * 0.1 + _time * 20) * 5;
          path.lineTo(size.x / 2 - bottomWidth / 2 + xOffset, y);
        }
        break;

      case PouringStyle.droplets:
        // Draw 3 big cartoon drops
        for (int i = 0; i < 3; i++) {
          final dropY = (y + _time * 500 + i * 40) % size.y;
          final dropRect = Rect.fromCenter(
            center: Offset(size.x / 2, dropY),
            width: 15,
            height: 25,
          );
          canvas.drawOval(dropRect, paint);
          canvas.drawOval(dropRect, outlinePaint);
        }
        return; // Early return as we drew directly
    }

    if (style != PouringStyle.droplets) {
      canvas.drawPath(path, paint);
      canvas.drawPath(path, outlinePaint);
    }
  }
}
