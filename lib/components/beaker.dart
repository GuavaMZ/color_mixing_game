import 'dart:math';
import 'dart:ui';
import 'package:color_mixing_deductive/components/bubble_particles.dart';
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
  bool isBlindMode = false;

  late BubbleParticles _bubbleParticles;

  // Cached Paints
  final Paint _liquidPaint = Paint()..style = PaintingStyle.fill;
  final Paint _outlinePaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  final Paint _reflectionPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.3)
    ..style = PaintingStyle.fill;

  // Symbol Paints
  final Paint _symbolPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4
    ..color = Colors.white.withValues(alpha: 0.8);

  Beaker({required Vector2 position, required Vector2 size})
    : super(position: position, size: size, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _bubbleParticles = BubbleParticles(size: size);
    add(_bubbleParticles);
  }

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

    // Update bubbles
    _bubbleParticles.liquidLevel = _activeLevel;
    _bubbleParticles.color = currentColor;

    // Decay shake level
    if (_shakeLevel > 0) {
      _shakeLevel = (_shakeLevel - dt * 2).clamp(0.0, 1.0);
    }
  }

  @override
  void render(Canvas canvas) {
    // Note: Children (BubbleParticles) render automatically after this if we call super.render?
    // Actually PositionComponent renders children on top.
    // We want bubbles INSIDE the liquid/glass.
    // So custom render order might be needed: Glass Back -> Liquid -> Bubbles -> Glass Front.
    // Since Bubbles is a child, it renders last.
    // We can manually render children inside clipped area OR let them render on top if we trust clip.
    // But children of PositionComponent are not automatically clipped to parent size.
    // So we should probably NOT add BubbleParticles as a child if we want to clip it manually here,
    // OR we use canvas.clipPath here and render children manually?
    // simpler: Let's manage bubbles drawing HERE instead of a separate component if we want complex clipping.
    // BUT I added a component. Let's try to clip children.

    // Actually, I'll draw the Liquid and THEN the bubbles manually if I can, OR just Clip, draw liquid, then draw bubbles myself (logic inside Beaker).
    // The Update loop handles physics. Render handles drawing.
    // Since I added BubbleParticles as child, it will draw on top of everything I draw here.
    // That's fine for "Glass Front" effect if the glass front is translucent.
    // But bubbles should be BEHIND the front glass highlights/outline.

    // Better approach: Don't add BubbleParticles as a child. Just keep it as a member and call its update/render manually.

    // 0. Beaker Shape
    final beakerPath = _getBeakerPath(size);

    // 1. Back Glass
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

    // 2. Liquid & Content
    if (_activeLevel > 0) {
      canvas.save();
      canvas.clipPath(beakerPath);

      final clampedLevel = _activeLevel.clamp(0.0, 1.0);
      final liquidTop = size.y * (1 - clampedLevel);

      // Liquid Color
      final displayColor = isBlindMode ? const Color(0xFF222222) : currentColor;
      _liquidPaint.color = displayColor;

      // Draw Liquid Wave
      final liquidPath = Path();
      const waveCount = 1.5;
      final waveAmplitude = 6.0 * (1 + _shakeLevel * 2.5);
      final waveSpeed = 6.0;

      liquidPath.moveTo(0, liquidTop);
      for (double x = 0; x <= size.x; x += 4) {
        final yOffset =
            sin(x / size.x * waveCount * pi + _time * waveSpeed) *
            waveAmplitude;
        liquidPath.lineTo(x, liquidTop + yOffset);
      }
      liquidPath.lineTo(size.x, size.y);
      liquidPath.lineTo(0, size.y);
      liquidPath.close();

      final liquidGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [displayColor, Color.lerp(displayColor, Colors.black, 0.4)!],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));

      _liquidPaint.shader = liquidGradient;
      canvas.drawPath(liquidPath, _liquidPaint);

      // 2.1 Draw Bubbles (Manually clipped)
      _bubbleParticles.render(canvas);

      // 2.2 Blind Mode Symbols
      if (isBlindMode && _activeLevel > 0.1) {
        _drawBlindModeSymbols(canvas, size, liquidTop);
      }

      // 2.3 Surface Line
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

    // 3. Glass Outline
    canvas.drawPath(beakerPath, _outlinePaint);

    // 4. Highlights
    _drawHighlights(canvas);

    // 5. Blind Mode "?" if empty-ish/unset (legacy)
    // Removing legacy '?' if we have specific symbols, but let's keep it if level is low or color is unknown?
    // The user wants geometric symbols.
  }

  void _drawBlindModeSymbols(Canvas canvas, Vector2 size, double liquidTop) {
    // Estimate color components from currentColor
    // We need to know the Mix. Since `currentColor` is a Color, we can try to guess or better, pass the mix state.
    // But Beaker only knows Color. R, G, B components of the Color.
    // Pure Red ~ (255, 0, 0).
    final r = currentColor.red;
    final g = currentColor.green;
    final b = currentColor.blue;

    // Threshold to show symbol
    const threshold = 50;

    final centerY = (liquidTop + size.y) / 2;
    final centerX = size.x / 2;

    // We'll draw symbols in a row or overlapping?
    // Let's create a composite visual.
    // Red -> Triangle
    // Blue -> Square
    // Yellow (Green component in additive?) -> Circle.
    // Wait, the game is CMY or RGB? "Color Mixing Deductive" usually implies RYB or CMY or RGB.
    // Existing code has rDrops, gDrops, bDrops, white, black. So it's RGB mixing.
    // User request: "Triangle for Red, Square for Blue, Circle for Yellow".
    // Yellow in RGB is Red + Green.
    // So if Red & Green are high -> Yellow -> Circle.
    // If just Red -> Triangle.
    // If just Blue -> Square.
    // If Green? User didn't specify Green symbol. Maybe 'Circle' for Yellow implies Green?
    // Usually Yellow = Red + Green in light.
    // Let's stick to Red, Blue, Yellow (Red+Green).

    final bool hasRed = r > threshold;
    final bool hasGreen = g > threshold; // Used for Yellow
    final bool hasBlue = b > threshold;

    // Logic:
    // If Red & Green -> Show Yellow Circle? Or Show Red Triangle AND Green Symbol?
    // User said "Circle for Yellow".
    // I'll try to map RGB to the requested symbols.

    // Setup positions
    double iconSize = 40;

    // We are drawing on Canvas, not widgets.

    // Calculate total width to center them
    // simple logic: Draw symbols based on presence.

    // If multiple, offset them
    // Let's always draw them in fixed slots or overlaid?
    // "Inscribed inside".

    if (hasBlue) {
      // Square
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(centerX, centerY),
          width: iconSize,
          height: iconSize,
        ),
        _symbolPaint,
      );
    }

    // If Red and Green are both high, maybe it's Yellow?
    if (hasRed && hasGreen) {
      // Yellow Circle
      canvas.drawCircle(Offset(centerX, centerY), iconSize / 2, _symbolPaint);
    } else if (hasRed) {
      // Red Triangle
      final path = Path();
      path.moveTo(centerX, centerY - iconSize / 2);
      path.lineTo(centerX + iconSize / 2, centerY + iconSize / 2);
      path.lineTo(centerX - iconSize / 2, centerY + iconSize / 2);
      path.close();
      canvas.drawPath(path, _symbolPaint);
    }
    // What if Green only?
    else if (hasGreen) {
      // Triangle pointing down? or Circle?
      // User didn't specify Green. I'll use Circle for Green too as it makes Yellow.
      canvas.drawCircle(Offset(centerX, centerY), iconSize / 2, _symbolPaint);
    }
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
