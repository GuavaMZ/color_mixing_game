import 'dart:convert';
import 'dart:io';
import 'dart:math';

// Standalone runner for generating levels.json
void main() {
  final generator = LevelGenerator();
  final levels = generator.generateLevels(500);

  // Create output file
  final file = File('assets/levels.json');
  final jsonContent = jsonEncode({'levels': levels});

  file.writeAsStringSync(jsonContent);
  print('Successfully generated ${levels.length} levels to assets/levels.json');
}

class LevelGenerator {
  final Random _rng = Random(42); // Fixed seed for reproducibility

  List<Map<String, dynamic>> generateLevels(int targetCount) {
    List<Map<String, dynamic>> levels = [];
    final Set<String> usedRecipes = {};

    // --- Phase 1: Tutorial & Basics (1-20) ---
    // Primary colors and simple 1:1 mixes
    levels.addAll(
      _generatePhase(
        startId: 1,
        count: 20,
        complexity: 1, // 1-2 colors
        allowWhite: false,
        allowBlack: false,
        usedRecipes: usedRecipes,
        phaseName: "Basics",
      ),
    );

    // --- Phase 2: Tints (21-60) ---
    // Introducing White (Pastels/Tints)
    levels.addAll(
      _generatePhase(
        startId: 21,
        count: 40,
        complexity: 2, // 2-3 colors
        allowWhite: true,
        allowBlack: false,
        usedRecipes: usedRecipes,
        phaseName: "Tints",
      ),
    );

    // --- Phase 3: Shades (61-120) ---
    // Introducing Black (Shades) & Complex Ratios
    levels.addAll(
      _generatePhase(
        startId: 61,
        count: 60,
        complexity: 3, // 2-3 colors
        allowWhite: false,
        allowBlack: true,
        usedRecipes: usedRecipes,
        phaseName: "Shades",
      ),
    );

    // --- Phase 4: Tertiary & Muddy (121-250) ---
    // Mixing 3+ colors, including Grey (White + Black)
    levels.addAll(
      _generatePhase(
        startId: 121,
        count: 130,
        complexity: 4, // 3-4 colors
        allowWhite: true,
        allowBlack: true,
        usedRecipes: usedRecipes,
        phaseName: "Advanced Mixing",
      ),
    );

    // --- Phase 5: Expert (251-400) ---
    // High complexity, subtle differences
    levels.addAll(
      _generatePhase(
        startId: 251,
        count: 150,
        complexity: 5, // 4-5 colors
        allowWhite: true,
        allowBlack: true,
        usedRecipes: usedRecipes,
        phaseName: "Expert",
      ),
    );

    // --- Phase 6: Grandmaster (401-500) ---
    // Max complexity, high drops, frequent blind levels
    levels.addAll(
      _generatePhase(
        startId: 401,
        count: 100,
        complexity: 6, // 5 colors
        allowWhite: true,
        allowBlack: true,
        usedRecipes: usedRecipes,
        phaseName: "Grandmaster",
      ),
    );

    // FAILSAFE: Ensure we have exactly targetCount levels
    while (levels.length < targetCount) {
      final last = levels.last;
      levels.add({
        'id': levels.length + 1,
        'recipe': Map<String, int>.from(last['recipe']),
        'maxDrops': last['maxDrops'],
        'difficultyFactor': last['difficultyFactor'],
        'isBlindMode': last['isBlindMode'],
        'hint': last['hint'],
      });
      print("Filled missing level ${levels.length} with duplicate.");
    }

    return levels;
  }

  List<Map<String, dynamic>> _generatePhase({
    required int startId,
    required int count,
    required int complexity,
    required bool allowWhite,
    required bool allowBlack,
    required Set<String> usedRecipes,
    required String phaseName,
  }) {
    List<Map<String, dynamic>> phaseLevels = [];
    int generated = 0;
    int attempts = 0;

    while (generated < count && attempts < 2000000) {
      attempts++;

      // 1. Generate Recipe based on complexity
      Map<String, int> recipe = _createRecipe(
        complexity,
        allowWhite,
        allowBlack,
      );

      // 2. Validate & Normalize
      if (_isRecipeEmpty(recipe)) continue;

      final key = _getRecipeKey(recipe);
      if (usedRecipes.contains(key)) continue;

      // 3. Calculate props
      int totalDrops = recipe.values.reduce((a, b) => a + b);
      // Complexity Check: Skip if too simple for late phases
      int distinctColors = recipe.values.where((v) => v > 0).length;
      if (complexity >= 4 && distinctColors < 3 && attempts < 100000) continue;
      if (complexity >= 6 && distinctColors < 4 && attempts < 100000) continue;

      // 4. Accept Level
      usedRecipes.add(key);

      double difficulty = _calculateDifficulty(startId + generated, 500);
      bool isBlind = _shouldBeBlind(startId + generated);
      int maxDrops = (totalDrops * 1.5).ceil() + 2;
      // Grandmaster restriction
      if (complexity == 6) maxDrops = totalDrops + 5;

      phaseLevels.add({
        'id': startId + generated,
        'recipe': recipe,
        'maxDrops': maxDrops,
        'difficultyFactor': difficulty,
        'isBlindMode': isBlind,
        'hint': _generateHint(recipe),
      });
      generated++;
    }

    // Fill remaining if generation failed (shouldn't happen with valid logic)
    if (generated < count) {
      print(
        "Warning: Could not generate unique levels for phase $phaseName. Generated $generated/$count",
      );
    }

    return phaseLevels;
  }

  Map<String, int> _createRecipe(
    int complexity,
    bool allowWhite,
    bool allowBlack,
  ) {
    int r = 0, g = 0, b = 0, w = 0, k = 0;

    // Base colors (R, G, B)
    // Complexity 1: 1-2 colors, low drops
    // Complexity 6: All colors, high drops

    int maxValPerColor = complexity <= 2
        ? 3
        : (complexity <= 4 ? 5 : (complexity <= 5 ? 8 : 20));

    // Determine how many distinct colors to pick
    int colorsToPick = 1;
    if (complexity == 1)
      colorsToPick = _rng.nextInt(2) + 1; // 1 or 2
    else if (complexity == 2)
      colorsToPick = _rng.nextInt(2) + 2; // 2 or 3
    else if (complexity == 3)
      colorsToPick = _rng.nextInt(2) + 2; // 2 or 3
    else if (complexity == 4)
      colorsToPick = _rng.nextInt(3) + 3; // 3 to 5
    else
      colorsToPick = _rng.nextInt(3) + 3; // 3 to 5

    List<int> choices = [0, 1, 2]; // Indices for R, G, B
    if (allowWhite) choices.add(3);
    if (allowBlack) choices.add(4);

    choices.shuffle(_rng);

    for (int i = 0; i < colorsToPick && i < choices.length; i++) {
      int val = _rng.nextInt(maxValPerColor) + 1;
      switch (choices[i]) {
        case 0:
          r = val;
          break;
        case 1:
          g = val;
          break;
        case 2:
          b = val;
          break;
        case 3:
          w = val;
          break;
        case 4:
          k = val;
          break;
      }
    }

    // Special case for Phase 1 (Tutorial consistency)
    if (complexity == 1 && r + g + b + w + k > 4) {
      // Simplify
      return _createRecipe(1, false, false);
    }

    return {'red': r, 'green': g, 'blue': b, 'white': w, 'black': k};
  }

  bool _isRecipeEmpty(Map<String, int> r) {
    return (r['red']! + r['green']! + r['blue']! + r['white']! + r['black']!) ==
        0;
  }

  String _getRecipeKey(Map<String, int> r) {
    // Simplify ratio
    int gcd = _gcdList([
      r['red']!,
      r['green']!,
      r['blue']!,
      r['white']!,
      r['black']!,
    ]);
    return "${r['red']! ~/ gcd}-${r['green']! ~/ gcd}-${r['blue']! ~/ gcd}-${r['white']! ~/ gcd}-${r['black']! ~/ gcd}";
  }

  double _calculateDifficulty(int id, int total) {
    return (id / total).clamp(0.0, 1.0);
  }

  bool _shouldBeBlind(int id) {
    // Boss levels logic
    if (id <= 20) return false;
    if (id > 400) return id % 5 == 0; // Frequent in GM
    if (id % 10 == 0) return true; // Every 10th level usually
    return false;
  }

  String _generateHint(Map<String, int> recipe) {
    int r = recipe['red']!;
    int g = recipe['green']!;
    int b = recipe['blue']!;
    int w = recipe['white']!;
    int k = recipe['black']!;

    int total = r + g + b + w + k;
    if (total == 0) return "Empty?";

    // Tutorial Hints
    if (w == 0 && k == 0) {
      if (r > 0 && g == 0 && b == 0) return "Just Red";
      if (g > 0 && r == 0 && b == 0) return "Just Green";
      if (b > 0 && r == 0 && g == 0) return "Just Blue";
      if (r == g && b == 0) return "Equal Red and Green make Yellow";
      if (r == b && g == 0) return "Equal Red and Blue make Magenta";
      if (g == b && r == 0) return "Equal Green and Blue make Cyan";
    }

    // Dominant Color Hints
    String dominant = "";
    int maxVal = 0;
    if (r > maxVal) {
      maxVal = r;
      dominant = "Red";
    }
    if (g > maxVal) {
      maxVal = g;
      dominant = "Green";
    }
    if (b > maxVal) {
      maxVal = b;
      dominant = "Blue";
    }
    if (w > maxVal) {
      maxVal = w;
      dominant = "White";
    }
    if (k > maxVal) {
      maxVal = k;
      dominant = "Black";
    }

    if (w > 0 && w >= total * 0.4) return "Looks very pale (needs White)";
    if (k > 0 && k >= total * 0.4) return "Looks very dark (needs Black)";
    if (r == g && g == b && r > 0) return "Perfect balance of colors";

    if (maxVal >= total * 0.5) return "Mostly $dominant";

    return "Observe the color carefully";
  }

  int _gcd(int a, int b) {
    while (b != 0) {
      int t = b;
      b = a % b;
      a = t;
    }
    return a;
  }

  int _gcdList(List<int> numbers) {
    if (numbers.isEmpty) return 1;
    int result = numbers[0];
    for (int i = 1; i < numbers.length; i++) {
      result = _gcd(result, numbers[i]);
    }
    return result;
  }
}
