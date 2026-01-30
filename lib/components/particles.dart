import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

class WinningParticles extends Component {
  final Vector2 position; // مركز الانفجار
  final List<Color> colors; // الألوان اللي هتستخدم في الانفجار

  WinningParticles({required this.position, required this.colors});

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // إنشاء نظام الجسيمات
    final particalComponent = ParticleSystemComponent(
      position: position,
      particle: Particle.generate(
        count: 200, // عدد الجسيمات
        lifespan: 1.5, // عمر الجسيم (ثانية ونصف)
        generator: (i) {
          final random = Random();
          final speed =
              Vector2.random() * 200 - Vector2(100, 100); // سرعة عشوائية
          final color =
              colors[random.nextInt(
                colors.length,
              )]; // لون عشوائي من الألوان المحددة

          return AcceleratedParticle(
            acceleration: Vector2(0, 50), // تأثير الجاذبية
            speed: (Vector2.random() - Vector2.all(0.5)) * 300, // سرعة عشوائية
            position: position,
            child: RotatingParticle(
              from: 0,
              to: pi * 2,
              child: CircleParticle(
                paint: Paint()..color = color,
                radius: 5 + random.nextDouble() * 10, // حجم دائرة عشوائي
              ),
            ),
          );
        },
      ),
    );

    add(particalComponent);

    Future.delayed(const Duration(seconds: 2), () {
      removeFromParent(); // إزالة النظام بعد انتهاء الجسيمات
    });
  }
}
