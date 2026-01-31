import 'package:color_mixing_deductive/core/level_model.dart';
import 'package:flutter/material.dart';

class LevelManager {
  int currentLevelIndex = 0;

  final List<LevelModel> levels = [
    LevelModel(
      id: 1,
      maxDrops: 10,
      difficultyFactor: 0.3,
      availableColors: [Colors.red, Colors.green],
    ),
    LevelModel(
      id: 2,
      maxDrops: 15,
      difficultyFactor: 0.5,
      availableColors: [Colors.red, Colors.green, Colors.blue],
    ),
    LevelModel(
      id: 3,
      maxDrops: 12,
      difficultyFactor: 0.8,
      availableColors: [Colors.red, Colors.green, Colors.blue],
    ),
  ];

  LevelModel get currentLevel => levels[currentLevelIndex];

  bool nextLevel() {
    if (currentLevelIndex < levels.length - 1) {
      currentLevelIndex++;
      return true; // فيه ليفل كمان
    }
    return false; // خلصنا كل الليفلات
  }

  void reset() {
    currentLevelIndex = 0;
  }
}
