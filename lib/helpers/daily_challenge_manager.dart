import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

/// Manages daily challenges with streak tracking
class DailyChallengeManager {
  static const String _lastChallengeKey = 'daily_challenge_date';
  static const String _streakKey = 'daily_challenge_streak';
  static const String _completedTodayKey = 'daily_challenge_completed';
  static const String _currentChallengeKey = 'daily_challenge_current';

  /// Check if a new challenge is available
  static Future<bool> isNewChallengeAvailable() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_lastChallengeKey);
    final today = _getTodayString();

    return lastDate != today;
  }

  /// Check if today's challenge is completed
  static Future<bool> isTodayCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_lastChallengeKey);
    final completed = prefs.getBool(_completedTodayKey) ?? false;
    final today = _getTodayString();

    return lastDate == today && completed;
  }

  /// Get current streak
  static Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_streakKey) ?? 0;
  }

  /// Generate today's challenge
  static Future<DailyChallenge> getTodaysChallenge() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayString();
    final lastDate = prefs.getString(_lastChallengeKey);

    // If same day, return stored challenge
    if (lastDate == today) {
      final stored = prefs.getString(_currentChallengeKey);
      if (stored != null) {
        return DailyChallenge.fromJson(stored);
      }
    }

    // Generate new challenge
    final challenge = _generateChallenge();
    await prefs.setString(_currentChallengeKey, challenge.toJson());
    await prefs.setString(_lastChallengeKey, today);
    await prefs.setBool(_completedTodayKey, false);

    return challenge;
  }

  /// Complete today's challenge
  static Future<void> completeChallenge() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayString();
    final lastDate = prefs.getString(_lastChallengeKey);

    // Update streak
    int streak = prefs.getInt(_streakKey) ?? 0;
    if (lastDate == _getYesterdayString()) {
      streak++;
    } else if (lastDate != today) {
      streak = 1;
    }

    await prefs.setInt(_streakKey, streak);
    await prefs.setBool(_completedTodayKey, true);
    await prefs.setString(_lastChallengeKey, today);
  }

  static DailyChallenge _generateChallenge() {
    final random = Random(DateTime.now().day);
    final types = [
      ChallengeType.limitedDrops,
      ChallengeType.noWhite,
      ChallengeType.noBlack,
      ChallengeType.speedRun,
      ChallengeType.perfectMatch,
    ];

    final type = types[random.nextInt(types.length)];

    switch (type) {
      case ChallengeType.limitedDrops:
        return DailyChallenge(
          type: type,
          description: 'Complete a level using 5 drops or less',
          requirement: 5,
          reward: 100,
        );
      case ChallengeType.noWhite:
        return DailyChallenge(
          type: type,
          description: 'Complete a level without using white drops',
          requirement: 0,
          reward: 80,
        );
      case ChallengeType.noBlack:
        return DailyChallenge(
          type: type,
          description: 'Complete a level without using black drops',
          requirement: 0,
          reward: 80,
        );
      case ChallengeType.speedRun:
        return DailyChallenge(
          type: type,
          description: 'Complete Time Attack mode in under 15 seconds',
          requirement: 15,
          reward: 120,
        );
      case ChallengeType.perfectMatch:
        return DailyChallenge(
          type: type,
          description: 'Get 3 perfect matches (100%) in a row',
          requirement: 3,
          reward: 150,
        );
    }
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

enum ChallengeType { limitedDrops, noWhite, noBlack, speedRun, perfectMatch }

class DailyChallenge {
  final ChallengeType type;
  final String description;
  final int requirement;
  final int reward;

  DailyChallenge({
    required this.type,
    required this.description,
    required this.requirement,
    required this.reward,
  });

  String toJson() {
    return '${type.index}|$description|$requirement|$reward';
  }

  static DailyChallenge fromJson(String json) {
    final parts = json.split('|');
    return DailyChallenge(
      type: ChallengeType.values[int.parse(parts[0])],
      description: parts[1],
      requirement: int.parse(parts[2]),
      reward: int.parse(parts[3]),
    );
  }
}
