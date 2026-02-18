import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:color_mixing_deductive/core/security_service.dart';

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
    // Migration logic
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('lives_count')) {
      final oldLives = prefs.getInt('lives_count');
      if (oldLives != null) {
        await SecurityService.write('lives_count', oldLives.toString());
        await prefs.remove('lives_count');
      }
    }
    if (prefs.containsKey('next_regen_time')) {
      final oldTime = prefs.getString('next_regen_time');
      if (oldTime != null) {
        await SecurityService.write('next_regen_time', oldTime);
        await prefs.remove('next_regen_time');
      }
    }

    // Load from secure storage
    final livesStr = await SecurityService.read('lives_count');
    _lives = livesStr != null ? (int.tryParse(livesStr) ?? maxLives) : maxLives;

    final lastRegenTimeStr = await SecurityService.read('next_regen_time');

    if (lastRegenTimeStr != null && _lives < maxLives) {
      final storedNextRegen = DateTime.tryParse(lastRegenTimeStr);
      if (storedNextRegen != null) {
        final now = DateTime.now();

        if (now.isAfter(storedNextRegen)) {
          // Time passed since next regen target
          final diff = now.difference(storedNextRegen);
          final regeneratedLives =
              1 + (diff.inSeconds / regenDuration.inSeconds).floor();

          _lives = (_lives + regeneratedLives).clamp(0, maxLives);

          if (_lives < maxLives) {
            final cyclesPassed = regeneratedLives;
            _nextRegenTime = storedNextRegen.add(regenDuration * cyclesPassed);

            // Safety: If somehow calculated time is still in past
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
      }
    } else {
      _nextRegenTime = null;
      if (_lives < maxLives) {
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

  void addLives(int amount) {
    _lives = (_lives + amount).clamp(
      0,
      maxLives + 5,
    ); // Allow overfill up to +5? Or just max?
    // User asked for "gives 3 free lives". Usually free lives can stack over max in some games,
    // but usually they cap at max.
    // However, if I am at 5/5 and redeem, and it stays 5/5, I wasted it.
    // Let's allow overflow temporarily, or just clamp to max?
    // Given "free lives" as a reward, usually it overfills.
    // Let's allow overflow up to say 10 or just add it.
    // But logic depends on `maxLives`.
    // The previous logic uses `maxLives` heavily.
    // For safety and simplicity in this existing system, let's clamp to maxLives first,
    // OR allow overflow but regen only works below maxLives.
    // The regen logic checks `if (_lives < maxLives)`.
    // So if I have 8/5, regen stops (correct).
    // If I consume one -> 7/5, regen still stopped.
    // This supports overflow naturally.

    // So I will remove clamping or clamp to a higher reasonable limit (20).
    // But `init` logic `_lives = (_lives + regeneratedLives).clamp(0, maxLives);` might reset it on restart if I'm over max!
    // Ah, `init` logic assumes max is cap.
    // If I have 8 lives, save it. Restart app. Init loads 8.
    // `if (lastRegenTimeStr != null && _lives < maxLives)` -> false.
    // `if (_lives < maxLives)` at end -> false.
    // So it seems safe to overflow, EXCEPT if `init` has explicit clamp.
    // In `init`: `_lives = ...`. It reads from storage.
    // `clamp(0, maxLives)` is ONLY used during regeneration calculation.
    // So if I load 8, I keep 8.

    // One edge case: `_lives` initialized to `maxLives`.
    // I'll stick to clamping to `99` or something to prevent exploit, but allow > maxLives.

    if (_lives + amount > 99)
      _lives = 99;
    else
      _lives += amount;

    // If we are now full/overfull, stop timer
    if (_lives >= maxLives) {
      _nextRegenTime = null;
      _regenTimer?.cancel();
    }

    _save();
    notifyListeners();
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
    await SecurityService.write('lives_count', _lives.toString());
    if (_nextRegenTime != null) {
      await SecurityService.write(
        'next_regen_time',
        _nextRegenTime!.toIso8601String(),
      );
    } else {
      await SecurityService.delete('next_regen_time');
    }
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
