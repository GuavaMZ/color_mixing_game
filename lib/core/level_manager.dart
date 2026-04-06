import 'dart:math';
import 'package:color_mixing_deductive/core/color_logic.dart';
import 'package:color_mixing_deductive/core/level_model.dart';
import 'package:color_mixing_deductive/core/save_manager.dart';
import 'package:color_mixing_deductive/helpers/string_manager.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show compute;

class LevelManager {
  int currentLevelIndex = 0;
  List<LevelModel> classicLevels = [];
  List<LevelModel> timeAttackLevels = [];

  Map<int, int> classicLevelStars = {};
  Map<int, int> timeAttackLevelStars = {};

  String currentMode = 'classic';

  /// The currently selected phase for the classic level map (1-based).
  int selectedPhase = 1;

  LevelManager() {
    classicLevels = [];
    timeAttackLevels = _generateTimeAttackLevels(50);

    for (int i = 1; i <= 50; i++) {
      timeAttackLevelStars[i] = i == 1 ? 0 : -1;
    }
  }

  List<LevelModel> get levels =>
      currentMode == 'classic' ? classicLevels : timeAttackLevels;
  Map<int, int> get levelStars =>
      currentMode == 'classic' ? classicLevelStars : timeAttackLevelStars;

  LevelModel get currentLevel {
    if (levels.isEmpty) {
      // Fallback to avoid RangeError if level data failed to load
      return LevelModel(
        id: 1,
        phase: 1,
        maxDrops: 10,
        difficultyFactor: 0.5,
        availableColors: [Colors.red, Colors.green, Colors.blue],
        targetColor: Colors.red,
        recipe: {'red': 1},
        hint: '',
        isBlindMode: false,
      );
    }
    final safeIndex = currentLevelIndex.clamp(0, levels.length - 1);
    return levels[safeIndex];
  }

  // ─── Phase helpers ────────────────────────────────────────────────────────

  /// All levels belonging to a given phase (1-based).
  List<LevelModel> levelsForPhase(int phaseId) =>
      classicLevels.where((l) => l.phase == phaseId).toList();

  /// Returns true if the given phase is unlocked.
  /// Phase 1 is always unlocked. Later phases unlock when all levels of the
  /// previous phase are completed (stars > 0).
  bool isPhaseUnlocked(int phaseId) {
    if (phaseId <= 1) return true;
    final prevLevels = levelsForPhase(phaseId - 1);
    if (prevLevels.isEmpty) return false;
    return prevLevels.every((l) => (classicLevelStars[l.id] ?? -1) > 0);
  }

  /// Progress (completedCount, totalCount) for a phase.
  (int, int) phaseProgress(int phaseId) {
    final phaseLevels = levelsForPhase(phaseId);
    final completed = phaseLevels
        .where((l) => (classicLevelStars[l.id] ?? -1) > 0)
        .length;
    return (completed, phaseLevels.length);
  }

  /// Stars earned in a phase.
  int phaseStars(int phaseId) {
    return levelsForPhase(
      phaseId,
    ).fold(0, (sum, l) => sum + ((classicLevelStars[l.id] ?? 0).clamp(0, 3)));
  }

  // ─── Navigation ───────────────────────────────────────────────────────────

  bool nextLevel() {
    if (currentLevelIndex < levels.length - 1) {
      currentLevelIndex++;
      return true;
    }
    return false;
  }

  void reset() {
    currentLevelIndex = 0;
  }

  // ─── Loading ──────────────────────────────────────────────────────────────

  Future<void> loadLevels() async {
    try {
      final jsonString = await rootBundle.loadString('assets/levels.json');
      classicLevels = await compute(_parseLevels, jsonString);

      for (var level in classicLevels) {
        if (!classicLevelStars.containsKey(level.id)) {
          classicLevelStars[level.id] = level.id == 1 ? 0 : -1;
        }
      }
    } catch (e) {
      debugPrint("Error loading levels: $e");
    }
  }

  static List<LevelModel> _parseLevels(String jsonString) {
    final dynamic decoded = jsonDecode(jsonString);
    final List<dynamic> levelsList = (decoded is Map)
        ? decoded['levels']
        : decoded;

    final List<LevelModel> loadedLevels = [];
    for (var levelData in levelsList) {
      try {
        final Map<String, dynamic> rawRecipe = levelData['recipe'] ?? {};
        final Map<String, int> recipe = {
          'red': (rawRecipe['R'] ?? rawRecipe['red'] ?? 0) as int,
          'green': (rawRecipe['G'] ?? rawRecipe['green'] ?? 0) as int,
          'blue': (rawRecipe['B'] ?? rawRecipe['blue'] ?? 0) as int,
          'white': (rawRecipe['W'] ?? rawRecipe['white'] ?? 0) as int,
          'black': (rawRecipe['K'] ?? rawRecipe['black'] ?? 0) as int,
        };

        loadedLevels.add(
          _createLevel(
            id: levelData['id'] ?? 0,
            phase: levelData['phase'] ?? 1,
            recipe: recipe,
            maxDrops: levelData['maxDrops'] ?? 6,
            difficulty: ((levelData['difficultyFactor'] ?? 0.5) as num)
                .toDouble(),
            isBlindMode: levelData['isBlindMode'] ?? false,
            hintOverride: _mapHint(levelData['hint']),
          ),
        );
      } catch (e) {
        // Since we are in an isolate, we can't use debugPrint directly if we want to be safe,
        // but Flutter's compute usually handles it or we just ignore.
      }
    }
    return loadedLevels;
  }

  Future<void> initProgress() async {
    await loadLevels();

    classicLevelStars = await SaveManager.loadProgress('classic');
    timeAttackLevelStars = await SaveManager.loadProgress('timeAttack');

    if (classicLevelStars.isEmpty || (classicLevelStars[1] ?? -1) == -1) {
      classicLevelStars[1] = 0;
    }
    if (timeAttackLevelStars.isEmpty || (timeAttackLevelStars[1] ?? -1) == -1) {
      timeAttackLevelStars[1] = 0;
    }
  }

  // ─── Time Attack ──────────────────────────────────────────────────────────

  List<LevelModel> _generateTimeAttackLevels(int count) {
    final List<LevelModel> result = [];

    for (int i = 1; i <= count; i++) {
      final rng = Random(i + 5000);
      int r = 0, g = 0, b = 0;
      int maxDrops = 10;
      if (i < 10) {
        r = rng.nextInt(3) + 1;
        g = rng.nextInt(3);
      } else {
        r = rng.nextInt(5) + 1;
        g = rng.nextInt(5) + 1;
        b = rng.nextInt(5);
      }

      if (r + g + b == 0) r = 2;

      result.add(
        _createLevel(
          id: i,
          phase: 1,
          recipe: {'red': r, 'green': g, 'blue': b},
          maxDrops: maxDrops,
          difficulty: i / count,
        ),
      );
    }
    return result;
  }

  // ─── Level Factory ────────────────────────────────────────────────────────

  static LevelModel _createLevel({
    required int id,
    required int phase,
    required Map<String, dynamic> recipe,
    required int maxDrops,
    required double difficulty,
    bool isBlindMode = false,
    String? hintOverride,
  }) {
    final int r = recipe['red'] ?? 0;
    final int g = recipe['green'] ?? 0;
    final int b = recipe['blue'] ?? 0;
    final int white = recipe['white'] ?? 0;
    final int black = recipe['black'] ?? 0;

    final Color targetColor = ColorLogic.createMixedColor(
      r,
      g,
      b,
      whiteDrops: white,
      blackDrops: black,
    );

    return LevelModel(
      id: id,
      phase: phase,
      maxDrops: maxDrops,
      difficultyFactor: difficulty,
      availableColors: [
        Colors.red,
        Colors.green,
        Colors.blue,
        Colors.white,
        Colors.black,
      ],
      targetColor: targetColor,
      recipe: recipe,
      hint: hintOverride ?? _generateSmartHint(r, g, b, white, black),
      isBlindMode: isBlindMode,
    );
  }

  // ─── Hint Generation ──────────────────────────────────────────────────────

  static String _generateSmartHint(int r, int g, int b, int w, int k) {
    if (w > 0 && r == 0 && g == 0 && b == 0 && k == 0) {
      return AppStrings.hintPureWhite;
    }
    if (k > 0 && r == 0 && g == 0 && b == 0 && w == 0) {
      return AppStrings.hintPureBlack;
    }

    if (w > 0 && w >= r && w >= g && w >= b) return AppStrings.hintNeedsWhite;
    if (k > 0 && k >= r && k >= g && k >= b) return AppStrings.hintNeedsBlack;
    if (r > 0 && g == 0 && b == 0) return AppStrings.hintPureRed;
    if (g > 0 && r == 0 && b == 0) return AppStrings.hintPureGreen;
    if (b > 0 && r == 0 && g == 0) return AppStrings.hintPureBlue;

    if (r == g && r > 0 && b == 0) return AppStrings.hintMixRG;
    if (r == b && r > 0 && g == 0) return AppStrings.hintMixRB;
    if (g == b && g > 0 && r == 0) return AppStrings.hintMixGB;

    if (r > g && r > b) {
      if (g > 0 && b > 0) return AppStrings.hintMostlyRed;
      if (g > 0) return AppStrings.hintRedGreen;
      return AppStrings.hintRedBlue;
    }

    if (g > r && g > b) {
      if (r > 0 && b > 0) return AppStrings.hintMostlyGreen;
      if (r > 0) return AppStrings.hintGreenRed;
      return AppStrings.hintGreenBlue;
    }

    if (b > r && b > g) {
      if (r > 0 && g > 0) return AppStrings.hintMostlyBlue;
      if (r > 0) return AppStrings.hintBlueRed;
      return AppStrings.hintBlueGreen;
    }

    if (r == g && g == b && r > 0) return AppStrings.hintBalanceAll;

    return AppStrings.hintObserve;
  }

  static String _mapHint(String? hint) {
    if (hint == null || hint.isEmpty) return AppStrings.hintObserve;

    switch (hint) {
      case 'hint_pure_red':
      case 'Just Red':
        return AppStrings.hintPureRed;
      case 'hint_pure_green':
      case 'Just Green':
        return AppStrings.hintPureGreen;
      case 'hint_pure_blue':
      case 'Just Blue':
        return AppStrings.hintPureBlue;
      case 'hint_pure_white':
        return AppStrings.hintPureWhite;
      case 'hint_pure_black':
        return AppStrings.hintPureBlack;
      case 'hint_mostly_red':
      case 'Mostly Red':
        return AppStrings.hintMostlyRed;
      case 'hint_mostly_green':
      case 'Mostly Green':
        return AppStrings.hintMostlyGreen;
      case 'hint_mostly_blue':
      case 'Mostly Blue':
        return AppStrings.hintMostlyBlue;
      case 'hint_mix_rb':
      case 'Equal Red and Blue make Magenta':
        return AppStrings.hintMixRB;
      case 'hint_mix_gb':
      case 'Equal Green and Blue make Cyan':
        return AppStrings.hintMixGB;
      case 'hint_mix_rg':
      case 'Equal Red and Green make Yellow':
        return AppStrings.hintMixRG;
      case 'hint_needs_white':
      case 'Looks very pale (needs White)':
        return AppStrings.hintNeedsWhite;
      case 'hint_needs_black':
      case 'Looks very dark (needs Black)':
        return AppStrings.hintNeedsBlack;
      case 'hint_balance_all':
      case 'Perfect balance of colors':
        return AppStrings.hintBalanceAll;
      case 'hint_observe':
      case 'Observe the color carefully':
        return AppStrings.hintObserve;
      default:
        if (hint.startsWith('hint_')) return hint;
        return AppStrings.hintObserve;
    }
  }

  // ─── Progress & Unlocking ─────────────────────────────────────────────────

  void unlockNextLevel(int currentLevelIndex, int stars) {
    if (levels.isEmpty) return;

    int levelId = levels[currentLevelIndex].id;
    int existingStars = levelStars[levelId] ?? -1;
    if (stars > existingStars) {
      levelStars[levelId] = stars;
    }

    if (currentLevelIndex < levels.length - 1) {
      int nextLevelId = levels[currentLevelIndex + 1].id;
      if ((levelStars[nextLevelId] ?? -1) == -1) {
        levelStars[nextLevelId] = 0;
      }
    }

    SaveManager.saveProgress(levelStars, currentMode);
  }

  int get totalLevels => levels.length;

  int get totalStarsEarned {
    return levelStars.values.where((s) => s > 0).fold(0, (sum, s) => sum + s);
  }
}
