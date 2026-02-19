import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:color_mixing_deductive/core/lab_catalog.dart';

class BeakerStand extends PositionComponent {
  LabItem config;

  BeakerStand({
    required Vector2 position,
    required Vector2 size,
    required this.config,
  }) : super(position: position, size: size, anchor: Anchor.center);

  void updateConfig(LabItem newConfig) {
    config = newConfig;
  }

  @override
  void render(Canvas canvas) {
    if (config.id == 'stand_basic' ||
        config.id == 'stand_chrome' ||
        config.id == 'stand_wood') {
      _renderSolidStand(canvas);
    } else if (config.id == 'stand_holo') {
      _renderHoloStand(canvas);
    } else if (config.id == 'stand_levitate') {
      _renderLevitateStand(canvas);
    } else {
      _renderSolidStand(canvas);
    }
  }

  void _renderSolidStand(Canvas canvas) {
    // Base platform
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: config.gradientColors.isNotEmpty
            ? config.gradientColors
            : [Colors.grey.shade400, Colors.grey.shade700],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));

    // Draw a simple trapezoid base
    final path = Path();
    final w = size.x;
    final h = size.y;

    // Top is narrower than bottom
    path.moveTo(w * 0.2, 0);
    path.lineTo(w * 0.8, 0);
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();

    canvas.drawPath(path, paint);

    // Add techy details (small panels/lines)
    final detailPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(w * 0.3, h * 0.3),
      Offset(w * 0.7, h * 0.3),
      detailPaint,
    );
    canvas.drawLine(
      Offset(w * 0.4, h * 0.6),
      Offset(w * 0.6, h * 0.6),
      detailPaint,
    );

    // Add specular highlight for chrome and general premium feel
    if (config.id == 'stand_chrome' || config.gradientColors.isNotEmpty) {
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawLine(
        Offset(w * 0.25, h * 0.2),
        Offset(w * 0.2, h * 0.8),
        highlightPaint,
      );

      final glossPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h));
      canvas.drawPath(path, glossPaint);
    }
  }

  void _renderHoloStand(Canvas canvas) {
    final baseColor = (config.gradientColors.isNotEmpty
        ? config.gradientColors.first
        : Colors.cyan);

    final paint = Paint()
      ..color = baseColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    // Draw multiple rings with aura
    for (int i = 0; i < 3; i++) {
      final yOffset = i * (size.y / 3);
      final radiusX = size.x / 2 - (i * 5);
      final radiusY = size.y / 4;

      final center = Offset(size.x / 2, size.y / 2 + yOffset - size.y / 4);

      // Glow Aura
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: radiusX * 2.2,
          height: radiusY * 2.2,
        ),
        Paint()
          ..color = baseColor.withValues(alpha: 0.05)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );

      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: radiusX * 2,
          height: radiusY * 2,
        ),
        paint,
      );

      // Ring border
      final borderPaint = Paint()
        ..color = baseColor.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: radiusX * 2,
          height: radiusY * 2,
        ),
        borderPaint,
      );

      // Scanning light effect
      if (i == 1) {
        final scanPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawArc(
          Rect.fromCenter(
            center: center,
            width: radiusX * 2,
            height: radiusY * 2,
          ),
          0,
          pi / 2,
          false,
          scanPaint,
        );
      }
    }
  }

  void _renderLevitateStand(Canvas canvas) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: config.gradientColors.isNotEmpty
            ? [
                config.gradientColors.first.withValues(alpha: 0.6),
                config.gradientColors.last.withValues(alpha: 0.0),
              ]
            : [Colors.purple.withValues(alpha: 0.6), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));

    // Glowing orb/field at the bottom
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x / 2, size.y * 0.8),
        width: size.x,
        height: size.y * 0.6,
      ),
      paint,
    );

    // Small floating bits
    final bitPaint = Paint()
      ..color = config.gradientColors.isNotEmpty
          ? config.gradientColors.first
          : Colors.purple;
    canvas.drawCircle(Offset(size.x * 0.2, size.y * 0.5), 2, bitPaint);
    canvas.drawCircle(Offset(size.x * 0.8, size.y * 0.3), 3, bitPaint);
    canvas.drawCircle(Offset(size.x * 0.5, size.y * 0.9), 2, bitPaint);
  }
}
