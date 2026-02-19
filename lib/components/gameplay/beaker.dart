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

class Beaker extends PositionComponent with HasGameRef<ColorMixerGame> {
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

  final Paint _specularHighlightPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.6)
    ..style = PaintingStyle.fill;

  Shader? _liquidGradientShader;
  Shader? _glassGradientShader;
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
    if (gameRef.currentMode == GameMode.chaosLab &&
        gameRef.chaosStability < 0.4) {
      final chaosFactor = (1.0 - gameRef.chaosStability / 0.4).clamp(0.0, 1.0);
      _shakeLevel = max(_shakeLevel, chaosFactor * 0.5);
    }

    _updatePaintsAndShaders();
  }

  void _updatePaintsAndShaders() {
    final displayColor = isBlindMode ? const Color(0xFF222222) : currentColor;

    // Update Liquid Surface Paint
    _liquidSurfacePaint.color = displayColor.withValues(alpha: 0.85);

    // Update Liquid Gradient Shader if needed
    if (_lastGradientColor != displayColor || _lastShaderSize != size) {
      // Liquid gradient - more vibrant with depth
      _liquidGradientShader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          displayColor.withValues(alpha: 0.95),
          displayColor.withValues(alpha: 0.75),
          displayColor.withValues(alpha: 0.85),
          displayColor.withValues(alpha: 0.95),
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));
      _liquidVolPaint.shader = _liquidGradientShader;

      // Back liquid layer for depth
      _liquidBackPaint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          displayColor.withValues(alpha: 0.6),
          displayColor.withValues(alpha: 0.8),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));

      // Glass gradient shader for premium look
      _glassGradientShader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.2),
          Colors.white.withValues(alpha: 0.05),
          Colors.white.withValues(alpha: 0.08),
          Colors.white.withValues(alpha: 0.15),
        ],
        stops: const [0.0, 0.4, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));
      _glassFrontPaint.shader = _glassGradientShader;

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
    _renderFrontGlass(canvas);
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
        final midY = size.y * 0.45;
        if (surfaceY >= midY) {
          final t = (surfaceY - midY) / (size.y - midY);
          surfaceWidth = size.x * (1 - t);
        } else {
          final t = surfaceY / midY;
          surfaceWidth = size.x * t;
        }
        ellipseH = 0; // Flat line for diamond
        break;
      case BeakerType.hexagon:
        // Hexagon width varies significantly
        if (surfaceY <= size.y * 0.25) {
          surfaceWidth = size.x * (0.5 + (surfaceY / (size.y * 0.25)) * 0.5);
        } else if (surfaceY <= size.y * 0.75) {
          surfaceWidth = size.x;
        } else {
          final t = (surfaceY - size.y * 0.75) / (size.y * 0.25);
          surfaceWidth = size.x * (1.0 - t * 0.5);
        }
        ellipseH = 0;
        break;
      case BeakerType.star:
        surfaceWidth = size.x; // Star is complex, use full width clipping
        ellipseH = 0;
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
      canvas.drawOval(rect, _liquidSurfacePaint);
      canvas.drawOval(rect, _liquidMeniscusPaint);
    } else {
      final halfW = surfaceWidth / 2;
      canvas.drawLine(
        Offset(size.x / 2 - halfW, surfaceY),
        Offset(size.x / 2 + halfW, surfaceY),
        _liquidMeniscusPaint,
      );
    }
  }

  void _renderFrontGlass(Canvas canvas) {
    final Path beakerPath = _getBeakerPathCached();
    canvas.drawPath(beakerPath, _glassFrontPaint);
    canvas.drawPath(beakerPath, _rimPaint);

    // Highlights
    _renderHighlights(canvas);
  }

  void _renderHighlights(Canvas canvas) {
    final centerX = size.x / 2;

    // Default vertical highlight
    final highlightRect = Rect.fromLTWH(
      size.x * 0.15,
      size.y * 0.1,
      size.x * 0.2,
      size.y * 0.7,
    );
    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.3),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(highlightRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(highlightRect, const Radius.circular(10)),
      highlightPaint,
    );

    // Type specific highlights
    if (type == BeakerType.laboratory || type == BeakerType.round) {
      canvas.drawCircle(
        Offset(centerX + size.x * 0.2, size.y * 0.7),
        size.x * 0.1,
        _specularHighlightPaint,
      );
    }
  }

  void _drawBlindModeSymbols(Canvas canvas, Vector2 size, double liquidTop) {
    final r = currentColor.red;
    final g = currentColor.green;
    final b = currentColor.blue;
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
        path.moveTo(size.x * 0.5, 0);
        path.lineTo(size.x, size.y * 0.25);
        path.lineTo(size.x, size.y * 0.75);
        path.lineTo(size.x * 0.5, size.y);
        path.lineTo(0, size.y * 0.75);
        path.lineTo(0, size.y * 0.25);
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
        path.moveTo(size.x / 2, 0);
        path.lineTo(size.x, size.y * 0.45);
        path.lineTo(size.x / 2, size.y);
        path.lineTo(0, size.y * 0.45);
        path.close();
        break;
      case BeakerType.star:
        final double cx = size.x / 2;
        final double cy = size.y / 2;
        final double outerR = size.x / 2;
        final double innerR = outerR * 0.42;
        const int points = 5;
        for (int i = 0; i < points * 2; i++) {
          final double angle = (pi / points) * i - pi / 2;
          final double r = (i % 2 == 0) ? outerR : innerR;
          path.lineTo(cx + r * cos(angle), cy + r * sin(angle));
        }
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
