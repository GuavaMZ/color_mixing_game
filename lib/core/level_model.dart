import 'package:flutter/material.dart';

class LevelModel {
  final int id;
  final int maxDrops;
  final double difficultyFactor; // 0 to 1 (determines target color complexity)
  final List<Color> availableColors;
  final Color targetColor; // The color to achieve
  final Map<String, int>
  recipe; // The solution recipe (e.g., {'red': 2, 'green': 1})
  final String hint; // Optional hint for the player
  final bool isBlindMode; // If true, beaker content is hidden

  LevelModel({
    required this.id,
    required this.maxDrops,
    required this.difficultyFactor,
    required this.availableColors,
    required this.targetColor,
    required this.recipe,
    this.hint = '',
    this.isBlindMode = false,
  });

  /// Get the minimum number of drops needed to solve this level
  int get minDropsNeeded {
    return recipe.values.fold(0, (sum, drops) => sum + drops);
  }

  /// Check if this level uses only 2 colors (easier)
  bool get isTwoColorLevel {
    return recipe.values.where((drops) => drops > 0).length == 2;
  }

  /// Get difficulty rating (1-5 stars)
  int get difficultyStars {
    if (difficultyFactor < 0.3) return 1;
    if (difficultyFactor < 0.5) return 2;
    if (difficultyFactor < 0.7) return 3;
    if (difficultyFactor < 0.9) return 4;
    return 5;
  }
}
