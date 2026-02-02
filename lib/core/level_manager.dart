import 'dart:math';
import 'package:color_mixing_deductive/core/color_logic.dart';
import 'package:color_mixing_deductive/core/level_model.dart';
import 'package:color_mixing_deductive/core/save_manager.dart';
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

  /// Classic Mode: Logical, step-by-step introduction to color theory
  List<LevelModel> _generateClassicLevels(int count) {
    final List<LevelModel> result = [];

    for (int i = 1; i <= count; i++) {
      int r = 0, g = 0, b = 0;
      int maxDrops = 10;
      double difficulty = i / count;

      if (i <= 3) {
        // Pure Primary Colors
        if (i == 1) r = 3;
        if (i == 2) g = 3;
        if (i == 3) b = 3;
        maxDrops = 6;
      } else if (i <= 9) {
        // Equal Binary Mixes (Yellow, Purple, Cyan)
        if (i <= 5) {
          r = 2;
          g = 2;
        } // Yellow
        else if (i <= 7) {
          r = 2;
          b = 2;
        } // Purple
        else {
          g = 2;
          b = 2;
        } // Cyan
        maxDrops = 8;
      } else if (i <= 20) {
        // Proportional Binary Mixes (Orange, Lime, etc)
        if (i % 3 == 0) {
          r = 4;
          g = 1;
        } else if (i % 3 == 1) {
          g = 4;
          b = 1;
        } else {
          b = 4;
          r = 1;
        }
        maxDrops = 10;
      } else if (i <= 50) {
        // Introduction to 3rd color
        r = 2 + (i % 4);
        g = 2 + ((i + 1) % 4);
        b = 1;
        maxDrops = 15;
      } else {
        // Complex tertiary shades
        final random = Random(i);
        r = random.nextInt(6) + 1;
        g = random.nextInt(6) + 1;
        b = random.nextInt(6) + 1;
        maxDrops = 20;
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
    final random = Random(12345);

    for (int i = 1; i <= count; i++) {
      double difficulty = i / count;
      int r = 0, g = 0, b = 0;
      int maxDrops = 12 + (i ~/ 10);

      // More random than classic but scaling complexity
      if (i <= 20) {
        r = random.nextInt(4);
        g = random.nextInt(4);
        if (r + g == 0) r = 2;
      } else if (i <= 50) {
        r = random.nextInt(5);
        g = random.nextInt(5);
        b = random.nextInt(3);
        if (r + g + b == 0) g = 3;
      } else {
        r = random.nextInt(7) + 1;
        g = random.nextInt(7) + 1;
        b = random.nextInt(7) + 1;
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
    if (r > 0 && g == 0 && b == 0) return "Think red. Just red.";
    if (g > 0 && r == 0 && b == 0) return "Go with pure green energy.";
    if (b > 0 && r == 0 && g == 0) return "Only the blue drops today.";

    if (r == g && r > 0 && b == 0) return "Mix red and green equally!";
    if (r == b && r > 0 && g == 0) return "A balanced mix of red and blue.";
    if (g == b && g > 0 && r == 0) return "Combine green and blue evenly.";

    if (r > g && r > b) {
      if (g > 0 && b > 0) return "Mostly red, with a splash of both others.";
      if (g > 0) return "Red is the base, add a bit of green.";
      return "Strong red with a touch of blue.";
    }

    if (g > r && g > b) {
      if (r > 0 && b > 0)
        return "Green is dominant here. Add a tiny bit of others.";
      if (r > 0) return "Start with green, then some red.";
      return "Mainly green, balanced with blue.";
    }

    if (b > r && b > g) {
      if (r > 0 && g > 0)
        return "A deep blue theme with slight hints of red and green.";
      if (r > 0) return "Blue first, then add red.";
      return "Lots of blue, just a little green.";
    }

    if (r == g && g == b && r > 0)
      return "The perfect balance of all three colors!";

    return "Observe the target closely and find the right mix.";
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
