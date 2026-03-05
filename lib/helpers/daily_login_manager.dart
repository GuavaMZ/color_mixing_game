import 'package:shared_preferences/shared_preferences.dart';
import 'package:color_mixing_deductive/core/save_manager.dart';
import 'package:color_mixing_deductive/helpers/statistics_manager.dart';

class DailyLoginManager {
  static const String _lastLoginKey = 'daily_login_last_date';
  static const String _loginStreakKey = 'daily_login_streak';
  static const String _claimedTodayKey = 'daily_login_claimed_today';

  // Static rewards for the 7-day track
  static const List<int> _dailyRewards = [50, 100, 150, 200, 250, 300, 500];

  static int getRewardForDay(int day) {
    if (day < 1 || day > 7) return 50;
    return _dailyRewards[day - 1];
  }

  /// Check if the user is eligible to claim a reward today.
  static Future<bool> canClaimToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_lastLoginKey);
    final today = _getTodayString();

    if (lastDate != today) {
      return true;
    }

    final claimedToday = prefs.getBool(_claimedTodayKey) ?? false;
    return !claimedToday;
  }

  /// Check if today's reward has already been claimed.
  static Future<bool> hasClaimedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_lastLoginKey);
    final today = _getTodayString();

    if (lastDate != today) {
      return false; // New day, hasn't claimed
    }

    return prefs.getBool(_claimedTodayKey) ?? false;
  }

  /// Retrieves the current streak (1-7), advancing or resetting it based on the date.
  static Future<int> getCurrentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayString();
    final yesterday = _getYesterdayString();
    final lastDate = prefs.getString(_lastLoginKey);

    int streak = prefs.getInt(_loginStreakKey) ?? 1;

    // If they already claimed/logged in today, return current streak
    if (lastDate == today) {
      return streak;
    }

    // If their last login was yesterday, they maintain the streak
    if (lastDate == yesterday) {
      int nextStreak = streak + 1;
      if (nextStreak > 7) {
        nextStreak = 1; // Loop back to 1 after completing a week
      }
      return nextStreak;
    }

    // If it's been more than a day (or no record), streak resets to 1
    return 1;
  }

  /// Claims today's reward, updates the streak, and awards the coins.
  static Future<int> claimToday() async {
    if (!(await canClaimToday())) {
      return 0; // Already claimed or not eligible
    }

    final prefs = await SharedPreferences.getInstance();
    final streakToClaim = await getCurrentStreak();
    final today = _getTodayString();

    // Grant reward
    int rewardCoins = getRewardForDay(streakToClaim);
    int currentCoins = await SaveManager.loadTotalCoins();
    await SaveManager.saveTotalCoins(currentCoins + rewardCoins);

    // Update Persistent State
    await prefs.setString(_lastLoginKey, today);
    await prefs.setInt(_loginStreakKey, streakToClaim);
    await prefs.setBool(_claimedTodayKey, true);

    // Track for achievements
    StatisticsManager.updateLoginStreak(streakToClaim);

    return rewardCoins;
  }

  static String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  static String _getYesterdayString() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return '${yesterday.year}-${yesterday.month}-${yesterday.day}';
  }
}
