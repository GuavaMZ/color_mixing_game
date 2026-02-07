import 'dart:convert';
import 'dart:math';
// import 'package:flutter/material.dart'; // Removed for script usage

class LevelGenerator {
  // Greatest Common Divisor for N numbers
  static int _gcd(int a, int b) {
    while (b != 0) {
      int t = b;
      b = a % b;
      a = t;
    }
    return a;
  }

  static int _gcdList(List<int> numbers) {
    if (numbers.isEmpty) return 1;
    int result = numbers[0];
    for (int i = 1; i < numbers.length; i++) {
      result = _gcd(result, numbers[i]);
    }
    return result;
  }

  static String _getRatioKey(int r, int g, int b, int w, int k) {
    final gcd = _gcdList([r, g, b, w, k]);
    if (gcd == 0) return "0-0-0-0-0";
    return "${r ~/ gcd}-${g ~/ gcd}-${b ~/ gcd}-${w ~/ gcd}-${k ~/ gcd}";
  }

  static List<Map<String, dynamic>> generateLevels(int targetCount) {
    List<Map<String, dynamic>> levels = [];
    Set<String> usedRatios = {};

    List<List<int>> candidateRecipes = [];

    // Generate up to 8 drops for complexity
    for (int totalDrops = 2; totalDrops <= 8; totalDrops++) {
      _generateCombinations(totalDrops, [], candidateRecipes);
    }

    for (var recipe in candidateRecipes) {
      int r = recipe[0];
      int g = recipe[1];
      int b = recipe[2];
      int w = recipe[3]; // White
      int k = recipe[4]; // Black

      if (r + g + b + w + k == 0) continue;

      String key = _getRatioKey(r, g, b, w, k);
      if (usedRatios.contains(key)) continue;

      usedRatios.add(key);

      // Calculate Difficulty Score
      int distinctComponents = [r, g, b, w, k].where((c) => c > 0).length;
      bool hasTintShade = w > 0 || k > 0;
      bool hasBoth = w > 0 && k > 0;

      double difficulty =
          (distinctComponents * 0.2) +
          (hasTintShade ? 0.3 : 0.0) +
          (hasBoth ? 0.4 : 0.0) +
          ((r + g + b + w + k) * 0.05);

      levels.add({
        'recipe': {'red': r, 'green': g, 'blue': b, 'white': w, 'black': k},
        'difficultyScore': difficulty,
        'totalDrops': r + g + b + w + k,
      });
    }

    // Sort by difficulty
    levels.sort((a, b) {
      int diffCompare = (a['difficultyScore'] as double).compareTo(
        b['difficultyScore'] as double,
      );
      if (diffCompare != 0) return diffCompare;
      return (a['totalDrops'] as int).compareTo(b['totalDrops'] as int);
    });

    if (levels.length > targetCount) {
      levels = levels.sublist(0, targetCount);
    }

    for (int i = 0; i < levels.length; i++) {
      levels[i]['id'] = i + 1;
      levels[i]['maxDrops'] =
          (levels[i]['totalDrops'] as int) + 3; // Strict but fair buffer
      levels[i]['difficultyFactor'] = (i / targetCount).clamp(0.0, 1.0);
      levels[i].remove('difficultyScore'); // Clean up
      levels[i].remove('totalDrops');
    }

    return levels;
  }

  static void _generateCombinations(
    int targetSum,
    List<int> current,
    List<List<int>> results,
  ) {
    if (current.length == 5) {
      if (current.reduce((a, b) => a + b) == targetSum) {
        results.add(List.from(current));
      }
      return;
    }

    int currentSum = current.isEmpty ? 0 : current.reduce((a, b) => a + b);
    int remaining = targetSum - currentSum;

    for (int i = 0; i <= remaining; i++) {
      List<int> next = List.from(current)..add(i);
      _generateCombinations(targetSum, next, results);
    }
  }
}

void main() {
  final levels = LevelGenerator.generateLevels(300);
  print(jsonEncode({'levels': levels}));
}
