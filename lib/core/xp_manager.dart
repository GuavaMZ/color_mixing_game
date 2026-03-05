import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:color_mixing_deductive/core/save_manager.dart';
import 'package:color_mixing_deductive/color_mixer_game.dart';

/// Manages the player's XP, level, and prestige progression.
///
/// XP is earned each time the player wins a level. The XP required to reach
/// the next level grows by a factor of 1.15 per level (exponential curve) so
/// early levels feel snappy while later levels feel meaningful.
///
/// After level 100 the player can "Prestige" — resetting their level to 0 but
/// keeping a permanent prestige badge and a one-time prestige bonus reward.
class XpManager {
  // ─── Singleton ─────────────────────────────────────────────────────────────
  XpManager._();
  static final XpManager instance = XpManager._();

  // ─── Persistence keys ──────────────────────────────────────────────────────
  static const String _xpKey = 'player_xp';
  static const String _levelKey = 'player_level';
  static const String _prestigeKey = 'player_prestige';

  // ─── Tuning constants ─────────────────────────────────────────────────────
  static const int baseXp = 100; // XP needed for level 1→2
  static const double xpGrowthFactor = 1.15;
  static const int maxLevel = 100;

  // ─── Rank titles by level bracket ─────────────────────────────────────────
  static const List<RankTier> _ranks = [
    RankTier(minLevel: 0, title: 'Apprentice', emoji: '🧪'),
    RankTier(minLevel: 10, title: 'Junior Chemist', emoji: '⚗️'),
    RankTier(minLevel: 20, title: 'Chemist', emoji: '🔬'),
    RankTier(minLevel: 35, title: 'Senior Chemist', emoji: '🧬'),
    RankTier(minLevel: 50, title: 'Alchemist', emoji: '✨'),
    RankTier(minLevel: 65, title: 'Grand Alchemist', emoji: '🌟'),
    RankTier(minLevel: 80, title: 'Color Wizard', emoji: '🔮'),
    RankTier(minLevel: 95, title: 'Color God', emoji: '👑'),
  ];

  // ─── State ────────────────────────────────────────────────────────────────

  /// Current XP within the current level.
  final ValueNotifier<int> currentXp = ValueNotifier<int>(0);

  /// Player's current level (0-based, max = [maxLevel]).
  final ValueNotifier<int> playerLevel = ValueNotifier<int>(0);

  /// How many times the player has prestiged.
  final ValueNotifier<int> prestigeCount = ValueNotifier<int>(0);

  /// Fires whenever a level-up event occurs (value = new level).
  final ValueNotifier<int?> levelUpEvent = ValueNotifier<int?>(null);

  ColorMixerGame? _game;

  // ─── Initialisation ───────────────────────────────────────────────────────

  /// Load persisted XP state. Call once during game startup.
  Future<void> init() async {
    currentXp.value = await _loadInt(_xpKey, 0);
    playerLevel.value = await _loadInt(_levelKey, 0);
    prestigeCount.value = await _loadInt(_prestigeKey, 0);
  }

  void attachGame(ColorMixerGame game) => _game = game;

  // ─── XP Calculation ───────────────────────────────────────────────────────

  /// Returns the XP required to go FROM [level] TO [level + 1].
  static int xpForLevel(int level) {
    if (level <= 0) return baseXp;
    return (baseXp * pow(xpGrowthFactor, level)).round();
  }

  /// XP to next level boundary from current state.
  int get xpToNextLevel => xpForLevel(playerLevel.value);

  /// Progress 0.0–1.0 within the current level.
  double get levelProgress {
    final needed = xpToNextLevel;
    if (needed <= 0) return 1.0;
    return (currentXp.value / needed).clamp(0.0, 1.0);
  }

  // ─── Earning XP ───────────────────────────────────────────────────────────

  /// Award XP based on win outcome. Called from [ColorMixerGame.showWinEffect].
  ///
  /// Returns coin bonus (from level-ups) so the caller can display it.
  Future<int> addXpForWin({
    required int stars,
    required GameMode mode,
    required int comboCount,
  }) async {
    // Base XP by stars
    int xp = switch (stars) {
      3 => 50,
      2 => 25,
      _ => 10,
    };

    // Mode multiplier
    xp = switch (mode) {
      GameMode.timeAttack => (xp * 1.5).round(),
      GameMode.colorEcho => (xp * 1.3).round(),
      GameMode.chaosLab => (xp * 2.0).round(),
      _ => xp,
    };

    // Combo bonus: +5% XP per combo level
    if (comboCount >= 3) {
      xp = (xp * (1.0 + comboCount * 0.05)).round();
    }

    return await _addXp(xp);
  }

  /// Raw XP addition — handles level-ups internally.
  Future<int> _addXp(int amount) async {
    int coinsAwarded = 0;
    int remaining = amount;

    while (remaining > 0 && playerLevel.value < maxLevel) {
      final needed = xpToNextLevel - currentXp.value;
      if (remaining >= needed) {
        // Level up!
        remaining -= needed;
        currentXp.value = 0;
        playerLevel.value++;

        // Award level-up coins
        final bonus = _levelUpBonus(playerLevel.value);
        coinsAwarded += bonus;
        if (_game != null && bonus > 0) {
          _game!.addCoins(bonus);
        }

        // Fire event for overlay
        levelUpEvent.value = playerLevel.value;

        // Persist after each level-up
        await _persist();

        if (playerLevel.value >= maxLevel) break;
      } else {
        currentXp.value = currentXp.value + remaining;
        remaining = 0;
      }
    }

    // If already max level, just accrue XP (displayed as prestige XP)
    if (playerLevel.value >= maxLevel) {
      currentXp.value = currentXp.value + remaining;
    }

    await _persist();
    return coinsAwarded;
  }

  /// Coins awarded on level-up. Milestone levels give bigger bonuses.
  int _levelUpBonus(int level) {
    if (level % 10 == 0) return 500; // Milestone: every 10 levels
    if (level % 5 == 0) return 150; // Mini milestone: every 5 levels
    return 50; // Normal level-up
  }

  // ─── Prestige ─────────────────────────────────────────────────────────────

  bool get canPrestige => playerLevel.value >= maxLevel;

  Future<void> prestige() async {
    if (!canPrestige) return;
    prestigeCount.value++;
    playerLevel.value = 0;
    currentXp.value = 0;
    await _persist();

    // Award a prestige bonus
    _game?.addCoins(2000);
  }

  // ─── Rank Info ────────────────────────────────────────────────────────────

  RankTier get currentRank {
    final level = playerLevel.value;
    RankTier result = _ranks.first;
    for (final rank in _ranks) {
      if (level >= rank.minLevel) result = rank;
    }
    return result;
  }

  String get rankTitle => currentRank.title;
  String get rankEmoji => currentRank.emoji;
  String get fullRankLabel => '${currentRank.emoji} ${currentRank.title}';

  // ─── Persistence ──────────────────────────────────────────────────────────

  Future<void> _persist() async {
    await SaveManager.saveBool(
      '${_xpKey}_marker',
      true,
    ); // trigger rate limiter properly
    // Use generic int save via sharedPrefs wrapper
    await _saveInt(_xpKey, currentXp.value);
    await _saveInt(_levelKey, playerLevel.value);
    await _saveInt(_prestigeKey, prestigeCount.value);
  }

  static Future<int> _loadInt(String key, int defaultValue) async {
    // Reuse SaveManager's secure read path via generic string storage
    final data = await SaveManager.getStringList('xp_data_$key');
    if (data != null && data.isNotEmpty) {
      return int.tryParse(data.first) ?? defaultValue;
    }
    return defaultValue;
  }

  static Future<void> _saveInt(String key, int value) async {
    await SaveManager.saveStringList('xp_data_$key', [value.toString()]);
  }
}

class RankTier {
  final int minLevel;
  final String title;
  final String emoji;
  const RankTier({
    required this.minLevel,
    required this.title,
    required this.emoji,
  });
}
