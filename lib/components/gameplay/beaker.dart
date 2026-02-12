import 'dart:math';
import 'dart:ui';
import 'package:color_mixing_deductive/components/particles/bubble_particles.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../../color_mixer_game.dart';

enum BeakerType { classic, laboratory, magicBox, hexagon, cylinder, round }

class Beaker extends PositionComponent with HasGameRef<ColorMixerGame> {
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

    // Meltdown Shake
    if (gameRef.currentMode == GameMode.chaosLab &&
        gameRef.chaosStability < 0.4) {
      final chaosFactor = (1.0 - gameRef.chaosStability / 0.4).clamp(0.0, 1.0);
      _shakeLevel = max(_shakeLevel, chaosFactor * 0.5);
    }
  }

  @override
  void render(Canvas canvas) {
    switch (type) {
      case BeakerType.classic:
        _renderClassic3D(canvas);
        break;
      case BeakerType.cylinder:
        _renderCylinder3D(canvas);
        break;
      case BeakerType.laboratory:
        _renderLaboratory3D(canvas);
        break;
      case BeakerType.magicBox:
        _renderMagicBox3D(canvas);
        break;
      case BeakerType.hexagon:
        _renderHexagon3D(canvas);
        break;
      case BeakerType.round:
        _renderRound3D(canvas);
        break;
    }
  }

  void _renderClassic3D(Canvas canvas) {
    // 1. Setup Geometry (Cylinder with elliptical top/bottom)
    // We treat the beaker as a cylinder.
    final double radius = size.x / 2;
    final double centerX = size.x / 2;
    final double topY = 0;
    final double bottomY = size.y;
    final double ellipseHeight = size.x * _perspectiveRatio;

    // 2. Back Glass Wall (Behind Liquid)
    // Draw the full cylinder background
    final Paint backGlassPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    // Draw relative to a "cylinder" shape.
    // Top Ellipse: Rect.fromLTWH(0, 0, size.x, ellipseHeight)
    // Bottom Ellipse: Rect.fromLTWH(0, size.y - ellipseHeight, size.x, ellipseHeight)

    final backPath = Path();
    backPath.moveTo(0, topY + ellipseHeight / 2);
    // Top back arc (from left to right, curving down) -> This matches "bottom half of top ellipse"
    backPath.arcTo(
      Rect.fromLTWH(0, topY, size.x, ellipseHeight),
      pi,
      -pi,
      false,
    );
    backPath.lineTo(size.x, bottomY - ellipseHeight / 2);
    // Bottom back arc (from right to left, curving down) -> "bottom half of bottom ellipse"
    backPath.arcTo(
      Rect.fromLTWH(0, bottomY - ellipseHeight, size.x, ellipseHeight),
      0,
      pi,
      false,
    );
    backPath.close();

    canvas.drawPath(backPath, backGlassPaint);

    // 3. Liquid (Painter's Algorithm)
    if (_activeLevel > 0.01) {
      _renderLiquid3D(canvas, centerX, radius, bottomY, ellipseHeight);
    }

    // 4. Front Glass (Highlights & Rims)
    _renderFrontGlass3D(canvas, centerX, radius, topY, bottomY, ellipseHeight);
  }

  void _renderLiquid3D(
    Canvas canvas,
    double centerX,
    double radius,
    double bottomY,
    double ellipseHeight,
  ) {
    final clampedLevel = _activeLevel.clamp(0.0, 1.0);
    // Liquid Height from bottom
    final liquidHeight = size.y * clampedLevel;
    final liquidSurfaceY = size.y - liquidHeight;

    // Need to adjust liquidTopY to be the CENTER of the surface ellipse
    // If level is 1.0 (full), surface is at topY.
    // If level is 0.0, surface is at bottomY.

    // We need to construct the liquid volume.
    // Volume = Bottom Ellipse (full) to Surface Ellipse (full).
    // But we draw Back Surface -> Volume -> Front Surface.

    final displayColor = isBlindMode ? const Color(0xFF222222) : currentColor;

    // 3.1 Back Liquid Surface (The part "behind" the meniscus if looking from top, or just the top ellipse back half)
    // Actually, if we look from slightly above (perspective), we see the TOP of the liquid.
    // So we see the FULL surface ellipse.
    // But we should draw it in order.
    // Let's draw the "Liquid Column" first (back part), then Surface?

    // Liquid Column Path:
    // Starts at surfaceY, goes down to bottomY.
    final liquidPath = Path();
    liquidPath.moveTo(0, liquidSurfaceY);
    // Bottom arc (full bottom ellipse? No, just the visible front part? Or full if transparent?)
    // If glass is transparent, we see the liquid volume.
    // Let's draw the main body relative to the "Front" view.
    // Actually, standard 3D cylinder liquid:
    // 1. Draw "Surface Ellipse" (top of liquid).
    // 2. Draw "Body" (Rect from surface center to bottom center with curved bottom).

    // Let's refine based on "Painter's Algorithm" in plan:
    // 2. Back Liquid Surface: The back half of the liquid meniscus.
    // 3. Liquid Volume: Main body.
    // 5. Front Liquid Surface: Front half.

    // Liquid Gradient
    final liquidGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        displayColor.withValues(alpha: 0.9),
        displayColor.withValues(alpha: 0.7), // Center is lighter/translucent?
        displayColor.withValues(alpha: 0.9),
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));

    Paint volPaint = Paint()..shader = liquidGradient;
    Paint surfacePaint = Paint()
      ..color = displayColor.withValues(
        alpha: 0.8,
      ); // Slightly different for surface

    // Back of Liquid Surface (The "Inside" look of the meniscus if transparent?)
    // If we look from top, we see the whole ellipse.
    // Let's draw the Liquid Volume (Back/Sides) first.

    Path volumePath = Path();
    volumePath.moveTo(0, liquidSurfaceY);
    // Side down
    volumePath.lineTo(0, bottomY - ellipseHeight / 2);
    // Bottom Curve (Front half of bottom ellipse - actually we see the front of the bottom curve)
    volumePath.arcTo(
      Rect.fromLTWH(0, bottomY - ellipseHeight, size.x, ellipseHeight),
      pi,
      -pi,
      false,
    ); // This is top half? No, logic: 0 is Right, pi is Left.
    // CW: 0 -> pi (Bottom half). CCW: 0 -> -pi (Top half).
    // We want the bottom curve of the cylinder. That is 0 to pi.
    volumePath.lineTo(size.x, liquidSurfaceY);
    // Top Curve (Front half or Back half?)
    // To close the volume "behind" the front glass, we usually just draw the front face for 2D.
    // BUT for 3D effect with transparency:
    // functionality: Draw the "Back" of the liquid cylinder first?

    // SIMPLIFICATION:
    // 1. Draw Surface Ellipse (Full) -> Represents the top level.
    // 2. Draw Body (Rectangle from Equator of Surface to Equator of Bottom, with Bottom Arc).

    // Draw Surface Ellipse
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, liquidSurfaceY),
        width: size.x,
        height: ellipseHeight,
      ),
      surfacePaint,
    );

    // Draw Body
    Path bodyPath = Path();
    bodyPath.moveTo(0, liquidSurfaceY);
    bodyPath.lineTo(0, bottomY - ellipseHeight / 2);
    // Bottom Arc (0 to pi)
    bodyPath.arcTo(
      Rect.fromLTWH(0, bottomY - ellipseHeight, size.x, ellipseHeight),
      pi,
      -pi,
      false, // Left to Right via Bottom
    );
    // Note: arcTo(rect, startAngle, sweepAngle, forceMoveTo)
    // 0 is Right (3 o'clock). pi is Left (9 o'clock).
    // pi to 0 (CCW?) -> Top half.
    // pi to 2pi (CW) -> Bottom half.
    // We want Left (pi) to Right (0) via Bottom. So Start=pi, Sweep=pi? No, Sweep=-pi is Top. Sweep=pi is Bottom?
    // Let's verify: arcTo sweeps clockwise for positive? Memory fuzzy on Flutter Path.arcTo default direction.
    // Usually positive sweep is clockwise.
    // pi + pi = 2pi (0). So yes.

    bodyPath.lineTo(size.x, liquidSurfaceY);
    // Close back to 0, liquidSurfaceY?
    // We need to fill the area between Surface Equator and Bottom Equator.
    bodyPath.lineTo(0, liquidSurfaceY);
    bodyPath.close();

    canvas.drawPath(bodyPath, volPaint);

    // 4. Bubbles (Clipped to Liquid Body)
    // We need a clip path for bubbles.
    // The bubble clip should be the Body + Surface?
    // Or just the Body is enough for now.
    canvas.save();
    canvas.clipPath(bodyPath); // Clip to liquid volume
    _bubbleParticles.forceRender(canvas); // Render particles manually
    canvas.restore();

    // Draw Surface Ring (Meniscus)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, liquidSurfaceY),
        width: size.x,
        height: ellipseHeight,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _renderFrontGlass3D(
    Canvas canvas,
    double centerX,
    double radius,
    double topY,
    double bottomY,
    double ellipseHeight,
  ) {
    // Light reflections on the glass tube
    // Vertical gradient highlights
    final highlightPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.2),
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.3), // Stronger specular
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.1, 0.2, 0.85, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), highlightPaint);

    // Rims (Top and Bottom)
    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Top Rim
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, topY + ellipseHeight / 2),
        width: size.x,
        height: ellipseHeight,
      ),
      rimPaint,
    );

    // Bottom Rim
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, bottomY - ellipseHeight / 2),
        width: size.x,
        height: ellipseHeight,
      ),
      rimPaint,
    );
  }

  void _renderCylinder3D(Canvas canvas) {
    _renderClassic3D(canvas);
  }

  void _renderLaboratory3D(Canvas canvas) {
    final double neckWidth = size.x * 0.4;
    final double neckHeight = size.y * 0.35;
    final double centerX = size.x / 2;
    final double bottomY = size.y;
    final double ellipseHeight = size.x * _perspectiveRatio;
    final double neckEllipseHeight = neckWidth * _perspectiveRatio;

    // 1. Back Glass
    final Paint backGlassPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    canvas.drawPath(_getBeakerPath(size), backGlassPaint);

    // 2. Liquid
    if (_activeLevel > 0.01) {
      final clampedLevel = _activeLevel.clamp(0.0, 1.0);
      final liquidH = size.y * clampedLevel;
      final surfaceY = size.y - liquidH;

      double currentWidth;
      if (surfaceY > neckHeight) {
        final p = (surfaceY - neckHeight) / (bottomY - neckHeight);
        currentWidth = lerpDouble(neckWidth, size.x, p)!;
      } else {
        currentWidth = neckWidth;
      }
      final currentEllipseH = currentWidth * _perspectiveRatio;

      final displayColor = isBlindMode ? const Color(0xFF222222) : currentColor;
      final liquidGradient = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          displayColor.withValues(alpha: 0.9),
          displayColor.withValues(alpha: 0.7),
          displayColor.withValues(alpha: 0.9),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));

      final volPaint = Paint()..shader = liquidGradient;
      final surfacePaint = Paint()..color = displayColor.withValues(alpha: 0.8);

      final Path filledPath = Path();
      filledPath.moveTo(centerX - currentWidth / 2, surfaceY);
      if (surfaceY < neckHeight) {
        filledPath.lineTo(centerX - neckWidth / 2, neckHeight);
      }
      filledPath.lineTo(0, bottomY - ellipseHeight / 2);
      filledPath.arcTo(
        Rect.fromLTWH(0, bottomY - ellipseHeight, size.x, ellipseHeight),
        pi,
        -pi,
        false,
      );
      if (surfaceY < neckHeight) {
        filledPath.lineTo(centerX + neckWidth / 2, neckHeight);
      }
      filledPath.lineTo(centerX + currentWidth / 2, surfaceY);
      filledPath.close();

      canvas.drawPath(filledPath, volPaint);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centerX, surfaceY),
          width: currentWidth,
          height: currentEllipseH,
        ),
        surfacePaint,
      );

      // Blind Mode Symbols
      if (isBlindMode && _activeLevel > 0.1) {
        _drawBlindModeSymbols(canvas, size, surfaceY);
      }

      canvas.save();
      canvas.clipPath(filledPath);
      _bubbleParticles.forceRender(canvas);
      canvas.restore();

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centerX, surfaceY),
          width: currentWidth,
          height: currentEllipseH,
        ),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // 3. Front Rims / Details
    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, 0),
        width: neckWidth,
        height: neckEllipseHeight,
      ),
      rimPaint,
    );

    _drawHighlights(canvas);
  }

  void _renderMagicBox3D(Canvas canvas) {
    final double padding = 8.0;
    final Rect frontRect = Rect.fromLTWH(0, 0, size.x, size.y);

    // 1. Back Glass
    canvas.drawRRect(
      RRect.fromRectAndRadius(frontRect, const Radius.circular(12)),
      Paint()..color = Colors.white.withValues(alpha: 0.05),
    );

    // 2. Liquid
    if (_activeLevel > 0.01) {
      final clampedLevel = _activeLevel.clamp(0.0, 1.0);
      final liquidH = (size.y - padding * 2) * clampedLevel;
      final surfaceY = size.y - padding - liquidH;
      final displayColor = isBlindMode ? const Color(0xFF222222) : currentColor;

      final Rect liquidRect = Rect.fromLTRB(
        padding,
        surfaceY,
        size.x - padding,
        size.y - padding,
      );
      final liquidPaint = Paint()..color = displayColor.withValues(alpha: 0.8);

      canvas.drawRRect(
        RRect.fromRectAndRadius(liquidRect, const Radius.circular(4)),
        liquidPaint,
      );

      // Blind Mode Symbols
      if (isBlindMode && _activeLevel > 0.1) {
        _drawBlindModeSymbols(canvas, size, surfaceY);
      }

      canvas.save();
      canvas.clipRRect(
        RRect.fromRectAndRadius(liquidRect, const Radius.circular(4)),
      );
      _bubbleParticles.forceRender(canvas);
      canvas.restore();

      canvas.drawLine(
        Offset(padding, surfaceY),
        Offset(size.x - padding, surfaceY),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.4)
          ..strokeWidth = 2,
      );
    }

    // 3. Front
    canvas.drawRRect(
      RRect.fromRectAndRadius(frontRect, const Radius.circular(12)),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    _drawHighlights(canvas);
  }

  void _renderHexagon3D(Canvas canvas) {
    // 1. Back
    canvas.drawPath(
      _getBeakerPath(size),
      Paint()..color = Colors.white.withValues(alpha: 0.05),
    );

    // 2. Liquid
    if (_activeLevel > 0.01) {
      final clampedLevel = _activeLevel.clamp(0.0, 1.0);
      final surfaceY = size.y * (1 - clampedLevel);
      final displayColor = isBlindMode ? const Color(0xFF222222) : currentColor;

      final Path liquidPath = Path();
      liquidPath.moveTo(size.x * 0.1, surfaceY);
      liquidPath.lineTo(0, size.y * 0.75);
      liquidPath.lineTo(size.x * 0.5, size.y);
      liquidPath.lineTo(size.x, size.y * 0.75);
      liquidPath.lineTo(size.x * 0.9, surfaceY);
      liquidPath.close();

      canvas.drawPath(
        liquidPath,
        Paint()..color = displayColor.withValues(alpha: 0.8),
      );

      // Blind Mode Symbols
      if (isBlindMode && _activeLevel > 0.1) {
        _drawBlindModeSymbols(canvas, size, surfaceY);
      }

      canvas.save();
      canvas.clipPath(liquidPath);
      _bubbleParticles.forceRender(canvas);
      canvas.restore();
    }

    // 3. Front
    canvas.drawPath(
      _getBeakerPath(size),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    _drawHighlights(canvas);
  }

  void _renderRound3D(Canvas canvas) {
    final neckWidth = size.x * 0.35;
    final neckHeight = size.y * 0.35;
    final centerX = size.x / 2;
    final sphereCenterY = size.y - (size.x / 2);
    final sphereRadius = size.x / 2;

    // 1. Back
    canvas.drawPath(
      _getBeakerPath(size),
      Paint()..color = Colors.white.withValues(alpha: 0.05),
    );

    // 2. Liquid
    if (_activeLevel > 0.01) {
      final clampedLevel = _activeLevel.clamp(0.0, 1.0);
      final liquidH = size.y * clampedLevel;
      final surfaceY = size.y - liquidH;
      final displayColor = isBlindMode ? const Color(0xFF222222) : currentColor;

      final Path liquidBody = Path();
      liquidBody.addPath(_getBeakerPath(size), Offset.zero);

      canvas.save();
      canvas.clipPath(liquidBody);
      canvas.drawRect(
        Rect.fromLTWH(0, surfaceY, size.x, size.y),
        Paint()..color = displayColor.withValues(alpha: 0.8),
      );

      // Blind Mode Symbols
      if (isBlindMode && _activeLevel > 0.1) {
        _drawBlindModeSymbols(canvas, size, surfaceY);
      }

      _bubbleParticles.forceRender(canvas);
      canvas.restore();

      // Surface Ellipse
      double currentW = neckWidth;
      if (surfaceY > neckHeight) {
        final dy = (surfaceY - sphereCenterY).abs();
        currentW = 2 * sqrt(max(0, sphereRadius * sphereRadius - dy * dy));
      }
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centerX, surfaceY),
          width: currentW,
          height: currentW * _perspectiveRatio,
        ),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // 3. Front
    canvas.drawPath(
      _getBeakerPath(size),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    _drawHighlights(canvas);
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
        // Pseudo-3D Cylinder Silhouette
        final double ellipseHeight = size.x * _perspectiveRatio;

        path.moveTo(0, ellipseHeight / 2); // Start at top-left of cylinder body

        // Left Side
        path.lineTo(0, size.y - ellipseHeight / 2);

        // Bottom Curve
        path.arcTo(
          Rect.fromLTWH(0, size.y - ellipseHeight, size.x, ellipseHeight),
          pi,
          -pi,
          false,
        );

        // Right Side
        path.lineTo(size.x, ellipseHeight / 2);

        // Top Curve (Back Rim)
        path.arcTo(Rect.fromLTWH(0, 0, size.x, ellipseHeight), 0, -pi, false);

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
