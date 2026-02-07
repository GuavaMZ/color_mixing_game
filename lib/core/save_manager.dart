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

  static Future<void> savePurchasedSkins(List<String> skins) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('purchased_skins', skins);
  }

  static Future<void> saveAchievements(List<String> achievements) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('unlocked_achievements', achievements);
  }

  static Future<List<String>> loadAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('unlocked_achievements') ?? [];
  }
}
