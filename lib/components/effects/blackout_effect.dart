import 'dart:ui';
import 'package:flame/components.dart';
import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:flutter/material.dart';

class BlackoutEffect extends PositionComponent with HasGameRef<ColorMixerGame> {
  @override
  int get priority => 100; // Render on top of almost everything

  @override
  Future<void> onLoad() async {
    super.onLoad();
    size = gameRef.size;
  }

  @override
  void render(Canvas canvas) {
    // Create a path that covers the whole screen but cuts out the beaker area
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.x, size.y));

    // Define the "hole" area around the beaker
    // We add some padding/glow area
    final beakerPos = gameRef.beaker.position;
    final beakerSize = gameRef.beaker.size;
    final holeRect = Rect.fromCenter(
      center: Offset(beakerPos.x, beakerPos.y),
      width: beakerSize.x * 1.5,
      height: beakerSize.y * 1.5,
    );

    // Subtract the hole from the main path
    final holePath = Path()..addOval(holeRect);
    final overlayPath = Path.combine(PathOperation.difference, path, holePath);

    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;
    // ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10); // Soft edges

    canvas.drawPath(overlayPath, paint);

    // Draw a radial gradient "glow" at the edge of the hole for smoothness?
    // Or just let the mask filter do it if performant.
    // Manual gradient ring around the hole:
    final gradient =
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

    final gradientPaint = Paint()
      ..shader = gradient
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
