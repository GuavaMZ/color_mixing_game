import 'dart:math';
import 'package:color_mixing_deductive/core/color_logic.dart';
import 'package:color_mixing_deductive/core/level_model.dart';
import 'package:flutter/material.dart';

class LevelManager {
  int currentLevelIndex = 0;
  late List<LevelModel> levels;

  LevelManager() {
    levels = _generateLevels();
  }

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

  /// Generate a progressive list of solvable levels
  List<LevelModel> _generateLevels() {
    return [
      // ===== BEGINNER LEVELS (2 colors) =====

      // Level 1: Pure Red (easiest - just one color)
      _createLevel(
        id: 1,
        recipe: {'red': 3, 'green': 0, 'blue': 0},
        availableColors: [Colors.red, Colors.green],
        maxDrops: 8,
        difficulty: 0.1,
        hint: 'Try using only red drops!',
      ),

      // Level 2: Pure Green
      _createLevel(
        id: 2,
        recipe: {'red': 0, 'green': 3, 'blue': 0},
        availableColors: [Colors.red, Colors.green],
        maxDrops: 8,
        difficulty: 0.15,
        hint: 'This time, use only green!',
      ),

      // Level 3: Yellow (Red + Green equally)
      _createLevel(
        id: 3,
        recipe: {'red': 2, 'green': 2, 'blue': 0},
        availableColors: [Colors.red, Colors.green],
        maxDrops: 10,
        difficulty: 0.25,
        hint: 'Mix red and green equally to make yellow!',
      ),

      // Level 4: Orange (More red than green)
      _createLevel(
        id: 4,
        recipe: {'red': 3, 'green': 1, 'blue': 0},
        availableColors: [Colors.red, Colors.green],
        maxDrops: 10,
        difficulty: 0.3,
        hint: 'Use more red than green for orange!',
      ),

      // Level 5: Lime (More green than red)
      _createLevel(
        id: 5,
        recipe: {'red': 1, 'green': 3, 'blue': 0},
        availableColors: [Colors.red, Colors.green],
        maxDrops: 10,
        difficulty: 0.35,
        hint: 'Use more green than red!',
      ),

      // ===== INTERMEDIATE LEVELS (3 colors) =====

      // Level 6: Pure Blue (introduction to third color)
      _createLevel(
        id: 6,
        recipe: {'red': 0, 'green': 0, 'blue': 3},
        availableColors: [Colors.red, Colors.green, Colors.blue],
        maxDrops: 10,
        difficulty: 0.4,
        hint: 'Now you have blue! Try using only blue drops.',
      ),

      // Level 7: Purple (Red + Blue)
      _createLevel(
        id: 7,
        recipe: {'red': 2, 'green': 0, 'blue': 2},
        availableColors: [Colors.red, Colors.green, Colors.blue],
        maxDrops: 12,
        difficulty: 0.45,
        hint: 'Mix red and blue equally for purple!',
      ),

      // Level 8: Cyan (Green + Blue)
      _createLevel(
        id: 8,
        recipe: {'red': 0, 'green': 2, 'blue': 2},
        availableColors: [Colors.red, Colors.green, Colors.blue],
        maxDrops: 12,
        difficulty: 0.5,
        hint: 'Mix green and blue equally for cyan!',
      ),

      // Level 9: Pink (More red, less blue)
      _createLevel(
        id: 9,
        recipe: {'red': 4, 'green': 0, 'blue': 1},
        availableColors: [Colors.red, Colors.green, Colors.blue],
        maxDrops: 12,
        difficulty: 0.55,
        hint: 'Use lots of red with just a touch of blue!',
      ),

      // Level 10: Brown (All three colors, red dominant)
      _createLevel(
        id: 10,
        recipe: {'red': 3, 'green': 2, 'blue': 1},
        availableColors: [Colors.red, Colors.green, Colors.blue],
        maxDrops: 15,
        difficulty: 0.6,
        hint: 'Mix all three colors! More red, medium green, less blue.',
      ),

      // ===== ADVANCED LEVELS =====

      // Level 11: Teal (Green + Blue, green dominant)
      _createLevel(
        id: 11,
        recipe: {'red': 0, 'green': 3, 'blue': 2},
        availableColors: [Colors.red, Colors.green, Colors.blue],
        maxDrops: 12,
        difficulty: 0.65,
        hint: 'More green than blue, no red!',
      ),

      // Level 12: Magenta (Red + Blue, red dominant)
      _createLevel(
        id: 12,
        recipe: {'red': 3, 'green': 0, 'blue': 2},
        availableColors: [Colors.red, Colors.green, Colors.blue],
        maxDrops: 12,
        difficulty: 0.7,
        hint: 'More red than blue, skip green!',
      ),

      // Level 13: Olive (Red + Green, green dominant)
      _createLevel(
        id: 13,
        recipe: {'red': 1, 'green': 4, 'blue': 0},
        availableColors: [Colors.red, Colors.green, Colors.blue],
        maxDrops: 12,
        difficulty: 0.72,
        hint: 'Lots of green with a little red!',
      ),

      // Level 14: Gray (Equal mix of all three)
      _createLevel(
        id: 14,
        recipe: {'red': 2, 'green': 2, 'blue': 2},
        availableColors: [Colors.red, Colors.green, Colors.blue],
        maxDrops: 15,
        difficulty: 0.75,
        hint: 'Mix all three colors equally!',
      ),

      // Level 15: Sky Blue (More blue, some green, tiny red)
      _createLevel(
        id: 15,
        recipe: {'red': 1, 'green': 2, 'blue': 4},
        availableColors: [Colors.red, Colors.green, Colors.blue],
        maxDrops: 15,
        difficulty: 0.8,
        hint: 'Lots of blue, medium green, just a touch of red!',
      ),

      // ===== EXPERT LEVELS =====

      // Level 16: Coral (Complex red-orange-pink)
      _createLevel(
        id: 16,
        recipe: {'red': 5, 'green': 2, 'blue': 2},
        availableColors: [Colors.red, Colors.green, Colors.blue],
        maxDrops: 18,
        difficulty: 0.85,
        hint: 'Dominant red with equal green and blue!',
      ),

      // Level 17: Lavender (Subtle purple-pink)
      _createLevel(
        id: 17,
        recipe: {'red': 3, 'green': 1, 'blue': 4},
        availableColors: [Colors.red, Colors.green, Colors.blue],
        maxDrops: 18,
        difficulty: 0.88,
        hint: 'More blue than red, minimal green!',
      ),

      // Level 18: Peach (Delicate orange)
      _createLevel(
        id: 18,
        recipe: {'red': 4, 'green': 3, 'blue': 1},
        availableColors: [Colors.red, Colors.green, Colors.blue],
        maxDrops: 18,
        difficulty: 0.9,
        hint: 'Lots of red, good amount of green, tiny blue!',
      ),

      // Level 19: Mint (Subtle cyan-green)
      _createLevel(
        id: 19,
        recipe: {'red': 1, 'green': 4, 'blue': 3},
        availableColors: [Colors.red, Colors.green, Colors.blue],
        maxDrops: 18,
        difficulty: 0.93,
        hint: 'More green than blue, minimal red!',
      ),

      // Level 20: Burgundy (Deep red-purple) - FINAL CHALLENGE
      _createLevel(
        id: 20,
        recipe: {'red': 5, 'green': 1, 'blue': 3},
        availableColors: [Colors.red, Colors.green, Colors.blue],
        maxDrops: 20,
        difficulty: 0.95,
        hint: 'Master level! Lots of red, some blue, minimal green!',
      ),
    ];
  }

  /// Helper method to create a level from a recipe
  LevelModel _createLevel({
    required int id,
    required Map<String, int> recipe,
    required List<Color> availableColors,
    required int maxDrops,
    required double difficulty,
    String hint = '',
  }) {
    // Calculate the target color from the recipe
    final Color targetColor = ColorLogic.createMixedColor(
      recipe['red'] ?? 0,
      recipe['green'] ?? 0,
      recipe['blue'] ?? 0,
    );

    return LevelModel(
      id: id,
      maxDrops: maxDrops,
      difficultyFactor: difficulty,
      availableColors: availableColors,
      targetColor: targetColor,
      recipe: recipe,
      hint: hint,
    );
  }

  /// Get a random level of specific difficulty
  LevelModel getRandomLevelByDifficulty(
    double minDifficulty,
    double maxDifficulty,
  ) {
    final filteredLevels = levels
        .where(
          (level) =>
              level.difficultyFactor >= minDifficulty &&
              level.difficultyFactor <= maxDifficulty,
        )
        .toList();

    if (filteredLevels.isEmpty) return levels[0];

    return filteredLevels[Random().nextInt(filteredLevels.length)];
  }

  /// Get total number of levels
  int get totalLevels => levels.length;

  /// Get completion percentage
  double get completionPercentage => (currentLevelIndex / totalLevels) * 100;
}
