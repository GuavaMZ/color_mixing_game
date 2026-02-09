import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages and persists game statistics
class StatisticsManager {
  static const String _totalLevelsKey = 'stats_total_levels';
  static const String _perfectMatchesKey = 'stats_perfect_matches';
  static const String _totalDropsUsedKey = 'stats_total_drops';
  static const String _highestComboKey = 'stats_highest_combo';
  static const String _totalPlayTimeKey = 'stats_play_time';
  static const String _classicPlaysKey = 'stats_classic_plays';
  static const String _timeAttackPlaysKey = 'stats_time_attack_plays';
  static const String _colorEchoPlaysKey = 'stats_color_echo_plays';
  static const String _chaosLabPlaysKey = 'stats_chaos_lab_plays';

  // Increment level completion
  static Future<void> incrementLevelsCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(_totalLevelsKey) ?? 0;
    await prefs.setInt(_totalLevelsKey, current + 1);
  }

  // Increment perfect matches
  static Future<void> incrementPerfectMatches() async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(_perfectMatchesKey) ?? 0;
    await prefs.setInt(_perfectMatchesKey, current + 1);
  }

  // Add drops used
  static Future<void> addDropsUsed(int drops) async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(_totalDropsUsedKey) ?? 0;
    await prefs.setInt(_totalDropsUsedKey, current + drops);
  }

  // Update highest combo
  static Future<void> updateHighestCombo(int combo) async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(_highestComboKey) ?? 0;
    if (combo > current) {
      await prefs.setInt(_highestComboKey, combo);
    }
  }

  // Add play time (in seconds)
  static Future<void> addPlayTime(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(_totalPlayTimeKey) ?? 0;
    await prefs.setInt(_totalPlayTimeKey, current + seconds);
  }

  // Increment mode play count
  static Future<void> incrementModePlay(GameMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String key;
    switch (mode) {
      case GameMode.classic:
        key = _classicPlaysKey;
        break;
      case GameMode.timeAttack:
        key = _timeAttackPlaysKey;
        break;
      case GameMode.colorEcho:
        key = _colorEchoPlaysKey;
        break;
      case GameMode.chaosLab:
        key = _chaosLabPlaysKey;
        break;
      default:
        return;
    }
    int current = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, current + 1);
  }

  // Get all statistics
  static Future<Map<String, dynamic>> getAllStats() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'totalLevels': prefs.getInt(_totalLevelsKey) ?? 0,
      'perfectMatches': prefs.getInt(_perfectMatchesKey) ?? 0,
      'totalDrops': prefs.getInt(_totalDropsUsedKey) ?? 0,
      'highestCombo': prefs.getInt(_highestComboKey) ?? 0,
      'playTime': prefs.getInt(_totalPlayTimeKey) ?? 0,
      'classicPlays': prefs.getInt(_classicPlaysKey) ?? 0,
      'timeAttackPlays': prefs.getInt(_timeAttackPlaysKey) ?? 0,
      'colorEchoPlays': prefs.getInt(_colorEchoPlaysKey) ?? 0,
      'chaosLabPlays': prefs.getInt(_chaosLabPlaysKey) ?? 0,
    };
  }

  // Calculate average accuracy
  static Future<double> getAverageAccuracy() async {
    final stats = await getAllStats();
    int totalLevels = stats['totalLevels'];
    int perfectMatches = stats['perfectMatches'];
    if (totalLevels == 0) return 0.0;
    return (perfectMatches / totalLevels) * 100;
  }

  // Get favorite mode
  static Future<String> getFavoriteMode() async {
    final stats = await getAllStats();
    int classic = stats['classicPlays'];
    int timeAttack = stats['timeAttackPlays'];
    int colorEcho = stats['colorEchoPlays'];
    int chaosLab = stats['chaosLabPlays'];

    int max = [
      classic,
      timeAttack,
      colorEcho,
      chaosLab,
    ].reduce((a, b) => a > b ? a : b);
    if (max == 0) return 'None';
    if (max == classic) return 'Classic';
    if (max == timeAttack) return 'Time Attack';
    if (max == colorEcho) return 'Color Echo';
    return 'Chaos Lab';
  }
}
