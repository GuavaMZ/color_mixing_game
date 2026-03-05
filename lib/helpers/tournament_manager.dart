import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TournamentManager {
  static final TournamentManager instance = TournamentManager._internal();
  TournamentManager._internal();

  int personalBest = 0;
  String currentTheme = 'Neon Night';
  DateTime nextTournamentDate = DateTime.now().add(const Duration(days: 7));

  final ValueNotifier<int> scoreNotifier = ValueNotifier(0);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    personalBest = prefs.getInt('tournament_pb') ?? 0;
    scoreNotifier.value = personalBest;
    _calculateNextTournament();
  }

  void _calculateNextTournament() {
    DateTime now = DateTime.now();
    int daysUntilSunday = 7 - now.weekday;
    if (daysUntilSunday == 0) daysUntilSunday = 7;

    nextTournamentDate = DateTime(
      now.year,
      now.month,
      now.day + daysUntilSunday,
      0,
      0,
    );

    // Rotate weekly themes
    List<String> themes = [
      "Red Week",
      "Spectral Blues",
      "Warm Sunset",
      "Neon Cascade",
      "Emerald City",
    ];
    currentTheme =
        themes[(now.millisecondsSinceEpoch ~/ (1000 * 60 * 60 * 24 * 7)) %
            themes.length];
  }

  void submitScore(int accuracy, int speedBonus, int streak) {
    int finalScore = (accuracy * speedBonus * streak).toInt();
    if (finalScore > personalBest) {
      personalBest = finalScore;
      scoreNotifier.value = personalBest;
      _saveScore(personalBest);
    }
  }

  Future<void> _saveScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tournament_pb', score);
  }

  String getTimeRemainingString() {
    Duration remaining = nextTournamentDate.difference(DateTime.now());
    if (remaining.isNegative) {
      _calculateNextTournament();
      remaining = nextTournamentDate.difference(DateTime.now());
    }
    return '${remaining.inDays}d ${remaining.inHours % 24}h';
  }
}
