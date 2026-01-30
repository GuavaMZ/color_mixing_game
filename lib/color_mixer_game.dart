import 'dart:math';

import 'package:color_mixing_deductive/components/beaker.dart';
import 'package:color_mixing_deductive/components/particles.dart';
import 'package:color_mixing_deductive/core/color_logic.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class ColorMixerGame extends FlameGame with ChangeNotifier {
  late Beaker beaker;
  late Color targetColor;
  bool _hasWon = false; // متغير لتتبع حالة الفوز عشان الانفجار مايتكررش
  int rDrops = 0, gDrops = 0, bDrops = 0;
  final int maxDrops = 20;

  final ValueNotifier<double> matchPercentage = ValueNotifier<double>(0.0);
  final ValueNotifier<int> totalDrops = ValueNotifier<int>(0);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    targetColor = _generateRandomTarget();

    beaker = Beaker(position: size / 2, size: Vector2(180, 250));
    add(beaker);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // تحقق من حالة الفوز
    if (!_hasWon &&
        ColorLogic.checkMatch(beaker.currentColor, targetColor) >= 95.0) {
      _hasWon = true; // تعيين حالة الفوز لمنع التكرار
      // إضافة تأثيرات الفوز هنا (مثل الانفجار)
      showWinEffect();
    }
  }

  void showWinEffect() {
    // إضافة تأثيرات الفوز (مثل الانفجار)
    final explosionColors = [
      targetColor, // لون الهدف نفسه
      Colors.lightBlueAccent,
      Colors.pinkAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
    ];
    add(WinningParticles(position: beaker.position, colors: explosionColors));

    Future.delayed(const Duration(milliseconds: 1500), () {
      overlays.add('WinMenu'); // هنضيفها في خطوة قادمة
    });
  }

  void resetGame() {
    rDrops = 0;
    gDrops = 0;
    bDrops = 0;
    _hasWon = false;
    targetColor = _generateRandomTarget();
    beaker.currentColor = Colors.white.withValues(alpha: .3);
    beaker.liquidLevel = 0.1;

    overlays.remove('WinMenu');
    // Reset mixing state as well
    totalDrops.value = 0;
    matchPercentage.value = 0.0;
  }

  Color _generateRandomTarget() {
    final random = Random();
    // توليد لون بمزيج عشوائي من الأحمر والأخضر والأزرق
    return Color.fromARGB(
      255,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );
  }

  void addDrop(String colorType) {
    if (rDrops + gDrops + bDrops >= maxDrops) {
      return; // الحد الأقصى لعدد القطرات
    }

    if (colorType == 'red') rDrops++;
    if (colorType == 'green') gDrops++;
    if (colorType == 'blue') bDrops++;

    // 1. حساب اللون الجديد بناءً على النقاط
    Color newColor = ColorLogic.createMixedColor(rDrops, gDrops, bDrops);

    // 2. حساب المستوى (كمية السائل بالنسبة للمجموع الكلي)
    double level = (rDrops + gDrops + bDrops) / maxDrops;

    // 3. تحديث الشكل البصري في الـ Beaker
    beaker.updateVisuals(newColor, level);

    // تحديث المراقبين (هذا ما سيجعل الـ UI يتحدث فوراً)
    totalDrops.value = rDrops + gDrops + bDrops;
    matchPercentage.value = ColorLogic.checkMatch(newColor, targetColor);
  }

  void resetMixing() {
    rDrops = 0;
    gDrops = 0;
    bDrops = 0;
    totalDrops.value = 0;
    matchPercentage.value = 0.0;
    beaker.clearContents();
    // تحديث الـ UI (لو في حاجة محتاجة تتصفر في الـ Overlay)
    // النسبة هترجع تلقائياً للصفر أو للقيمة البدائية
    // notifyListeners();
  }
}
