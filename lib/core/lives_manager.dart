import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LivesManager extends ChangeNotifier {
  static const int maxLives = 5;
  static const Duration regenDuration = Duration(minutes: 10);

  int _lives = maxLives;
  DateTime? _nextRegenTime;
  Timer? _regenTimer;

  int get lives => _lives;
  DateTime? get nextRegenTime => _nextRegenTime;
  bool get canPlay => _lives > 0;

  // Singleton instance
  static final LivesManager _instance = LivesManager._internal();
  factory LivesManager() => _instance;
  LivesManager._internal();

  /// Load lives and calculate offline regeneration
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _lives = prefs.getInt('lives_count') ?? maxLives;

    final lastRegenTimeStr = prefs.getString('next_regen_time');

    if (lastRegenTimeStr != null && _lives < maxLives) {
      final storedNextRegen = DateTime.parse(lastRegenTimeStr);
      final now = DateTime.now();

      if (now.isAfter(storedNextRegen)) {
        // Time passed since next regen target
        final diff = now.difference(storedNextRegen);
        final regeneratedLives =
            1 + (diff.inSeconds / regenDuration.inSeconds).floor();

        _lives = (_lives + regeneratedLives).clamp(0, maxLives);

        if (_lives < maxLives) {
          // Calculate remaining time for the *next* life
          // The next regen should be: storedNext + (regeneratedLives * duration)
          // But that might be in the past? No, we added 1 for the first cycle.
          // Wait, simple logic:
          // We recovered N lives.
          // The next regen time should have been storedNext + N*duration.
          // If storedNext + N*duration is still in past (rare), update to now + duration?
          // No, keep the cycle accurate.

          final cyclesPassed = regeneratedLives;
          _nextRegenTime = storedNextRegen.add(regenDuration * cyclesPassed);

          // Safety: If somehow calculated time is still in past (floating point weirdness), reset to now + duration
          if (_nextRegenTime!.isBefore(now)) {
            _nextRegenTime = now.add(regenDuration);
          }
        } else {
          _nextRegenTime = null;
        }
      } else {
        // Still waiting for the first regen
        _nextRegenTime = storedNextRegen;
      }
    } else {
      _nextRegenTime = null;
      if (_lives < maxLives) {
        // Should have a timer but data missing? Reset timer
        _startRegenTimer();
      }
    }

    _save();
    _startRegenTimer();
    notifyListeners();
  }

  void consumeLife() {
    if (_lives > 0) {
      _lives--;
      if (_lives == maxLives - 1) {
        // Just dropped from max, start timer
        _nextRegenTime = DateTime.now().add(regenDuration);
        _startRegenTimer();
      }
      _save();
      notifyListeners();
    }
  }

  void _startRegenTimer() {
    _regenTimer?.cancel();

    if (_lives >= maxLives) {
      _nextRegenTime = null;
      _save();
      return;
    }

    if (_nextRegenTime == null) {
      _nextRegenTime = DateTime.now().add(regenDuration);
    }

    // Refresh UI every second for countdown
    _regenTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      if (_nextRegenTime != null && now.isAfter(_nextRegenTime!)) {
        // Regen one life
        _lives++;
        if (_lives < maxLives) {
          _nextRegenTime = _nextRegenTime!.add(regenDuration);
        } else {
          _nextRegenTime = null;
          timer.cancel();
        }
        _save();
      }
      notifyListeners();
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lives_count', _lives);
    if (_nextRegenTime != null) {
      await prefs.setString(
        'next_regen_time',
        _nextRegenTime!.toIso8601String(),
      );
    } else {
      await prefs.remove('next_regen_time');
    }
    await prefs.setInt('last_save_time', DateTime.now().millisecondsSinceEpoch);
  }

  String get timeUntilNextLife {
    if (_nextRegenTime == null) return "Full";
    final diff = _nextRegenTime!.difference(DateTime.now());
    if (diff.isNegative) return "00:00";
    final minutes = diff.inMinutes.toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}
