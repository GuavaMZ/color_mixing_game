import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../color_mixer_game.dart';

class GravityFluxEffect extends PositionComponent
    with HasGameRef<ColorMixerGame> {
  final Random _random = Random();
  final List<_FluxLine> _lines = [];
  double _timer = 0;

  GravityFluxEffect() : super(priority: 0);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    size = gameRef.beaker.size;
    position = Vector2.zero(); // Will be child of Beaker

    // Initialize some lines
    for (int i = 0; i < 5; i++) {
      _lines.add(_createLine());
    }
  }

  _FluxLine _createLine() {
    return _FluxLine(
      x: _random.nextDouble() * size.x,
      speed: 50 + _random.nextDouble() * 100,
      opacity: 0.1 + _random.nextDouble() * 0.2,
      width: 1 + _random.nextDouble() * 2,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;

    for (var line in _lines) {
      line.y -= line.speed * dt;
      if (line.y < 0) {
        line.y = size.y;
        line.x = _random.nextDouble() * size.x;
      }
    }

    // Occasional energy sparks
    if (_random.nextDouble() < 0.05) {
      // Could add sparks here
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var line in _lines) {
      paint.color = Colors.cyan.withValues(alpha: line.opacity);
      paint.strokeWidth = line.width;

      // Draw a vertical "flux" line segment
      canvas.drawLine(
        Offset(line.x, line.y),
        Offset(line.x, line.y + 40),
        paint,
      );
    }

    // Glow overlay
    final glowPaint = Paint()
      ..color = Colors.cyan.withValues(
        alpha: 0.05 + sin(_timer * 2).abs() * 0.05,
      )
      ..style = PaintingStyle.fill;

    canvas.drawRect(size.toRect(), glowPaint);
  }
}

class _FluxLine {
  double x;
  double y;
  double speed;
  double opacity;
  double width;

  _FluxLine({
    required this.x,
    required this.speed,
    required this.opacity,
    required this.width,
  }) : y = Random().nextDouble() * 300;
}
