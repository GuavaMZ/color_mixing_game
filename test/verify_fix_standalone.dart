
class LevelModel {
  final Map<String, dynamic> recipe;
  LevelModel({required this.recipe});
}

class LevelManager {
  late LevelModel currentLevel;
}

enum GameMode { classic, timeAttack, colorEcho, chaosLab, tournament, none }

class MockGame {
  GameMode currentMode = GameMode.classic;
  final LevelManager levelManager = LevelManager();
  int rDrops = 0, gDrops = 0, bDrops = 0, whiteDrops = 0, blackDrops = 0;

  bool isRecipeIngredientsFulfilled() {
    // Non-level modes don't have a fixed recipe
    if (currentMode != GameMode.classic && currentMode != GameMode.timeAttack) {
      return true;
    }

    final recipe = levelManager.currentLevel.recipe;
    final rRequired = (recipe['red'] ?? 0) as int;
    final gRequired = (recipe['green'] ?? 0) as int;
    final bRequired = (recipe['blue'] ?? 0) as int;
    final wRequired = (recipe['white'] ?? 0) as int;
    final kRequired = (recipe['black'] ?? 0) as int;

    if (rRequired > 0 && rDrops == 0) return false;
    if (gRequired > 0 && gDrops == 0) return false;
    if (bRequired > 0 && bDrops == 0) return false;
    if (wRequired > 0 && whiteDrops == 0) return false;
    if (kRequired > 0 && blackDrops == 0) return false;

    return true;
  }
}

void main() {
  final game = MockGame();
  
  // Test case 1: Recipe with white missing white
  game.levelManager.currentLevel = LevelModel(recipe: {'red': 1, 'white': 1});
  game.rDrops = 10;
  game.whiteDrops = 0;
  if (game.isRecipeIngredientsFulfilled() != false) throw Exception("Test 1 Failed: Should not fulfill without white");
  print('Test 1 (Missing White): PASS');

  // Test case 2: Recipe with white having white
  game.whiteDrops = 1;
  if (game.isRecipeIngredientsFulfilled() != true) throw Exception("Test 2 Failed: Should fulfill with white");
  print('Test 2 (Has White): PASS');

  // Test case 3: Recipe without white
  game.levelManager.currentLevel = LevelModel(recipe: {'red': 1});
  game.whiteDrops = 0;
  if (game.isRecipeIngredientsFulfilled() != true) throw Exception("Test 3 Failed: Should fulfill without white if not needed");
  print('Test 3 (No White needed): PASS');

  // Test case 4: Non-classic mode
  game.currentMode = GameMode.colorEcho;
  game.levelManager.currentLevel = LevelModel(recipe: {'red': 50}); // Impossible recipe
  game.rDrops = 0;
  if (game.isRecipeIngredientsFulfilled() != true) throw Exception("Test 4 Failed: Non-classic modes should always return true");
  print('Test 4 (Non-classic mode): PASS');

  print('\nALL TESTS PASSED!');
}
