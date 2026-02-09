import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../helpers/audio_manager.dart';
import '../color_mixer_game.dart';

/// Glitch effect overlay for Chaos Lab Mode
class GlitchEffect extends Component with HasGameRef<ColorMixerGame> {
  final Random _random = Random();
  double _glitchTimer = 0;
  double _nextGlitchTime = 2.0;
  bool _isGlitching = false;
  double _glitchDuration = 0;
  double _glitchOffset = 0;
  int _scanLineY = 0;

  @override
  void update(double dt) {
    super.update(dt);

    _glitchTimer += dt;

    if (_isGlitching) {
      _glitchDuration -= dt;
      if (_glitchDuration <= 0) {
        _isGlitching = false;
        _nextGlitchTime = 1.5 + _random.nextDouble() * 3.0;
        _glitchTimer = 0;
      } else {
        // Update glitch parameters
        _glitchOffset = (_random.nextDouble() - 0.5) * 20;
        _scanLineY = _random.nextInt(800);
      }
    } else if (_glitchTimer >= _nextGlitchTime) {
      _isGlitching = true;
      AudioManager().playGlitch();
      _glitchDuration = 0.1 + _random.nextDouble() * 0.2;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (!_isGlitching || parent == null) return;

    final gameSize = gameRef.size;

    // RGB channel separation effect
    final rgbPaint = Paint()..blendMode = BlendMode.screen;

    // Red channel offset
    rgbPaint.color = Colors.red.withValues(alpha: 0.15);
    canvas.drawRect(
      Rect.fromLTWH(_glitchOffset, 0, gameSize.x, gameSize.y),
      rgbPaint,
    );

    // Cyan channel offset (opposite direction)
    rgbPaint.color = Colors.cyan.withValues(alpha: 0.15);
    canvas.drawRect(
      Rect.fromLTWH(-_glitchOffset, 0, gameSize.x, gameSize.y),
      rgbPaint,
    );

    // Scan lines
    final scanLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 2;

    for (int i = 0; i < 5; i++) {
      final y = (_scanLineY + i * 50) % gameSize.y.toInt();
      canvas.drawLine(
        Offset(0, y.toDouble()),
        Offset(gameSize.x, y.toDouble()),
        scanLinePaint,
      );
    }

    // Random horizontal displacement bars
    if (_random.nextDouble() < 0.3) {
      final barHeight = 20.0 + _random.nextDouble() * 40;
      final barY = _random.nextDouble() * gameSize.y;

      final displacementPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.05);

      canvas.drawRect(
        Rect.fromLTWH(0, barY, gameSize.x, barHeight),
        displacementPaint,
      );
    }
  }
}
