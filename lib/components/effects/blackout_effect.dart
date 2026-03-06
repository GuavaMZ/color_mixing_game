import 'package:flame/components.dart';
import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:flutter/material.dart';

class BlackoutEffect extends PositionComponent
    with HasGameReference<ColorMixerGame> {
  Path? _cachedOverlayPath;
  Shader? _cachedGradientShader;
  Vector2? _lastBeakerPos;
  Vector2? _lastSize;

  @override
  int get priority => 100; // Render on top of almost everything

  @override
  Future<void> onLoad() async {
    super.onLoad();
    size = game.size;
  }

  @override
  void render(Canvas canvas) {
    _updateCacheIfNeeded();

    if (_cachedOverlayPath != null) {
      final paint = Paint()
        ..color = Colors.black.withValues(alpha: 0.95)
        ..style = PaintingStyle.fill;
      canvas.drawPath(_cachedOverlayPath!, paint);
    }

    if (_cachedGradientShader != null) {
      final beakerPos = game.beaker.position;
      final beakerSize = game.beaker.size;

      final gradientPaint = Paint()
        ..shader = _cachedGradientShader
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(beakerPos.x, beakerPos.y),
          width: beakerSize.x * 2.0,
          height: beakerSize.y * 2.0,
        ),
        gradientPaint,
      );
    }
  }

  void _updateCacheIfNeeded() {
    final beakerPos = game.beaker.position;
    final beakerSize = game.beaker.size;

    if (_cachedOverlayPath != null &&
        _lastBeakerPos == beakerPos &&
        _lastSize == size) {
      return;
    }

    _lastBeakerPos = beakerPos.clone();
    _lastSize = size.clone();

    // Create a path that covers the whole screen but cuts out the beaker area
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.x, size.y));

    // Define the "hole" area around the beaker
    final holeRect = Rect.fromCenter(
      center: Offset(beakerPos.x, beakerPos.y),
      width: beakerSize.x * 1.5,
      height: beakerSize.y * 1.5,
    );

    // Subtract the hole from the main path
    final holePath = Path()..addOval(holeRect);
    _cachedOverlayPath = Path.combine(PathOperation.difference, path, holePath);

    // Update gradient shader
    _cachedGradientShader =
        RadialGradient(
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.95)],
          stops: const [0.5, 1.0],
        ).createShader(
          Rect.fromCenter(
            center: Offset(beakerPos.x, beakerPos.y),
            width: beakerSize.x * 2.0,
            height: beakerSize.y * 2.0,
          ),
        );
  }
}
