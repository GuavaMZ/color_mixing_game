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

    // --- Phase 1: The Basics (1-20) ---
    // Primaries, Secondaries, Simple ratios (2:1, 1:2)
    levels.addAll(
      _generatePhase(
        startId: 1,
        count: 20,
        generatorRule: _generateBasicColors,
        usedRecipes: usedRecipes,
        phaseName: "Basics",
      ),
    );

    // --- Phase 2: Light & Dark (21-60) ---
    // Pure Tints & Shades + Secondary Tints/Shades
    levels.addAll(
      _generatePhase(
        startId: 21,
        count: 40,
        generatorRule: _generateTintsAndShades,
        usedRecipes: usedRecipes,
        phaseName: "Tints & Shades",
      ),
    );

    // --- Phase 3: Tertiary & Tones (61-120) ---
    // 3:1 or 4:1 ratios, Grays (W+K), White+Black combos with 1 color
    levels.addAll(
      _generatePhase(
        startId: 61,
        count: 60,
        generatorRule: _generateTertiaryAndTones,
        usedRecipes: usedRecipes,
        phaseName: "Tertiary & Tones",
      ),
    );

    // --- Phase 4: Advanced Mixing (121-250) ---
    // Structured 3-color ratios (3:2:1, occasionally tinted/shaded)
    levels.addAll(
      _generatePhase(
        startId: 121,
        count: 130,
        generatorRule: _generateAdvancedMixes,
        usedRecipes: usedRecipes,
        phaseName: "Advanced Mixing",
      ),
    );

    // --- Phase 5: Expert (251-400) ---
    // 4 colors (R, G, B, W/K) or subtle differences, higher drop counts
    levels.addAll(
      _generatePhase(
        startId: 251,
        count: 150,
        generatorRule: _generateExpertMixes,
        usedRecipes: usedRecipes,
        phaseName: "Expert",
      ),
    );

    // --- Phase 6: Grandmaster (401-500) ---
    // Max complexity, occasional 5 colors
    levels.addAll(
      _generatePhase(
        startId: 401,
        count: 100,
        generatorRule: _generateGrandmasterMixes,
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
    required Map<String, int> Function(int attempt) generatorRule,
    required Set<String> usedRecipes,
    required String phaseName,
  }) {
    List<Map<String, dynamic>> phaseLevels = [];
    int generated = 0;
    int attempts = 0;

    // Hardcoded some basic first levels if Phase 1 to guarantee exact starting levels
    if (phaseName == "Basics") {
      final basicsList = [
        {'red': 1, 'green': 0, 'blue': 0, 'white': 0, 'black': 0}, // Red
        {'red': 0, 'green': 1, 'blue': 0, 'white': 0, 'black': 0}, // Green
        {'red': 0, 'green': 0, 'blue': 1, 'white': 0, 'black': 0}, // Blue
        {'red': 1, 'green': 1, 'blue': 0, 'white': 0, 'black': 0}, // Yellow
        {'red': 1, 'green': 0, 'blue': 1, 'white': 0, 'black': 0}, // Magenta
        {'red': 0, 'green': 1, 'blue': 1, 'white': 0, 'black': 0}, // Cyan
        {'red': 2, 'green': 1, 'blue': 0, 'white': 0, 'black': 0}, // Orange
        {'red': 1, 'green': 2, 'blue': 0, 'white': 0, 'black': 0}, // Lime
        {'red': 2, 'green': 0, 'blue': 1, 'white': 0, 'black': 0}, // Pinkish
        {'red': 1, 'green': 0, 'blue': 2, 'white': 0, 'black': 0}, // Purple
        {'red': 0, 'green': 2, 'blue': 1, 'white': 0, 'black': 0}, // Mint
        {'red': 0, 'green': 1, 'blue': 2, 'white': 0, 'black': 0}, // Azure
      ];

      for (var recipe in basicsList) {
        if (generated >= count) break;

        final key = _getRecipeKey(recipe);
        if (!usedRecipes.contains(key)) {
          usedRecipes.add(key);
          phaseLevels.add(
            _buildLevelInfo(
              startId: startId,
              generated: generated,
              recipe: recipe,
              totalLevels: 500,
              phaseName: phaseName,
            ),
          );
          generated++;
        }
      }
    }

    while (generated < count && attempts < 200000) {
      attempts++;

      Map<String, int> recipe = generatorRule(attempts);

      // Validate & Normalize
      if (_isRecipeEmpty(recipe)) continue;

      final key = _getRecipeKey(recipe);
      if (usedRecipes.contains(key)) continue;

      int totalDrops = recipe.values.reduce((a, b) => a + b);
      if (totalDrops > 25) continue; // safety

      usedRecipes.add(key);

      phaseLevels.add(
        _buildLevelInfo(
          startId: startId,
          generated: generated,
          recipe: recipe,
          totalLevels: 500,
          phaseName: phaseName,
        ),
      );

      generated++;
    }

    if (generated < count) {
      print(
        "Warning: Could not generate unique levels for phase $phaseName. Generated $generated/$count",
      );
    }

    return phaseLevels;
  }

  Map<String, dynamic> _buildLevelInfo({
    required int startId,
    required int generated,
    required Map<String, int> recipe,
    required int totalLevels,
    required String phaseName,
  }) {
    int id = startId + generated;
    int totalDrops = recipe.values.reduce((a, b) => a + b);

    double difficulty = _calculateDifficulty(id, totalLevels);
    bool isBlind = _shouldBeBlind(id, phaseName);

    int maxDrops = (totalDrops * 1.5).ceil() + 2;

    if (phaseName == "Expert") maxDrops = totalDrops + 5;
    if (phaseName == "Grandmaster") maxDrops = totalDrops + 3;

    return {
      'id': id,
      'recipe': recipe,
      'maxDrops': maxDrops,
      'difficultyFactor': difficulty,
      'isBlindMode': isBlind,
      'hint': _generateHint(recipe),
    };
  }

  // --- Generator Rules ---

  Map<String, int> _generateBasicColors(int attempt) {
    // Fallback if hardcoded basics ran out
    int r = 0, g = 0, b = 0;
    int type = _rng.nextInt(4);
    if (type == 0) {
      // Primary
      int c = _rng.nextInt(3);
      if (c == 0)
        r = _rng.nextInt(3) + 1;
      else if (c == 1)
        g = _rng.nextInt(3) + 1;
      else
        b = _rng.nextInt(3) + 1;
    } else if (type == 1) {
      // Secondary 1:1
      int val = _rng.nextInt(3) + 1;
      int skip = _rng.nextInt(3);
      if (skip != 0) r = val;
      if (skip != 1) g = val;
      if (skip != 2) b = val;
    } else if (type == 2) {
      // Ratio 2:1 or 3:1 or 4:1
      int main = _rng.nextInt(3);
      int sec = (main + 1 + _rng.nextInt(2)) % 3;

      int val1 = _rng.nextInt(3) + 2; // 2, 3, or 4
      int val2 = 1;

      if (main == 0)
        r = val1;
      else if (main == 1)
        g = val1;
      else
        b = val1;

      if (sec == 0)
        r = val2;
      else if (sec == 1)
        g = val2;
      else
        b = val2;
    } else {
      // Ratio 3:2
      int main = _rng.nextInt(3);
      int sec = (main + 1 + _rng.nextInt(2)) % 3;

      int val1 = 3;
      int val2 = 2;

      if (main == 0)
        r = val1;
      else if (main == 1)
        g = val1;
      else
        b = val1;

      if (sec == 0)
        r = val2;
      else if (sec == 1)
        g = val2;
      else
        b = val2;
    }
    return {'red': r, 'green': g, 'blue': b, 'white': 0, 'black': 0};
  }

  Map<String, int> _generateTintsAndShades(int attempt) {
    int r = 0, g = 0, b = 0, w = 0, k = 0;

    // Choose base color style: Primary or Secondary
    int skip = _rng.nextInt(3);
    int baseVal1 = _rng.nextInt(2) + 1;
    int baseVal2 = _rng.nextInt(2) == 0 ? baseVal1 : 0; // chance for secondary

    if (skip != 0) r = baseVal1;
    if (skip != 1) g = r == 0 ? baseVal1 : baseVal2;
    if (r == 0 && g == 0) {
      g = baseVal1;
      b = baseVal1;
    } else if (r > 0 && g == 0)
      b = baseVal2;
    else if (r == 0 && g > 0)
      b = baseVal2;

    if (r == 0 && g == 0 && b == 0) r = 1;

    // Apply tint or shade
    bool isTint = _rng.nextBool();
    int strength = _rng.nextInt(3) + 1; // 1 to 3
    if (isTint)
      w = strength;
    else
      k = strength;

    return {'red': r, 'green': g, 'blue': b, 'white': w, 'black': k};
  }

  Map<String, int> _generateTertiaryAndTones(int attempt) {
    int r = 0, g = 0, b = 0, w = 0, k = 0;

    int type = _rng.nextInt(3);
    if (type == 0) {
      // 3:1:1 complex ratios basically
      r = _rng.nextInt(4);
      g = _rng.nextInt(4);
      b = _rng.nextInt(4);
      if (r == 0 && g == 0 && b == 0) r = 3;
      // Guarantee exactly one 0
      int zeros = (r == 0 ? 1 : 0) + (g == 0 ? 1 : 0) + (b == 0 ? 1 : 0);
      if (zeros == 0) r = 0; // force a 0
      if (zeros == 2) {
        // Need at least two non-zeros
        if (r == 0) g = 1;
        if (b == 0) b = 1;
      }
    } else if (type == 1) {
      // One color + grey (W+K)
      int c = _rng.nextInt(3);
      if (c == 0)
        r = _rng.nextInt(3) + 1;
      else if (c == 1)
        g = _rng.nextInt(3) + 1;
      else
        b = _rng.nextInt(3) + 1;

      w = _rng.nextInt(2) + 1;
      k = _rng.nextInt(2) + 1;
    } else {
      // Tints & shades of mixed ratios
      r = _rng.nextInt(3) + 1;
      g = _rng.nextInt(3) + 1;
      if (_rng.nextBool()) b = 1;

      if (_rng.nextBool()) w = _rng.nextInt(2) + 1;
      if (_rng.nextBool()) k = _rng.nextInt(2) + 1;

      // Prevent muddy (w & k together in complex)
      if (w > 0 && k > 0) {
        if (_rng.nextBool())
          w = 0;
        else
          k = 0;
      }
    }
    return {'red': r, 'green': g, 'blue': b, 'white': w, 'black': k};
  }

  Map<String, int> _generateAdvancedMixes(int attempt) {
    int r = _rng.nextInt(5);
    int g = _rng.nextInt(5);
    int b = _rng.nextInt(5);
    int w = 0;
    int k = 0;

    // Ensure all 3 colors exist (complex advanced mix)
    if (r == 0) r = 1;
    if (g == 0) g = 1;
    if (b == 0) b = 1;

    // Maybe add White or Black
    if (_rng.nextBool()) {
      w = _rng.nextInt(3) + 1;
    } else if (_rng.nextBool()) {
      k = _rng.nextInt(3) + 1;
    }

    return {'red': r, 'green': g, 'blue': b, 'white': w, 'black': k};
  }

  Map<String, int> _generateExpertMixes(int attempt) {
    int r = _rng.nextInt(6);
    int g = _rng.nextInt(6);
    int b = _rng.nextInt(6);
    int w = _rng.nextInt(3);
    int k = _rng.nextInt(3);

    // Allow up to 4 colors
    if (w > 0 && k > 0) {
      // Reduce chance of both W and K
      if (_rng.nextBool())
        w = 0;
      else
        k = 0;
    }
    if (r + g + b == 0) r = 2;
    return {'red': r, 'green': g, 'blue': b, 'white': w, 'black': k};
  }

  Map<String, int> _generateGrandmasterMixes(int attempt) {
    int r = _rng.nextInt(7) + 1;
    int g = _rng.nextInt(7) + 1;
    int b = _rng.nextInt(7) + 1;
    int w = _rng.nextInt(4);
    int k = _rng.nextInt(4);

    // Allow all 5 colors occasionally!
    return {'red': r, 'green': g, 'blue': b, 'white': w, 'black': k};
  }

  // --- Utilities ---

  bool _isRecipeEmpty(Map<String, int> r) {
    return (r['red']! + r['green']! + r['blue']! + r['white']! + r['black']!) ==
        0;
  }

  String _getRecipeKey(Map<String, int> r) {
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

  bool _shouldBeBlind(int id, String phaseName) {
    if (phaseName == "Basics" || phaseName == "Tints & Shades") return false;
    if (phaseName == "Grandmaster") return id % 4 == 0;
    if (phaseName == "Expert") return id % 8 == 0;
    return id % 15 == 0;
  }

  String _generateHint(Map<String, int> recipe) {
    int r = recipe['red']!;
    int g = recipe['green']!;
    int b = recipe['blue']!;
    int w = recipe['white']!;
    int k = recipe['black']!;

    int total = r + g + b + w + k;
    if (total == 0) return "Empty?";

    if (w == 0 && k == 0) {
      if (r > 0 && g == 0 && b == 0) return "hint_pure_red";
      if (g > 0 && r == 0 && b == 0) return "hint_pure_green";
      if (b > 0 && r == 0 && g == 0) return "hint_pure_blue";
      if (r == g && b == 0 && r > 0) return "hint_mix_rg"; // Yellow
      if (r == b && g == 0 && r > 0) return "hint_mix_rb"; // Magenta
      if (g == b && r == 0 && g > 0) return "hint_mix_gb"; // Cyan
    }

    if (w > 0 && w >= total * 0.4) return "hint_needs_white";
    if (k > 0 && k >= total * 0.4) return "hint_needs_black";
    if (r == g && g == b && r > 0) return "hint_balance_all";

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

    if (maxVal >= total * 0.4) {
      if (dominant == "Red") return "hint_mostly_red";
      if (dominant == "Green") return "hint_mostly_green";
      if (dominant == "Blue") return "hint_mostly_blue";
    }

    return "hint_observe";
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
