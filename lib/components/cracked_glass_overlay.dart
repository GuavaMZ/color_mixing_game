import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../helpers/audio_manager.dart';
import '../color_mixer_game.dart';

/// Cracked glass overlay for Chaos Lab Mode
class CrackedGlassOverlay extends Component with HasGameRef<ColorMixerGame> {
  final List<List<Offset>> _cracks = [];
  final Random _random = Random();

  @override
  void onMount() {
    super.onMount();
    AudioManager().playCrack();
    _generateCracks();
  }

  void _generateCracks() {
    if (parent == null) return;

    final gameSize = gameRef.size;

    // Create 2-3 impact points
    final impactPoints = [
      Offset(gameSize.x * 0.3, gameSize.y * 0.25),
      Offset(gameSize.x * 0.75, gameSize.y * 0.6),
    ];

    for (var impact in impactPoints) {
      _generateRadialCracks(impact, 8 + _random.nextInt(5));
    }
  }

  void _generateRadialCracks(Offset center, int numCracks) {
    for (int i = 0; i < numCracks; i++) {
      final angle =
          (i / numCracks) * 2 * pi + (_random.nextDouble() - 0.5) * 0.5;
      final length = 80 + _random.nextDouble() * 120;

      final crack = <Offset>[];
      crack.add(center);

      // Generate crack path with some randomness
      var currentPos = center;
      final segments = 5 + _random.nextInt(8);

      for (int j = 0; j < segments; j++) {
        final segmentLength = length / segments;
        final deviation = (_random.nextDouble() - 0.5) * 0.6;
        final segmentAngle = angle + deviation;

        currentPos = Offset(
          currentPos.dx + cos(segmentAngle) * segmentLength,
          currentPos.dy + sin(segmentAngle) * segmentLength,
        );

        crack.add(currentPos);
      }

      _cracks.add(crack);

      // Add some branching cracks
      if (_random.nextDouble() < 0.4 && crack.length > 3) {
        final branchPoint = crack[crack.length ~/ 2];
        final branchAngle = angle + (_random.nextDouble() - 0.5) * 1.5;
        final branchLength = length * 0.4;

        final branch = <Offset>[branchPoint];
        var branchPos = branchPoint;

        for (int k = 0; k < 3; k++) {
          branchPos = Offset(
            branchPos.dx + cos(branchAngle) * (branchLength / 3),
            branchPos.dy + sin(branchAngle) * (branchLength / 3),
          );
          branch.add(branchPos);
        }

        _cracks.add(branch);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final crackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    for (var crack in _cracks) {
      if (crack.length < 2) continue;

      final path = Path();
      path.moveTo(crack[0].dx, crack[0].dy);

      for (int i = 1; i < crack.length; i++) {
        path.lineTo(crack[i].dx, crack[i].dy);
      }

      // Draw glow first
      canvas.drawPath(path, glowPaint);
      // Then main crack
      canvas.drawPath(path, crackPaint);
    }
  }
}
