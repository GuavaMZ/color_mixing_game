import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SaveManager {
  static const String _levelKey = 'player_progress';

  // حفظ خريطة المستويات والنجوم
  // البيانات تخزن بصيغة: {"0": 3, "1": 2} (رقم الليفل: عدد النجوم)
  static Future<void> saveProgress(Map<int, int> progress, String mode) async {
    final prefs = await SharedPreferences.getInstance();
    // تحويل الخريطة إلى String (JSON) لحفظها
    String encodedData = jsonEncode(
      progress.map((key, value) => MapEntry(key.toString(), value)),
    );
    await prefs.setString('${_levelKey}_$mode', encodedData);
  }

  // استعادة البيانات عند فتح اللعبة
  static Future<Map<int, int>> loadProgress(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('${_levelKey}_$mode');

    if (data != null) {
      Map<String, dynamic> decoded = jsonDecode(data);
      return decoded.map(
        (key, value) => MapEntry(int.parse(key), value as int),
      );
    }

    // إذا كانت أول مرة يلعب، نفتح الليفل الأول (0) فقط
    return {0: 0};
  }

  // أضف هذه الدوال في lib/core/save_manager.dart

  static Future<void> saveTotalStars(int total) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('total_stars', total);
  }

  static Future<int> loadTotalStars() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('total_stars') ?? 0;
  }

  static Future<void> saveTotalCoins(int coins) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('total_coins', coins);
  }

  static Future<int> loadTotalCoins() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('total_coins') ?? 0;
  }

  static Future<void> savePurchasedSkins(List<String> skins) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('purchased_skins', skins);
  }

  static Future<List<String>> loadPurchasedSkins() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('purchased_skins') ?? [];
  }

  static Future<void> saveAchievements(List<String> achievements) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('unlocked_achievements', achievements);
  }

  static Future<List<String>> loadAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('unlocked_achievements') ?? [];
  }

  static Future<void> saveBlindMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('blind_mode_enabled', enabled);
  }

  static Future<bool> loadBlindMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('blind_mode_enabled') ?? false;
  }

  static Future<void> saveHelpers(Map<String, int> helpers) async {
    final prefs = await SharedPreferences.getInstance();
    String encodedData = jsonEncode(helpers);
    await prefs.setString('helper_counts', encodedData);
  }

  static Future<Map<String, int>> loadHelpers() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('helper_counts');
    if (data != null) {
      Map<String, dynamic> decoded = jsonDecode(data);
      return decoded.map((key, value) => MapEntry(key, value as int));
    }
    return {'extra_drops': 3, 'help_drop': 3, 'reveal_color': 3, 'undo': 5};
  }

  static Future<void> saveRandomEvents(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('random_events_enabled', enabled);
  }

  static Future<bool> loadRandomEvents() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('random_events_enabled') ?? false;
  }

  static Future<void> saveSelectedSkin(String skinName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_beaker_skin', skinName);
  }

  static Future<String?> loadSelectedSkin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selected_beaker_skin');
  }
}
