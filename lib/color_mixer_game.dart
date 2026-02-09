import 'package:color_mixing_deductive/components/ambient_particles.dart';
import 'package:color_mixing_deductive/components/background_gradient.dart';
import 'package:color_mixing_deductive/components/pattern_background.dart';
import 'package:color_mixing_deductive/components/beaker.dart';
import 'package:color_mixing_deductive/components/mix_particles.dart';
import 'package:color_mixing_deductive/components/particles.dart';
import 'package:color_mixing_deductive/components/pouring_effect.dart';
import 'package:color_mixing_deductive/components/fireworks.dart';
import 'package:color_mixing_deductive/components/holographic_radar.dart';
import 'package:color_mixing_deductive/components/spectral_target.dart';
import 'package:color_mixing_deductive/components/echo_particles.dart';
import 'package:color_mixing_deductive/components/glitch_effect.dart';
import 'package:color_mixing_deductive/components/blackout_effect.dart';
import 'package:color_mixing_deductive/components/unstable_beaker_effect.dart';
import 'package:color_mixing_deductive/components/acid_splatter.dart';
import 'package:color_mixing_deductive/components/surface_steam.dart';
import 'package:color_mixing_deductive/components/gravity_flux_effect.dart';
import 'package:color_mixing_deductive/components/inverted_controls_effect.dart';
import 'package:color_mixing_deductive/components/earthquake_visual_effect.dart';
import 'package:color_mixing_deductive/core/color_logic.dart';
import 'package:color_mixing_deductive/core/level_manager.dart';
import 'package:color_mixing_deductive/core/save_manager.dart';
import 'package:color_mixing_deductive/core/lives_manager.dart';
import 'package:color_mixing_deductive/helpers/audio_manager.dart';
import 'package:color_mixing_deductive/helpers/haptic_manager.dart';
import 'package:color_mixing_deductive/helpers/statistics_manager.dart';
import 'package:color_mixing_deductive/helpers/string_manager.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';

enum GameMode { classic, timeAttack, colorEcho, chaosLab, none }

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
  final ValueNotifier<int> totalCoins = ValueNotifier<int>(0);
  final ValueNotifier<Map<String, int>> helperCounts =
      ValueNotifier<Map<String, int>>({});

  // Combo System
  final ValueNotifier<int> comboCount = ValueNotifier<int>(0);
  int highestCombo = 0;
  final Map<String, int> helpersUsedInLevel = {}; // New field

  // Hint System
  final ValueNotifier<String?> currentHint = ValueNotifier<String?>(null);
  bool hasUsedHint = false;
  final int hintCost = 50;

  late BackgroundGradient backgroundGradient;
  late AmbientParticles ambientParticles;
  List<String> unlockedAchievements = [];
  bool globalBlindMode = false;

  GameMode currentMode = GameMode.none;
  double timeLeft = 30.0;
  double maxTime = 30.0; // Added for progress calculation
  bool isTimeUp = false;
  bool randomEventsEnabled = false;
  double _eventTimer = 0;

  // Random Event States
  bool isBlackout = false;
  bool isEvaporating = false;
  bool isControlsInverted = false;
  bool isUiGlitching = false;
  bool isEarthquake = false; // New earthquake flag
  bool isColorBlindEvent = false; // New color blind event flag
  bool isGravityFlux = false; // New gravity flux flag
  double _evaporationVisualOffset = 0.0; // Visual level to subtract

  // Earthquake shake offset
  Vector2 _earthquakeOffset = Vector2.zero();
  Vector2 get earthquakeOffset => _earthquakeOffset;

  final Random _random = Random();

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
    await LivesManager().init();
    totalStars = await SaveManager.loadTotalStars();
    totalCoins.value = await SaveManager.loadTotalCoins();
    unlockedAchievements = await SaveManager.loadAchievements();
    globalBlindMode = await SaveManager.loadBlindMode();
    randomEventsEnabled = await SaveManager.loadRandomEvents();

    // Load helpers
    final savedHelpers = await SaveManager.loadHelpers();
    helperCounts.value = Map<String, int>.from(savedHelpers);

    // Load skins
    final savedSkins = await SaveManager.loadPurchasedSkins();
    if (savedSkins.isNotEmpty) {
      unlockedSkins = savedSkins.map((s) {
        return BeakerType.values.firstWhere(
          (e) => e.toString() == s,
          orElse: () => BeakerType.classic,
        );
      }).toList();
    }
    if (!unlockedSkins.contains(BeakerType.classic)) {
      unlockedSkins.add(BeakerType.classic);
    }

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

    // Start music for Main Menu (Classic/Menu BGM)
    _audio.playMenuMusic();

    startLevel();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if ((currentMode == GameMode.timeAttack ||
            currentMode == GameMode.chaosLab) &&
        !_hasWon) {
      timeLeft -= dt;
      if (timeLeft <= 0) {
        timeLeft = 0;
        isTimeUp = true;
        _handleGameOver();
      }
      notifyListeners();
    }

    // Earthquake Logic
    if (isEarthquake && !_hasWon) {
      // Simple random shake
      double intensity = 5.0;
      _earthquakeOffset.x = (_random.nextDouble() - 0.5) * intensity * 2;
      _earthquakeOffset.y = (_random.nextDouble() - 0.5) * intensity * 2;
      camera.viewfinder.position = _earthquakeOffset;
    } else if (camera.viewfinder.position != Vector2.zero()) {
      camera.viewfinder.position = Vector2.zero();
      _earthquakeOffset = Vector2.zero();
    }

    // Evaporation Logic (Smooth Visual)
    if (isEvaporating && !_hasWon) {
      final double evaporationRate = 0.5; // (Drops per second)
      _evaporationVisualOffset += dt * evaporationRate;

      // When offset reaches one full drop's volume, remove a logical drop
      if (_evaporationVisualOffset >= 1.0) {
        _evaporationVisualOffset -= 1.0;
        if (totalDrops.value > 0) {
          if (rDrops > 0)
            rDrops--;
          else if (gDrops > 0)
            gDrops--;
          else if (bDrops > 0)
            bDrops--;
          else if (whiteDrops > 0)
            whiteDrops--;
          else if (blackDrops > 0)
            blackDrops--;

          _audio.playSteam(); // Sound effect
          if (totalDrops.value == 0) {
            _handleGameOver();
          }
        }
      }
      _updateGameState(); // Update visuals every frame during evaporation
    }

    helpersUsedInLevel.clear();
    // Random Events Logic
    if ((randomEventsEnabled && currentMode == GameMode.classic) ||
        currentMode == GameMode.chaosLab) {
      if (!_hasWon) {
        _eventTimer -= dt;
        if (_eventTimer <= 0) {
          _triggerRandomEvent();
          // Reset timer based on mode
          if (currentMode == GameMode.chaosLab) {
            _eventTimer = 20.0; // Fixed 20s for Chaos Lab
          } else {
            _eventTimer =
                10.0 + _random.nextDouble() * 5.0; // 10-15s for Classic
          }
        }
      }
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
    // Combo System: Increment on perfect match
    int stars = calculateStars();
    if (stars == 3) {
      comboCount.value++;
      if (comboCount.value > highestCombo) {
        highestCombo = comboCount.value;
      }
    } else {
      comboCount.value = 0;
    }

    // Haptic feedback for combos
    HapticManager().combo(comboCount.value);

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

    // Add shimmer effect for perfect matches
    if (stars == 3) {
      add(
        ShimmerEffect(
          targetPosition: beaker.position,
          targetColor: targetColor,
        ),
      );
    }

    // Add Fireworks Celebration
    add(Fireworks(size: size));

    // Show Achievement (Mock Trigger)
    if (!unlockedAchievements.contains('mad_chemist')) {
      unlockedAchievements.add('mad_chemist');
      SaveManager.saveAchievements(unlockedAchievements);
      overlays.add('Achievement');
    }

    // Combo King Achievement
    if (comboCount.value >= 10 &&
        !unlockedAchievements.contains('combo_king')) {
      unlockedAchievements.add('combo_king');
      SaveManager.saveAchievements(unlockedAchievements);
      overlays.add('Achievement');
    }

    // New Achievements Logic
    _checkAdvAchievements(stars);

    // Award combo bonus coins
    int baseCoins = stars * 10;
    int comboMultiplier = 1;
    if (comboCount.value >= 10) {
      comboMultiplier = 5;
    } else if (comboCount.value >= 5) {
      comboMultiplier = 3;
    } else if (comboCount.value >= 3) {
      comboMultiplier = 2;
    }
    int bonusCoins = baseCoins * (comboMultiplier - 1);
    addCoins(baseCoins + bonusCoins);

    // Track statistics
    StatisticsManager.incrementLevelsCompleted();
    if (stars == 3) {
      StatisticsManager.incrementPerfectMatches();
    }
    StatisticsManager.updateHighestCombo(comboCount.value);
    StatisticsManager.addDropsUsed(totalDrops.value);
    StatisticsManager.incrementModePlay(currentMode);

    Future.delayed(const Duration(milliseconds: 1500), () {
      overlays.add('WinMenu');
    });
  }

  void resetGame() {
    _hasWon = false;
    comboCount.value = 0; // Reset combo on retry
    // Remove overlays if they exist
    overlays.remove('WinMenu');
    overlays.remove('GameOver');
    _evaporationVisualOffset = 0.0;

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
    // Handle Inverse Controls
    String effectiveColorType = colorType;
    if (isControlsInverted) {
      if (colorType == 'red')
        effectiveColorType = 'blue';
      else if (colorType == 'blue')
        effectiveColorType = 'red';
      // Can also swap others if desired, e.g. green/yellow? Green is secondary?
      // Let's stick to Red/Blue as per request "red button adds blue, and the yellow button adds red"
      // Wait, request said "yellow button adds red".
      // The game has 'red', 'green', 'blue', 'white', 'black'. No explicit 'yellow' button mentioned in code?
      // RGB are primaries. Maybe user meant a specific button.
      // Assuming user meant "Red <-> Blue" swap for standard inversion.
      // If "yellow" refers to something else, I'll stick to Red/Blue swap for max confusion.
    }

    Color dropColor;
    if (effectiveColorType == 'red') {
      dropColor = Colors.red;
      rDrops++;
    } else if (effectiveColorType == 'green') {
      dropColor = Colors.green;
      gDrops++;
    } else if (effectiveColorType == 'blue') {
      dropColor = Colors.blue;
      bDrops++;
    } else if (effectiveColorType == 'white') {
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

    // Add mix particles for visual feedback
    add(
      MixParticles(
        dropColor: dropColor,
        mixPosition: beaker.position + Vector2(0, -beaker.size.y * 0.3),
      ),
    );

    // Haptic feedback
    HapticManager().light();

    if (currentMode == GameMode.colorEcho) {
      add(
        EchoParticles(
          position: beaker.position + Vector2(0, -50),
          color: dropColor,
        ),
      );
    }

    _updateGameState();
  }

  void undoLastDrop() {
    if (dropHistory.isEmpty || _hasWon) return;

    // Undo is now a consumable helper
    if (!useHelper('undo')) return;

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

  void addExtraDrops() {
    if (_hasWon) return;
    if (!useHelper('extra_drops')) return;

    maxDrops += 5;
    dropsLimitReached.value = false;
    notifyListeners();
    _audio.playDrop(); // Or a specific powerup sound
  }

  void addHelpDrop() {
    if (_hasWon) return;

    final level = levelManager.currentLevel;
    final recipe =
        level.recipe; // Map<String, dynamic> {'red': 1, 'green': 2...}

    // Check which color is missing based on the recipe
    // We compare what we have dropped vs what is required
    // NOTE: This logic assumes the user is trying to match the EXACT recipe.
    // If they have already over-dropped a color, we might need to be smart,
    // but for now, let's just find the first deficient color.

    String? colorToDrop;

    // Helper to get deficiency
    int needed(String color, int current) {
      int required = (recipe[color] as int?) ?? 0;
      return (current < required) ? 1 : 0;
    }

    if (needed('red', rDrops) > 0)
      colorToDrop = 'red';
    else if (needed('green', gDrops) > 0)
      colorToDrop = 'green';
    else if (needed('blue', bDrops) > 0)
      colorToDrop = 'blue';
    else if (needed('white', whiteDrops) > 0)
      colorToDrop = 'white';
    else if (needed('black', blackDrops) > 0)
      colorToDrop = 'black';

    if (colorToDrop != null) {
      if (!useHelper('help_drop')) return;
      addDrop(colorToDrop);
    } else {
      // Recipe is effectively fulfilled by current counts (or over-fulfilled).
      // If we are not winning, maybe we have extra drops of other colors?
      // In that case, we can't really "help" by adding a needed drop because nothing is "needed" count-wise.
      // Maybe give a hint? or just do nothing.
      // For now, let's just return.
      debugPrint("Help Helper: No drops needed according to recipe counts.");
    }
  }

  /// Temporarily reveal the color in blind mode
  void revealHiddenColor() {
    if (!isBlindMode) return;
    if (!useHelper('reveal_color')) return;

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
        (rDrops +
            gDrops +
            bDrops +
            whiteDrops +
            blackDrops -
            _evaporationVisualOffset) /
        maxDrops;
    level = level.clamp(0.0, 1.0);

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
    _startLevelBgm(); // Start gameplay music

    if (currentMode == GameMode.colorEcho) {
      targetColor = ColorLogic.generateRandomHardColor();
      maxDrops = 15;
      isBlindMode = Random().nextBool(); // 50% chance of blind mode in echo
    } else if (currentMode == GameMode.chaosLab) {
      // Chaos Lab Mode: Unstable, random target colors
      targetColor = ColorLogic.generateRandomHardColor();
      maxDrops = 18;
      isBlindMode = false; // No blind mode in chaos - too chaotic already!
    } else {
      final level = levelManager.currentLevel;
      targetColor = level.targetColor;
      maxDrops = level.maxDrops;
      isBlindMode = level.isBlindMode;
    }

    // Master override: Blind Mode must be enabled in settings to be active in-game
    if (!globalBlindMode) {
      isBlindMode = false;
    }

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
    isColorBlindEvent = false;
    _evaporationVisualOffset = 0.0;
    _lastBeakerColor = Colors.transparent;

    // Remove any remaining fireworks
    children.whereType<Fireworks>().forEach((f) => f.removeFromParent());

    // Reset beaker visuals immediately
    beaker.isBlindMode = isBlindMode;
    beaker.clearContents();
    beaker.currentColor = Colors.white.withValues(alpha: .2);

    if (currentMode == GameMode.timeAttack) {
      final level = levelManager.currentLevel;
      // Base time scales with difficulty
      maxTime = 30.0 - (level.difficultyFactor * 10);
      maxTime = maxTime.clamp(10, 30);
      timeLeft = maxTime;
      isTimeUp = false;
    } else if (currentMode == GameMode.colorEcho) {
      // Echo mode also has time attack? Or unlimited?
      // User said "random hard target color", let's give it a generous but decreasing time if needed?
      // For now, let's make it unlimited time or a fixed 20s.
      timeLeft = 25.0;
      maxTime = 25.0;
      isTimeUp = false;
    } else {
      timeLeft = 0;
      isTimeUp = false;
    }

    // Clear any existing radar or spectral target
    children.whereType<HolographicRadar>().forEach((r) => r.removeFromParent());
    children.whereType<SpectralGhostTarget>().forEach(
      (s) => s.removeFromParent(),
    );

    // Clear any existing chaos effects
    children.whereType<GlitchEffect>().forEach((g) => g.removeFromParent());
    children.whereType<InvertedControlsEffect>().forEach(
      (i) => i.removeFromParent(),
    );
    children.whereType<EarthquakeVisualEffect>().forEach(
      (e) => e.removeFromParent(),
    );
    overlays.remove('Blackout');
    children.whereType<AcidSplatter>().forEach(
      (e) => e.removeFromParent(),
    ); // Remove Acid

    // Check beaker for unstable effect and steam
    beaker.children.whereType<UnstableBeakerEffect>().forEach(
      (u) => u.removeFromParent(),
    );
    beaker.children.whereType<SurfaceSteam>().forEach(
      (s) => s.removeFromParent(),
    );
    beaker.children.whereType<GravityFluxEffect>().forEach(
      (g) => g.removeFromParent(),
    );

    if (currentMode == GameMode.colorEcho) {
      add(HolographicRadar(position: beaker.position, radius: 130));
      add(
        SpectralGhostTarget(
          position: Vector2(size.x / 2, 120),
          targetColor: targetColor,
        ),
      );
      overlays.add('ColorEchoHUD');
      overlays.remove('Controls');
    } else if (currentMode == GameMode.chaosLab) {
      // Chaos Lab Mode: Unstable, random target colors
      // Start CLEAN - events will trigger periodically

      // Set chaos timer
      timeLeft = 120.0;
      maxTime = 120.0;
      isTimeUp = false;

      // Reset event timer to trigger first event after 20 seconds
      _eventTimer = 20.0;

      overlays.add('ChaosLabHUD');
      overlays.remove('Controls');
      overlays.remove('ColorEchoHUD');
    } else {
      overlays.remove('ColorEchoHUD');
      overlays.remove('ChaosLabHUD');
    }

    notifyListeners();
  }

  void _startLevelBgm() {
    String musicMode = 'classic';
    if (currentMode == GameMode.timeAttack) {
      musicMode = 'timeAttack';
    } else if (currentMode == GameMode.colorEcho) {
      musicMode = 'colorEcho';
    } else if (currentMode == GameMode.chaosLab) {
      musicMode = 'chaosLab'; // Will map to timeAttack in manager
    }
    _audio.playGameMusic(musicMode);
  }

  void goToNextLevel() {
    int stars = calculateStars();

    if (currentMode == GameMode.colorEcho) {
      overlays.remove('WinMenu');
      startLevel();
      notifyListeners();
      return;
    }

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
    int minDrops = (currentMode == GameMode.colorEcho)
        ? 7 // Arbitrary target for stars in random mode
        : levelManager.currentLevel.minDropsNeeded;

    // 3 stars: within 2 drops of optimal
    // 2 stars: within 5 drops of optimal
    // 1 star: completed
    if (drops <= minDrops + 2) return 3;
    if (drops <= minDrops + 5) return 2;
    return 1;
  }

  void selectModeAndStart(GameMode mode) {
    currentMode = mode;
    comboCount.value = 0; // Reset combo on mode change
    levelManager.currentMode = mode == GameMode.classic
        ? 'classic'
        : 'timeAttack';

    // Keep playing Menu music on Level Map for a "planning" phase
    _audio.playMenuMusic();

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
    LivesManager().consumeLife();
  }

  int totalStars = 0;
  List<BeakerType> unlockedSkins = [BeakerType.classic];

  void addCoins(int amount) {
    totalCoins.value += amount;
    SaveManager.saveTotalCoins(totalCoins.value);
    notifyListeners();
  }

  void buyOrSelectSkin(BeakerType type, int price) {
    if (unlockedSkins.contains(type)) {
      beaker.type = type; // Select skin
    } else if (totalCoins.value >= price) {
      totalCoins.value -= price;
      unlockedSkins.add(type);
      beaker.type = type;

      // Save new state
      SaveManager.saveTotalCoins(totalCoins.value);
      List<String> skinNames = unlockedSkins.map((e) => e.toString()).toList();
      SaveManager.savePurchasedSkins(skinNames);

      _audio.playUnlock();
    }
    notifyListeners();
  }

  Future<void> toggleBlindMode(bool enabled) async {
    globalBlindMode = enabled;
    await SaveManager.saveBlindMode(enabled);
    notifyListeners();
  }

  bool useHelper(String helperId) {
    final current = helperCounts.value[helperId] ?? 0;
    if (current > 0) {
      Map<String, int> newCounts = Map<String, int>.from(helperCounts.value);
      newCounts[helperId] = current - 1;
      helperCounts.value = newCounts;
      SaveManager.saveHelpers(newCounts);
      helpersUsedInLevel[helperId] = (helpersUsedInLevel[helperId] ?? 0) + 1;
      notifyListeners();
      return true;
    }
    return false;
  }

  void returnToMainMenu() {
    currentMode = GameMode.none;
    _audio.playMenuMusic();

    // Clear any temporary game overlays
    overlays.remove('PauseMenu');
    overlays.remove('GameOver');
    overlays.remove('WinMenu');
    overlays.remove('Controls');
    overlays.remove('LevelMap');
    overlays.remove('ColorEchoHUD');

    overlays.add('MainMenu');
    notifyListeners();
  }

  void addHelper(String helperId, int amount) {
    Map<String, int> newCounts = Map<String, int>.from(helperCounts.value);
    newCounts[helperId] = (newCounts[helperId] ?? 0) + amount;
    helperCounts.value = newCounts;
    SaveManager.saveHelpers(newCounts);
    notifyListeners();
  }

  void _checkAdvAchievements(int stars) async {
    final stats = await StatisticsManager.getAllStats();

    // Lab Survivor: 5 levels in Chaos Lab
    if (currentMode == GameMode.chaosLab &&
        stats['chaosLabPlays'] >= 5 &&
        !unlockedAchievements.contains('lab_survivor')) {
      _unlock('lab_survivor');
    }

    // Spectral Sync: 100% match in Color Echo
    if (currentMode == GameMode.colorEcho &&
        matchPercentage.value == 100 &&
        !unlockedAchievements.contains('spectral_sync')) {
      _unlock('spectral_sync');
    }

    // Master Chemist: Level 50 (index 49)
    if (levelManager.currentLevelIndex >= 49 &&
        !unlockedAchievements.contains('master_chemist')) {
      _unlock('master_chemist');
    }

    // Blind Master: 3 stars in Blind Mode
    if (beaker.isBlindMode &&
        stars == 3 &&
        !unlockedAchievements.contains('blind_master')) {
      _unlock('blind_master');
    }

    // Shopaholic: All 6 skins unlocked (classic, flask, magic, cylinder, hex, round)
    if (unlockedSkins.length >= 6 &&
        !unlockedAchievements.contains('shopaholic')) {
      _unlock('shopaholic');
    }

    // Stability Expert: Exactly one Stability Matrix used (extra_drops)
    if (helpersUsedInLevel['extra_drops'] == 1 &&
        !unlockedAchievements.contains('stability_expert')) {
      _unlock('stability_expert');
    }
  }

  void _unlock(String id) {
    if (!unlockedAchievements.contains(id)) {
      unlockedAchievements.add(id);
      SaveManager.saveAchievements(unlockedAchievements);
      overlays.add('Achievement');
    }
  }

  void _triggerRandomEvent() {
    // Prevent stacking
    if (isBlackout || isEvaporating || isControlsInverted || isUiGlitching)
      return;

    // Check for existing visual effects
    bool isEffectActive =
        children.whereType<GlitchEffect>().isNotEmpty ||
        children.whereType<InvertedControlsEffect>().isNotEmpty ||
        children.whereType<EarthquakeVisualEffect>().isNotEmpty ||
        beaker.children.whereType<SurfaceSteam>().isNotEmpty ||
        beaker.children.whereType<GravityFluxEffect>().isNotEmpty ||
        beaker.children.whereType<UnstableBeakerEffect>().isNotEmpty;

    if (isEffectActive) return;

    // Show visual warning
    add(AnomalyWarning());

    // Delay actual effect slightly
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (currentMode != GameMode.classic &&
          currentMode != GameMode.timeAttack &&
          currentMode != GameMode.chaosLab) {
        return;
      }

      // Select Event Type
      // 0-5: Visual Effects (Old)
      // 6: Blackout
      // 7: Evaporation
      // 8: Inverse Controls
      // 9: Glitchy UI
      // 10: Earthquake (Already implemented in logic)
      // 11: Color Blindness (NEW)
      // 12: Gravity Flux (NEW)

      int eventType = _random.nextInt(13);

      // Determine duration based on mode
      double duration;
      if (currentMode == GameMode.chaosLab) {
        duration = 6.0 + _random.nextDouble() * 4.0; // 6-10 seconds
      } else {
        duration = 8.0 + _random.nextDouble() * 4.0; // 8-12 seconds
      }

      switch (eventType) {
        case 6: // Blackout
          isBlackout = true;
          add(BlackoutEffect());
          overlays.add('Blackout');
          _audio.playAlarm(); // Or specific power down sound
          break;
        case 7: // Evaporation
          isEvaporating = true;
          beaker.add(SurfaceSteam(beaker: beaker));
          _audio.playSteam();
          break;
        case 10: // Earthquake
          isEarthquake = true;
          add(EarthquakeVisualEffect());
          break;
        case 8: // Inverse Controls
          isControlsInverted = true;
          add(InvertedControlsEffect());
          // add(GlitchEffect()); // Visual indicator on screen too
          _audio.playGlitch();
          break;
        case 12: // Gravity Flux (NEW)
          isGravityFlux = true;
          beaker.add(GravityFluxEffect());
          // _audio.playGlitch();
          break;
        case 9: // Glitchy UI
          isUiGlitching = true;
          add(GlitchEffect());
          _audio.playGlitch();
          break;
        case 11: // Color Blindness
          isColorBlindEvent = true;
          beaker.isBlindMode = true;
          _audio.playSteam(); // Reuse a "digital shift" sound or steam
          break;
        default: // Visual Effects (Old)
          final effects = [
            () => add(GlitchEffect()),
            () => beaker.add(UnstableBeakerEffect()),
          ];
          effects[eventType % effects.length]();
          break;
      }

      notifyListeners(); // Update UI for flags

      // Auto-remove effect
      Future.delayed(Duration(milliseconds: (duration * 1000).toInt()), () {
        // Reset Logic Flags
        isBlackout = false;
        isEvaporating = false;
        _evaporationVisualOffset = 0.0;
        isControlsInverted = false;
        isUiGlitching = false;
        isColorBlindEvent = false;
        isGravityFlux = false;
        beaker.isBlindMode = isBlindMode; // Restore from level setting

        overlays.remove('Blackout');
        notifyListeners();

        if (currentMode != GameMode.chaosLab) {
          // Cleanup Components
          children.whereType<BlackoutEffect>().forEach(
            (e) => e.removeFromParent(),
          );
          children.whereType<GlitchEffect>().forEach(
            (g) => g.removeFromParent(),
          );
          children.whereType<InvertedControlsEffect>().forEach(
            (i) => i.removeFromParent(),
          );
          children.whereType<EarthquakeVisualEffect>().forEach(
            (e) => e.removeFromParent(),
          );
          children.whereType<AcidSplatter>().forEach(
            (e) => e.removeFromParent(),
          );
          beaker.children.whereType<SurfaceSteam>().forEach(
            (s) => s.removeFromParent(),
          );
          beaker.children.whereType<GravityFluxEffect>().forEach(
            (g) => g.removeFromParent(),
          );
          beaker.children.whereType<UnstableBeakerEffect>().forEach(
            (u) => u.removeFromParent(),
          );
        }
      });
    });
  }
}

class AnomalyWarning extends PositionComponent with HasGameRef<ColorMixerGame> {
  late TextComponent _text;
  double _timer = 0;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    position = Vector2(gameRef.size.x / 2, gameRef.size.y * 0.2);
    anchor = Anchor.center;

    _text = TextComponent(
      text: AppStrings.anomalyDetected.getString(gameRef.buildContext!),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.redAccent,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 4.0,
          shadows: [
            Shadow(color: Colors.red, blurRadius: 10, offset: Offset(0, 0)),
          ],
        ),
      ),
      anchor: Anchor.center,
    );

    add(_text);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;

    // Pulse effect
    _text.scale = Vector2.all(1.0 + sin(_timer * 10) * 0.1);
    _text.textRenderer = TextPaint(
      style:
          const TextStyle(
            color: Colors.redAccent,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 4.0,
            shadows: [
              Shadow(color: Colors.red, blurRadius: 10, offset: Offset(0, 0)),
            ],
          ).copyWith(
            color: Colors.redAccent.withValues(
              alpha: (sin(_timer * 15) + 1) / 2,
            ),
          ),
    );

    // Remove after 2 seconds
    if (_timer >= 2.0) {
      removeFromParent();
    }
  }
}
