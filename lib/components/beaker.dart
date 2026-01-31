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

    final glassRect = size.toRect();
    final rrect = RRect.fromRectAndRadius(glassRect, const Radius.circular(15));

    // 1. Draw shadow for depth
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawRRect(rrect.shift(const Offset(0, 5)), shadowPaint);

    // 2. Draw liquid with gradient if level > 0
    if (liquidLevel > 0) {
      final liquidHeight = size.y * liquidLevel;
      final liquidTop = size.y * (1 - liquidLevel);

      // Create gradient for liquid depth effect
      final liquidGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          currentColor.withOpacity(0.7),
          currentColor,
          currentColor.withOpacity(0.9),
        ],
        stops: const [0.0, 0.5, 1.0],
      );

      final liquidPaint = Paint()
        ..shader = liquidGradient.createShader(
          Rect.fromLTWH(0, liquidTop, size.x, liquidHeight),
        );

      // Draw liquid with rounded bottom corners
      final liquidPath = Path()
        ..moveTo(0, liquidTop)
        ..lineTo(0, size.y - 15)
        ..quadraticBezierTo(0, size.y, 15, size.y)
        ..lineTo(size.x - 15, size.y)
        ..quadraticBezierTo(size.x, size.y, size.x, size.y - 15)
        ..lineTo(size.x, liquidTop)
        ..close();

      canvas.drawPath(liquidPath, liquidPaint);

      // Add shimmer effect on liquid surface
      final shimmerPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      final shimmerRect = Rect.fromLTWH(
        size.x * 0.1,
        liquidTop,
        size.x * 0.8,
        3,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(shimmerRect, const Radius.circular(2)),
        shimmerPaint,
      );
    }

    // 3. Draw glass container with gradient
    final glassGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withOpacity(0.4),
        Colors.white.withOpacity(0.1),
        Colors.white.withOpacity(0.2),
      ],
    );

    final glassFillPaint = Paint()
      ..shader = glassGradient.createShader(glassRect)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(rrect, glassFillPaint);

    // 4. Draw glass border
    final glassBorderPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(rrect, glassBorderPaint);

    // 5. Add highlight reflection on left side
    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomLeft,
        colors: [Colors.white.withOpacity(0.5), Colors.white.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.x * 0.3, size.y))
      ..style = PaintingStyle.fill;

    final highlightPath = Path()
      ..moveTo(15, 0)
      ..lineTo(size.x * 0.25, 0)
      ..lineTo(size.x * 0.2, size.y)
      ..lineTo(15, size.y)
      ..quadraticBezierTo(0, size.y, 0, size.y - 15)
      ..lineTo(0, 15)
      ..quadraticBezierTo(0, 0, 15, 0)
      ..close();

    canvas.drawPath(highlightPath, highlightPaint);

    // 6. Add inner glow
    final innerGlowPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(glassRect.deflate(4), const Radius.circular(12)),
      innerGlowPaint,
    );
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
