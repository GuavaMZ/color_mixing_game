import 'dart:math';
import 'package:color_mixing_deductive/components/ambient_particles.dart';
import 'package:color_mixing_deductive/components/background_gradient.dart';
import 'package:color_mixing_deductive/components/pattern_background.dart';
import 'package:color_mixing_deductive/components/beaker.dart';
import 'package:color_mixing_deductive/components/particles.dart';
import 'package:color_mixing_deductive/components/pouring_effect.dart';
import 'package:color_mixing_deductive/core/color_logic.dart';
import 'package:color_mixing_deductive/core/level_manager.dart';
import 'package:color_mixing_deductive/core/save_manager.dart';
import 'package:color_mixing_deductive/helpers/audio_manager.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';

enum GameMode { classic, timeAttack }

class ColorMixerGame extends FlameGame with ChangeNotifier {
  late Beaker beaker;
  late Color targetColor;
  bool _hasWon = false;
  int rDrops = 0, gDrops = 0, bDrops = 0;
  int maxDrops = 20;
  final LevelManager levelManager = LevelManager();
  final AudioManager _audio = AudioManager();
  Color? _lastBeakerColor;

  final ValueNotifier<double> matchPercentage = ValueNotifier<double>(0.0);
  final ValueNotifier<int> totalDrops = ValueNotifier<int>(0);
  final ValueNotifier<bool> dropsLimitReached = ValueNotifier<bool>(false);

  late BackgroundGradient backgroundGradient;
  late AmbientParticles ambientParticles;

  GameMode currentMode = GameMode.classic;
  double timeLeft = 30.0;

  void Function(VoidCallback)? _transitionCallback;

  void setTransitionCallback(void Function(VoidCallback) callback) {
    _transitionCallback = callback;
  }

  void transitionTo(String overlayToRemove, String overlayToAdd) {
    if (_transitionCallback != null) {
      _transitionCallback!(() {
        overlays.remove(overlayToRemove);
        overlays.add(overlayToAdd);
      });
    } else {
      overlays.remove(overlayToRemove);
      overlays.add(overlayToAdd);
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // تحميل التقدم المحفوظ من الهاتف
    await levelManager.initProgress();

    // Add background gradient first (rendered first)
    backgroundGradient = BackgroundGradient();
    add(backgroundGradient);

    // Add pattern overlay
    add(PatternBackground());

    // Add ambient particles for atmosphere
    ambientParticles = AmbientParticles();
    add(ambientParticles);

    startLevel();

    // Position Beaker slightly above center to make room for bottom controls
    // size.y * 0.40 places it comfortably above the new minimal controls
    beaker = Beaker(
      position: Vector2(size.x / 2, size.y * 0.54),
      size: Vector2(180, 250),
    );
    add(beaker);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (currentMode == GameMode.timeAttack && !_hasWon) {
      timeLeft -= dt;
      if (timeLeft <= 0) {
        timeLeft = 0;
        _handleGameOver();
      }
      notifyListeners();
    }

    // Check win condition ONLY if color changed
    if (!_hasWon && beaker.currentColor != _lastBeakerColor) {
      _lastBeakerColor = beaker.currentColor;
      if (ColorLogic.checkMatch(beaker.currentColor, targetColor) >= 95.0) {
        _hasWon = true;
        showWinEffect();
      }
    }
  }

  @override
  void onRemove() {
    _audio.stopMusic();
    super.onRemove();
  }

  void showWinEffect() {
    _audio.playWin();

    // Add winning particles
    final explosionColors = [
      targetColor,
      Colors.lightBlueAccent,
      Colors.pinkAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
    ];
    add(WinningParticles(position: beaker.position, colors: explosionColors));

    Future.delayed(const Duration(milliseconds: 1500), () {
      overlays.add('WinMenu');
    });
  }

  void resetGame() {
    rDrops = 0;
    gDrops = 0;
    bDrops = 0;
    _hasWon = false;
    beaker.currentColor = Colors.white.withValues(alpha: 0.3);
    beaker.liquidLevel = 0.1;

    overlays.remove('WinMenu');
    totalDrops.value = 0;
    matchPercentage.value = 0.0;
    dropsLimitReached.value = false;

    // Start the same level again
    startLevel();
  }

  void addDrop(String colorType) {
    if (_hasWon) return;
    if (rDrops + gDrops + bDrops >= maxDrops) {
      dropsLimitReached.value = true;
      return;
    }

    _audio.playDrop();

    // Map colorType to actual Color
    Color dropColor;
    if (colorType == 'red') {
      dropColor = Colors.red;
      rDrops++;
    } else if (colorType == 'green') {
      dropColor = Colors.green;
      gDrops++;
    } else {
      dropColor = Colors.blue;
      bDrops++;
    }

    // Add pouring effect
    final random = Random();
    final randomStyle =
        PouringStyle.values[random.nextInt(PouringStyle.values.length)];

    add(
      PouringEffect(
        position: Vector2(size.x / 2 - 25, size.y / 2 - 250),
        size: Vector2(50, 150),
        color: dropColor,
        style: randomStyle,
      ),
    );

    // Check if max drops reached
    if (rDrops + gDrops + bDrops >= maxDrops) {
      dropsLimitReached.value = true;
    }

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
    _audio.playReset();
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

    // Reset time for time attack mode
    if (currentMode == GameMode.timeAttack) {
      timeLeft = 30.0;
    }

    if (isLoaded) {
      beaker.clearContents();
    }
    notifyListeners();
  }

  void goToNextLevel() {
    int stars = calculateStars();

    // Save progress
    levelManager.unlockNextLevel(levelManager.currentLevelIndex, stars);

    // Check if next level exists
    int nextLevelIndex = levelManager.currentLevelIndex + 1;
    if (nextLevelIndex < levelManager.levels.length) {
      levelManager.currentLevelIndex = nextLevelIndex;
      resetGame(); // This restarts the level with the new index
      // Ensure we are on controls view (resetGame does startLevel)
    } else {
      // Game Completed? Back to map
      overlays.remove('WinMenu');
      overlays.add('LevelMap');
    }
    notifyListeners();
  }

  int calculateStars() {
    int drops = totalDrops.value;
    int minDrops = levelManager.currentLevel.minDropsNeeded;

    // 3 stars: within 2 drops of optimal
    // 2 stars: within 5 drops of optimal
    // 1 star: completed
    if (drops <= minDrops + 2) return 3;
    if (drops <= minDrops + 5) return 2;
    return 1;
  }

  void selectModeAndStart(GameMode mode) {
    currentMode = mode;
    levelManager.currentMode = mode == GameMode.classic
        ? 'classic'
        : 'timeAttack';

    if (mode == GameMode.timeAttack) {
      timeLeft = 30.0;
    }
    overlays.remove('MainMenu');
    overlays.add('LevelMap');
    notifyListeners();
  }

  void _handleGameOver() {
    _hasWon = false; // نضمن أن حالة الفوز لم تتحقق
    // إيقاف أي أصوات أو حركات جارية
    FlameAudio.play(
      'game_over_sound.mp3',
      volume: 0.5,
    ); // اختيار صوت يوحي بالخسارة

    overlays.add('GameOver');
  }

  int totalStars = 0;
  List<BeakerType> unlockedSkins = [BeakerType.classic];

  void buyOrSelectSkin(BeakerType type, int price) {
    if (unlockedSkins.contains(type)) {
      beaker.type = type; // اختيار الشكل
    } else if (totalStars >= price) {
      totalStars -= price;
      unlockedSkins.add(type);
      beaker.type = type;
      // حفظ البيانات الجديدة في الذاكرة
      SaveManager.saveTotalStars(totalStars);
    }
    notifyListeners();
  }
}
