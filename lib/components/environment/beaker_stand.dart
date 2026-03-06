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

  final Paint _basePaint = Paint();
  final Paint _detailPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  final Paint _highlightPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  final Paint _glossPaint = Paint();

  final Paint _holoAuraPaint = Paint();
  final Paint _holoFillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _holoBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  Shader? _baseShader;
  Shader? _glossShader;
  Shader? _auraShader;
  LabItem? _lastConfig;
  Vector2? _lastSize;

  void updateConfig(LabItem newConfig) {
    config = newConfig;
  }

  void _updateCacheIfNeeded() {
    if (_lastConfig?.id == config.id && _lastSize == size) return;
    _lastConfig = config;
    _lastSize = size.clone();

    final w = size.x;
    final h = size.y;

    _baseShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: config.gradientColors.isNotEmpty
          ? config.gradientColors
          : [Colors.grey.shade400, Colors.grey.shade700],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    _glossShader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: 0.2),
        Colors.white.withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    if (config.id == 'stand_holo') {
      final baseColor = (config.gradientColors.isNotEmpty
          ? config.gradientColors.first
          : Colors.cyan);
      _auraShader = RadialGradient(
        colors: [
          baseColor.withValues(alpha: 0.1),
          baseColor.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: 20));
      _holoAuraPaint.shader = _auraShader;
    }
  }

  @override
  void render(Canvas canvas) {
    _updateCacheIfNeeded();
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
    _basePaint.shader = _baseShader;

    final path = Path();
    final w = size.x;
    final h = size.y;

    path.moveTo(w * 0.2, 0);
    path.lineTo(w * 0.8, 0);
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();

    canvas.drawPath(path, _basePaint);

    _detailPaint.color = Colors.white.withValues(alpha: 0.1);
    canvas.drawLine(
      Offset(w * 0.3, h * 0.3),
      Offset(w * 0.7, h * 0.3),
      _detailPaint,
    );
    canvas.drawLine(
      Offset(w * 0.4, h * 0.6),
      Offset(w * 0.6, h * 0.6),
      _detailPaint,
    );

    if (config.id == 'stand_chrome' || config.gradientColors.isNotEmpty) {
      _highlightPaint.color = Colors.white.withValues(alpha: 0.3);
      canvas.drawLine(
        Offset(w * 0.25, h * 0.2),
        Offset(w * 0.2, h * 0.8),
        _highlightPaint,
      );

      _glossPaint.shader = _glossShader;
      canvas.drawPath(path, _glossPaint);
    }
  }

  void _renderHoloStand(Canvas canvas) {
    final baseColor = (config.gradientColors.isNotEmpty
        ? config.gradientColors.first
        : Colors.cyan);

    _holoFillPaint.color = baseColor.withValues(alpha: 0.2);
    _holoBorderPaint.color = baseColor.withValues(alpha: 0.5);

    for (int i = 0; i < 3; i++) {
      final yOffset = i * (size.y / 3);
      final radiusX = size.x / 2 - (i * 5);
      final radiusY = size.y / 4;
      final center = Offset(size.x / 2, size.y / 2 + yOffset - size.y / 4);

      // Glow Aura using shared shader and scaling
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(radiusX * 2.2 / 20.0, radiusY * 2.2 / 20.0);
      canvas.drawCircle(Offset.zero, 20, _holoAuraPaint);
      canvas.restore();

      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: radiusX * 2,
          height: radiusY * 2,
        ),
        _holoFillPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: radiusX * 2,
          height: radiusY * 2,
        ),
        _holoBorderPaint,
      );

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
    final w = size.x;
    final h = size.y;
    _basePaint.shader = _baseShader;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, h * 0.8),
        width: w,
        height: h * 0.6,
      ),
      _basePaint,
    );

    final bitPaint = Paint()
      ..color = config.gradientColors.isNotEmpty
          ? config.gradientColors.first
          : Colors.purple;
    canvas.drawCircle(Offset(w * 0.2, h * 0.5), 2, bitPaint);
    canvas.drawCircle(Offset(w * 0.8, h * 0.3), 3, bitPaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.9), 2, bitPaint);
  }
}
