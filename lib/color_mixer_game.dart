import 'package:color_mixing_deductive/core/ad_manager.dart';
import 'package:color_mixing_deductive/helpers/daily_challenge_manager.dart';
import 'package:color_mixing_deductive/components/particles/ambient_particles.dart';
import 'package:color_mixing_deductive/components/environment/background_gradient.dart';
import 'package:color_mixing_deductive/components/environment/pattern_background.dart';
import 'package:color_mixing_deductive/components/gameplay/beaker.dart';
import 'package:color_mixing_deductive/components/particles/mix_particles.dart';
import 'package:color_mixing_deductive/components/particles/particles.dart';
import 'package:color_mixing_deductive/components/gameplay/pouring_effect.dart';
import 'package:color_mixing_deductive/components/effects/fireworks.dart';
import 'package:color_mixing_deductive/components/gameplay/holographic_radar.dart';
import 'package:color_mixing_deductive/components/gameplay/spectral_target.dart';
import 'package:color_mixing_deductive/components/particles/echo_particles.dart';
import 'package:color_mixing_deductive/components/effects/glitch_effect.dart';
import 'package:color_mixing_deductive/components/effects/blackout_effect.dart';
import 'package:color_mixing_deductive/components/effects/unstable_beaker_effect.dart';
import 'package:color_mixing_deductive/components/effects/acid_splatter.dart';
import 'package:color_mixing_deductive/components/environment/surface_steam.dart';
import 'package:color_mixing_deductive/components/effects/gravity_flux_effect.dart';
import 'package:color_mixing_deductive/core/lab_catalog.dart';
import 'package:color_mixing_deductive/components/environment/beaker_stand.dart';
import 'package:color_mixing_deductive/components/environment/string_lights.dart';
import 'package:color_mixing_deductive/components/effects/inverted_controls_effect.dart';
import 'package:color_mixing_deductive/components/effects/earthquake_visual_effect.dart';
import 'package:color_mixing_deductive/core/season_pass_manager.dart';
import 'package:color_mixing_deductive/core/vip_manager.dart';
import 'package:color_mixing_deductive/components/effects/mirror_distortion_effect.dart';
import 'package:color_mixing_deductive/components/effects/wind_force_effect.dart';
import 'package:color_mixing_deductive/components/effects/leaking_beaker_effect.dart';
import 'package:color_mixing_deductive/components/effects/chromatic_aberration_effect.dart';
import 'package:color_mixing_deductive/components/effects/electrical_sparks.dart';
import 'package:color_mixing_deductive/components/effects/emergency_lights.dart';
import 'package:color_mixing_deductive/components/effects/cracked_glass_overlay.dart';
import 'package:color_mixing_deductive/core/color_logic.dart';
import 'package:color_mixing_deductive/core/level_manager.dart';
import 'package:color_mixing_deductive/core/save_manager.dart';
import 'package:color_mixing_deductive/core/coin_store.dart';
import 'package:color_mixing_deductive/core/lives_manager.dart';
import 'package:color_mixing_deductive/core/xp_manager.dart';
import 'package:color_mixing_deductive/core/card_collection_manager.dart';
import 'package:color_mixing_deductive/core/achievement_engine.dart';
import 'package:color_mixing_deductive/core/adaptive_difficulty.dart';
import 'package:color_mixing_deductive/helpers/audio_manager.dart';
import 'package:color_mixing_deductive/helpers/event_rarity_system.dart';
import 'package:color_mixing_deductive/helpers/haptic_manager.dart';
import 'package:color_mixing_deductive/helpers/statistics_manager.dart';
import 'package:color_mixing_deductive/helpers/tournament_manager.dart';
import 'dart:math';
import 'dart:async';
import 'package:flame/game.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';

enum GameMode { classic, timeAttack, colorEcho, chaosLab, tournament, none }

// ═══════════════════════════════════════════════════════════════════════════
// CHAOS LAB CONSTANTS
// ═══════════════════════════════════════════════════════════════════════════
// Base stability decay per second (0.3% of stability lost each second)
const double _chaosBaseDecayRate = 0.003;
// Additional decay per round completed (0.1% per round)
const double _chaosRoundDecayFactor = 0.001;
// Instability multiplier - decay increases as stability drops (0.8% per 1% lost)
const double _chaosInstabilityMultiplier = 0.008;
// Phase thresholds
const double _chaosPhaseStableThreshold = 0.7;   // Above 70% = STABLE
const double _chaosPhaseCautionThreshold = 0.4;  // 40-70% = CAUTION
// Event timing
const double _chaosEventMinInterval = 5.0;       // Minimum seconds between events
const double _chaosEventMaxInterval = 20.0;      // Maximum seconds between events
// ═══════════════════════════════════════════════════════════════════════════

class ColorMixerGame extends FlameGame with ChangeNotifier {
  late Beaker beaker;
  late Color targetColor;
  bool _hasWon = false;
  bool _hasLost = false;
  bool _isTransitioning = false;
  int rDrops = 0, gDrops = 0, bDrops = 0;
  int whiteDrops = 0, blackDrops = 0;
  bool isBlindMode = false;

  // Disaster State
  bool isMirrored = false;
  bool hasWind = false;
  double windForce = 0;
  double chaosStability = 1.0;
  bool isLeaking = false;
  bool isBlackout = false;
  bool isEvaporating = false;
  bool isControlsInverted = false;
  bool isUiGlitching = false;
  bool isEarthquake = false;
  bool isColorBlindEvent = false;
  bool isGravityFlux = false;

  // New positive events
  bool isTimeFreeze = false;
  bool isDoubleCoinActive = false;

  // Echo Mode — Progressive Difficulty & Scoring
  int echoRound = 0;
  double echoScore = 0.0;
  int echoStreak = 0;
  final ValueNotifier<bool> echoAlmostSync = ValueNotifier<bool>(false);

  // Chaos Mode — Phase System & Stability Recovery
  int chaosRound = 0;
  double _previousMatchPct = 0.0;
  final ValueNotifier<String> chaosPhase = ValueNotifier<String>('STABLE');
  final ValueNotifier<bool> stabilityRecovered = ValueNotifier<bool>(false);

  /// Returns true if the user is actively playing a level.
  bool get isActivelyPlayingLevel {
    if (_hasWon || _hasLost) return false;

    // If any of these menus are open, we are not actively playing
    final nonPlayOverlays = [
      'MainMenu',
      'PauseMenu',
      'Settings',
      'LevelMap',
      'Shop',
      'Gallery',
      'ModeGuide',
      'Statistics',
      'DailyChallenge',
      'DailyLogin',
      'LabUpgrade',
      'RandomEventAlert', // Also don't decrement while the alert is playing
      'IntroSplash',
    ];

    for (final overlay in nonPlayOverlays) {
      if (overlays.isActive(overlay)) return false;
    }

    // Must be in a mode that has a HUD active (or Tutorial)
    return overlays.isActive('Controls') ||
        overlays.isActive('ColorEchoHUD') ||
        overlays.isActive('ChaosLabHUD') ||
        overlays.isActive('Tutorial');
  }

  // --- Particle Settings
  int currentLevelIndex = 0;
  final Random _random = Random();
  Random get random => _random;

  int maxDrops = 20;
  final LevelManager levelManager = LevelManager();
  final AudioManager _audio = AudioManager();

  // Mode States
  GameMode currentMode = GameMode.none;
  double timeLeft = 30.0;
  double maxTime = 30.0; // Added for progress calculation
  bool isTimeUp = false;

  // Hint System
  final ValueNotifier<String?> currentHint = ValueNotifier<String?>(null);
  bool hasUsedHint = false;
  final int hintCost = 50;

  final ValueNotifier<double> matchPercentage = ValueNotifier<double>(0.0);
  final ValueNotifier<int> totalDrops = ValueNotifier<int>(0);
  int lastEarnedCoins = 0; // For UI synchronization
  bool randomEventBonusApplied = false;
  final ValueNotifier<bool> dropsLimitReached = ValueNotifier<bool>(false);
  final ValueNotifier<int> totalCoins = ValueNotifier<int>(0);
  final ValueNotifier<Map<String, int>> helperCounts =
      ValueNotifier<Map<String, int>>({});

  DateTime _levelStartTime = DateTime.now();
  double _winTimer = -1.0;
  Completer<void>? _winAnimationCompleter;

  // Combo System
  final ValueNotifier<int> comboCount = ValueNotifier<int>(0);
  int highestCombo = 0;
  final Map<String, int> helpersUsedInLevel = {}; // New field

  int totalStars = 0;
  Color _lastBeakerColor = Colors.transparent;

  static const double _dropCooldown = 1.0;
  double _dropCooldownTimer = 0.0;
  final ValueNotifier<double> dropCooldownProgress = ValueNotifier(1.0);

  int _lastNotifiedTime = -1;
  double _lastNotifiedMatch = -1.0;
  double _winCheckTimer = 0.0;
  static const double _winCheckInterval = 0.1; // Check win every 100ms

  // Win Menu specific state
  int winPreviousLevel = 0;
  int winPreviousXp = 0;
  int winXpEarned = 0;
  // ──────────────────────────────────────────────────────────────────────────
  // Achievements & Rewards
  // ──────────────────────────────────────────────────────────────────────────
  final List<AchievementDef> achievementQueue = [];
  final ValueNotifier<String?> rewardNotification = ValueNotifier(null);

  CardDef? winUnlockedCard;

  late BackgroundGradient backgroundGradient;
  late AmbientParticles ambientParticles;
  late PatternBackground patternBackground;
  BeakerStand? beakerStand;
  StringLights? stringLights;
  bool globalBlindMode = false;
  bool reducedMotionEnabled = false;

  List<BeakerType> unlockedSkins = [BeakerType.classic];

  // Random Events State
  bool randomEventsEnabled = false;
  double _eventTimer = 0;

  // Random Event States
  double _evaporationVisualOffset = 0.0; // Visual level to subtract

  // Active event tracking (for HUD badge)
  final ValueNotifier<EventConfig?> pendingEvent = ValueNotifier<EventConfig?>(
    null,
  );
  final ValueNotifier<String?> activeEventLabel = ValueNotifier<String?>(null);
  final ValueNotifier<double> activeEventProgress = ValueNotifier<double>(0.0);
  final ValueNotifier<double> loadingProgress = ValueNotifier<double>(0.0);
  double _activeEventDuration = 0.0;
  double _activeEventElapsed = 0.0;
  bool _randomEventOccurredThisLevel = false;
  bool _cardDroppedThisLevel = false;

  /// Incremented each time a level starts. Used to cancel stale [Future.delayed]
  /// callbacks from random events that were triggered in a previous session.
  int _levelSession = 0;

  bool get isAnyRandomEventActive =>
      isBlackout ||
      isEvaporating ||
      isControlsInverted ||
      isUiGlitching ||
      isEarthquake ||
      isColorBlindEvent ||
      isGravityFlux ||
      isMirrored ||
      hasWind ||
      isTimeFreeze ||
      isDoubleCoinActive;

  // Earthquake shake offset
  Vector2 _earthquakeOffset = Vector2.zero();
  Vector2 get earthquakeOffset => _earthquakeOffset;

  void Function(VoidCallback, {bool isReverse})? _transitionCallback;

  void setTransitionCallback(
    void Function(VoidCallback, {bool isReverse}) callback,
  ) {
    _transitionCallback = callback;
  }

  void transitionTo(
    String overlayToRemove,
    String overlayToAdd, {
    bool isReverse = false,
    VoidCallback? midpointAction,
  }) {
    if (_isTransitioning) return;
    _isTransitioning = true;

    if (_transitionCallback != null) {
      _transitionCallback!(() {
        if (overlayToRemove.isNotEmpty) overlays.remove(overlayToRemove);
        midpointAction?.call();
        if (overlayToAdd.isNotEmpty) overlays.add(overlayToAdd);
        _isTransitioning = false;
      }, isReverse: isReverse);
    } else {
      if (overlayToRemove.isNotEmpty) overlays.remove(overlayToRemove);
      midpointAction?.call();
      if (overlayToAdd.isNotEmpty) overlays.add(overlayToAdd);
      _isTransitioning = false;
    }
  }

  void transitionToLevel(int index) {
    transitionTo(
      'LevelMap',
      'Controls',
      midpointAction: () {
        levelManager.currentLevelIndex = index;
        startLevel();
      },
    );
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Register Ad Lifecycle Callbacks to pause/resume game
    AdManager().onAdOpened = () {
      debugPrint('Game paused for Ad');
      paused = true;
    };
    AdManager().onAdClosed = () {
      debugPrint('Game resumed after Ad');
      paused = false;
    };

    // تحميل التقدم المحفوظ من الهاتف
    // تحميل التقدم المحفوظ من الهاتف
    await levelManager.initProgress();
    loadingProgress.value = 0.1;
    await LivesManager().init();
    loadingProgress.value = 0.2;
    totalStars = await SaveManager.loadTotalStars();
    totalCoins.value = await SaveManager.loadTotalCoins();
    globalBlindMode = await SaveManager.loadBlindMode();
    reducedMotionEnabled = await SaveManager.loadReducedMotion();
    randomEventsEnabled = await SaveManager.loadRandomEvents();
    loadingProgress.value = 0.3;

    // ── Phase 1: Init meta-progression systems ──────────────────────────────
    await XpManager.instance.init();
    XpManager.instance.attachGame(this);
    final savedAchievements = await SaveManager.loadAchievements();
    await AchievementEngine.instance.init(savedAchievements);
    await AdaptiveDifficulty.instance.init();
    // ────────────────────────────────────────────────────────────────────────

    CoinStoreService.instance.attachGame(this);
    CoinStoreService.instance.initialize();
    loadingProgress.value = 0.4;

    // Load helpers
    final savedHelpers = await SaveManager.loadHelpers();
    helperCounts.value = Map<String, int>.from(savedHelpers);
    loadingProgress.value = 0.5;

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
    loadingProgress.value = 0.6;

    // Load Lab Configuration
    final labConfig = await SaveManager.loadLabConfig();

    // Get Lab Items
    final bgItem = LabCatalog.getItemByCategory(
      'background',
      labConfig['background'] ?? 'bg_default',
    );
    final lightItem = LabCatalog.getItemByCategory(
      'lighting',
      labConfig['lighting'] ?? 'light_basic',
    );
    final surfaceItem = LabCatalog.getItemByCategory(
      'surface',
      labConfig['surface'] ?? 'surface_steel',
    );
    final standItem = LabCatalog.getItemByCategory(
      'stand',
      labConfig['stand'] ?? 'stand_basic',
    );
    final lightsItem = LabCatalog.getItemByCategory(
      'string_lights',
      labConfig['string_lights'] ?? 'lights_none',
    );
    loadingProgress.value = 0.8;

    // Add background gradient first (rendered first)
    backgroundGradient = BackgroundGradient(
      configColors: bgItem?.gradientColors,
    );
    add(backgroundGradient);

    // Add pattern overlay
    patternBackground = PatternBackground(config: surfaceItem);
    add(patternBackground);

    // Add ambient particles for atmosphere
    ambientParticles = AmbientParticles(
      configColors: lightItem?.gradientColors,
    );
    add(ambientParticles);
    loadingProgress.value = 1.0;

    // Add string lights
    stringLights = StringLights(
      size: Vector2(size.x, 200),
      currentConfig: lightsItem,
    );
    add(stringLights!);

    // Position Beaker slightly above center to make room for bottom controls
    final beakerPos = Vector2(size.x / 2, size.y * 0.54);

    // Add Beaker Stand (Behind Beaker)
    if (standItem != null) {
      beakerStand = BeakerStand(
        position: Vector2(
          beakerPos.x,
          beakerPos.y + 110,
        ), // Offset to be under beaker
        size: Vector2(200, 60),
        config: standItem,
      );
      add(beakerStand!);
    }

    // Position Beaker slightly above center to make room for bottom controls
    beaker = Beaker(position: beakerPos, size: Vector2(180, 250));

    // Load persisted skin
    final selectedSkinName = await SaveManager.loadSelectedSkin();
    if (selectedSkinName != null) {
      beaker.type = BeakerType.values.firstWhere(
        (e) => e.toString() == selectedSkinName,
        orElse: () => BeakerType.classic,
      );
    }

    add(beaker);

    // Start music for Main Menu (Classic/Menu BGM)
    _audio.playMenuMusic();

    targetColor = Colors.transparent; // Set placeholder color until game starts
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_winTimer > 0) {
      _winTimer -= dt;
      if (_winTimer <= 0) {
        _winTimer = -1.0;
        if (_winAnimationCompleter != null &&
            !_winAnimationCompleter!.isCompleted) {
          _winAnimationCompleter!.complete();
        }
      }
    }

    if (_dropCooldownTimer > 0) {
      _dropCooldownTimer -= dt;
      if (_dropCooldownTimer < 0) _dropCooldownTimer = 0;
      dropCooldownProgress.value = 1.0 - (_dropCooldownTimer / _dropCooldown);
    } else if (dropCooldownProgress.value < 1.0) {
      dropCooldownProgress.value = 1.0;
    }

    if ((currentMode == GameMode.timeAttack ||
            currentMode == GameMode.colorEcho ||
            currentMode == GameMode.chaosLab) &&
        !_hasWon) {
      // Only decrease time if not frozen
      if (!isTimeFreeze) {
        timeLeft -= dt;
      }

      // Chaos Stability Decay - Accelerates as stability drops
      if (currentMode == GameMode.chaosLab) {
        // Dynamic decay: base + round scaling + instability multiplier
        double decayRate = _chaosBaseDecayRate +
            (chaosRound * _chaosRoundDecayFactor) +
            ((1.0 - chaosStability) * _chaosInstabilityMultiplier);
        chaosStability -= decayRate * dt;
        if (chaosStability < 0) chaosStability = 0;

        if (chaosStability <= 0 && !_hasWon && !_hasLost) {
          _handleGameOver();
        }

        // Update chaos phase based on stability thresholds
        if (chaosStability > _chaosPhaseStableThreshold) {
          chaosPhase.value = 'STABLE';
        } else if (chaosStability > _chaosPhaseCautionThreshold) {
          chaosPhase.value = 'CAUTION';
        } else {
          chaosPhase.value = 'CRITICAL';
        }
      }

      if (timeLeft <= 0) {
        isTimeUp = true;
        _handleGameOver();
      }

      // Throttled notification: only if time (int) or match percentage (significant delta) changes
      bool shouldNotify = false;
      if (timeLeft.toInt() != _lastNotifiedTime) {
        _lastNotifiedTime = timeLeft.toInt();
        shouldNotify = true;
      }
      if ((matchPercentage.value - _lastNotifiedMatch).abs() >= 0.1) {
        _lastNotifiedMatch = matchPercentage.value;
        shouldNotify = true;
      }

      if (shouldNotify) notifyListeners();
    }

    // Earthquake Logic
    if (isEarthquake && !_hasWon) {
      // Simple random shake
      double intensity = reducedMotionEnabled ? 0.5 : 5.0;
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
        if (dropHistory.isNotEmpty) {
          final evaporatedDrop = dropHistory.removeAt(0);
          if (evaporatedDrop == 'red' && rDrops > 0) {
            rDrops--;
          } else if (evaporatedDrop == 'green' && gDrops > 0) {
            gDrops--;
          } else if (evaporatedDrop == 'blue' && bDrops > 0) {
            bDrops--;
          } else if (evaporatedDrop == 'white' && whiteDrops > 0) {
            whiteDrops--;
          } else if (evaporatedDrop == 'black' && blackDrops > 0) {
            blackDrops--;
          }

          _audio.playSteam(); // Sound effect
          if (dropHistory.isEmpty) {
            _handleGameOver();
          }
        } else if (totalDrops.value > 0) {
          if (rDrops > 0) {
            rDrops--;
          } else if (gDrops > 0) {
            gDrops--;
          } else if (bDrops > 0) {
            bDrops--;
          } else if (whiteDrops > 0) {
            whiteDrops--;
          } else if (blackDrops > 0) {
            blackDrops--;
          }

          _audio.playSteam(); // Sound effect
          if (rDrops + gDrops + bDrops + whiteDrops + blackDrops == 0) {
            _handleGameOver();
          }
        }
      }
      _updateGameState(); // Update visuals every frame during evaporation
    }

    // Random Events Logic (Chaos Director)
    if (isActivelyPlayingLevel) {
      if (currentMode == GameMode.chaosLab && !_hasWon) {
        _eventTimer -= dt;
        if (_eventTimer <= 0) {
          _triggerChaosMeltdown();
          // Stability based frequency: more events as stability drops
          // Range: 5-20 seconds based on stability (lower stability = more frequent)
          _eventTimer = _chaosEventMinInterval +
              (chaosStability *
                  (_chaosEventMaxInterval - _chaosEventMinInterval));
        }
      } else if (randomEventsEnabled &&
          (currentMode == GameMode.classic ||
              currentMode == GameMode.timeAttack) &&
          !_hasWon) {
        _eventTimer -= dt;
        if (_eventTimer <= 0) {
          _triggerRandomEvent();
          _eventTimer = 10.0 + _random.nextDouble() * 5.0;
        }
      }

      // Active event progress tracking for HUD badge
      if (isAnyRandomEventActive &&
          _activeEventDuration > 0 &&
          (currentMode == GameMode.classic ||
              currentMode == GameMode.timeAttack)) {
        _activeEventElapsed += dt;
        activeEventProgress.value =
            1.0 - (_activeEventElapsed / _activeEventDuration).clamp(0.0, 1.0);
      }
    }

    // Throttled win condition check ONLY if color changed
    if (!_hasWon &&
        !_isTransitioning &&
        beaker.currentColor != _lastBeakerColor) {
      _winCheckTimer += dt;
      if (_winCheckTimer >= _winCheckInterval) {
        _winCheckTimer = 0.0;
        _lastBeakerColor = beaker.currentColor;
        if (ColorLogic.checkMatch(beaker.currentColor, targetColor) >= 93.0 &&
            _isRecipeIngredientsFulfilled()) {
          _hasWon = true;
          showWinEffect();
        }
      }
    } else {
      _winCheckTimer = 0.0;
    }
  }

  @override
  void onRemove() {
    _audio.dispose();
    disposeRandomEvents(); // Call disposeRandomEvents on game removal
    super.onRemove();
  }

  void disposeRandomEvents() {
    // Reset Logic Flags
    isBlackout = false;
    isEvaporating = false;
    _evaporationVisualOffset = 0.0;
    isControlsInverted = false;
    isUiGlitching = false;
    isColorBlindEvent = false;
    isGravityFlux = false;
    isEarthquake = false;
    isTimeFreeze = false;
    isDoubleCoinActive = false;
    _randomEventOccurredThisLevel = false;
    _earthquakeOffset = Vector2.zero();

    // Restore beaker state from current level setting
    beaker.isBlindMode = isBlindMode;

    // Reset HUD
    activeEventLabel.value = null;
    activeEventProgress.value = 0.0;
    _activeEventDuration = 0.0;
    _activeEventElapsed = 0.0;
    pendingEvent.value = null;

    overlays.remove('Blackout');
    overlays.remove('RandomEventAlert');

    // Cleanup Components
    children.whereType<BlackoutEffect>().forEach((e) => e.removeFromParent());
    children.whereType<GlitchEffect>().forEach((g) => g.removeFromParent());
    children.whereType<InvertedControlsEffect>().toList().forEach(
      (i) => i.removeFromParent(),
    );
    children.whereType<EarthquakeVisualEffect>().toList().forEach(
      (e) => e.removeFromParent(),
    );
    children.whereType<AcidSplatter>().toList().forEach(
      (e) => e.removeFromParent(),
    );
    children.whereType<MirrorDistortionEffect>().toList().forEach(
      (e) => e.removeFromParent(),
    );
    children.whereType<WindForceEffect>().toList().forEach(
      (e) => e.removeFromParent(),
    );
    children.whereType<LeakingBeakerEffect>().toList().forEach(
      (e) => e.removeFromParent(),
    );
    children.whereType<ChromaticAberrationEffect>().toList().forEach(
      (e) => e.removeFromParent(),
    );

    beaker.children.whereType<SurfaceSteam>().toList().forEach(
      (s) => s.removeFromParent(),
    );
    beaker.children.whereType<GravityFluxEffect>().toList().forEach(
      (g) => g.removeFromParent(),
    );
    beaker.children.whereType<UnstableBeakerEffect>().toList().forEach(
      (u) => u.removeFromParent(),
    );

    notifyListeners();
  }

  Future<void> showWinEffect() async {
    if (overlays.isActive('WinMenu')) return;

    _winAnimationCompleter = Completer<void>();
    _winTimer = 1.5; // Start the visual delay immediately

    disposeRandomEvents();

    _audio.playWin();

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

    // Evaluated via AchievementEngine in Phase 2

    // Evaluate Daily Challenge Logic
    _evaluateDailyChallenges(stars);

    // Check for Level 10 rewards
    _checkLevelReward();

    // Factor in mode-specific base rewards
    int baseCoins = 0;
    if (currentMode == GameMode.classic || currentMode == GameMode.timeAttack) {
      if (stars == 3) {
        baseCoins = 100;
      } else if (stars == 2) {
        baseCoins = 50;
      } else if (stars == 1) {
        baseCoins = 20;
      }
    } else {
      baseCoins = stars * 10; // Default fallback
    }

    int comboMultiplier = 1;
    if (comboCount.value >= 10) {
      comboMultiplier = 5;
    } else if (comboCount.value >= 5) {
      comboMultiplier = 3;
    } else if (comboCount.value >= 3) {
      comboMultiplier = 2;
    }
    int bonusCoins = (baseCoins * (comboMultiplier - 1)).toInt();
    int totalAwarded = baseCoins + bonusCoins;

    // Apply Random Event Bonus (1.3x) if enabled and occurred
    if (randomEventsEnabled && _randomEventOccurredThisLevel) {
      totalAwarded = (totalAwarded * 1.3).round();
      randomEventBonusApplied = true;
    } else {
      randomEventBonusApplied = false;
    }

    lastEarnedCoins = totalAwarded;
    await addCoins(totalAwarded);

    // Save progress immediately
    if (currentMode == GameMode.classic || currentMode == GameMode.timeAttack) {
      levelManager.unlockNextLevel(levelManager.currentLevelIndex, stars);
    }

    // Track statistics (Phase 1 extended)
    StatisticsManager.incrementLevelsCompleted();
    if (stars == 3) {
      StatisticsManager.incrementPerfectMatches();
    }
    if (currentMode == GameMode.classic) {
      StatisticsManager.incrementClassicLevelsCompleted();
    } else if (currentMode == GameMode.timeAttack) {
      StatisticsManager.incrementTimeAttackWins();
    }
    StatisticsManager.recordLevelHintStatus(
      usedHint: hasUsedHint,
      wasClassicPerfect:
          currentMode == GameMode.classic && stars == 3 && !hasUsedHint,
    );
    StatisticsManager.updateHighestCombo(comboCount.value);
    StatisticsManager.addDropsUsed(totalDrops.value);
    StatisticsManager.incrementModePlay(currentMode);

    // ── Phase 1: XP + Achievement Engine ─────────────────────────────────
    // Store previous state for Win Menu
    winPreviousLevel = XpManager.instance.playerLevel.value;
    winPreviousXp = XpManager.instance.currentXp.value;

    // Award XP and wait for it
    winXpEarned = await XpManager.instance.addXpForWin(
      stars: stars,
      mode: currentMode,
      comboCount: comboCount.value,
    );

    // ── Phase 2: Season Pass XP Feed ─────────────────────────────────────
    if (winXpEarned > 0) {
      SeasonPassManager.instance.addPassXp(winXpEarned);
    }

    // Record adaptive difficulty outcome (only for classic levelled mode)
    if (currentMode == GameMode.classic) {
      AdaptiveDifficulty.instance.recordOutcome(won: true);
    }

    // Run achievement engine check
    final stats = await StatisticsManager.getAllStats();
    final discoveredColors = await SaveManager.loadDiscoveredColors();
    final totalSpent = await SaveManager.loadTotalSpent();
    final dailyCount = await SaveManager.loadDailyChallengeCount();

    final ctx = AchievementContext(
      stars: stars,
      totalLevelsCompleted: stats['totalLevels'] ?? 0,
      classicLevelsCompleted: stats['classicLevelsCompleted'] ?? 0,
      totalDropsUsed: stats['totalDrops'] ?? 0,
      dropsUsedThisLevel: totalDrops.value,
      hasUsedHint: hasUsedHint,
      totalStars: totalStars,
      playerLevel: XpManager.instance.playerLevel.value,
      prestigeCount: XpManager.instance.prestigeCount.value,
      highestCombo: comboCount.value > highestCombo
          ? comboCount.value
          : highestCombo,
      timeAttackWins: stats['timeAttackWins'] ?? 0,
      echoRound: echoRound,
      chaosRound: chaosRound,
      hasPlayedAllModes: stats['hasPlayedAllModes'] ?? false,
      levelsWithoutHints: stats['levelsWithoutHints'] ?? 0,
      classicPerfectNoHints: stats['classicPerfectNoHints'] ?? 0,
      totalCoins: totalCoins.value,
      loginStreak: stats['loginStreak'] ?? 0,
      wonWithActiveEvent: isAnyRandomEventActive,
      wonDuringBlackout: isBlackout,
      chaosLabPlays: stats['chaosLabPlays'] ?? 0,
      matchPercentage: matchPercentage.value,
      currentLevelIndex: levelManager.currentLevelIndex,
      isBlindMode: beaker.isBlindMode,
      unlockedSkinsCount: unlockedSkins.length,
      extraDropsUsed: helpersUsedInLevel['extra_drops'] ?? 0,
      levelDuration: DateTime.now().difference(_levelStartTime),
      discoveredColorsCount: discoveredColors.length,
      totalSpent: totalSpent,
      dailyChallengeCount: dailyCount,
      chaosStability: chaosStability,
      has10OfEachHelper:
          helperCounts.value.values.every((v) => v >= 10) &&
          helperCounts.value.length == 4,
      minDropsNeeded: levelManager.currentLevel.minDropsNeeded,
    );

    AchievementEngine.instance.check(ctx).then((newIds) {
      if (newIds.isNotEmpty && isMounted) {
        for (final id in newIds) {
          final def = AchievementCatalog.byId(id);
          if (def != null) {
            achievementQueue.add(def);
          }
        }
        _showNextAchievement();
      }
    });
    // ───────────────────────────────────────────────────────────────────────

    // Phase 1: Card Collection Drop
    winUnlockedCard = null;
    if (!_cardDroppedThisLevel &&
        (stars == 3 || currentMode != GameMode.classic)) {
      if (Random().nextDouble() > 0.6) {
        // 40% chance drop
        _cardDroppedThisLevel = true;
        winUnlockedCard = await CardCollectionManager.instance.dropRandomCard();
      }
    }

    // Wait for the visual timer to complete if it hasn't already
    if (_winTimer > 0 &&
        _winAnimationCompleter != null &&
        !_winAnimationCompleter!.isCompleted) {
      await _winAnimationCompleter!.future;
    }

    _executeWinTransition();
  }

  Future<void> _executeWinTransition() async {
    if (!isMounted) return;

    if (currentMode == GameMode.colorEcho) {
      // Echo scoring: reward efficiency (fewer drops = more points)
      echoScore += matchPercentage.value * (maxDrops - totalDrops.value + 1);
      echoRound++;
      echoStreak++;

      // Base 50, Streak 1.0x multiplier
      int echoCoins = (50 * (1 + echoStreak * 1.0)).toInt();
      lastEarnedCoins = echoCoins;
      await addCoins(echoCoins);

      // Milestone reward
      if (echoStreak % 5 == 0) {
        _grantRandomHelper();
      }

      overlays.add('EchoWin');
    } else if (currentMode == GameMode.chaosLab) {
      // Chaos base 50 + 10x per round depth
      int chaosBaseCoins = 50 + (chaosRound * 10);
      int chaosBonus = (chaosBaseCoins * chaosStability).toInt();
      lastEarnedCoins = chaosBaseCoins + chaosBonus;
      await addCoins(lastEarnedCoins);
      chaosRound++;

      // Chaos Survivor bonus
      if (chaosStability < 0.3) {
        _grantRandomHelper();
      }

      overlays.add('ChaosWin');
    } else if (currentMode == GameMode.tournament) {
      // Tournament scoring logic
      int accuracy = matchPercentage.value.toInt();
      // Assume tournament levels have a 60s base for speed bonus if time-based,
      // but if classic-like, maybe speed isn't the focus.
      // Let's use a flat speed bonus factor or based on time taken.
      int speedBonus = 10;

      TournamentManager.instance.submitScore(
        accuracy,
        speedBonus,
        comboCount.value + 1,
      );

      // Award some coins
      int tournamentCoins = (accuracy * 2).toInt();
      lastEarnedCoins = tournamentCoins;
      await addCoins(tournamentCoins);

      overlays.remove('TournamentHUD');
      overlays.add('WinMenu');
    } else {
      overlays.add('WinMenu');
    }
  }

  /// Start next Echo round without resetting score/streak
  void nextEchoRound() {
    _hasWon = false;
    _hasLost = false;
    overlays.remove('EchoWin');
    _resetGameplayVariables();
    startLevel();
    notifyListeners();
  }

  /// Start next Chaos round without resetting round counter
  void nextChaosRound() {
    _hasWon = false;
    _hasLost = false;
    overlays.remove('ChaosWin');
    _resetGameplayVariables();
    startLevel();
    notifyListeners();
  }

  void resetGame() {
    _hasWon = false;
    _hasLost = false;
    _resetGameplayVariables();

    comboCount.value = 0; // Reset combo on retry
    // Remove overlays if they exist
    overlays.remove('WinMenu');
    overlays.remove('GameOver');
    overlays.remove('EchoWin');
    overlays.remove('EchoGameOver');
    overlays.remove('ChaosWin');
    overlays.remove('ChaosGameOver');
    overlays.remove('TournamentHUD');
    overlays.remove('CardUnlock');
    _evaporationVisualOffset = 0.0;

    // Reset Echo state on retry (not next round)
    if (currentMode == GameMode.colorEcho) {
      echoRound = 0;
      echoScore = 0.0;
      echoStreak = 0;
    }
    // Reset Chaos state on retry
    if (currentMode == GameMode.chaosLab) {
      chaosRound = 0;
    }

    transitionTo(
      '',
      '',
      midpointAction: () {
        startLevel();
      },
    );
  }

  void _resetGameplayVariables() {
    beaker.clearContents();
    totalDrops.value = 0;
    matchPercentage.value = 0;
    rDrops = 0;
    gDrops = 0;
    bDrops = 0;
    whiteDrops = 0;
    blackDrops = 0;
    dropsLimitReached.value = false;
    dropHistory.clear();
    _previousMatchPct = 0.0;
  }

  void startTournamentMode() {
    _hasWon = false;
    _hasLost = false;
    currentMode = GameMode.tournament;

    // Set a seed based on the current week to ensure everyone gets the same colors
    final now = DateTime.now();
    final weekSeed =
        now.year * 100 +
        (now.millisecondsSinceEpoch ~/ (1000 * 60 * 60 * 24 * 7));
    final rng = Random(weekSeed);

    // Generate a target color based on the weekly theme
    final theme = TournamentManager.instance.currentTheme;
    if (theme == "Red Week") {
      targetColor = Color.fromARGB(
        255,
        rng.nextInt(100) + 155, // High red
        rng.nextInt(80), // Low green
        rng.nextInt(80), // Low blue
      );
    } else if (theme == "Spectral Blues") {
      targetColor = Color.fromARGB(
        255,
        rng.nextInt(80), // Low red
        rng.nextInt(100) + 50, // Med green
        rng.nextInt(155) + 100, // High blue
      );
    } else if (theme == "Emerald City") {
      targetColor = Color.fromARGB(
        255,
        rng.nextInt(60), // Low red
        rng.nextInt(155) + 100, // High green
        rng.nextInt(60), // Low blue
      );
    } else {
      // Default random for Neon Cascade / Warm Sunset
      targetColor = Color.fromARGB(
        255,
        rng.nextInt(256),
        rng.nextInt(256),
        rng.nextInt(256),
      );
    }

    beaker.clearContents();
    matchPercentage.value = 0;
    totalDrops.value = 0;
    rDrops = 0;
    gDrops = 0;
    bDrops = 0;
    whiteDrops = 0;
    blackDrops = 0;
    dropsLimitReached.value = false;
    dropHistory.clear();
    _previousMatchPct = 0.0;

    if (overlays.isActive('MainMenu')) overlays.remove('MainMenu');
    if (!overlays.isActive('TournamentHUD')) overlays.add('TournamentHUD');
    startLevel();
    notifyListeners();
  }

  List<String> dropHistory = [];

  void addDrop(String colorType, {bool ignoreInversion = false}) {
    if (_hasWon) return;
    if (_dropCooldownTimer > 0) return;
    if (rDrops + gDrops + bDrops + whiteDrops + blackDrops >= maxDrops) {
      dropsLimitReached.value = true;
      return;
    }

    _dropCooldownTimer = _dropCooldown;
    dropCooldownProgress.value = 0.0;
    _audio.playDrop();

    // Map colorType to actual Color
    // Handle Inverse Controls
    String effectiveColorType = colorType;
    if (isControlsInverted && !ignoreInversion) {
      if (colorType == 'red') {
        effectiveColorType = 'blue';
      } else if (colorType == 'blue') {
        effectiveColorType = 'red';
      }
      // Can also swap others if desired, e.g. green/yellow? Green is secondary?
      // Let's stick to Red/Blue as per request "red button adds blue, and the yellow button adds red"
      // Wait, request said "yellow button adds red".
      // The game has 'red', 'green', 'blue', 'white', 'black'. No explicit 'yellow' button mentioned in code?
      // RGB are primaries. Maybe user meant a specific button.
      // Assuming user meant "Red <-> Blue" swap for standard inversion.
      // If "yellow" refers to something else, I'll stick to Red/Blue swap for max confusion.
    }

    dropHistory.add(effectiveColorType);

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

    if (needed('red', rDrops) > 0) {
      colorToDrop = 'red';
    } else if (needed('green', gDrops) > 0) {
      colorToDrop = 'green';
    } else if (needed('blue', bDrops) > 0) {
      colorToDrop = 'blue';
    } else if (needed('white', whiteDrops) > 0) {
      colorToDrop = 'white';
    } else if (needed('black', blackDrops) > 0) {
      colorToDrop = 'black';
    }

    if (colorToDrop != null) {
      if (!useHelper('help_drop')) return;
      addDrop(colorToDrop, ignoreInversion: true);
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

    // Echo Mode: proximity hint when match >= 80%
    if (currentMode == GameMode.colorEcho) {
      echoAlmostSync.value =
          matchPercentage.value >= 80.0 && matchPercentage.value < 100.0;
    }

    // Chaos Mode: stability recovery on accurate drops
    if (currentMode == GameMode.chaosLab &&
        matchPercentage.value > _previousMatchPct) {
      double improvement = matchPercentage.value - _previousMatchPct;
      if (improvement >= 5.0) {
        chaosStability = (chaosStability + 0.08).clamp(0.0, 1.0);
        stabilityRecovered.value =
            !stabilityRecovered.value; // Toggle to trigger UI
      }
    }
    _previousMatchPct = matchPercentage.value;

    // Auto-win if 100% match
    if (matchPercentage.value == 100.0 &&
        !_hasWon &&
        _isRecipeIngredientsFulfilled()) {
      _hasWon = true;
      AdManager().recordWin();
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

  bool _isRecipeIngredientsFulfilled() {
    // Non-level modes don't have a fixed recipe
    if (currentMode != GameMode.classic && currentMode != GameMode.timeAttack) {
      return true;
    }

    final recipe = levelManager.currentLevel.recipe;
    final rRequired = (recipe['red'] ?? 0) as int;
    final gRequired = (recipe['green'] ?? 0) as int;
    final bRequired = (recipe['blue'] ?? 0) as int;
    final wRequired = (recipe['white'] ?? 0) as int;
    final kRequired = (recipe['black'] ?? 0) as int;

    if (rRequired > 0 && rDrops == 0) return false;
    if (gRequired > 0 && gDrops == 0) return false;
    if (bRequired > 0 && bDrops == 0) return false;
    if (wRequired > 0 && whiteDrops == 0) return false;
    if (kRequired > 0 && blackDrops == 0) return false;

    return true;
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

  void drainLiquid(double amount) {
    if (beaker.liquidLevel > 0) {
      // Logic: subtract from counts? Or just visual?
      // For "Professional Disaster", it should be structural.
      // We reduce the counts proportionally or just the total.
      // Let's just reduce the visual level if we want it to be simple,
      // but for "Next Level", it should actually set the player back.
      double factor = amount / beaker.liquidLevel;
      if (factor > 1.0) factor = 1.0;
      if (factor < 0.0) factor = 0.0;

      rDrops = (rDrops * (1 - factor)).toInt();
      gDrops = (gDrops * (1 - factor)).toInt();
      bDrops = (bDrops * (1 - factor)).toInt();
      whiteDrops = (whiteDrops * (1 - factor)).toInt();
      blackDrops = (blackDrops * (1 - factor)).toInt();

      dropHistory.clear(); // Cannot cleanly undo part of drops

      _updateGameState();
    }
  }

  void startLevel() {
    _hasWon = false;
    _hasLost = false;
    _dropCooldownTimer = 0.0;
    dropCooldownProgress.value = 1.0;

    _startLevelBgm(); // Start gameplay music

    if (currentMode == GameMode.colorEcho) {
      targetColor = ColorLogic.generateRandomHardColor();
      // Progressive difficulty: reduce drops and time each round
      maxDrops = (30 - echoRound).clamp(15, 30);
      isBlindMode = _random.nextBool(); // 50% chance of blind mode in echo
    } else if (currentMode == GameMode.chaosLab) {
      // Chaos Lab Mode: Unstable, random target colors
      targetColor = ColorLogic.generateRandomHardColor();
      maxDrops = 40;
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
    _resetGameplayVariables();

    isColorBlindEvent = false;
    isDoubleCoinActive = false;
    _evaporationVisualOffset = 0.0;
    _randomEventOccurredThisLevel = false;
    _cardDroppedThisLevel = false;
    randomEventBonusApplied = false;
    helpersUsedInLevel.clear();
    _lastBeakerColor = Colors.transparent;
    _levelStartTime = DateTime.now();
    currentHint.value = null; // Reset hint
    hasUsedHint = false;

    // Apply isBlindMode to beaker immediately
    beaker.isBlindMode = isBlindMode;
    _levelSession++; // Invalidate any pending random-event delayed futures

    // Reset Chaos State
    chaosStability = 1.0;
    isMirrored = false;
    hasWind = false;
    windForce = 0;
    isLeaking = false;
    camera.viewfinder.transform.scale = Vector2.all(1.0);

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
      // Progressive: reduce time each round
      maxTime = (25.0 - echoRound * 2).clamp(12.0, 25.0);
      timeLeft = maxTime;
      isTimeUp = false;
      echoAlmostSync.value = false;
    } else {
      timeLeft = 0;
      isTimeUp = false;
    }

    // Centralized cleanup of game/HUD overlays
    final gameOverlays = [
      'Controls',
      'ColorEchoHUD',
      'ChaosLabHUD',
      'Blackout',
      'WinMenu',
      'GameOver',
      'EchoWin',
      'EchoGameOver',
      'ChaosWin',
      'ChaosGameOver',
      'Tutorial',
      'Tournament',
      'TournamentHUD',
      'CardUnlock',
    ];
    for (final overlay in gameOverlays) {
      overlays.remove(overlay);
    }

    if (currentMode == GameMode.colorEcho) {
      add(HolographicRadar(position: beaker.position, radius: 130));
      add(
        SpectralGhostTarget(
          position: Vector2(size.x / 2, 120),
          targetColor: targetColor,
        ),
      );
      add(ChromaticAberrationEffect());
      overlays.add('ColorEchoHUD');
    } else if (currentMode == GameMode.chaosLab) {
      // Chaos Lab: dynamic difficulty based on chaosRound
      timeLeft = 240.0;
      maxTime = 240.0;
      isTimeUp = false;
      _previousMatchPct = 0.0;
      chaosPhase.value = 'STABLE';

      // Dynamic first-event timer: shrinks each round
      _eventTimer = (20.0 - chaosRound * 2).clamp(8.0, 20.0);

      overlays.add('ChaosLabHUD');
    } else if (currentMode == GameMode.classic ||
        currentMode == GameMode.timeAttack) {
      overlays.add('Controls');
    }

    // Random Events Initialization
    disposeRandomEvents();
    if (randomEventsEnabled &&
        (currentMode == GameMode.classic ||
            currentMode == GameMode.timeAttack)) {
      // First event after 10-15 seconds
      _eventTimer = 10.0 + _random.nextDouble() * 5.0;
    }
    randomEventBonusApplied = false;

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

  void revealHint() {
    if (currentHint.value != null) return;
    if (currentMode == GameMode.classic || currentMode == GameMode.timeAttack) {
      final level = levelManager.currentLevel;
      currentHint.value = level.hint;
      hasUsedHint = true;
      _audio.playButton(); // Play a subtle sound
      notifyListeners();
    }
  }

  void goToNextLevel() {
    _hasWon = false;
    _hasLost = false;
    _resetGameplayVariables();

    if (currentMode == GameMode.colorEcho) {
      transitionTo(
        'WinMenu',
        '',
        midpointAction: () {
          startLevel();
        },
      );
      return;
    }

    // Check if next level exists
    int nextLevelIndex = levelManager.currentLevelIndex + 1;
    if (nextLevelIndex < levelManager.levels.length) {
      transitionTo(
        'WinMenu',
        'Controls',
        midpointAction: () {
          levelManager.currentLevelIndex = nextLevelIndex;
          startLevel();
        },
      );
    } else {
      // Phase complete — navigate to Level Map with reverse transition
      transitionTo(
        'WinMenu',
        'LevelMap',
        isReverse: true,
        midpointAction: () {
          // Additional phase complete logic could go here
        },
      );
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
    transitionTo('MainMenu', 'LevelMap');
    notifyListeners();
  }

  void _handleGameOver() {
    if (_hasLost || _hasWon) return;
    _hasLost = true;
    _hasWon = false; // نضمن أن حالة الفوز لم تتحقق
    AdManager().recordLoss();

    disposeRandomEvents();

    _audio.playGameOver();

    overlays.remove('TournamentHUD');
    overlays.remove('CardUnlock');

    if (currentMode == GameMode.colorEcho) {
      overlays.add('EchoGameOver');
    } else if (currentMode == GameMode.chaosLab) {
      overlays.add('ChaosGameOver');
    } else {
      overlays.add('GameOver');
    }

    if (currentMode != GameMode.colorEcho && currentMode != GameMode.chaosLab) {
      LivesManager().consumeLife();
    }
  }

  Future<void> addCoins(int amount) async {
    // Phase 2: Apply VIP coin multiplier
    final multiplied = (amount * VipManager.instance.coinMultiplier).round();
    bool success = await SaveManager.addCoins(
      multiplied,
      reason: 'Gameplay reward',
    );
    if (success) {
      totalCoins.value = await SaveManager.loadTotalCoins();
      notifyListeners();
    }
  }

  Future<bool> spendCoins(int amount) async {
    bool success = await SaveManager.spendCoins(
      amount,
      reason: 'Store purchase',
    );
    if (success) {
      totalCoins.value = await SaveManager.loadTotalCoins();
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Phase 2: Revive the player after a game over by watching a rewarded ad.
  /// Restores [drops] drops and resumes the level.
  void reviveWithDrops(int drops) {
    overlays.remove('GameOver');
    overlays.remove('EchoGameOver');
    overlays.remove('ChaosGameOver');

    _hasLost = false;
    isTimeUp = false;
    timeLeft = maxTime;

    maxDrops += drops;
    dropsLimitReached.value = false;
    _cardDroppedThisLevel = false;

    _updateGameState();

    // Restore the correct HUD for the current mode
    if (currentMode == GameMode.colorEcho) {
      overlays.add('ColorEchoHUD');
    } else if (currentMode == GameMode.chaosLab) {
      overlays.add('ChaosLabHUD');
    } else {
      overlays.add('Controls');
    }
    _startLevelBgm();
    notifyListeners();
  }

  Future<void> buyOrSelectSkin(BeakerType type, int price) async {
    if (unlockedSkins.contains(type)) {
      beaker.type = type; // Select skin
      await SaveManager.saveSelectedSkin(type.toString());
      notifyListeners();
    } else {
      bool success = await SaveManager.spendCoins(
        price,
        reason: 'Bought skin ${type.toString()}',
      );
      if (success) {
        totalCoins.value = await SaveManager.loadTotalCoins();
        unlockedSkins.add(type);
        beaker.type = type;
        await SaveManager.saveSelectedSkin(type.toString());

        List<String> skinNames = unlockedSkins
            .map((e) => e.toString())
            .toList();
        await SaveManager.savePurchasedSkins(skinNames);

        _audio.playUnlock();
        notifyListeners();
      }
    }
  }

  /// Apply lab config changes immediately to all environment components.
  void applyLabConfig(Map<String, String> config) {
    final bgItem = LabCatalog.getItemByCategory(
      'background',
      config['background'] ?? 'bg_default',
    );
    final lightItem = LabCatalog.getItemByCategory(
      'lighting',
      config['lighting'] ?? 'light_basic',
    );
    final surfaceItem = LabCatalog.getItemByCategory(
      'surface',
      config['surface'] ?? 'surface_steel',
    );
    final standItem = LabCatalog.getItemByCategory(
      'stand',
      config['stand'] ?? 'stand_basic',
    );
    final lightsItem = LabCatalog.getItemByCategory(
      'string_lights',
      config['string_lights'] ?? 'lights_none',
    );

    backgroundGradient.updateConfig(bgItem?.gradientColors);
    ambientParticles.updateConfig(lightItem?.gradientColors);
    patternBackground.updateConfig(surfaceItem);
    stringLights?.updateConfig(lightsItem);
    if (standItem != null) {
      if (beakerStand != null) {
        beakerStand!.updateConfig(standItem);
      } else {
        final beakerPos = Vector2(size.x / 2, size.y * 0.54);
        beakerStand = BeakerStand(
          position: Vector2(beakerPos.x, beakerPos.y + 110),
          size: Vector2(200, 60),
          config: standItem,
        );
        add(beakerStand!);
      }
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (stringLights != null) {
      stringLights!.size = Vector2(size.x, 200);
    }
  }

  Future<void> toggleBlindMode(bool enabled) async {
    globalBlindMode = enabled;
    await SaveManager.saveBlindMode(enabled);
    notifyListeners();
  }

  Future<void> toggleReducedMotion(bool enabled) async {
    reducedMotionEnabled = enabled;
    await SaveManager.saveReducedMotion(enabled);
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

  bool addHelpers(String helperId, int count) {
    final current = helperCounts.value[helperId] ?? 0;
    Map<String, int> newCounts = Map<String, int>.from(helperCounts.value);
    newCounts[helperId] = current + count;
    helperCounts.value = newCounts;
    SaveManager.saveHelpers(newCounts);
    notifyListeners();
    return true;
  }

  void navigateToPage(String pageName, {bool isReverse = false}) {
    transitionTo(
      '',
      pageName,
      isReverse: isReverse,
      midpointAction: () {
        // If navigating to MainMenu, reset mode and music
        if (pageName == 'MainMenu') {
          currentMode = GameMode.none;
          _audio.playMenuMusic();
          disposeRandomEvents();
        }

        // Clear ALL currently active overlays except the target
        final active = overlays.activeOverlays.toList();
        for (final overlay in active) {
          if (overlay != pageName) {
            overlays.remove(overlay);
          }
        }

        // Force re-initialization of the target page
        overlays.remove(pageName);
      },
    );
  }

  void returnToMainMenu() => navigateToPage('MainMenu', isReverse: true);

  void showPhaseSelect() {
    currentMode = GameMode.classic;
    navigateToPage('PhaseSelect', isReverse: false);
  }

  void showLevelMapForPhase(int phaseId) {
    levelManager.selectedPhase = phaseId;
    navigateToPage('LevelMap', isReverse: false);
  }

  void addHelper(String helperId, int amount) {
    Map<String, int> newCounts = Map<String, int>.from(helperCounts.value);
    newCounts[helperId] = (newCounts[helperId] ?? 0) + amount;
    helperCounts.value = newCounts;
    SaveManager.saveHelpers(newCounts);
    notifyListeners();
  }

  Future<void> _evaluateDailyChallenges(int stars) async {
    // Only fetch challenge if we haven't completed it today
    bool completed = await DailyChallengeManager.isTodayCompleted();
    if (completed) return;

    final challenge = await DailyChallengeManager.getTodaysChallenge();

    bool achieved = false;
    switch (challenge.type) {
      case ChallengeType.limitedDrops:
        if (totalDrops.value <= challenge.requirement) achieved = true;
        break;
      case ChallengeType.noWhite:
        if (whiteDrops == 0) achieved = true;
        break;
      case ChallengeType.noBlack:
        if (blackDrops == 0) achieved = true;
        break;
      case ChallengeType.speedRun:
        if (currentMode == GameMode.timeAttack) {
          double elapsed = maxTime - timeLeft;
          if (elapsed <= challenge.requirement) achieved = true;
        }
        break;
      case ChallengeType.perfectMatch:
        // The manager defines this as 3 consecutive matches, but we don't track
        // global streak natively outside of this loop. We'll simplify to just achieving
        // 1 perfect match right now, or we'd need a separate static streak tracker.
        // Given stars == 3 means 100% match. We will use `comboCount.value`!
        if (comboCount.value >= challenge.requirement) achieved = true;
        break;
    }

    if (achieved) {
      await DailyChallengeManager.completeChallenge();
      await SaveManager.incrementDailyChallengeCount();
      // Add coins directly. SaveManager is called inside completeChallenge? No, the plan says to call it.
      // Wait, DailyChallengeManager doesn't grant coins. ColorMixerGame should.
      await addCoins(challenge.reward);

      // Show notification overlay
      overlays.add(
        'Achievement',
      ); // We reuse Achievement overlay, but let's just use it conceptually or we can pass args.
      // Currently the game hardcodes 'Achievement' args in main.dart:
      // 'Achievement': (context, game) => AchievementNotification(title: "MAD CHEMIST"...)
      // But we can just use the standard addCoins floating text instead, and the UI will show it as done.
    }
  }

  Future<void> _checkLevelReward() async {
    if (currentMode != GameMode.classic) return;

    // Level IDs are 1-based, currentLevelIndex is 0-based.
    // e.g. level 10 == index 9.
    int completedLevelId = levelManager.currentLevel.id;

    // Check if it's a multiple of 10
    if (completedLevelId > 0 && completedLevelId % 10 == 0) {
      String rewardKey = 'helper_reward_level_$completedLevelId';
      bool hasClaimed = await SaveManager.getBool(rewardKey) ?? false;

      if (!hasClaimed) {
        // Award 1 of each helper
        addHelper('undo', 1);
        addHelper('extra_drops', 1);
        addHelper('help_drop', 1);
        addHelper('reveal_color', 1);

        await SaveManager.saveBool(rewardKey, true);

        // Visual notification
        rewardNotification.value = "Level Reward Claimed!";
        if (!overlays.isActive('RewardToast')) {
          overlays.add('RewardToast');
        }
      }
    }
  }

  void _grantRandomHelper() {
    final helpers = ['undo', 'extra_drops', 'help_drop', 'reveal_color'];
    final selected = helpers[_random.nextInt(helpers.length)];
    addHelper(selected, 1);

    // Quick notification that a helper was found via RewardToast overlay
    rewardNotification.value = "Found ${selected.replaceAll('_', ' ')}!";
    if (!overlays.isActive('RewardToast')) {
      overlays.add('RewardToast');
    }
  }

  void _showNextAchievement() {
    if (achievementQueue.isNotEmpty && !overlays.isActive('Achievement')) {
      overlays.add('Achievement');
    }
  }

  void dismissAchievement() {
    if (achievementQueue.isNotEmpty) {
      achievementQueue.removeAt(0);
    }
    overlays.remove('Achievement');
    // Check if more achievements are in queue
    Future.delayed(const Duration(milliseconds: 300), () {
      if (isMounted) _showNextAchievement();
    });
  }

  void _triggerChaosMeltdown() {
    // Track active chaos events for UI display

    // Escalate based on stability with enhanced visual feedback
    if (chaosStability > 0.7) {
      // Level 1: Initial anomalies
      _triggerRandomEvent();
      _audio.playAlarm(); // Warning sound
    } else if (chaosStability > 0.4) {
      // Level 2: Multiple overlapping events
      _triggerRandomEvent();
      Future.delayed(const Duration(seconds: 2), () {
        if (currentMode == GameMode.chaosLab && !_hasWon) {
          _triggerRandomEvent();
        }
      });

      if (!children.any((c) => c is EmergencyLights)) {
        add(EmergencyLights());
      }
      _audio.playSpark(); // Electrical warning
    } else {
      // Level 3: FULL MELTDOWN
      _triggerRandomEvent();
      Future.delayed(const Duration(seconds: 1), () {
        if (currentMode == GameMode.chaosLab && !_hasWon) {
          _triggerRandomEvent();
        }
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (currentMode == GameMode.chaosLab && !_hasWon) {
          _triggerRandomEvent();
        }
      });

      // Add all critical visual effects
      if (!children.any((c) => c is ElectricalSparks)) {
        add(ElectricalSparks());
      }
      if (!children.any((c) => c is EmergencyLights)) {
        add(EmergencyLights());
      }
      if (!children.any((c) => c is CrackedGlassOverlay)) {
        add(CrackedGlassOverlay());
      }
      if (!children.any((c) => c is ChromaticAberrationEffect)) {
        add(ChromaticAberrationEffect());
      }

      // Force severe events with higher probability
      if (!isMirrored && _random.nextDouble() < 0.7) {
        add(MirrorDistortionEffect());
      }
      if (!hasWind && _random.nextDouble() < 0.7) add(WindForceEffect());

      // Play critical alert
      _audio.playAlarm();
    }

    notifyListeners();
  }

  void _triggerRandomEvent() {
    // Prevent stacking of certain events
    if (isBlackout || isEvaporating || isControlsInverted || isUiGlitching) {
      return;
    }

    // Check for existing visual effects
    bool isEffectActive =
        children.whereType<GlitchEffect>().isNotEmpty ||
        children.whereType<InvertedControlsEffect>().isNotEmpty ||
        children.whereType<EarthquakeVisualEffect>().isNotEmpty ||
        beaker.children.whereType<SurfaceSteam>().isNotEmpty ||
        beaker.children.whereType<GravityFluxEffect>().isNotEmpty ||
        beaker.children.whereType<UnstableBeakerEffect>().isNotEmpty;

    if (isEffectActive) return;

    // Determine mode string for duration calculation
    String modeString = 'classic';
    if (currentMode == GameMode.chaosLab) {
      modeString = 'chaosLab';
    } else if (currentMode == GameMode.timeAttack) {
      modeString = 'timeAttack';
    }

    // Select event now so the alert overlay can display its name
    final event = EventRaritySystem.getRandomEvent();
    pendingEvent.value = event;

    // Track that an event occurred this level for the reward multiplier
    _randomEventOccurredThisLevel = true;

    // Show visual warning
    overlays.add('RandomEventAlert');

    // Capture the session token so stale callbacks can be rejected
    final capturedSession = _levelSession;

    // Delay actual effect slightly to let the built-in alert finish (2.2 seconds)
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (_levelSession != capturedSession) return; // Level changed — bail out
      if (currentMode != GameMode.classic &&
          currentMode != GameMode.timeAttack &&
          currentMode != GameMode.chaosLab) {
        return;
      }

      final duration = EventRaritySystem.getDuration(event, modeString);

      // Set active event details for HUD badge
      activeEventLabel.value = event.labelKey;
      activeEventProgress.value = 1.0;
      _activeEventDuration = duration;
      _activeEventElapsed = 0.0;

      // Trigger event based on ID
      switch (event.id) {
        // Common Events
        case 'glitch':
          add(GlitchEffect());
          _audio.playGlitch();
          break;
        case 'unstable':
          beaker.add(UnstableBeakerEffect());
          _audio.playSpark();
          break;
        case 'earthquake':
          isEarthquake = true;
          add(EarthquakeVisualEffect());
          _audio.playCrack();
          break;
        case 'ui_glitch':
          isUiGlitching = true;
          add(GlitchEffect());
          _audio.playGlitch();
          break;
        case 'evaporation_short':
          isEvaporating = true;
          beaker.add(SurfaceSteam(beaker: beaker));
          _audio.playSteam();
          break;
        case 'inverted_short':
          isControlsInverted = true;
          add(InvertedControlsEffect());
          _audio.playGlitch();
          break;
        case 'color_blind_short':
          isColorBlindEvent = true;
          beaker.isBlindMode = true;
          _audio.playSteam();
          break;
        case 'gravity_flux':
          isGravityFlux = true;
          beaker.add(GravityFluxEffect());
          _audio.playSpark();
          break;

        // Uncommon Events
        case 'blackout':
          isBlackout = true;
          add(BlackoutEffect());
          overlays.add('Blackout');
          _audio.playAlarm();
          break;
        case 'mirror':
          if (!isMirrored) {
            add(MirrorDistortionEffect());
            _audio.playGlitch();
          }
          break;
        case 'wind':
          if (!hasWind) {
            add(WindForceEffect());
            _audio.playSteam();
          }
          break;
        case 'digital_spike':
          add(GlitchEffect(intensity: 1.8));
          _audio.playGlitch();
          break;
        case 'leak':
          if (!children.any((c) => c is LeakingBeakerEffect)) {
            add(LeakingBeakerEffect());
            _audio.playSteam();
          }
          break;
        case 'evaporation_long':
          isEvaporating = true;
          beaker.add(SurfaceSteam(beaker: beaker));
          _audio.playSteam();
          break;

        // Rare Events (Positive!)
        case 'time_freeze':
          isTimeFreeze = true;
          _audio.playUnlock(); // Positive sound
          // Visual indicator will be added to HUD
          break;
        case 'double_coins':
          isDoubleCoinActive = true;
          _audio.playUnlock(); // Positive sound
          // Visual indicator will be added to HUD
          break;

        // Epic Event
        case 'chaos_cascade':
          // Trigger 2-3 random common/uncommon events
          int cascadeCount = 2 + _random.nextInt(2); // 2 or 3 events
          for (int i = 0; i < cascadeCount; i++) {
            Future.delayed(Duration(milliseconds: i * 1000), () {
              if (currentMode == GameMode.chaosLab && !_hasWon) {
                _triggerRandomEvent();
              }
            });
          }
          _audio.playAlarm();
          break;
        case 'system_meltdown':
          isBlackout = true;
          add(BlackoutEffect());
          overlays.add('Blackout');
          add(GlitchEffect(intensity: 2.2));
          _audio.playAlarm();
          _audio.playGlitch();
          break;
      }

      notifyListeners();

      // Auto-remove effect after duration
      Future.delayed(Duration(milliseconds: (duration * 1000).toInt()), () {
        if (_levelSession != capturedSession) {
          return; // Level changed — bail out
        }
        // Clear active event HUD
        activeEventLabel.value = null;
        activeEventProgress.value = 0.0;
        _activeEventDuration = 0.0;
        _activeEventElapsed = 0.0;

        // Reset Logic Flags
        isBlackout = false;
        isEvaporating = false;
        _evaporationVisualOffset = 0.0;
        isControlsInverted = false;
        isUiGlitching = false;
        isColorBlindEvent = false;
        isGravityFlux = false;
        isEarthquake = false;
        isTimeFreeze = false;
        // Note: isDoubleCoinActive persists until level completion
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
          children.whereType<InvertedControlsEffect>().toList().forEach(
            (i) => i.removeFromParent(),
          );
          children.whereType<EarthquakeVisualEffect>().toList().forEach(
            (e) => e.removeFromParent(),
          );
          children.whereType<AcidSplatter>().toList().forEach(
            (e) => e.removeFromParent(),
          );
          beaker.children.whereType<SurfaceSteam>().toList().forEach(
            (s) => s.removeFromParent(),
          );
          beaker.children.whereType<GravityFluxEffect>().toList().forEach(
            (g) => g.removeFromParent(),
          );
          beaker.children.whereType<UnstableBeakerEffect>().toList().forEach(
            (u) => u.removeFromParent(),
          );
        }
      });
    });
  }

  @override
  void lifecycleStateChange(AppLifecycleState state) {
    debugPrint('Game Lifecycle: $state');
    switch (state) {
      case AppLifecycleState.resumed:
        AudioManager().resumeMusic();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        AudioManager().pauseMusic();
        break;
      default:
        // Handle newer states like 'hidden' if they exist in the current Flutter version
        if (state.toString().contains('hidden')) {
          AudioManager().pauseMusic();
        }
    }
    super.lifecycleStateChange(state);
  }
}
