import 'package:color_mixing_deductive/components/ambient_particles.dart';
import 'package:color_mixing_deductive/components/background_gradient.dart';
import 'package:color_mixing_deductive/components/beaker.dart';
import 'package:color_mixing_deductive/components/particles.dart';
import 'package:color_mixing_deductive/core/color_logic.dart';
import 'package:color_mixing_deductive/core/level_manager.dart';
import 'package:color_mixing_deductive/helpers/audio_manager.dart';
import 'package:flame/game.dart';
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

  final ValueNotifier<double> matchPercentage = ValueNotifier<double>(0.0);
  final ValueNotifier<int> totalDrops = ValueNotifier<int>(0);
  final ValueNotifier<bool> dropsLimitReached = ValueNotifier<bool>(false);

  late BackgroundGradient backgroundGradient;
  late AmbientParticles ambientParticles;

  GameMode currentMode = GameMode.classic;
  double timeLeft = 30.0;

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

    beaker = Beaker(position: size / 2, size: Vector2(180, 250));
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

    // Check win condition
    if (!_hasWon &&
        ColorLogic.checkMatch(beaker.currentColor, targetColor) >= 95.0) {
      _hasWon = true;
      showWinEffect();
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
    beaker.currentColor = Colors.white.withValues(alpha: .3);
    beaker.liquidLevel = 0.1;

    overlays.remove('WinMenu');
    totalDrops.value = 0;
    matchPercentage.value = 0.0;
    dropsLimitReached.value = false;

    // Start the same level again
    startLevel();
  }

  void addDrop(String colorType) {
    _audio.playDrop();

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
    levelManager.unlockNextLevel(stars);
    overlays.remove('WinMenu');
    overlays.remove('Controls');
    overlays.add('LevelMap');
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
    if (mode == GameMode.timeAttack) {
      timeLeft = 30.0;
    }
    overlays.remove('MainMenu');
    overlays.add('LevelMap');
  }

  void _handleGameOver() {
    // For now, just show level map to try again
    overlays.remove('Controls');
    overlays.add('LevelMap');
  }
}
