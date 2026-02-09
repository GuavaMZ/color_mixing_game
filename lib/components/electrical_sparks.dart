import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../helpers/audio_manager.dart';
import '../color_mixer_game.dart';

/// Individual spark particle
class Spark {
  Vector2 position;
  Vector2 velocity;
  double lifetime;
  double maxLifetime;
  Color color;
  double size;

  Spark({
    required this.position,
    required this.velocity,
    required this.maxLifetime,
    required this.color,
  }) : lifetime = 0,
       size = 2 + Random().nextDouble() * 3;

  void update(double dt) {
    position += velocity * dt;
    lifetime += dt;
    velocity.y += 200 * dt; // Gravity
    velocity *= 0.95; // Air resistance
  }

  bool get isDead => lifetime >= maxLifetime;

  double get opacity => 1 - (lifetime / maxLifetime);
}

/// Electrical sparks effect for Chaos Lab Mode
class ElectricalSparks extends Component with HasGameRef<ColorMixerGame> {
  final List<Spark> _sparks = [];
  final Random _random = Random();
  double _burstTimer = 0;
  double _nextBurstTime = 1.5;

  final Paint _sparkPaint = Paint()
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

  @override
  void update(double dt) {
    super.update(dt);

    _burstTimer += dt;

    // Create spark bursts
    if (_burstTimer >= _nextBurstTime) {
      _createSparkBurst();
      AudioManager().playSpark();
      _burstTimer = 0;
      _nextBurstTime = 0.8 + _random.nextDouble() * 2.0;
    }

    // Update sparks
    _sparks.removeWhere((s) => s.isDead);
    for (var spark in _sparks) {
      spark.update(dt);
    }
  }

  void _createSparkBurst() {
    if (parent == null) return;

    final gameSize = gameRef.size;

    // Spark locations (near control panel area - bottom)
    final sparkPoints = [
      Vector2(gameSize.x * 0.2, gameSize.y * 0.85),
      Vector2(gameSize.x * 0.8, gameSize.y * 0.85),
    ];

    final sparkPoint = sparkPoints[_random.nextInt(sparkPoints.length)];

    // Create burst of sparks
    final numSparks = 8 + _random.nextInt(12);

    for (int i = 0; i < numSparks; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 50 + _random.nextDouble() * 100;

      final sparkColors = [
        const Color(0xFFFAFF00), // Electric yellow
        const Color(0xFF00F0FF), // Cyan
        Colors.white,
      ];

      _sparks.add(
        Spark(
          position: sparkPoint.clone(),
          velocity: Vector2(
            cos(angle) * speed,
            sin(angle) * speed - 50, // Bias upward
          ),
          maxLifetime: 0.3 + _random.nextDouble() * 0.4,
          color: sparkColors[_random.nextInt(sparkColors.length)],
        ),
      );
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    for (var spark in _sparks) {
      _sparkPaint.color = spark.color.withValues(alpha: spark.opacity);

      // Draw spark as small circle
      canvas.drawCircle(spark.position.toOffset(), spark.size, _sparkPaint);

      // Draw trail
      if (spark.velocity.length > 50) {
        final trailPaint = Paint()
          ..color = spark.color.withValues(alpha: spark.opacity * 0.3)
          ..strokeWidth = spark.size * 0.5
          ..strokeCap = StrokeCap.round;

        final trailEnd = spark.position - (spark.velocity.normalized() * 8);

        canvas.drawLine(
          spark.position.toOffset(),
          trailEnd.toOffset(),
          trailPaint,
        );
      }
    }
  }
}
