import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

enum BeakerType { classic, laboratory, magicBox, hexagon, cylinder, round }

class Beaker extends PositionComponent {
  Color currentColor = Colors.white.withValues(alpha: .2);
  Color _targetColor = Colors.white.withValues(alpha: .2);
  double liquidLevel = 0.0;
  double _activeLevel = 0.0;
  double _time = 0.0;
  double _shakeLevel = 0.0;
  BeakerType type = BeakerType.classic;

  // Cached Paints
  final Paint _liquidPaint = Paint()..style = PaintingStyle.fill;
  final Paint _glassPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.1)
    ..style = PaintingStyle.fill;
  final Paint _outlinePaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  final Paint _highlightPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.25)
    ..style = PaintingStyle.fill;
  final Paint _reflectionPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.3)
    ..style = PaintingStyle.fill;

  Beaker({required Vector2 position, required Vector2 size})
    : super(position: position, size: size, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Smoothly interpolate current color towards target color
    if (currentColor != _targetColor) {
      currentColor =
          Color.lerp(currentColor, _targetColor, dt * 5) ?? _targetColor;
    }

    // Smoothly interpolate liquid level
    if ((_activeLevel - liquidLevel).abs() > 0.001) {
      _activeLevel = lerpDouble(_activeLevel, liquidLevel, dt * 3)!;
    } else {
      _activeLevel = liquidLevel;
    }

    // Decay shake level
    if (_shakeLevel > 0) {
      _shakeLevel = (_shakeLevel - dt * 2).clamp(0.0, 1.0);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Get the shape path based on beaker type
    final beakerPath = _getBeakerPath(size);

    // 0. Beaker Back Glass (Semi-transparent dark fill)
    final glassGradient = LinearGradient(
      colors: [
        Colors.white.withValues(alpha: 0.05),
        Colors.white.withValues(alpha: 0.15),
        Colors.white.withValues(alpha: 0.05),
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));

    final glassPaint = Paint()
      ..shader = glassGradient
      ..style = PaintingStyle.fill;

    canvas.drawPath(beakerPath, glassPaint);

    // 1. Draw Liquid (Clipped to beaker shape)
    if (_activeLevel > 0) {
      canvas.save();
      canvas.clipPath(beakerPath);

      // Clamp level to prevent visual overflow glitches
      // Ensure we don't draw liquid above the rim if level > 1.0 (though logic prevents it usually)
      final clampedLevel = _activeLevel.clamp(0.0, 1.0);
      final liquidTop = size.y * (1 - clampedLevel);
      _liquidPaint.color = currentColor;

      final liquidPath = Path();
      const waveCount = 1.5;
      final waveAmplitude = 6.0 * (1 + _shakeLevel * 2.5);
      final waveSpeed = 6.0;

      liquidPath.moveTo(0, liquidTop);

      // Draw top wave curve
      for (double x = 0; x <= size.x; x += 4) {
        final yOffset =
            sin(x / size.x * waveCount * pi + _time * waveSpeed) *
            waveAmplitude;
        liquidPath.lineTo(x, liquidTop + yOffset);
      }

      liquidPath.lineTo(size.x, size.y);
      liquidPath.lineTo(0, size.y);
      liquidPath.close();

      // Liquid Gradient (Top to Bottom Darker)
      final liquidGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          currentColor,
          Color.lerp(currentColor, Colors.black, 0.2)!, // Proper darkening
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));

      _liquidPaint.shader = liquidGradient;

      canvas.drawPath(liquidPath, _liquidPaint);

      // Draw Surface Wave Line Only (Better than outlining the whole liquid)
      final surfacePath = Path();
      surfacePath.moveTo(0, liquidTop);
      for (double x = 0; x <= size.x; x += 2) {
        final yOffset =
            sin(x / size.x * waveCount * pi + _time * waveSpeed) *
            waveAmplitude;
        surfacePath.lineTo(x, liquidTop + yOffset);
      }

      final surfacePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(surfacePath, surfacePaint);

      canvas.restore();
    }

    // 2. Draw Glass Rim/Body Outline
    // Outer thick neon-ish border for cartoon look
    canvas.drawPath(beakerPath, _outlinePaint);

    // 3. Realistic Highlights (Gloss)
    _drawHighlights(canvas);
  }

  Path _getBeakerPath(Vector2 size) {
    final path = Path();
    switch (type) {
      case BeakerType.laboratory:
        // Flask shape
        path.moveTo(size.x * 0.35, 0);
        path.lineTo(size.x * 0.65, 0);
        path.lineTo(size.x * 0.65, size.y * 0.4);
        path.cubicTo(
          size.x,
          size.y * 0.5,
          size.x,
          size.y,
          size.x * 0.8,
          size.y,
        );
        path.lineTo(size.x * 0.2, size.y);
        path.cubicTo(0, size.y, 0, size.y * 0.5, size.x * 0.35, size.y * 0.4);
        path.close();
        break;
      case BeakerType.magicBox:
        // Box shape with rounded bottom
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.x, size.y),
          const Radius.circular(12),
        );
        path.addRRect(rect);
        break;
      case BeakerType.hexagon:
        // Hexagon shape
        path.moveTo(size.x * 0.5, 0);
        path.lineTo(size.x, size.y * 0.25);
        path.lineTo(size.x, size.y * 0.75);
        path.lineTo(size.x * 0.5, size.y);
        path.lineTo(0, size.y * 0.75);
        path.lineTo(0, size.y * 0.25);
        path.close();
        break;
      case BeakerType.cylinder:
        // Tall cylinder shape
        double w = size.x * 0.6;
        double offsetX = (size.x - w) / 2;
        path.addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(offsetX, 0, w, size.y),
            const Radius.circular(8),
          ),
        );
        break;
      case BeakerType.round:
        // Round bottom flask (sphere with neck)
        double neckW = size.x * 0.4;
        double sphereR = size.x / 2;

        // Neck
        path.moveTo((size.x - neckW) / 2, 0);
        path.lineTo((size.x + neckW) / 2, 0);
        path.lineTo((size.x + neckW) / 2, size.y * 0.4);

        // Sphere body
        // We draw an arc for the body
        path.arcToPoint(
          Offset((size.x - neckW) / 2, size.y * 0.4),
          radius: Radius.circular(sphereR),
          largeArc: true,
          clockwise: true,
        );
        path.close();
        break;
      case BeakerType.classic:
      default:
        // Realistic Beaker Shape
        // Straight sides, rounded corners at bottom
        double r = 15.0; // Bottom radius

        path.moveTo(0, 0); // Top Left
        path.lineTo(0, size.y - r); // Left side
        path.quadraticBezierTo(0, size.y, r, size.y); // Bottom Left Corner
        path.lineTo(size.x - r, size.y); // Bottom
        path.quadraticBezierTo(
          size.x,
          size.y,
          size.x,
          size.y - r,
        ); // Bottom Right Corner
        path.lineTo(size.x, 0); // Right Side
        path.close();
    }
    return path;
  }

  void _drawHighlights(Canvas canvas) {
    // Draw Rim for Classic/Realistic Beaker
    if (type == BeakerType.classic) {
      final rimPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;

      // Flared Rim
      final rimPath = Path();
      rimPath.moveTo(-5, 0);
      rimPath.lineTo(size.x + 5, 0);
      // Maybe a slight lip structure

      // Draw a rounded rect for the distinct heavy rim look at the top
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-4, -4, size.x + 8, 8),
          Radius.circular(4),
        ),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.2)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-4, -4, size.x + 8, 8),
          Radius.circular(4),
        ),
        rimPaint,
      );
    }

    switch (type) {
      case BeakerType.laboratory:
        canvas.drawCircle(
          Offset(size.x * 0.75, size.y * 0.7),
          8,
          _reflectionPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(size.x * 0.4, 10, 6, size.y * 0.3),
            const Radius.circular(3),
          ),
          _reflectionPaint,
        );
        break;
      case BeakerType.hexagon:
        canvas.drawCircle(
          Offset(size.x * 0.8, size.y * 0.3),
          6,
          _reflectionPaint,
        );
        break;
      case BeakerType.cylinder:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(size.x * 0.25, 20, 6, size.y * 0.6),
            const Radius.circular(3),
          ),
          _reflectionPaint,
        );
        break;
      case BeakerType.round:
        canvas.drawCircle(
          Offset(size.x * 0.7, size.y * 0.6),
          12,
          _reflectionPaint,
        );
        break;
      default:
        // Side highlight
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(10, 25, 12, size.y * 0.5),
            const Radius.circular(6),
          ),
          _reflectionPaint,
        );
        // Top highlight
        canvas.drawCircle(const Offset(35, 18), 6, _reflectionPaint);
    }
  }

  void updateVisuals(Color newMixedColor, double newLevel) {
    _targetColor = newMixedColor;
    liquidLevel = newLevel;
    _shakeLevel = 1.0;

    add(
      MoveEffect.by(
        Vector2(0, 5),
        EffectController(duration: 0.1, alternate: true, repeatCount: 1),
      ),
    );
  }

  void clearContents() {
    _targetColor = Colors.white.withValues(alpha: .2);
    liquidLevel = 0.0;
    add(
      MoveEffect.by(
        Vector2(0, 10),
        EffectController(duration: 0.1, alternate: true),
      ),
    );
  }
}
