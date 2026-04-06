import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:color_mixing_deductive/core/lab_catalog.dart';
import '../../color_mixer_game.dart';

class PatternBackground extends Component with HasGameReference<ColorMixerGame> {
  Sprite? _starSprite;
  LabItem? config;

  // Confetti/Star configuration
  final List<_StarParticle> _stars = [];
  // final double _speed = 20.0;

  final Paint _gridPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  final Paint _glowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  final Paint _tickPaint = Paint()..strokeWidth = 1;

  final Paint _crystalPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  final Paint _crystalFillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _scientificPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  Shader? _glowShader;
  LabItem? _lastConfig;
  Vector2? _lastSize;

  PatternBackground({this.config});

  void updateConfig(LabItem? newConfig) {
    config = newConfig;
  }

  @override
  void renderTree(Canvas canvas) {
    if (!game.isActivelyPlayingLevel) return;
    super.renderTree(canvas);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // try {
    //   // Load the star asset as requested
    //   _starSprite = await Sprite.load('star.png');
    //
    //   // Initialize stars
    //   final size = gameRef.size;
    //   for (int i = 0; i < 30; i++) {
    //     _stars.add(
    //       _StarParticle(
    //         x: (size.x * (i / 30)) % size.x,
    //         y: (i * 50.0) % size.y,
    //         scale: 0.5 + (i % 3) * 0.2,
    //         rotationSpeed: (i % 2 == 0 ? 1 : -1) * (0.5 + (i % 5) * 0.1),
    //       ),
    //     );
    //   }
    // } catch (e) {
    //   debugPrint("Error loading star.png: $e");
    // }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_starSprite == null && config == null) return;

    // User requested no animation for the background
    // We comment out the movement logic

    // final size = gameRef.size;
    // for (var star in _stars) {
    //   star.y += _speed * dt;
    //   star.rotation += star.rotationSpeed * dt;
    //   if (star.y > size.y + 20) {
    //     star.y = -20;
    //     star.x = (star.x + 50) % size.x;
    //   }
    // }
  }

  void _updateCacheIfNeeded() {
    if (_lastConfig?.id == config?.id && _lastSize == game.size) return;
    _lastConfig = config;
    _lastSize = game.size.clone();

    final baseColor = config?.placeholderColor ?? Colors.cyan;

    // Use a radial gradient for glow instead of MaskFilter.blur
    _glowShader = RadialGradient(
      colors: [
        baseColor.withValues(alpha: 0.1),
        baseColor.withValues(alpha: 0),
      ],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: 10));
    _glowPaint.shader = _glowShader;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _updateCacheIfNeeded();

    // Render Pattern based on Config
    if (config != null) {
      if (config!.id.contains('cyber') || config!.id.contains('steel')) {
        _renderGridPattern(canvas);
      } else if (config!.id.contains('crystal')) {
        _renderCrystalPattern(canvas);
      }
    }

    if (_starSprite == null) return;

    for (var star in _stars) {
      _starSprite!.render(
        canvas,
        position: Vector2(star.x, star.y),
        size: Vector2(24 * star.scale, 24 * star.scale),
        anchor: Anchor.center,
        overridePaint: Paint()
          ..color = Colors.white.withValues(alpha: 0.15), // Subtle
      );
    }
  }

  void _renderGridPattern(Canvas canvas) {
    final size = game.size;
    final baseColor = config?.placeholderColor ?? Colors.cyan;

    _gridPaint.color = baseColor.withValues(alpha: 0.1);

    const gridSize = 60.0;

    // Vertical lines
    for (double x = 0; x <= size.x; x += gridSize) {
      canvas.save();
      canvas.translate(x, size.y / 2);
      canvas.scale(1, size.y / 10.0);
      canvas.drawCircle(Offset.zero, 10, _glowPaint);
      canvas.restore();

      canvas.drawLine(Offset(x, 0), Offset(x, size.y), _gridPaint);

      // Measurement Ticks
      _drawTicks(canvas, Offset(x, 0), true, size.y);
    }

    // Horizontal lines
    for (double y = 0; y <= size.y; y += gridSize) {
      canvas.save();
      canvas.translate(size.x / 2, y);
      canvas.scale(size.x / 10.0, 1);
      canvas.drawCircle(Offset.zero, 10, _glowPaint);
      canvas.restore();

      canvas.drawLine(Offset(0, y), Offset(size.x, y), _gridPaint);

      // Measurement Ticks
      _drawTicks(canvas, Offset(0, y), false, size.x);
    }

    // Coordinates/Labels at intersections (some of them)
    _drawCoordinates(canvas, size, gridSize);
  }

  void _drawTicks(Canvas canvas, Offset start, bool isVertical, double length) {
    _tickPaint.color = (config?.placeholderColor ?? Colors.cyan).withValues(
      alpha: 0.2,
    );

    const tickSpacing = 12.0;
    const tickLength = 4.0;

    for (double i = 0; i < length; i += tickSpacing) {
      if (isVertical) {
        canvas.drawLine(
          Offset(start.dx - tickLength / 2, i),
          Offset(start.dx + tickLength / 2, i),
          _tickPaint,
        );
      } else {
        canvas.drawLine(
          Offset(i, start.dy - tickLength / 2),
          Offset(i, start.dy + tickLength / 2),
          _tickPaint,
        );
      }
    }
  }

  void _drawCoordinates(Canvas canvas, Vector2 size, double gridSize) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final textColor = (config?.placeholderColor ?? Colors.cyan).withValues(
      alpha: 0.3,
    );

    for (double x = gridSize; x < size.x; x += gridSize * 3) {
      for (double y = gridSize; y < size.y; y += gridSize * 3) {
        final coordText =
            "X:${(x / 10).toStringAsFixed(0)} Y:${(y / 10).toStringAsFixed(0)}";
        textPainter.text = TextSpan(
          text: coordText,
          style: TextStyle(
            color: textColor,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x + 4, y + 4));
      }
    }
  }

  void _renderCrystalPattern(Canvas canvas) {
    final size = game.size;
    final baseColor = config?.placeholderColor ?? Colors.white;

    _crystalPaint.color = baseColor.withValues(alpha: 0.1);
    _crystalFillPaint.color = baseColor.withValues(alpha: 0.03);

    const gridSize = 100.0;

    for (double x = 0; x <= size.x; x += gridSize) {
      for (double y = 0; y <= size.y; y += gridSize) {
        if ((x / gridSize + y / gridSize) % 2 == 0) continue;

        final rect = Rect.fromLTWH(
          x + 10,
          y + 10,
          gridSize - 20,
          gridSize - 20,
        );

        // Layered crystal effect
        canvas.drawRect(rect, _crystalFillPaint);
        canvas.drawRect(rect, _crystalPaint);

        // Inner detail lines
        canvas.drawLine(rect.topLeft, rect.bottomRight, _crystalPaint);
        canvas.drawLine(rect.topRight, rect.bottomLeft, _crystalPaint);
      }
    }

    // Add scientific crosshairs
    _drawScientificOverlays(canvas, size);
  }

  void _drawScientificOverlays(Canvas canvas, Vector2 size) {
    _scientificPaint.color = (config?.placeholderColor ?? Colors.white)
        .withValues(alpha: 0.15);

    final centerX = size.x / 2;
    final centerY = size.y / 2;

    // Central Crosshair
    canvas.drawCircle(Offset(centerX, centerY), 40, _scientificPaint);
    canvas.drawLine(
      Offset(centerX - 60, centerY),
      Offset(centerX - 20, centerY),
      _scientificPaint,
    );
    canvas.drawLine(
      Offset(centerX + 20, centerY),
      Offset(centerX + 60, centerY),
      _scientificPaint,
    );
    canvas.drawLine(
      Offset(centerX, centerY - 60),
      Offset(centerX, centerY - 20),
      _scientificPaint,
    );
    canvas.drawLine(
      Offset(centerX, centerY + 20),
      Offset(centerX, centerY + 60),
      _scientificPaint,
    );
  }
}

class _StarParticle {
  double x;
  double y;
  double scale;
  double rotation = 0.0;
  double rotationSpeed;

  _StarParticle({
    required this.x,
    required this.y,
    required this.scale,
    required this.rotationSpeed,
  });
}
