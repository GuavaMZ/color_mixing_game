import 'package:color_mixing_deductive/components/ambient_particles.dart';
import 'package:color_mixing_deductive/components/background_gradient.dart';
import 'package:color_mixing_deductive/components/beaker.dart';
import 'package:color_mixing_deductive/components/particles.dart';
import 'package:color_mixing_deductive/core/color_logic.dart';
import 'package:color_mixing_deductive/core/level_manager.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';

class ColorMixerGame extends FlameGame with ChangeNotifier {
  late Beaker beaker;
  late Color targetColor;
  bool _hasWon = false;
  int rDrops = 0, gDrops = 0, bDrops = 0;
  int maxDrops = 20; // Will be updated per level
  final LevelManager levelManager = LevelManager();

  final ValueNotifier<double> matchPercentage = ValueNotifier<double>(0.0);
  final ValueNotifier<int> totalDrops = ValueNotifier<int>(0);
  final ValueNotifier<bool> dropsLimitReached = ValueNotifier<bool>(false);

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

    // await FlameAudio.audioCache.loadAll(['drop.mp3', 'win.mp3', 'reset.mp3']);

    startLevel();

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
    beaker.currentColor = Colors.white.withValues(alpha: .3);
    beaker.liquidLevel = 0.1;

    overlays.remove('WinMenu');
    // Reset mixing state as well
    totalDrops.value = 0;
    matchPercentage.value = 0.0;

    // Start the same level again
    startLevel();
  }

  void addDrop(String colorType) {
    FlameAudio.play('drop.mp3', volume: 0.5);

    // Check if max drops reached
    if (rDrops + gDrops + bDrops >= maxDrops) {
      dropsLimitReached.value = true;
      return;
    }

    if (colorType == 'red') rDrops++;
    if (colorType == 'green') gDrops++;
    if (colorType == 'blue') bDrops++;

    // Calculate new color based on drops
    Color newColor = ColorLogic.createMixedColor(rDrops, gDrops, bDrops);

    // Calculate level (liquid amount relative to max)
    double level = (rDrops + gDrops + bDrops) / maxDrops;

    // Update beaker visuals
    beaker.updateVisuals(newColor, level);

    // Update observers for UI
    totalDrops.value = rDrops + gDrops + bDrops;
    matchPercentage.value = ColorLogic.checkMatch(newColor, targetColor);

    // Check if approaching limit
    if (totalDrops.value >= maxDrops - 2) {
      dropsLimitReached.value = true;
    } else {
      dropsLimitReached.value = false;
    }
  }

  void resetMixing() {
    FlameAudio.play('reset.mp3', volume: 0.4);
    rDrops = 0;
    gDrops = 0;
    bDrops = 0;
    totalDrops.value = 0;
    matchPercentage.value = 0.0;
    dropsLimitReached.value = false;
    beaker.clearContents();
  }

  void startLevel() {
    final level = levelManager.currentLevel;

    // Use the pre-defined target color from the level
    targetColor = level.targetColor;

    // Update max drops from level
    maxDrops = level.maxDrops;

    rDrops = 0;
    gDrops = 0;
    bDrops = 0;
    totalDrops.value = 0;
    matchPercentage.value = 0.0;
    dropsLimitReached.value = false;
    _hasWon = false;

    if (isLoaded) {
      beaker.clearContents();
    }
    notifyListeners();
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
