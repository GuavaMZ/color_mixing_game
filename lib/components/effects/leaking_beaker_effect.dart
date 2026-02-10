import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

import '../../color_mixer_game.dart';

/// A disaster effect where the beaker leaks liquid.
/// The player must tap the cracks to fix them.
class LeakingBeakerEffect extends Component with HasGameRef<ColorMixerGame> {
  final List<_LeakPoint> _leaks = [];
  final Random _random = Random();
  double _leakTimer = 0;

  @override
  void onMount() {
    super.onMount();
    _spawnLeak();
    _spawnLeak();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _leakTimer += dt;

    if (_leaks.isEmpty && _leakTimer > 2.0) {
      _spawnLeak();
      _leakTimer = 0;
    }

    for (final leak in _leaks) {
      // Liquid drains
      gameRef.drainLiquid(0.005 * dt);

      // Spawn drip particles
      if (_random.nextDouble() < 0.2) {
        _spawnDrip(leak.position);
      }
    }
  }

  void _spawnLeak() {
    final beaker = gameRef.beaker;
    final x =
        (beaker.size.x * 0.2) + _random.nextDouble() * (beaker.size.x * 0.6);
    final y =
        (beaker.size.y * 0.3) + _random.nextDouble() * (beaker.size.y * 0.4);

    final leak = _LeakPoint(
      position: Vector2(x, y),
      onFixed: (p) => _leaks.remove(p),
    );
    _leaks.add(leak);
    beaker.add(leak);
  }

  void _spawnDrip(Vector2 pos) {
    final beaker = gameRef.beaker;
    gameRef.add(
      ParticleSystemComponent(
        particle: Particle.generate(
          count: 1,
          lifespan: 1.0,
          generator: (i) => AcceleratedParticle(
            position: beaker.position + pos - beaker.size / 2,
            speed: Vector2((_random.nextDouble() - 0.5) * 20, 100),
            acceleration: Vector2(0, 200),
            child: CircleParticle(
              radius: 2.0,
              paint: Paint()
                ..color = beaker.currentColor.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}

class _LeakPoint extends PositionComponent with TapCallbacks {
  final Function(_LeakPoint) onFixed;
  final List<Offset> _crackLines = [];

  _LeakPoint({required Vector2 position, required this.onFixed}) {
    this.position = position;
    size = Vector2.all(40);
    anchor = Anchor.center;

    final random = Random();
    for (int i = 0; i < 4; i++) {
      _crackLines.add(
        Offset(
          (random.nextDouble() - 0.5) * 30,
          (random.nextDouble() - 0.5) * 30,
        ),
      );
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final line in _crackLines) {
      canvas.drawLine(Offset.zero, line, paint);
    }

    // Pulse effect
    final pulse = (sin(DateTime.now().millisecondsSinceEpoch / 200) + 1) / 2;
    canvas.drawCircle(
      Offset.zero,
      5 + pulse * 5,
      paint
        ..style = PaintingStyle.fill
        ..color = paint.color.withValues(alpha: 0.3),
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    onFixed(this);
    removeFromParent();
  }
}
