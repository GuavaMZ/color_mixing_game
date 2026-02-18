import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:color_mixing_deductive/core/lab_catalog.dart';

class PatternBackground extends Component with HasGameReference {
  Sprite? _starSprite;
  LabItem? config;

  // Confetti/Star configuration
  final List<_StarParticle> _stars = [];
  // final double _speed = 20.0;

  PatternBackground({this.config});

  void updateConfig(LabItem? newConfig) {
    config = newConfig;
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

  @override
  void render(Canvas canvas) {
    super.render(canvas);

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
    final paint = Paint()
      ..color = (config?.placeholderColor ?? Colors.cyan).withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const gridSize = 50.0;

    // Vertical lines
    for (double x = 0; x <= size.x; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), paint);
    }

    // Horizontal lines
    for (double y = 0; y <= size.y; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), paint);
    }
  }

  void _renderCrystalPattern(Canvas canvas) {
    final size = game.size;
    final paint = Paint()
      ..color = (config?.placeholderColor ?? Colors.white).withValues(
        alpha: 0.05,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw random connected lines/triangles for crystal feel
    // For now, simpler geometric pattern
    const gridSize = 80.0;

    for (double x = 0; x <= size.x; x += gridSize) {
      for (double y = 0; y <= size.y; y += gridSize) {
        if ((x / gridSize + y / gridSize) % 2 == 0) continue;

        canvas.drawRect(
          Rect.fromLTWH(x, y, gridSize * 0.8, gridSize * 0.8),
          paint,
        );
      }
    }
  }
}

class _StarParticle {
  double x;
  double y;
  double scale;
  double rotation;
  double rotationSpeed;

  _StarParticle({
    required this.x,
    required this.y,
    required this.scale,
    this.rotation = 0,
    required this.rotationSpeed,
  });
}
