import 'dart:math';
import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:color_mixing_deductive/helpers/audio_manager.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class AcidBlob extends PositionComponent
    with TapCallbacks, HasGameRef<ColorMixerGame> {
  double opacity = 0.9;
  final Paint _paint = Paint();
  final Random _random = Random();
  final Path _blobPath = Path();

  AcidBlob({required Vector2 position, required double size}) {
    this.position = position;
    this.size = Vector2(size, size);
    anchor = Anchor.center;
  }

  @override
  void onLoad() {
    super.onLoad();
    _paint.color = Colors.greenAccent.withValues(alpha: opacity);
    // Random rotation for visual variety
    angle = _random.nextDouble() * 2 * pi;

    // Generate path once
    final radius = size.x / 2;
    _blobPath.moveTo(radius + radius * 0.8, radius); // Start point
    for (double i = 0; i < 2 * pi; i += pi / 8) {
      // Noise factor
      double offset = (0.8 + _random.nextDouble() * 0.4) * radius;
      _blobPath.lineTo(radius + offset * cos(i), radius + offset * sin(i));
    }
    _blobPath.close();
  }

  @override
  void render(Canvas canvas) {
    _paint.color = Colors.greenAccent.withValues(alpha: opacity);
    canvas.drawPath(_blobPath, _paint);

    // Simple bubbling details
    final bubblePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3 * opacity);
    canvas.drawCircle(
      Offset(size.x * 0.6, size.y * 0.4),
      size.x * 0.15,
      bubblePaint,
    );
    canvas.drawCircle(
      Offset(size.x * 0.3, size.y * 0.6),
      size.x * 0.1,
      bubblePaint,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    // "Wipe" effect - reduce opacity
    opacity -= 0.3;
    scale.scale(0.9);

    // AudioManager().playSquish(); // No squish sound, using drop for feedback?
    // Using existing drop or similar low impact sound
    // AudioManager().playDrop();

    if (opacity <= 0.1) {
      removeFromParent();
    }
  }
}

class AcidSplatter extends Component with HasGameRef<ColorMixerGame> {
  final Random _random = Random();

  @override
  Future<void> onLoad() async {
    super.onLoad();
    AudioManager().playSteam(); // Reuse steam sound for hiss
    _spawnBlobs();
  }

  void _spawnBlobs() {
    // Spawn 5-8 random blobs
    int count = 5 + _random.nextInt(4);
    final gameSize = gameRef.size;

    for (int i = 0; i < count; i++) {
      double x = gameSize.x * 0.1 + _random.nextDouble() * gameSize.x * 0.8;
      double y = gameSize.y * 0.2 + _random.nextDouble() * gameSize.y * 0.5;
      double blobSize = 80 + _random.nextDouble() * 70;

      add(AcidBlob(position: Vector2(x, y), size: blobSize));
    }
  }
}
