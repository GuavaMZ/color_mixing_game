import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../helpers/audio_manager.dart';
import '../helpers/haptic_manager.dart';
import '../helpers/theme_constants.dart';
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

  // New digital artifacts
  final List<Rect> _glitchBlocks = [];
  double _chromaticIntensity = 0;

  @override
  void update(double dt) {
    super.update(dt);

    _glitchTimer += dt;

    if (_isGlitching) {
      _glitchDuration -= dt;
      if (_glitchDuration <= 0) {
        _isGlitching = false;
        _nextGlitchTime =
            1.0 + _random.nextDouble() * 2.5; // More frequent in higher chaos
        _glitchTimer = 0;
        _glitchBlocks.clear();
        _chromaticIntensity = 0;
      } else {
        // Update glitch parameters
        _glitchOffset =
            (_random.nextDouble() - 0.5) * 35; // Increased intensity
        _scanLineY = _random.nextInt(800);

        // Generate random digital blocks
        if (_random.nextDouble() < 0.4) {
          _glitchBlocks.clear();
          for (int i = 0; i < 3; i++) {
            _glitchBlocks.add(
              Rect.fromLTWH(
                _random.nextDouble() * gameRef.size.x,
                _random.nextDouble() * gameRef.size.y,
                50 + _random.nextDouble() * 150,
                10 + _random.nextDouble() * 40,
              ),
            );
          }
        }

        _chromaticIntensity = _random.nextDouble();
      }
    } else if (_glitchTimer >= _nextGlitchTime) {
      _isGlitching = true;
      AudioManager().playGlitch();
      _glitchDuration = 0.15 + _random.nextDouble() * 0.3;

      // Impact haptic if enabled
      HapticManager().light();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (!_isGlitching || parent == null) return;

    final gameSize = gameRef.size;

    // 1. Digital Color Split (Chromatic Aberration)
    final rgbPaint = Paint()..blendMode = BlendMode.screen;

    // Red channel offset (Shift Left)
    rgbPaint.color = Colors.red.withValues(alpha: 0.2 * _chromaticIntensity);
    canvas.drawRect(
      Rect.fromLTWH(_glitchOffset, 0, gameSize.x, gameSize.y),
      rgbPaint,
    );

    // Cyan channel offset (Shift Right)
    rgbPaint.color = Colors.cyan.withValues(alpha: 0.2 * _chromaticIntensity);
    canvas.drawRect(
      Rect.fromLTWH(-_glitchOffset, 0, gameSize.x, gameSize.y),
      rgbPaint,
    );

    // 2. Fragmented Scan Lines
    final scanLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1.5;

    for (int i = 0; i < 8; i++) {
      final y = (_scanLineY + i * 40) % gameSize.y.toInt();
      if (_random.nextDouble() < 0.7) {
        canvas.drawLine(
          Offset(0, y.toDouble()),
          Offset(gameSize.x, y.toDouble()),
          scanLinePaint,
        );
      }
    }

    // 3. Digital Failure Blocks (White/Cyan/Magenta blocks)
    final blockPaint = Paint()..style = PaintingStyle.fill;
    for (var block in _glitchBlocks) {
      final palette = [
        Colors.white,
        Colors.cyan,
        AppTheme.neonMagenta,
        Colors.yellow,
      ];
      blockPaint.color = palette[_random.nextInt(palette.length)].withValues(
        alpha: 0.15,
      );
      canvas.drawRect(block, blockPaint);
    }

    // 4. Horizontal Displacement "Shreds"
    if (_random.nextDouble() < 0.5) {
      final shredHeight = 15.0 + _random.nextDouble() * 50;
      final shredY = _random.nextDouble() * gameSize.y;
      final shredOffset = (_random.nextDouble() - 0.5) * 60;

      final shredPaint = Paint()
        ..color = Color(0xFF15192B).withValues(alpha: 0.4);

      // Draw a "copied" strip of background or just a dark displacement bar
      canvas.drawRect(
        Rect.fromLTWH(shredOffset, shredY, gameSize.x, shredHeight),
        shredPaint,
      );
    }

    // 5. Full Screen Tint Flash
    if (_random.nextDouble() < 0.1) {
      canvas.drawColor(Colors.white.withValues(alpha: 0.05), BlendMode.overlay);
    }
  }
}
