import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:color_mixing_deductive/core/security_service.dart';

class SaveManager {
  static const String _levelKey = 'player_progress';
  static const String _labConfigKey = 'lab_configuration';
  static const String _unlockedLabItemsKey = 'unlocked_lab_items';

  // Helper method to migrate data from SharedPreferences to SecurityService
  static Future<void> _migrateIfNeeded(String key) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(key)) {
      final value = prefs.getString(key);
      if (value != null) {
        await SecurityService.write(key, value);
        await prefs.remove(key); // Remove from insecure storage after migration
        print('Migrated $key to secure storage.');
      }
    }
  }

  // حفظ خريطة المستويات والنجوم
  // البيانات تخزن بصيغة: {"0": 3, "1": 2} (رقم الليفل: عدد النجوم)
  static Future<void> saveProgress(Map<int, int> progress, String mode) async {
    String key = '${_levelKey}_$mode';
    // تحويل الخريطة إلى String (JSON) لحفظها
    String encodedData = jsonEncode(
      progress.map((key, value) => MapEntry(key.toString(), value)),
    );
    await SecurityService.write(key, encodedData);
  }

  // استعادة البيانات عند فتح اللعبة
  static Future<Map<int, int>> loadProgress(String mode) async {
    String key = '${_levelKey}_$mode';
    await _migrateIfNeeded(key);

    String? data = await SecurityService.read(key);

    if (data != null) {
      try {
        Map<String, dynamic> decoded = jsonDecode(data);
        // Sanity check for invalid star counts
        if (decoded.values.any((v) => v is! int || v < 0 || v > 3)) {
          print(
            'SecurityWarning: Invalid star count detected in progress. Resetting.',
          );
          return {0: 0};
        }
        return decoded.map(
          (key, value) => MapEntry(int.parse(key), value as int),
        );
      } catch (e) {
        print('Error parsing progress data: $e');
        // If data is corrupted/tampered, fallback to default
        return {0: 0};
      }
    }

    // إذا كانت أول مرة يلعب، نفتح الليفل الأول (0) فقط
    return {0: 0};
  }

  static Future<void> saveTotalStars(int total) async {
    await SecurityService.write('total_stars', total.toString());
  }

  static Future<int> loadTotalStars() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('total_stars')) {
      final val = prefs.getInt('total_stars');
      if (val != null) {
        await SecurityService.write('total_stars', val.toString());
        await prefs.remove('total_stars');
      }
    }

    final data = await SecurityService.read('total_stars');
    final val = data != null ? int.tryParse(data) ?? 0 : 0;
    return val < 0 ? 0 : val;
  }

  static Future<void> saveTotalCoins(int coins) async {
    await SecurityService.write('total_coins', coins.toString());
  }

  static Future<int> loadTotalCoins() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('total_coins')) {
      final val = prefs.getInt('total_coins');
      if (val != null) {
        await SecurityService.write('total_coins', val.toString());
        await prefs.remove('total_coins');
      }
    }

    final data = await SecurityService.read('total_coins');
    final val = data != null ? int.tryParse(data) ?? 0 : 0;
    return val < 0 ? 0 : val;
  }

  static Future<void> savePurchasedSkins(List<String> skins) async {
    // Store list as JSON string
    await SecurityService.write('purchased_skins', jsonEncode(skins));
  }

  static Future<List<String>> loadPurchasedSkins() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('purchased_skins')) {
      final val = prefs.getStringList('purchased_skins');
      if (val != null) {
        await SecurityService.write('purchased_skins', jsonEncode(val));
        await prefs.remove('purchased_skins');
      }
    }

    final data = await SecurityService.read('purchased_skins');
    if (data != null) {
      try {
        final List<dynamic> decoded = jsonDecode(data);
        return decoded.cast<String>();
      } catch (e) {
        print('Error parsing skins: $e');
        return [];
      }
    }
    return [];
  }

  static Future<void> saveAchievements(List<String> achievements) async {
    await SecurityService.write(
      'unlocked_achievements',
      jsonEncode(achievements),
    );
  }

  static Future<List<String>> loadAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('unlocked_achievements')) {
      final val = prefs.getStringList('unlocked_achievements');
      if (val != null) {
        await SecurityService.write('unlocked_achievements', jsonEncode(val));
        await prefs.remove('unlocked_achievements');
      }
    }

    final data = await SecurityService.read('unlocked_achievements');
    if (data != null) {
      try {
        final List<dynamic> decoded = jsonDecode(data);
        return decoded.cast<String>();
      } catch (e) {
        print('Error parsing achievements: $e');
        return [];
      }
    }
    return [];
  }

  static Future<void> saveBlindMode(bool enabled) async {
    await SecurityService.write('blind_mode_enabled', enabled.toString());
  }

  static Future<bool> loadBlindMode() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('blind_mode_enabled')) {
      final val = prefs.getBool('blind_mode_enabled');
      if (val != null) {
        await SecurityService.write('blind_mode_enabled', val.toString());
        await prefs.remove('blind_mode_enabled');
      }
    }

    final data = await SecurityService.read('blind_mode_enabled');
    return data == 'true';
  }

  static Future<void> saveHelpers(Map<String, int> helpers) async {
    String encodedData = jsonEncode(helpers);
    await SecurityService.write('helper_counts', encodedData);
  }

  static Future<Map<String, int>> loadHelpers() async {
    await _migrateIfNeeded('helper_counts');

    String? data = await SecurityService.read('helper_counts');
    if (data != null) {
      try {
        Map<String, dynamic> decoded = jsonDecode(data);
        // Sanity check for negative helper counts
        if (decoded.values.any((v) => v is! int || v < 0)) {
          print('SecurityWarning: Negative helper count detected. Resetting.');
          return {
            'extra_drops': 3,
            'help_drop': 3,
            'reveal_color': 3,
            'undo': 5,
          };
        }
        return decoded.map((key, value) => MapEntry(key, value as int));
      } catch (e) {
        print('Error parsing helpers: $e');
        // Fallback to defaults
      }
    }
    return {'extra_drops': 3, 'help_drop': 3, 'reveal_color': 3, 'undo': 5};
  }

  static Future<void> saveRandomEvents(bool enabled) async {
    await SecurityService.write('random_events_enabled', enabled.toString());
  }

  static Future<bool> loadRandomEvents() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('random_events_enabled')) {
      final val = prefs.getBool('random_events_enabled');
      if (val != null) {
        await SecurityService.write('random_events_enabled', val.toString());
        await prefs.remove('random_events_enabled');
      }
    }

    final data = await SecurityService.read('random_events_enabled');
    return data == 'true';
  }

  static Future<void> saveSelectedSkin(String skinName) async {
    await SecurityService.write('selected_beaker_skin', skinName);
  }

  static Future<String?> loadSelectedSkin() async {
    await _migrateIfNeeded('selected_beaker_skin');
    return await SecurityService.read('selected_beaker_skin');
  }

  // Lab Upgrade Methods

  static Future<void> saveLabConfig(Map<String, String> config) async {
    String encoded = jsonEncode(config);
    await SecurityService.write(_labConfigKey, encoded);
  }

  static Future<Map<String, String>> loadLabConfig() async {
    await _migrateIfNeeded(_labConfigKey);

    String? data = await SecurityService.read(_labConfigKey);
    if (data != null) {
      try {
        Map<String, dynamic> decoded = jsonDecode(data);
        return decoded.map((key, value) => MapEntry(key, value as String));
      } catch (e) {
        print('Error parsing lab config: $e');
      }
    }
    // Default Configuration
    return {
      'surface': 'surface_steel',
      'lighting': 'light_basic',
      'background': 'bg_default',
      'stand': 'stand_basic',
    };
  }

  static Future<void> saveUnlockedLabItems(List<String> items) async {
    await SecurityService.write(_unlockedLabItemsKey, jsonEncode(items));
  }

  static Future<List<String>> loadUnlockedLabItems() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_unlockedLabItemsKey)) {
      final val = prefs.getStringList(_unlockedLabItemsKey);
      if (val != null) {
        await SecurityService.write(_unlockedLabItemsKey, jsonEncode(val));
        await prefs.remove(_unlockedLabItemsKey);
      }
    }

    String? data = await SecurityService.read(_unlockedLabItemsKey);
    if (data != null) {
      try {
        final List<dynamic> decoded = jsonDecode(data);
        return decoded.cast<String>();
      } catch (e) {
        print('Error parsing unlocked items: $e');
      }
    }
    // Default Unlocked Items - includes new stand category
    return ['surface_steel', 'light_basic', 'bg_default', 'stand_basic'];
  }

  // Gallery Color Discovery Methods
  static const String _discoveredColorsKey = 'discovered_colors';

  static Future<Set<int>> loadDiscoveredColors() async {
    // Migration
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_discoveredColorsKey)) {
      final val = prefs.getStringList(_discoveredColorsKey);
      if (val != null) {
        await SecurityService.write(_discoveredColorsKey, jsonEncode(val));
        await prefs.remove(_discoveredColorsKey);
      }
    }

    final data = await SecurityService.read(_discoveredColorsKey);
    if (data != null) {
      try {
        final List<dynamic> decoded = jsonDecode(data);
        return decoded.map((id) => int.parse(id.toString())).toSet();
      } catch (e) {
        print('Error parsing discovered colors: $e');
      }
    }
    return {};
  }

  static Future<void> saveDiscoveredColor(int colorId) async {
    final discovered = await loadDiscoveredColors();
    discovered.add(colorId);
    await saveDiscoveredColors(discovered);
  }

  static Future<void> saveDiscoveredColors(Set<int> colorIds) async {
    final List<String> stringIds = colorIds.map((id) => id.toString()).toList();
    await SecurityService.write(_discoveredColorsKey, jsonEncode(stringIds));
  }

  // Generic save/load methods for tutorial and other systems
  static Future<void> saveBool(String key, bool value) async {
    await SecurityService.write(key, value.toString());
  }

  static Future<bool?> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(key)) {
      final val = prefs.getBool(key);
      if (val != null) {
        await SecurityService.write(key, val.toString());
        await prefs.remove(key);
      }
    }

    final data = await SecurityService.read(key);
    return data == 'true';
  }

  static Future<void> saveStringList(String key, List<String> value) async {
    await SecurityService.write(key, jsonEncode(value));
  }

  static Future<List<String>?> getStringList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(key)) {
      final val = prefs.getStringList(key);
      if (val != null) {
        await SecurityService.write(key, jsonEncode(val));
        await prefs.remove(key);
      }
    }

    final data = await SecurityService.read(key);
    if (data != null) {
      try {
        final List<dynamic> decoded = jsonDecode(data);
        return decoded.cast<String>();
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Redeem Codes Logic
  static const String _redeemedCodesKey = 'redeemed_codes';

  static Future<bool> isCodeRedeemed(String code) async {
    final codes = await _loadRedeemedCodes();
    return codes.contains(code);
  }

  static Future<void> markCodeAsRedeemed(String code) async {
    final codes = await _loadRedeemedCodes();
    codes.add(code);
    await SecurityService.write(_redeemedCodesKey, jsonEncode(codes));
  }

  static Future<List<String>> _loadRedeemedCodes() async {
    final data = await SecurityService.read(_redeemedCodesKey);
    if (data != null) {
      try {
        return List<String>.from(jsonDecode(data));
      } catch (e) {
        return [];
      }
    }
    return [];
  }
}
