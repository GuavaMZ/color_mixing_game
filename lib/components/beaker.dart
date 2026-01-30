import 'package:color_mixing_deductive/core/color_logic.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

class Beaker extends PositionComponent {
  Color currentColor = Colors.white.withValues(alpha: .2);
  Color _targetColor = Colors.white.withValues(alpha: .2); // For interpolation
  double liquidLevel = 0.0; // يبدأ الوعاء بـ 10% سائل

  Beaker({required Vector2 position, required Vector2 size})
    : super(position: position, size: size, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    // Smoothly interpolate current color towards target color
    if (currentColor != _targetColor) {
      currentColor =
          Color.lerp(currentColor, _targetColor, dt * 5) ?? _targetColor;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (liquidLevel > 0) {
      // 1. رسم السائل بحواف ناعمة
      final liquidRect = Rect.fromLTWH(
        0,
        size.y * (1 - liquidLevel), // الارتفاع يتحدد بناءً على المستوى
        size.x,
        size.y * liquidLevel,
      );

      // 1. رسم السائل اللي جوه الوعاء
      final liquidPaint = Paint()
        ..color = currentColor
        ..style = PaintingStyle.fill;

      // رسم السائل (مع إضافة زوايا دائرية بسيطة من الأسفل)
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          liquidRect,
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
        liquidPaint,
      );
    }

    // 2. رسم حدود الوعاء (الزجاج)
    final glassPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    final glassRect = size.toRect();
    canvas.drawRRect(
      RRect.fromRectAndRadius(glassRect, const Radius.circular(10)),
      glassPaint,
    );

    canvas.drawRect(size.toRect(), glassPaint);
  }

  // ميثود هنستخدمها لما نضغط على الأزرار لاحقاً
  void mixWith(Color newColor) {
    _targetColor = Color.lerp(currentColor, newColor, 0.5)!;
  }

  // 1. تحديث المنطق (Logic)
  void addColor(Color colorToAdd) {
    // 1. تحديث المنطق (Logic)
    _targetColor = ColorLogic.mix(currentColor, colorToAdd);

    // 2. تأثير الاهتزاز (Shake Effect) لإعطاء شعور بالتفاعل
    add(
      MoveEffect.by(
        Vector2(4, 0),
        EffectController(duration: 0.05, alternate: true, repeatCount: 3),
      ),
    );

    if (liquidLevel < 0.9) {
      liquidLevel += 0.05; // زيادة مستوى السائل بنسبة 10%
    }
  }

  void updateVisuals(Color newMixedColor, double newLevel) {
    // 1. تعيين اللون المستهدف بدلاً من Effect
    _targetColor = newMixedColor;

    // 2. تحديث مستوى السائل
    liquidLevel = newLevel;

    // 3. تأثير الاهتزاز الاحترافي عند كل "نقطة"
    add(
      MoveEffect.by(
        Vector2(0, 5), // اهتزاز لأسفل وأعلى
        EffectController(duration: 0.1, alternate: true, repeatCount: 1),
      ),
    );
  }

  void clearContents() {
    // إعادة تعيين الألوان
    _targetColor = Colors.white.withValues(alpha: .2);

    // ممكن هنا نضيف Effect يقلل الـ liquidLevel للصفر تدريجياً لو حابب
    liquidLevel = 0.0;

    // اهتزاز خفيف لتأكيد المسح
    add(
      MoveEffect.by(
        Vector2(0, 10),
        EffectController(duration: 0.1, alternate: true),
      ),
    );
  }
}
