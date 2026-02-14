import 'dart:math';
import 'package:color_mixing_deductive/core/color_logic.dart';
import 'package:color_mixing_deductive/core/level_model.dart';
import 'package:color_mixing_deductive/core/save_manager.dart';
import 'package:color_mixing_deductive/helpers/string_manager.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:flutter/material.dart';

class LevelManager {
  int currentLevelIndex = 0;
  List<LevelModel> classicLevels = [];
  List<LevelModel> timeAttackLevels = [];

  Map<int, int> classicLevelStars = {};
  Map<int, int> timeAttackLevelStars = {};

  String currentMode = 'classic';

  LevelManager() {
    // Initial empty state, will be populated by loadLevels
    classicLevels = [];
    timeAttackLevels = _generateTimeAttackLevels(100);

    // Default initialization (will be overwritten by initProgress)
    for (int i = 0; i < 100; i++) {
      timeAttackLevelStars[i] = i == 0 ? 0 : -1;
    }
  }

  List<LevelModel> get levels =>
      currentMode == 'classic' ? classicLevels : timeAttackLevels;
  Map<int, int> get levelStars =>
      currentMode == 'classic' ? classicLevelStars : timeAttackLevelStars;

  LevelModel get currentLevel => levels[currentLevelIndex];

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

  Future<void> loadLevels() async {
    try {
      final jsonString = await rootBundle.loadString('assets/levels.json');
      final Map<String, dynamic> data = jsonDecode(jsonString);
      final List<dynamic> levelsList = data['levels'];

      classicLevels = levelsList.map((levelData) {
        final Map<String, dynamic> recipe = Map<String, int>.from(
          levelData['recipe'],
        );

        return _createLevel(
          id: levelData['id'],
          recipe: recipe,
          maxDrops: levelData['maxDrops'],
          difficulty: (levelData['difficultyFactor'] as num).toDouble(),
          isBlindMode: levelData['isBlindMode'] ?? false,
          hintOverride: _mapHint(levelData['hint']),
        );
      }).toList();

      // Ensure stars map is sized correctly
      for (var level in classicLevels) {
        if (!classicLevelStars.containsKey(level.id)) {
          classicLevelStars[level.id] = level.id == 1 ? 0 : -1;
        }
      }
    } catch (e) {
      debugPrint("Error loading levels: $e");
    }
  }

  Future<void> initProgress() async {
    await loadLevels();

    classicLevelStars = await SaveManager.loadProgress('classic');
    timeAttackLevelStars = await SaveManager.loadProgress('timeAttack');

    if (classicLevelStars.isEmpty || (classicLevelStars[1] ?? -1) == -1) {
      classicLevelStars[1] =
          0; // Level 1 unlocked (using id 1-based indexing from JSON)
    }
    // Handle 0-based legacy keys if present
    if (classicLevelStars.containsKey(0) && !classicLevelStars.containsKey(1)) {
      classicLevelStars[1] = classicLevelStars[0]!;
    }
    if (timeAttackLevelStars.isEmpty || (timeAttackLevelStars[0] ?? -1) == -1) {
      timeAttackLevelStars[0] = 0;
    }
  }

  /// Time Attack Mode: Faster paced, more randomized but still progressive
  List<LevelModel> _generateTimeAttackLevels(int count) {
    final List<LevelModel> result = [];

    for (int i = 1; i <= count; i++) {
      // Simplified generation for Time Attack (keep independent)
      // ... (Logic could be refined later)
      // For now, generate a basic spread
      final rng = Random(i + 5000);
      int r = 0, g = 0, b = 0;
      int maxDrops = 10;
      if (i < 20) {
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
          recipe: {'red': r, 'green': g, 'blue': b},
          maxDrops: maxDrops,
          difficulty: i / count,
        ),
      );
    }
    return result;
  }

  LevelModel _createLevel({
    required int id,
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

  String _generateSmartHint(int r, int g, int b, int w, int k) {
    if (w > 0 && r == 0 && g == 0 && b == 0 && k == 0)
      return AppStrings.hintPureWhite;
    if (k > 0 && r == 0 && g == 0 && b == 0 && w == 0)
      return AppStrings.hintPureBlack;

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

  String _mapHint(String? hint) {
    if (hint == null || hint.isEmpty) return AppStrings.hintObserve;

    switch (hint) {
      case "Just Red":
        return AppStrings.hintPureRed;
      case "Just Green":
        return AppStrings.hintPureGreen;
      case "Just Blue":
        return AppStrings.hintPureBlue;
      case "Mostly Red":
        return AppStrings.hintMostlyRed;
      case "Mostly Green":
        return AppStrings.hintMostlyGreen;
      case "Mostly Blue":
        return AppStrings.hintMostlyBlue;
      case "Equal Red and Blue make Magenta":
        return AppStrings.hintMixRB;
      case "Equal Green and Blue make Cyan":
        return AppStrings.hintMixGB;
      case "Equal Red and Green make Yellow":
        return AppStrings.hintMixRG;
      case "Looks very pale (needs White)":
        return AppStrings.hintNeedsWhite;
      case "Looks very dark (needs Black)":
        return AppStrings.hintNeedsBlack;
      case "Observe the color carefully":
        return AppStrings.hintObserve;
      case "Perfect balance of colors":
        return AppStrings.hintBalanceAll;
      default:
        // Check if it's already a hint_ key
        if (hint.startsWith("hint_")) return hint;
        return AppStrings.hintObserve;
    }
  }

  void unlockNextLevel(int currentLevelIndex, int stars) {
    if (levels.isEmpty) return;

    // Update current level star
    int levelId = levels[currentLevelIndex].id;
    levelStars[levelId] = stars;

    // Unlock next level
    if (currentLevelIndex < levels.length - 1) {
      // Logic assumes levels are sorted by ID in the list matches index
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
