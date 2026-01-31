import 'dart:math';

import 'package:color_mixing_deductive/components/ambient_particles.dart';
import 'package:color_mixing_deductive/components/background_gradient.dart';
import 'package:color_mixing_deductive/components/beaker.dart';
import 'package:color_mixing_deductive/components/particles.dart';
import 'package:color_mixing_deductive/core/color_logic.dart';
import 'package:color_mixing_deductive/core/level_manager.dart';
import 'package:color_mixing_deductive/core/level_model.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';

class ColorMixerGame extends FlameGame with ChangeNotifier {
  late Beaker beaker;
  late Color targetColor;
  bool _hasWon = false;
  int rDrops = 0, gDrops = 0, bDrops = 0;
  final int maxDrops = 20;
  final LevelManager levelManager = LevelManager();

  final ValueNotifier<double> matchPercentage = ValueNotifier<double>(0.0);
  final ValueNotifier<int> totalDrops = ValueNotifier<int>(0);

  late BackgroundGradient backgroundGradient;
  late AmbientParticles ambientParticles;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Add background gradient first (rendered first)
    backgroundGradient = BackgroundGradient();
    add(backgroundGradient);

    // Add ambient particles for atmosphere
    ambientParticles = AmbientParticles();
    add(ambientParticles);

    startLevel();
    // await FlameAudio.audioCache.loadAll(['drop.mp3', 'win.mp3', 'reset.mp3']);

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

  @override
  void onMount() {
    super.onMount();
    // تشغيل موسيقى هادئة في الخلفية
    // FlameAudio.bgm.play('background_music.mp3', volume: 0.2);
  }

  @override
  void onRemove() {
    // إيقاف الموسيقى عند إغلاق اللعبة
    FlameAudio.bgm.stop();
    super.onRemove();
  }

  void showWinEffect() {
    FlameAudio.play('win.mp3', volume: 0.7);
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
    FlameAudio.play('drop.mp3', volume: 0.5);

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
    FlameAudio.play('reset.mp3', volume: 0.4);
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

  void startLevel() {
    final level = levelManager.currentLevel;

    // توليد لون هدف بناءً على صعوبة الليفل
    targetColor = _generateTargetForLevel(level);

    rDrops = 0;
    gDrops = 0;
    bDrops = 0;
    totalDrops.value = 0;
    matchPercentage.value = 0.0;

    if (isLoaded) {
      beaker.clearContents();
    }
    notifyListeners();
  }

  // دالة ذكية لتوليد لون هدف بناءً على الصعوبة
  Color _generateTargetForLevel(LevelModel level) {
    // لو ليفل سهل، بنخلط لونين بس، لو صعب بنخلط التلاتة بنسب معقدة
    // (ممكن نستخدم الـ difficultyFactor هنا لتقليل العشوائية)
    return ColorLogic.createMixedColor(
      Random().nextInt(5),
      Random().nextInt(5),
      level.availableColors.contains(Colors.blue) ? Random().nextInt(5) : 0,
    );
  }

  void goToNextLevel() {
    if (levelManager.nextLevel()) {
      overlays.remove('WinMenu');
      startLevel();
    } else {
      print("Game Finished!");
    }
  }

  int calculateStars() {
    // مثال: إذا حلها في أقل من 5 نقط يأخذ 3 نجوم، أقل من 10 نقط نجمتين، وهكذا
    int drops = totalDrops.value;
    if (drops <= 6) return 3;
    if (drops <= 12) return 2;
    return 1;
  }
}
