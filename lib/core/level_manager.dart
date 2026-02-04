import 'dart:math';
import 'package:color_mixing_deductive/core/color_logic.dart';
import 'package:color_mixing_deductive/core/level_model.dart';
import 'package:color_mixing_deductive/core/save_manager.dart';
import 'package:color_mixing_deductive/helpers/string_manager.dart';
import 'package:flutter/material.dart';

class LevelManager {
  int currentLevelIndex = 0;
  List<LevelModel> classicLevels = [];
  List<LevelModel> timeAttackLevels = [];

  Map<int, int> classicLevelStars = {};
  Map<int, int> timeAttackLevelStars = {};

  String currentMode = 'classic';

  LevelManager() {
    classicLevels = _generateClassicLevels(100);
    timeAttackLevels = _generateTimeAttackLevels(100);

    // Default initialization (will be overwritten by initProgress)
    for (int i = 0; i < 100; i++) {
      classicLevelStars[i] = i == 0 ? 0 : -1;
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

  Future<void> initProgress() async {
    classicLevelStars = await SaveManager.loadProgress('classic');
    timeAttackLevelStars = await SaveManager.loadProgress('timeAttack');

    if (classicLevelStars.isEmpty || (classicLevelStars[0] ?? -1) == -1) {
      classicLevelStars[0] = 0;
    }
    if (timeAttackLevelStars.isEmpty || (timeAttackLevelStars[0] ?? -1) == -1) {
      timeAttackLevelStars[0] = 0;
    }
  }

  int _gcd(int a, int b) {
    while (b != 0) {
      int t = b;
      b = a % b;
      a = t;
    }
    return a;
  }

  int _gcd3(int a, int b, int c) {
    if (a == 0 && b == 0 && c == 0) return 1;
    // Handle cases where some are zero
    int res = a;
    if (b > 0) res = (res == 0) ? b : _gcd(res, b);
    if (c > 0) res = (res == 0) ? c : _gcd(res, c);
    return res;
  }

  String _getRatioKey(int r, int g, int b) {
    if (r == 0 && g == 0 && b == 0) return "0-0-0";
    final common = _gcd3(r, g, b);
    return "${r ~/ common}-${g ~/ common}-${b ~/ common}";
  }

  /// Classic Mode: Logical, step-by-step introduction to color theory
  List<LevelModel> _generateClassicLevels(int count) {
    final List<LevelModel> result = [];
    final Set<String> usedRatios = {};

    for (int i = 1; i <= count; i++) {
      int r = 0, g = 0, b = 0;
      int maxDrops = 10;
      double difficulty = i / count;

      // Smart loop to ensure uniqueness
      bool uniqueFound = false;
      int attempts = 0;
      final rng = Random(i + 100);

      while (!uniqueFound && attempts < 100) {
        attempts++;
        if (i <= 3) {
          // Phase 1: Pure Primaries (Only 3 possible unique ratios)
          if (i == 1)
            r = 3;
          else if (i == 2)
            g = 3;
          else
            b = 3;
          maxDrops = 8;
        } else if (i <= 12) {
          // Phase 2: Fundamental Binary Mixes (Yellow, Cyan, Magenta)
          // Ratios: 1:1, 2:1, 1:2
          final combination = (i - 4) % 3;
          final ratioType = (i - 4) ~/ 3; // 0=1:1, 1=2:1, 2=1:2

          int val1 = (ratioType == 2) ? 1 : 2;
          int val2 = (ratioType == 1) ? 1 : 2;
          if (ratioType == 0) {
            val1 = 2;
            val2 = 2;
          }

          if (combination == 0) {
            r = val1;
            g = val2;
            b = 0;
          } else if (combination == 1) {
            g = val1;
            b = val2;
            r = 0;
          } else {
            b = val1;
            r = val2;
            g = 0;
          }
          maxDrops = 10;
        } else if (i <= 35) {
          // Phase 3: Tertiary Colors (Varied Binary Mixes)
          final combination = i % 3;
          r = 0;
          g = 0;
          b = 0;
          int v1 = rng.nextInt(5) + 1;
          int v2 = rng.nextInt(5) + 1;
          if (combination == 0) {
            r = v1;
            g = v2;
          } else if (combination == 1) {
            g = v1;
            b = v2;
          } else {
            b = v1;
            r = v2;
          }
          maxDrops = 12;
        } else if (i <= 65) {
          // Phase 4: Introduction to 3rd Color (Low saturation)
          r = rng.nextInt(6) + 2;
          g = rng.nextInt(6) + 2;
          b = rng.nextInt(6) + 2;
          // Force one to be the "contaminant" (very low)
          final weak = rng.nextInt(3);
          if (weak == 0)
            r = 1;
          else if (weak == 1)
            g = 1;
          else
            b = 1;
          maxDrops = 15;
        } else {
          // Phase 5: Complex RGB Master Levels
          r = rng.nextInt(10) + 2;
          g = rng.nextInt(10) + 2;
          b = rng.nextInt(10) + 2;
          maxDrops = 20;
        }

        final key = _getRatioKey(r, g, b);
        if (!usedRatios.contains(key) && (r + g + b > 0)) {
          usedRatios.add(key);
          uniqueFound = true;
        }
      }

      result.add(
        _createLevel(
          id: i,
          recipe: {'red': r, 'green': g, 'blue': b},
          maxDrops: maxDrops,
          difficulty: difficulty,
        ),
      );
    }
    return result;
  }

  /// Time Attack Mode: Faster paced, more randomized but still progressive
  List<LevelModel> _generateTimeAttackLevels(int count) {
    final List<LevelModel> result = [];
    final Set<String> usedRatios = {};

    for (int i = 1; i <= count; i++) {
      final random = Random(i + 2000);
      double difficulty = i / count;
      int r = 0, g = 0, b = 0;
      int maxDrops = 10 + (i ~/ 5);

      bool uniqueFound = false;
      int attempts = 0;

      while (!uniqueFound && attempts < 100) {
        attempts++;
        if (i <= 15) {
          // Early levels: mostly 1 or 2 colors
          if (random.nextBool()) {
            r = random.nextInt(5) + 1;
            g = random.nextInt(5);
          } else {
            g = random.nextInt(5) + 1;
            b = random.nextInt(5);
          }
        } else {
          // Later levels: full complexity
          r = random.nextInt(12) + 1;
          g = random.nextInt(12) + 1;
          b = random.nextInt(12) + 1;
        }

        if (r + g + b == 0) r = 5;

        final key = _getRatioKey(r, g, b);
        if (!usedRatios.contains(key)) {
          usedRatios.add(key);
          uniqueFound = true;
        }
      }

      result.add(
        _createLevel(
          id: i,
          recipe: {'red': r, 'green': g, 'blue': b},
          maxDrops: maxDrops,
          difficulty: difficulty,
        ),
      );
    }
    return result;
  }

  LevelModel _createLevel({
    required int id,
    required Map<String, int> recipe,
    required int maxDrops,
    required double difficulty,
  }) {
    final int r = recipe['red'] ?? 0;
    final int g = recipe['green'] ?? 0;
    final int b = recipe['blue'] ?? 0;

    final Color targetColor = ColorLogic.createMixedColor(r, g, b);

    return LevelModel(
      id: id,
      maxDrops: maxDrops,
      difficultyFactor: difficulty,
      availableColors: [Colors.red, Colors.green, Colors.blue],
      targetColor: targetColor,
      recipe: recipe,
      hint: _generateSmartHint(r, g, b),
    );
  }

  String _generateSmartHint(int r, int g, int b) {
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

  void unlockNextLevel(int currentLvlIdx, int stars) {
    levelStars[currentLvlIdx] = stars;

    int nextLvl = currentLvlIdx + 1;
    if (nextLvl < 100) {
      if ((levelStars[nextLvl] ?? -1) == -1) {
        levelStars[nextLvl] = 0;
      }
    }

    SaveManager.saveProgress(levelStars, currentMode);
  }

  int get totalLevels => levels.length;

  int get totalStarsEarned {
    return levelStars.values.where((s) => s > 0).fold(0, (sum, s) => sum + s);
  }
}
