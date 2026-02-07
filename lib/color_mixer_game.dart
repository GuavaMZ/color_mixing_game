import 'package:color_mixing_deductive/components/ambient_particles.dart';
import 'package:color_mixing_deductive/components/background_gradient.dart';
import 'package:color_mixing_deductive/components/pattern_background.dart';
import 'package:color_mixing_deductive/components/beaker.dart';
import 'package:color_mixing_deductive/components/particles.dart';
import 'package:color_mixing_deductive/components/pouring_effect.dart';
import 'package:color_mixing_deductive/components/fireworks.dart';
import 'package:color_mixing_deductive/core/color_logic.dart';
import 'package:color_mixing_deductive/core/level_manager.dart';
import 'package:color_mixing_deductive/core/save_manager.dart';
import 'package:color_mixing_deductive/helpers/audio_manager.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

enum GameMode { classic, timeAttack, none }

class ColorMixerGame extends FlameGame with ChangeNotifier {
  late Beaker beaker;
  late Color targetColor;
  bool _hasWon = false;
  int rDrops = 0, gDrops = 0, bDrops = 0;
  int whiteDrops = 0, blackDrops = 0;
  bool isBlindMode = false;
  int maxDrops = 20;
  final LevelManager levelManager = LevelManager();
  final AudioManager _audio = AudioManager();
  Color? _lastBeakerColor;

  final ValueNotifier<double> matchPercentage = ValueNotifier<double>(0.0);
  final ValueNotifier<int> totalDrops = ValueNotifier<int>(0);
  final ValueNotifier<bool> dropsLimitReached = ValueNotifier<bool>(false);

  late BackgroundGradient backgroundGradient;
  late AmbientParticles ambientParticles;
  List<String> unlockedAchievements = [];

  GameMode currentMode = GameMode.none;
  double timeLeft = 30.0;
  double maxTime = 30.0; // Added for progress calculation
  bool isTimeUp = false;

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
    // تحميل التقدم المحفوظ من الهاتف
    await levelManager.initProgress();
    totalStars = await SaveManager.loadTotalStars();
    unlockedAchievements = await SaveManager.loadAchievements();

    // Add background gradient first (rendered first)
    backgroundGradient = BackgroundGradient();
    add(backgroundGradient);

    // Add pattern overlay
    add(PatternBackground());

    // Add ambient particles for atmosphere
    ambientParticles = AmbientParticles();
    add(ambientParticles);

    // Position Beaker slightly above center to make room for bottom controls
    beaker = Beaker(
      position: Vector2(size.x / 2, size.y * 0.54),
      size: Vector2(180, 250),
    );
    add(beaker);

    startLevel();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (currentMode == GameMode.timeAttack && !_hasWon) {
      timeLeft -= dt;
      if (timeLeft <= 0) {
        timeLeft = 0;
        isTimeUp = true;
        _handleGameOver();
      }
      notifyListeners();
    }

    // Check win condition ONLY if color changed
    if (!_hasWon && beaker.currentColor != _lastBeakerColor) {
      _lastBeakerColor = beaker.currentColor;
      if (ColorLogic.checkMatch(beaker.currentColor, targetColor) == 100.0) {
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

    // Add winning particles (Explosion)
    final explosionColors = [
      targetColor,
      Colors.lightBlueAccent,
      Colors.pinkAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
    ];
    add(WinningParticles(position: beaker.position, colors: explosionColors));

    // Add Fireworks Celebration
    add(Fireworks(size: size));

    // Show Achievement (Mock Trigger)
    if (!unlockedAchievements.contains('mad_chemist')) {
      unlockedAchievements.add('mad_chemist');
      SaveManager.saveAchievements(unlockedAchievements);
      overlays.add('Achievement');
    }

    Future.delayed(const Duration(milliseconds: 1500), () {
      overlays.add('WinMenu');
    });
  }

  void resetGame() {
    _hasWon = false;
    // Remove WinMenu overlay if it exists (for replay from win screen)
    overlays.remove('WinMenu');

    // Removed levelManager.reset() as it resets currentLevelIndex to 0
    beaker.clearContents();
    totalDrops.value = 0;
    matchPercentage.value = 0;
    rDrops = 0;
    gDrops = 0;
    bDrops = 0;
    dropsLimitReached.value = false;
    startLevel();
    notifyListeners();
  }

  List<String> dropHistory = [];

  void addDrop(String colorType) {
    if (_hasWon) return;
    if (rDrops + gDrops + bDrops + whiteDrops + blackDrops >= maxDrops) {
      dropsLimitReached.value = true;
      return;
    }

    _audio.playDrop();
    dropHistory.add(colorType);

    // Map colorType to actual Color
    Color dropColor;
    if (colorType == 'red') {
      dropColor = Colors.red;
      rDrops++;
    } else if (colorType == 'green') {
      dropColor = Colors.green;
      gDrops++;
    } else if (colorType == 'blue') {
      dropColor = Colors.blue;
      bDrops++;
    } else if (colorType == 'white') {
      dropColor = Colors.white;
      whiteDrops++;
    } else {
      // Black
      dropColor = Colors.black;
      blackDrops++;
    }

    // Add pouring effect
    final double beakerY = beaker.position.y;
    final double beakerHeight = beaker.size.y;
    final double beakerTop = beakerY - beakerHeight / 2;

    // Calculate current liquid level height
    final double currentDropsRatio =
        (rDrops + gDrops + bDrops + whiteDrops + blackDrops) / maxDrops;
    // Don't go above 1.0 logic-wise for targetY calculation
    final double effectiveRatio = currentDropsRatio > 1.0
        ? 1.0
        : currentDropsRatio;

    // Target Y is where the liquid surface is
    final double beakerBottom = beakerY + beakerHeight / 2;
    final double targetY = beakerBottom - (effectiveRatio * beakerHeight);

    add(
      PouringEffect(
        position: Vector2(size.x / 2, beakerTop - 150),
        targetY: targetY,
        sourceY: beakerTop - 150,
        color: dropColor,
      ),
    );

    _updateGameState();
  }

  void undoLastDrop() {
    if (dropHistory.isEmpty || _hasWon) return;

    final lastDrop = dropHistory.removeLast();
    if (lastDrop == 'red') {
      rDrops--;
    } else if (lastDrop == 'green') {
      gDrops--;
    } else if (lastDrop == 'blue') {
      bDrops--;
    } else if (lastDrop == 'white') {
      whiteDrops--;
    } else if (lastDrop == 'black') {
      blackDrops--;
    }

    // Play sound?
    _audio.playDrop(); // Reuse drop sound or specific undo sound

    dropsLimitReached.value = false;
    _updateGameState();
  }

  /// Temporarily reveal the color in blind mode
  void revealHiddenColor() {
    if (!isBlindMode) return;

    beaker.isBlindMode = false;
    // Trigger visual update
    beaker.updateVisuals(beaker.currentColor, beaker.liquidLevel);

    Future.delayed(const Duration(seconds: 2), () {
      if (!isMounted) return;
      beaker.isBlindMode = true;
      beaker.updateVisuals(beaker.currentColor, beaker.liquidLevel);
    });
  }

  void _updateGameState() {
    // Calculate new color based on drops
    Color newColor = ColorLogic.createMixedColor(
      rDrops,
      gDrops,
      bDrops,
      whiteDrops: whiteDrops,
      blackDrops: blackDrops,
    );

    // Calculate level (liquid amount relative to max)
    double level =
        (rDrops + gDrops + bDrops + whiteDrops + blackDrops) / maxDrops;

    // Update beaker visuals
    beaker.updateVisuals(newColor, level);

    // Update observers for UI
    totalDrops.value = rDrops + gDrops + bDrops + whiteDrops + blackDrops;
    matchPercentage.value = ColorLogic.checkMatch(newColor, targetColor);

    // Auto-win if 100% match
    if (matchPercentage.value == 100.0) {
      _hasWon = true;
      showWinEffect();
    }

    // Check if max drops reached
    if (totalDrops.value >= maxDrops) {
      dropsLimitReached.value = true;
      if (!_hasWon) {
        isTimeUp = false;
        _handleGameOver();
      }
    } else {
      dropsLimitReached.value = false;
    }
  }

  void resetMixing() {
    _audio.playReset();
    rDrops = 0;
    gDrops = 0;
    bDrops = 0;
    whiteDrops = 0;
    blackDrops = 0;
    totalDrops.value = 0;
    matchPercentage.value = 0.0;
    dropsLimitReached.value = false;
    dropHistory.clear();
    beaker.clearContents();
  }

  void startLevel() {
    final level = levelManager.currentLevel;
    targetColor = level.targetColor;
    maxDrops = level.maxDrops;

    // Thoroughly reset game state
    rDrops = 0;
    gDrops = 0;
    bDrops = 0;
    whiteDrops = 0;
    blackDrops = 0;
    totalDrops.value = 0;
    matchPercentage.value = 0;
    dropsLimitReached.value = false;
    _hasWon = false;
    _lastBeakerColor = Colors.transparent;

    // Remove any remaining fireworks
    children.whereType<Fireworks>().forEach((f) => f.removeFromParent());

    // Reset beaker visuals immediately
    isBlindMode = level.isBlindMode;
    beaker.isBlindMode = isBlindMode;
    beaker.clearContents();
    beaker.currentColor = Colors.white.withValues(alpha: .2);

    if (currentMode == GameMode.timeAttack) {
      // Base time scales with difficulty
      maxTime = 30.0 - (level.difficultyFactor * 10);
      maxTime = maxTime.clamp(10, 30);
      timeLeft = maxTime;
      isTimeUp = false;
    } else {
      timeLeft = 0;
      isTimeUp = false;
    }

    notifyListeners();
  }

  void goToNextLevel() {
    int stars = calculateStars();

    // Save progress
    levelManager.unlockNextLevel(levelManager.currentLevelIndex, stars);

    // Remove WinMenu overlay
    overlays.remove('WinMenu');

    // Check if next level exists
    int nextLevelIndex = levelManager.currentLevelIndex + 1;
    if (nextLevelIndex < levelManager.levels.length) {
      levelManager.currentLevelIndex = nextLevelIndex;
      startLevel(); // Initialize and start the next level
    } else {
      // Game Completed? Back to map
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

    _audio.playGameOver();

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
