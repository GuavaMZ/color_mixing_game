import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../helpers/audio_manager.dart';
import '../color_mixer_game.dart';

/// Emergency alarm lights that flicker in the corners during Chaos Lab Mode
class EmergencyLights extends Component with HasGameRef<ColorMixerGame> {
  final Random _random = Random();
  double _flickerTimer = 0;
  double _nextFlickerTime = 0.2;
  double _opacity = 0.8;
  bool _isOn = true;

  final Paint _lightPaint = Paint()
    ..color = Colors.red.withValues(alpha: 0.3)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);

  @override
  void onMount() {
    super.onMount();
    AudioManager().playAlarm();
  }

  @override
  void update(double dt) {
    super.update(dt);

    _flickerTimer += dt;

    if (_flickerTimer >= _nextFlickerTime) {
      _isOn = !_isOn;
      _opacity = _isOn ? (0.6 + _random.nextDouble() * 0.4) : 0.1;
      _nextFlickerTime = _random.nextDouble() * 0.3 + 0.1;
      _flickerTimer = 0;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (parent == null) return;

    final gameSize = gameRef.size;
    final lightRadius = 120.0;

    _lightPaint.color = Colors.red.withValues(alpha: _opacity * 0.3);

    // Top-left corner light
    canvas.drawCircle(
      Offset(lightRadius / 2, lightRadius / 2),
      lightRadius,
      _lightPaint,
    );

    // Top-right corner light
    canvas.drawCircle(
      Offset(gameSize.x - lightRadius / 2, lightRadius / 2),
      lightRadius,
      _lightPaint,
    );

    // Bottom-left corner light
    canvas.drawCircle(
      Offset(lightRadius / 2, gameSize.y - lightRadius / 2),
      lightRadius,
      _lightPaint,
    );

    // Bottom-right corner light
    canvas.drawCircle(
      Offset(gameSize.x - lightRadius / 2, gameSize.y - lightRadius / 2),
      lightRadius,
      _lightPaint,
    );
  }
}
