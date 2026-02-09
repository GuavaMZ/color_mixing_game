import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Manages haptic feedback for the game
class HapticManager {
  static final HapticManager _instance = HapticManager._internal();
  factory HapticManager() => _instance;
  HapticManager._internal();

  bool _isEnabled = true;

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Light tap - for button presses, drop additions
  Future<void> light() async {
    if (!_isEnabled || kIsWeb) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('Haptic feedback not available: $e');
    }
  }

  /// Medium impact - for level complete, combo milestones
  Future<void> medium() async {
    if (!_isEnabled || kIsWeb) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('Haptic feedback not available: $e');
    }
  }

  /// Heavy impact - for perfect match, achievement unlock
  Future<void> heavy() async {
    if (!_isEnabled || kIsWeb) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint('Haptic feedback not available: $e');
    }
  }

  /// Selection click - for UI interactions
  Future<void> selection() async {
    if (!_isEnabled || kIsWeb) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (e) {
      debugPrint('Haptic feedback not available: $e');
    }
  }

  /// Vibrate pattern - for game over, random events
  Future<void> vibrate() async {
    if (!_isEnabled || kIsWeb) return;
    try {
      await HapticFeedback.vibrate();
    } catch (e) {
      debugPrint('Haptic feedback not available: $e');
    }
  }

  /// Success pattern - for wins
  Future<void> success() async {
    await heavy();
    await Future.delayed(const Duration(milliseconds: 100));
    await light();
  }

  /// Failure pattern - for game over
  Future<void> failure() async {
    await vibrate();
    await Future.delayed(const Duration(milliseconds: 50));
    await medium();
  }

  /// Combo pattern - for combo achievements
  Future<void> combo(int comboCount) async {
    if (comboCount >= 10) {
      await heavy();
    } else if (comboCount >= 5) {
      await medium();
    } else if (comboCount >= 3) {
      await light();
    }
  }
}
