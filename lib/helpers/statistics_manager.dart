import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages and persists game statistics for achievement tracking.
class StatisticsManager {
  // Core game progression stats
  static const String _totalLevelsKey = 'stats_total_levels';
  static const String _perfectMatchesKey = 'stats_perfect_matches';
  static const String _highestComboKey = 'stats_highest_combo';
  static const String _highestPerfectMatchStreakKey =
      'stats_highest_perfect_match_streak';

  // Resource usage stats
  static const String _totalDropsUsedKey = 'stats_total_drops';
  static const String _totalColorsMixedKey = 'stats_total_colors_mixed';

  // Playtime and game count stats
  static const String _totalPlayTimeKey = 'stats_play_time';
  static const String _totalGamesPlayedKey = 'stats_total_games_played';

  // Mode-specific play counts
  static const String _classicPlaysKey = 'stats_classic_plays';
  static const String _timeAttackPlaysKey = 'stats_time_attack_plays';
  static const String _colorEchoPlaysKey = 'stats_color_echo_plays';
  static const String _chaosLabPlaysKey = 'stats_chaos_lab_plays';

  // Phase 1 – Achievement Engine fields
  static const String _classicLevelsCompletedKey =
      'stats_classic_levels_completed';
  static const String _timeAttackWinsKey = 'stats_time_attack_wins';
  static const String _hintsUsedKey = 'stats_hints_used';
  static const String _levelsWithoutHintsKey = 'stats_levels_without_hints';
  static const String _classicPerfectNoHintsKey =
      'stats_classic_perfect_no_hints';
  static const String _loginStreakKey = 'stats_login_streak_max';
  static const String _hasPlayedClassicKey = 'stats_has_played_classic';
  static const String _hasPlayedTimeAttackKey = 'stats_has_played_time_attack';
  static const String _hasPlayedColorEchoKey = 'stats_has_played_color_echo';
  static const String _hasPlayedChaosLabKey = 'stats_has_played_chaos_lab';

  // --- Incrementers and Updaters ---

  // Increment total levels completed
  static Future<void> incrementLevelsCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(_totalLevelsKey) ?? 0;
    await prefs.setInt(_totalLevelsKey, current + 1);
  }

  // Increment classic levels completed
  static Future<void> incrementClassicLevelsCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(_classicLevelsCompletedKey) ?? 0;
    await prefs.setInt(_classicLevelsCompletedKey, current + 1);
  }

  // Increment time attack wins
  static Future<void> incrementTimeAttackWins() async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(_timeAttackWinsKey) ?? 0;
    await prefs.setInt(_timeAttackWinsKey, current + 1);
  }

  // Increment hint used count
  static Future<void> incrementHintsUsed() async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(_hintsUsedKey) ?? 0;
    await prefs.setInt(_hintsUsedKey, current + 1);
  }

  /// Record whether a level was completed without a hint.
  /// [wasClassicPerfect] = 3-star classic with no hint used.
  static Future<void> recordLevelHintStatus({
    required bool usedHint,
    bool wasClassicPerfect = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (!usedHint) {
      int noHint = prefs.getInt(_levelsWithoutHintsKey) ?? 0;
      await prefs.setInt(_levelsWithoutHintsKey, noHint + 1);
      if (wasClassicPerfect) {
        int perfNoHint = prefs.getInt(_classicPerfectNoHintsKey) ?? 0;
        await prefs.setInt(_classicPerfectNoHintsKey, perfNoHint + 1);
      }
    }
  }

  // Update max login streak
  static Future<void> updateLoginStreak(int streak) async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(_loginStreakKey) ?? 0;
    if (streak > current) {
      await prefs.setInt(_loginStreakKey, streak);
    }
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

  // Update highest perfect match streak
  static Future<void> updateHighestPerfectMatchStreak(int streak) async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(_highestPerfectMatchStreakKey) ?? 0;
    if (streak > current) {
      await prefs.setInt(_highestPerfectMatchStreakKey, streak);
    }
  }

  // Increment total colors mixed
  static Future<void> incrementColorsMixed(int count) async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(_totalColorsMixedKey) ?? 0;
    await prefs.setInt(_totalColorsMixedKey, current + count);
  }

  // Add play time (in seconds)
  static Future<void> addPlayTime(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(_totalPlayTimeKey) ?? 0;
    await prefs.setInt(_totalPlayTimeKey, current + seconds);
  }

  // Increment total games played
  static Future<void> incrementGamesPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(_totalGamesPlayedKey) ?? 0;
    await prefs.setInt(_totalGamesPlayedKey, current + 1);
  }

  // Increment mode play count
  static Future<void> incrementModePlay(GameMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String key;
    switch (mode) {
      case GameMode.classic:
        key = _classicPlaysKey;
        await prefs.setBool(_hasPlayedClassicKey, true);
        break;
      case GameMode.timeAttack:
        key = _timeAttackPlaysKey;
        await prefs.setBool(_hasPlayedTimeAttackKey, true);
        break;
      case GameMode.colorEcho:
        key = _colorEchoPlaysKey;
        await prefs.setBool(_hasPlayedColorEchoKey, true);
        break;
      case GameMode.chaosLab:
        key = _chaosLabPlaysKey;
        await prefs.setBool(_hasPlayedChaosLabKey, true);
        break;
      default:
        return;
    }
    int current = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, current + 1);
    await incrementGamesPlayed();
  }

  // --- Getters ---

  // Get all statistics
  static Future<Map<String, dynamic>> getAllStats() async {
    final prefs = await SharedPreferences.getInstance();
    final hasPlayedAll =
        (prefs.getBool(_hasPlayedClassicKey) ?? false) &&
        (prefs.getBool(_hasPlayedTimeAttackKey) ?? false) &&
        (prefs.getBool(_hasPlayedColorEchoKey) ?? false) &&
        (prefs.getBool(_hasPlayedChaosLabKey) ?? false);

    return {
      'totalLevels': prefs.getInt(_totalLevelsKey) ?? 0,
      'perfectMatches': prefs.getInt(_perfectMatchesKey) ?? 0,
      'totalDrops': prefs.getInt(_totalDropsUsedKey) ?? 0,
      'highestCombo': prefs.getInt(_highestComboKey) ?? 0,
      'highestPerfectMatchStreak':
          prefs.getInt(_highestPerfectMatchStreakKey) ?? 0,
      'totalColorsMixed': prefs.getInt(_totalColorsMixedKey) ?? 0,
      'playTime': prefs.getInt(_totalPlayTimeKey) ?? 0,
      'totalGamesPlayed': prefs.getInt(_totalGamesPlayedKey) ?? 0,
      'classicPlays': prefs.getInt(_classicPlaysKey) ?? 0,
      'timeAttackPlays': prefs.getInt(_timeAttackPlaysKey) ?? 0,
      'colorEchoPlays': prefs.getInt(_colorEchoPlaysKey) ?? 0,
      'chaosLabPlays': prefs.getInt(_chaosLabPlaysKey) ?? 0,
      // Phase 1 additions
      'classicLevelsCompleted': prefs.getInt(_classicLevelsCompletedKey) ?? 0,
      'timeAttackWins': prefs.getInt(_timeAttackWinsKey) ?? 0,
      'hintsUsed': prefs.getInt(_hintsUsedKey) ?? 0,
      'levelsWithoutHints': prefs.getInt(_levelsWithoutHintsKey) ?? 0,
      'classicPerfectNoHints': prefs.getInt(_classicPerfectNoHintsKey) ?? 0,
      'loginStreak': prefs.getInt(_loginStreakKey) ?? 0,
      'hasPlayedAllModes': hasPlayedAll,
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
