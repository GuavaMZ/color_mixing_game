import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:color_mixing_deductive/core/save_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('SaveManager migrates total_stars from SharedPreferences', () async {
    // 1. Setup SharedPreferences with old data
    SharedPreferences.setMockInitialValues({'total_stars': 100});

    // 2. Setup Mock Secure Storage (channel mock)
    // This intercepts the MethodChannel used by FlutterSecureStorage
    FlutterSecureStorage.setMockInitialValues({});

    // 3. Call loadTotalStars - should trigger migration
    final stars = await SaveManager.loadTotalStars();

    // 4. Verify data was loaded
    expect(stars, 100);

    // 5. Verify SharedPreferences is empty (migrated)
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('total_stars'), false);

    // 6. Verify Secure Storage has data (implicitly via load)
    final starsAfter = await SaveManager.loadTotalStars();
    expect(starsAfter, 100);
  });

  test('SaveManager integrity check passes on valid data', () async {
    FlutterSecureStorage.setMockInitialValues({});

    // We save data first to generate valid hash
    await SaveManager.saveTotalCoins(999);

    // Then load it back
    final coins = await SaveManager.loadTotalCoins();
    expect(coins, 999);
  });
}
