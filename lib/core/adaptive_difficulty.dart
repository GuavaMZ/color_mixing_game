import 'package:color_mixing_deductive/core/save_manager.dart';

/// Tracks the player's rolling win/loss history and exposes a difficulty
/// modifier that the [LevelManager] applies when selecting levels.
///
/// Algorithm:
///  - Rolling window of the last [windowSize] level outcomes (win/loss)
///  - Win rate > 80% → easy penalty (ramp difficulty by +[step])
///  - Win rate < 40% → hard relief (reduce difficulty by -[step])
///  - Otherwise → neutral (modifier stays unchanged within ±[maxAdjustment])
///
/// The modifier is clamped to [minModifier]..[maxModifier] so it never makes
/// levels impossibly easy or unfairly hard.
class AdaptiveDifficulty {
  // ─── Singleton ─────────────────────────────────────────────────────────────
  AdaptiveDifficulty._();
  static final AdaptiveDifficulty instance = AdaptiveDifficulty._();

  // ─── Tuning ────────────────────────────────────────────────────────────────
  static const int windowSize = 10; // rolling window length
  static const double step = 0.05; // per-adjustment step (5%)
  static const double minModifier = 0.7; // 70% of base difficulty
  static const double maxModifier = 1.4; // 140% of base difficulty

  // ─── State ────────────────────────────────────────────────────────────────
  final List<bool> _history = []; // true = win, false = loss
  double _modifier = 1.0;

  bool _helpingHandActive = false;

  /// Whether the Helping Hand auto-hint should fire next level start.
  bool get helpingHandActive => _helpingHandActive;
  void consumeHelpingHand() => _helpingHandActive = false;

  // ─── Init ─────────────────────────────────────────────────────────────────

  Future<void> init() async {
    final data = await SaveManager.getStringList('adaptive_difficulty_history');
    if (data != null) {
      _history.clear();
      for (final s in data) {
        _history.add(s == '1');
      }
    }

    final modData = await SaveManager.getStringList(
      'adaptive_difficulty_modifier',
    );
    if (modData != null && modData.isNotEmpty) {
      _modifier = double.tryParse(modData.first) ?? 1.0;
    }
  }

  // ─── Recording outcomes ───────────────────────────────────────────────────

  /// Record the outcome of a classic level.
  Future<void> recordOutcome({required bool won}) async {
    _history.add(won);
    if (_history.length > windowSize) {
      _history.removeAt(0);
    }

    _recalculate();
    await _persist();
  }

  void _recalculate() {
    if (_history.length < 3) return; // Not enough data yet

    final wins = _history.where((w) => w).length;
    final winRate = wins / _history.length;

    if (winRate > 0.80) {
      // Too easy — ramp up
      _modifier = (_modifier + step).clamp(minModifier, maxModifier);
      _helpingHandActive = false;
    } else if (winRate < 0.40) {
      // Too hard — ease back
      _modifier = (_modifier - step).clamp(minModifier, maxModifier);
      // Offer helping hand if consistently struggling
      if (winRate < 0.30) {
        _helpingHandActive = true;
      }
    }
    // else neutral — no change
  }

  // ─── Public API ───────────────────────────────────────────────────────────

  /// A value in [minModifier]..[maxModifier]. Apply to `difficultyFactor`
  /// when creating levels in LevelManager.
  double get difficultyModifier => _modifier;

  /// Recent win rate (0.0–1.0). May return null if not enough data.
  double? get recentWinRate {
    if (_history.length < 3) return null;
    return _history.where((w) => w).length / _history.length;
  }

  /// Number of recorded outcomes in the window.
  int get historyCount => _history.length;

  // ─── Persist ─────────────────────────────────────────────────────────────

  Future<void> _persist() async {
    final encoded = _history.map((b) => b ? '1' : '0').toList();
    await SaveManager.saveStringList('adaptive_difficulty_history', encoded);
    await SaveManager.saveStringList('adaptive_difficulty_modifier', [
      _modifier.toStringAsFixed(4),
    ]);
  }
}
