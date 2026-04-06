import 'dart:math';
import 'dart:ui';
import 'package:color_mixing_deductive/components/particles/bubble_particles.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../../color_mixer_game.dart';

enum BeakerType {
  classic,
  laboratory,
  magicBox,
  hexagon,
  cylinder,
  round,
  diamond,
  star,
  triangle,
}

class Beaker extends PositionComponent with HasGameReference<ColorMixerGame> {
  Color currentColor = Colors.white.withValues(alpha: .2);
  Color _targetColor = Colors.white.withValues(alpha: .2);
  double liquidLevel = 0.0;
  double _activeLevel = 0.0;
  double _shakeLevel = 0.0;
  BeakerType type = BeakerType.classic;
  bool isBlindMode = false;
  late BubbleParticles _bubbleParticles;

  // Cached Paints - Premium Glass Effects
  final Paint _glassFrontPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.15)
    ..style = PaintingStyle.fill;

  final Paint _glassBackPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.08)
    ..style = PaintingStyle.fill;

  // Symbol Paints
  final Paint _symbolPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4
    ..color = Colors.white.withValues(alpha: 0.8);

  // Liquid Paints
  final Paint _liquidVolPaint = Paint()..style = PaintingStyle.fill;
  final Paint _liquidSurfacePaint = Paint()..style = PaintingStyle.fill;
  final Paint _liquidMeniscusPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.4)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5;

  final Paint _liquidBackPaint = Paint()..style = PaintingStyle.fill;
  final Paint _rimPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.5)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.5;

  Shader? _liquidGradientShader;
  Shader? _glassGradientShader;
  Shader? _leftGleamShader;
  Shader? _rightGleamShader;
  Shader? _topRimShader;
  Color? _lastGradientColor;
  Vector2? _lastShaderSize;
  Path? _cachedBeakerPath;
  BeakerType? _lastPathType;
  Vector2? _lastPathSize;

  Beaker({required Vector2 position, required Vector2 size})
    : super(position: position, size: size, anchor: Anchor.center);

  // 3D Perspective Constant
  final double _perspectiveRatio = 0.15; // Height of ellipse relative to width

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _bubbleParticles = BubbleParticles(size: size);
    _bubbleParticles.manualRender =
        true; // We will render it manually in render()
    add(_bubbleParticles); // Add to tree so it gets GameRef and updates
  }

  @override
  void update(double dt) {
    _bubbleParticles.update(
      dt,
    ); // Handled by add(_bubbleParticles) automatically
    super.update(dt);

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

    // Meltdown Shake
    if (game.currentMode == GameMode.chaosLab && game.chaosStability < 0.4) {
      final chaosFactor = (1.0 - game.chaosStability / 0.4).clamp(0.0, 1.0);
      _shakeLevel = max(_shakeLevel, chaosFactor * 0.5);
    }

    _updatePaintsAndShaders();
  }

  Color _darken(Color color, [double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  void _updatePaintsAndShaders() {
    final displayColor = isBlindMode ? const Color(0xFF222222) : currentColor;

    // Surface Meniscus is slightly brighter
    _liquidSurfacePaint.color = displayColor.withValues(alpha: 0.9);

    if (_lastGradientColor != displayColor || _lastShaderSize != size) {
      // Cache darkened colors locally so we only compute HSL conversion once
      final dark05 = _darken(displayColor, 0.05);
      final dark1 = _darken(displayColor, 0.1);
      final dark2 = _darken(displayColor, 0.2);

      // 1. Liquid Volume Gradient: Darker at bottom, brighter at edges
      _liquidGradientShader = RadialGradient(
        center: const Alignment(0.0, -0.5),
        radius: 1.5,
        colors: [
          displayColor.withValues(alpha: 0.95), // Core brightness
          dark1.withValues(alpha: 0.95), // Deeper bottom/edges
          dark2.withValues(alpha: 1.0), // Slightly darker very bottom
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));
      _liquidVolPaint.shader = _liquidGradientShader;

      // Back liquid layer represents looking through the liquid to the back glass
      _liquidBackPaint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          dark05.withValues(alpha: 0.5),
          dark1.withValues(alpha: 0.8),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));

      // 2. Glass Gradient Shader: Simulates cylindrical reflection and glass thickness
      _glassGradientShader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0.4), // Strong left rim
          Colors.white.withValues(alpha: 0.05), // Mid-left transition
          Colors.transparent, // Clear view center
          Colors.black.withValues(alpha: 0.15), // Deep inner right curve
          Colors.white.withValues(alpha: 0.25), // Bounce light right rim
        ],
        stops: const [0.0, 0.15, 0.5, 0.85, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));
      _glassFrontPaint.shader = _glassGradientShader;

      // 3. Highlight Shaders
      final double w = size.x;
      final double h = size.y;

      // Sharp Left Gleam
      final Rect leftRect = Rect.fromLTWH(w * 0.08, 0, w * 0.12, h);
      _leftGleamShader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.45),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(leftRect);

      // Secondary Right Reflection
      final Rect rightRect = Rect.fromLTWH(w * 0.82, 0, w * 0.08, h);
      _rightGleamShader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.2),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rightRect);

      // Top Rim Catch-light
      final Rect topRimRect = Rect.fromLTWH(0, 0, w, h * 0.1);
      _topRimShader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.3),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(topRimRect);

      // Update rim stroke width for premium feel
      _rimPaint.strokeWidth = min(size.x, size.y) * 0.015;
      _rimPaint.color = Colors.white.withValues(alpha: 0.6);

      _lastGradientColor = displayColor;
      _lastShaderSize = size.clone();
    }
  }

  Path _getBeakerPathCached() {
    if (_cachedBeakerPath == null ||
        _lastPathType != type ||
        _lastPathSize != size) {
      _cachedBeakerPath = _getBeakerPath(size);
      _lastPathType = type;
      _lastPathSize = size.clone();
    }
    return _cachedBeakerPath!;
  }

  @override
  void render(Canvas canvas) {
    // 1. Render Back Glass (Base shape)
    final Path beakerPath = _getBeakerPathCached();
    canvas.drawPath(beakerPath, _glassBackPaint);

    // 2. Render Liquid with Clipping
    if (_activeLevel > 0.01) {
      canvas.save();
      canvas.clipPath(beakerPath);
      _renderLiquidInterior(canvas);
      canvas.restore();
    }

    // 3. Render Front Glass and Details
    _renderFrontGlass(canvas, beakerPath);
  }

  void _renderLiquidInterior(Canvas canvas) {
    final clampedLevel = _activeLevel.clamp(0.0, 1.0);
    final liquidHeight = size.y * clampedLevel;
    final liquidSurfaceY = size.y - liquidHeight;

    // Back liquid layer for depth
    canvas.drawRect(
      Rect.fromLTWH(0, liquidSurfaceY, size.x, size.y - liquidSurfaceY),
      _liquidBackPaint,
    );

    // Main liquid volume with gradient
    canvas.drawRect(
      Rect.fromLTWH(0, liquidSurfaceY, size.x, size.y - liquidSurfaceY),
      _liquidVolPaint,
    );

    // Bubbles
    _bubbleParticles.forceRender(canvas);

    // Surface effect (ellipse or line depending on shape)
    _renderLiquidSurface(canvas, liquidSurfaceY);

    // Blind Mode Symbols
    if (isBlindMode && _activeLevel > 0.1) {
      _drawBlindModeSymbols(canvas, size, liquidSurfaceY);
    }
  }

  void _renderLiquidSurface(Canvas canvas, double surfaceY) {
    double surfaceWidth = size.x;
    double ellipseH = size.x * _perspectiveRatio;

    // Adjust surface width/shape based on beaker type and height
    switch (type) {
      case BeakerType.laboratory:
        final neckWidth = size.x * 0.45;
        final neckHeight = size.y * 0.35;
        if (surfaceY > neckHeight) {
          final p = (surfaceY - neckHeight) / (size.y - neckHeight);
          surfaceWidth = lerpDouble(neckWidth, size.x, p)!;
        } else {
          surfaceWidth = neckWidth;
        }
        ellipseH = surfaceWidth * _perspectiveRatio;
        break;
      case BeakerType.round:
        final neckWidth = size.x * 0.35;
        final neckHeight = size.y * 0.35;
        final sphereCenterY = size.y - (size.x / 2);
        final sphereRadius = size.x / 2;
        if (surfaceY > neckHeight) {
          final dy = (surfaceY - sphereCenterY).abs();
          surfaceWidth =
              2 * sqrt(max(0, sphereRadius * sphereRadius - dy * dy));
        } else {
          surfaceWidth = neckWidth;
        }
        ellipseH = surfaceWidth * _perspectiveRatio;
        break;
      case BeakerType.triangle:
        final t = surfaceY / size.y;
        surfaceWidth = size.x * (1 - t);
        ellipseH = 0; // Flat line for triangle
        break;
      case BeakerType.diamond:
        // Faceted Diamond Flask
        // Base: 20% width. Neck: 30% width. Widest point: 100% at 45% height.
        final double h = size.y;
        final double w = size.x;
        final double neckH = h * 0.15;
        final double widestY = h * 0.45;
        final double baseW = w * 0.2;
        final double neckW = w * 0.3;

        if (surfaceY < neckH) {
          surfaceWidth = neckW;
        } else if (surfaceY < widestY) {
          final t = (surfaceY - neckH) / (widestY - neckH);
          surfaceWidth = lerpDouble(neckW, w, t)!;
        } else {
          final t = (surfaceY - widestY) / (h - widestY);
          surfaceWidth = lerpDouble(w, baseW, t)!;
        }
        ellipseH = surfaceWidth * _perspectiveRatio;
        break;
      case BeakerType.hexagon:
        // Tall Flat-Topped Hexagonal Flask
        // Base: 60%. Neck: 40%. Widest: 100% at 65% height.
        final double h = size.y;
        final double w = size.x;
        final double neckH = h * 0.1;
        final double widestY = h * 0.65;
        final double baseW = w * 0.6;
        final double neckW = w * 0.4;

        if (surfaceY < neckH) {
          surfaceWidth = neckW;
        } else if (surfaceY < widestY) {
          final t = (surfaceY - neckH) / (widestY - neckH);
          surfaceWidth = lerpDouble(neckW, w, t)!;
        } else {
          final t = (surfaceY - widestY) / (h - widestY);
          surfaceWidth = lerpDouble(w, baseW, t)!;
        }
        ellipseH = surfaceWidth * _perspectiveRatio;
        break;
      case BeakerType.star:
        // Stylized 4-Pointed Star Flask
        // A complex shape requiring tight surface tracking
        final double h = size.y;
        final double w = size.x;
        final double neckY = h * 0.15;
        final double shoulderY = h * 0.40;
        final double waistY = h * 0.60;
        final double baseY = h * 0.95;

        final double neckW = w * 0.25;
        final double shoulderW = w * 0.95;
        final double waistW = w * 0.40;
        final double baseW = w * 0.85;

        // Custom interpolation based on absolute bounds
        if (surfaceY < neckY) {
          surfaceWidth = neckW;
        } else if (surfaceY < shoulderY) {
          final t = (surfaceY - neckY) / (shoulderY - neckY);
          surfaceWidth = lerpDouble(neckW, shoulderW, t)!;
        } else if (surfaceY < waistY) {
          final t = (surfaceY - shoulderY) / (waistY - shoulderY);
          surfaceWidth = lerpDouble(shoulderW, waistW, t)!;
        } else if (surfaceY < baseY) {
          final t = (surfaceY - waistY) / (baseY - waistY);
          surfaceWidth = lerpDouble(waistW, baseW, t)!;
        } else {
          final t = (surfaceY - baseY) / (h - baseY);
          surfaceWidth = lerpDouble(baseW, 0.0, t)!;
        }

        // Slightly reduced perspective scaling for star points to prevent poking outside clip
        ellipseH = surfaceWidth * (_perspectiveRatio * 0.8);
        break;
      case BeakerType.magicBox:
      case BeakerType.cylinder:
      case BeakerType.classic:
        surfaceWidth = size.x;
        ellipseH = (type == BeakerType.magicBox)
            ? 0
            : size.x * _perspectiveRatio;
        break;
    }

    if (ellipseH > 0) {
      final rect = Rect.fromCenter(
        center: Offset(size.x / 2, surfaceY),
        width: surfaceWidth,
        height: ellipseH,
      );

      // Draw interior surface gradient to simulate meniscus depth
      final innerSurfacePaint = Paint()
        ..shader = RadialGradient(
          colors: [Colors.white.withValues(alpha: 0.4), Colors.transparent],
        ).createShader(rect);

      canvas.drawOval(rect, _liquidSurfacePaint);
      canvas.drawOval(rect, innerSurfacePaint);

      // Draw crispy outer edge highlight
      canvas.drawOval(rect, _liquidMeniscusPaint);
    } else {
      final halfW = surfaceWidth / 2;
      canvas.drawLine(
        // Draw a thicker line for edge view
        Offset(size.x / 2 - halfW, surfaceY),
        Offset(size.x / 2 + halfW, surfaceY),
        Paint()
          ..color = _liquidMeniscusPaint.color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 4,
      );
    }
  }

  void _renderFrontGlass(Canvas canvas, Path beakerPath) {
    canvas.drawPath(beakerPath, _glassFrontPaint);
    canvas.drawPath(beakerPath, _rimPaint);

    // Highlights
    _renderHighlights(canvas, beakerPath);
  }

  void _renderHighlights(Canvas canvas, Path beakerPath) {
    // Save state and clip to beaker interior so highlights conform precisely to any shape
    canvas.save();
    canvas.clipPath(beakerPath);

    final double w = size.x;
    final double h = size.y;

    // 1. Sharp Left Gleam (Main Specular)
    final Rect leftRect = Rect.fromLTWH(w * 0.08, 0, w * 0.12, h);
    final Paint leftGleam = Paint()..shader = _leftGleamShader;

    canvas.drawRect(leftRect, leftGleam);

    // 2. Secondary Right Reflection
    final Rect rightRect = Rect.fromLTWH(w * 0.82, 0, w * 0.08, h);
    final Paint rightGleam = Paint()..shader = _rightGleamShader;

    canvas.drawRect(rightRect, rightGleam);

    // 3. Top Rim Catch-light
    final Rect topRimRect = Rect.fromLTWH(0, 0, w, h * 0.1);
    final Paint topRimGleam = Paint()..shader = _topRimShader;
    canvas.drawRect(topRimRect, topRimGleam);

    // 4. Type specialized specular spotlight
    if (type == BeakerType.laboratory || type == BeakerType.round) {
      canvas.drawCircle(
        Offset(w * 0.75, h * 0.65),
        w * 0.08,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }

    // Cleanup clip
    canvas.restore();

    // 5. Very sharp 1px left edge rim light (drawn outside clip for contrast)
    final Paint sharpRim = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // We draw the silhouette again but slightly offset to catch the edge
    canvas.save();
    canvas.clipPath(_getBeakerPathCached());
    canvas.translate(w * 0.02, 0);
    canvas.drawPath(_getBeakerPathCached(), sharpRim);
    canvas.restore();
  }

  void _drawBlindModeSymbols(Canvas canvas, Vector2 size, double liquidTop) {
    final r = (currentColor.r * 255).round();
    final g = (currentColor.g * 255).round();
    final b = (currentColor.b * 255).round();
    const threshold = 50;

    final centerY = (liquidTop + size.y) / 2;
    final centerX = size.x / 2;
    const double iconSize = 40;

    final bool hasRed = r > threshold;
    final bool hasGreen = g > threshold;
    final bool hasBlue = b > threshold;

    if (hasBlue) {
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(centerX, centerY),
          width: iconSize,
          height: iconSize,
        ),
        _symbolPaint,
      );
    }

    if (hasRed && hasGreen) {
      canvas.drawCircle(Offset(centerX, centerY), iconSize / 2, _symbolPaint);
    } else if (hasRed) {
      final path = Path();
      path.moveTo(centerX, centerY - iconSize / 2);
      path.lineTo(centerX + iconSize / 2, centerY + iconSize / 2);
      path.lineTo(centerX - iconSize / 2, centerY + iconSize / 2);
      path.close();
      canvas.drawPath(path, _symbolPaint);
    } else if (hasGreen) {
      canvas.drawCircle(Offset(centerX, centerY), iconSize / 2, _symbolPaint);
    }
  }

  Path _getBeakerPath(Vector2 size) {
    // ... existing _getBeakerPath implementation is already quite good,
    // but I'll make sure classic/cylinder use perspective correctly in their silhouette
    final path = Path();
    switch (type) {
      case BeakerType.classic:
      case BeakerType.cylinder:
        final double ellipseHeight = size.x * _perspectiveRatio;
        final double w = (type == BeakerType.cylinder) ? size.x * 0.8 : size.x;
        final double ox = (size.x - w) / 2;

        path.moveTo(ox, ellipseHeight / 2);
        path.lineTo(ox, size.y - ellipseHeight / 2);
        path.arcTo(
          Rect.fromLTWH(ox, size.y - ellipseHeight, w, ellipseHeight),
          pi,
          -pi,
          false,
        );
        path.lineTo(ox + w, ellipseHeight / 2);
        path.arcTo(Rect.fromLTWH(ox, 0, w, ellipseHeight), 0, -pi, false);
        path.close();
        break;
      case BeakerType.laboratory:
        path.moveTo(size.x * 0.35, 0);
        path.lineTo(size.x * 0.65, 0);
        path.lineTo(size.x * 0.65, size.y * 0.35);
        path.cubicTo(
          size.x * 0.9,
          size.y * 0.45,
          size.x,
          size.y * 0.8,
          size.x * 0.8,
          size.y,
        );
        path.lineTo(size.x * 0.2, size.y);
        path.cubicTo(
          0,
          size.y * 0.8,
          size.x * 0.1,
          size.y * 0.45,
          size.x * 0.35,
          size.y * 0.35,
        );
        path.close();
        break;
      case BeakerType.magicBox:
        path.addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.x, size.y),
            const Radius.circular(12),
          ),
        );
        break;
      case BeakerType.hexagon:
        // Tall Flat-Topped Hexagonal Flask
        final double h = size.y;
        final double w = size.x;
        final double nx = w * 0.3; // neck x offset (40% width overall)
        final double wx = w; // max width
        final double bx = w * 0.2; // base x offset (60% width overall)

        path.moveTo(nx, 0); // Top left
        path.lineTo(w - nx, 0); // Top right
        path.lineTo(w - nx, h * 0.1); // Neck right down
        path.lineTo(wx, h * 0.65); // Flare right down to max width
        path.lineTo(w - bx, h); // Taper right down to base
        path.lineTo(bx, h); // Base width
        path.lineTo(0, h * 0.65); // Taper left up to max width
        path.lineTo(nx, h * 0.1); // Flare left up to neck
        path.close();
        break;
      case BeakerType.round:
        double neckW = size.x * 0.35;
        double sphereR = size.x / 2;
        path.moveTo((size.x - neckW) / 2, 0);
        path.lineTo((size.x + neckW) / 2, 0);
        path.lineTo((size.x + neckW) / 2, size.y * 0.35);
        path.arcToPoint(
          Offset((size.x - neckW) / 2, size.y * 0.35),
          radius: Radius.circular(sphereR),
          largeArc: true,
          clockwise: true,
        );
        path.close();
        break;
      case BeakerType.diamond:
        // Faceted Diamond Flask (standing)
        final double h = size.y;
        final double w = size.x;
        final double nx = w * 0.35; // Neck inset (30% width)
        final double bx = w * 0.40; // Base inset (20% width)

        path.moveTo(nx, 0); // Top left
        path.lineTo(w - nx, 0); // Top right
        path.lineTo(w - nx, h * 0.15); // Neck straight down
        path.lineTo(w, h * 0.45); // Flare right out
        path.lineTo(w - bx, h); // Taper down to base right
        path.lineTo(bx, h); // Base flat
        path.lineTo(0, h * 0.45); // Taper up to base left
        path.lineTo(nx, h * 0.15); // Flare in to neck
        path.close();
        break;
      case BeakerType.star:
        // Stylized 4-Point Mystic Vessel
        final double h = size.y;
        final double w = size.x;
        final double cx = w / 2;

        final double neckW = w * 0.25;
        final double shoulderW = w * 0.95;
        final double waistW = w * 0.40;
        final double baseW = w * 0.85;

        final double neckY = h * 0.15;
        final double shoulderY = h * 0.40;
        final double waistY = h * 0.60;
        final double baseY = h * 0.95;

        path.moveTo(cx - (neckW / 2), 0); // Top left rim
        path.lineTo(cx + (neckW / 2), 0); // Top right rim
        path.lineTo(cx + (neckW / 2), neckY); // Neck right down
        path.cubicTo(
          cx + (neckW / 2),
          neckY + (shoulderY - neckY) * 0.5, // c1
          cx + (shoulderW / 2),
          shoulderY - (shoulderY - neckY) * 0.5, // c2
          cx + (shoulderW / 2),
          shoulderY, // Right top point
        );
        path.cubicTo(
          cx + (shoulderW / 2),
          shoulderY + (waistY - shoulderY) * 0.5,
          cx + (waistW / 2),
          waistY - (waistY - shoulderY) * 0.5,
          cx + (waistW / 2),
          waistY, // Inner right corner
        );
        path.cubicTo(
          cx + (waistW / 2),
          waistY + (baseY - waistY) * 0.5,
          cx + (baseW / 2),
          baseY - (baseY - waistY) * 0.5,
          cx + (baseW / 2),
          baseY, // Right bottom point
        );
        path.cubicTo(
          cx + (baseW / 2),
          baseY + (h - baseY) * 0.5,
          cx,
          h,
          cx,
          h, // Absolute bottom tip
        );

        // Mirror for left side
        path.cubicTo(
          cx,
          h,
          cx - (baseW / 2),
          baseY + (h - baseY) * 0.5,
          cx - (baseW / 2),
          baseY, // Left bottom point
        );
        path.cubicTo(
          cx - (baseW / 2),
          baseY - (baseY - waistY) * 0.5,
          cx - (waistW / 2),
          waistY + (baseY - waistY) * 0.5,
          cx - (waistW / 2),
          waistY, // Inner left corner
        );
        path.cubicTo(
          cx - (waistW / 2),
          waistY - (waistY - shoulderY) * 0.5,
          cx - (shoulderW / 2),
          shoulderY + (waistY - shoulderY) * 0.5,
          cx - (shoulderW / 2),
          shoulderY, // Left top point
        );
        path.cubicTo(
          cx - (shoulderW / 2),
          shoulderY - (shoulderY - neckY) * 0.5,
          cx - (neckW / 2),
          neckY + (shoulderY - neckY) * 0.5,
          cx - (neckW / 2),
          neckY, // Neck left down
        );
        path.close();
        break;
      case BeakerType.triangle:
        path.moveTo(size.x / 2, 0);
        path.lineTo(size.x, size.y);
        path.lineTo(0, size.y);
        path.close();
        break;
    }
    return path;
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
