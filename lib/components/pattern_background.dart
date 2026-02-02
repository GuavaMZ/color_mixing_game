import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class PatternBackground extends Component with HasGameRef {
  Sprite? _starSprite;

  // Confetti/Star configuration
  final List<_StarParticle> _stars = [];
  // final double _speed = 20.0;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // try {
    //   // Load the star asset as requested
    //   _starSprite = await Sprite.load('star.png');

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
    if (_starSprite == null) return;

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
    if (_starSprite == null) return;

    for (var star in _stars) {
      _starSprite!.render(
        canvas,
        position: Vector2(star.x, star.y),
        size: Vector2(24 * star.scale, 24 * star.scale),
        anchor: Anchor.center,
        overridePaint: Paint()
          ..color = Colors.white.withOpacity(0.15), // Subtle
      );
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
