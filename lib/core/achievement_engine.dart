import 'package:flutter/material.dart';
import 'package:color_mixing_deductive/core/save_manager.dart';

// ─── Achievement Tier ─────────────────────────────────────────────────────────

enum AchievementTier { bronze, silver, gold }

extension AchievementTierX on AchievementTier {
  Color get color => switch (this) {
    AchievementTier.bronze => const Color(0xFFCD7F32),
    AchievementTier.silver => const Color(0xFFC0C0C0),
    AchievementTier.gold => const Color(0xFFFFD700),
  };

  String get label => switch (this) {
    AchievementTier.bronze => 'Bronze',
    AchievementTier.silver => 'Silver',
    AchievementTier.gold => 'Gold',
  };
}

// ─── Achievement Definition ───────────────────────────────────────────────────

class AchievementDef {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final AchievementTier tier;

  const AchievementDef({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.tier,
  });
}

// ─── Full Achievement Catalog ─────────────────────────────────────────────────

class AchievementCatalog {
  static const List<AchievementDef> all = [
    // ── Getting Started ───────────────────────────────────────────────────────
    AchievementDef(
      id: 'first_win',
      title: 'First Formula',
      description: 'Win your very first level.',
      icon: Icons.science_rounded,
      tier: AchievementTier.bronze,
    ),
    AchievementDef(
      id: 'first_perfect',
      title: 'Perfect Blend',
      description: 'Achieve a 3-star perfect match.',
      icon: Icons.star_rounded,
      tier: AchievementTier.bronze,
    ),
    AchievementDef(
      id: 'mad_chemist',
      title: 'Mad Chemist',
      description: 'Complete 10 levels in any mode.',
      icon: Icons.biotech_rounded,
      tier: AchievementTier.bronze,
    ),
    AchievementDef(
      id: 'drop_collector',
      title: 'Drop Collector',
      description: 'Use 500 total drops across all levels.',
      icon: Icons.water_drop_rounded,
      tier: AchievementTier.bronze,
    ),
    AchievementDef(
      id: 'first_hint',
      title: 'Need a Clue?',
      description: 'Use a hint for the first time.',
      icon: Icons.lightbulb_rounded,
      tier: AchievementTier.bronze,
    ),

    // ── Progression ───────────────────────────────────────────────────────────
    AchievementDef(
      id: 'level_25',
      title: '25 Levels Deep',
      description: 'Complete 25 classic levels.',
      icon: Icons.layers_rounded,
      tier: AchievementTier.bronze,
    ),
    AchievementDef(
      id: 'level_50',
      title: 'Halfway There',
      description: 'Complete 50 classic levels.',
      icon: Icons.filter_5_rounded,
      tier: AchievementTier.silver,
    ),
    AchievementDef(
      id: 'level_100',
      title: 'Century Scientist',
      description: 'Complete 100 classic levels.',
      icon: Icons.military_tech_rounded,
      tier: AchievementTier.gold,
    ),
    AchievementDef(
      id: 'player_level_10',
      title: 'Junior Chemist',
      description: 'Reach Player Level 10.',
      icon: Icons.trending_up_rounded,
      tier: AchievementTier.bronze,
    ),
    AchievementDef(
      id: 'player_level_50',
      title: 'Alchemist Rank',
      description: 'Reach Player Level 50.',
      icon: Icons.auto_awesome_rounded,
      tier: AchievementTier.silver,
    ),
    AchievementDef(
      id: 'player_level_100',
      title: 'Color God',
      description: 'Reach the maximum Player Level 100.',
      icon: Icons.workspace_premium_rounded,
      tier: AchievementTier.gold,
    ),
    AchievementDef(
      id: 'prestige',
      title: 'Beyond Mastery',
      description: 'Prestige for the first time.',
      icon: Icons.diamond_rounded,
      tier: AchievementTier.gold,
    ),

    // ── Stars ─────────────────────────────────────────────────────────────────
    AchievementDef(
      id: 'perfect_10',
      title: 'Perfect Streak',
      description: 'Get 3 stars on 10 different levels.',
      icon: Icons.grade_rounded,
      tier: AchievementTier.silver,
    ),
    AchievementDef(
      id: 'perfect_50',
      title: 'Star Hoarder',
      description: 'Collect 150 total stars.',
      icon: Icons.stars_rounded,
      tier: AchievementTier.gold,
    ),

    // ── Combo System ──────────────────────────────────────────────────────────
    AchievementDef(
      id: 'combo_3',
      title: 'Triple Threat',
      description: 'Achieve a 3-win combo streak.',
      icon: Icons.bolt_rounded,
      tier: AchievementTier.bronze,
    ),
    AchievementDef(
      id: 'combo_king',
      title: 'Combo King',
      description: 'Achieve a 10-win combo streak.',
      icon: Icons.local_fire_department_rounded,
      tier: AchievementTier.silver,
    ),
    AchievementDef(
      id: 'combo_legend',
      title: 'Combo Legend',
      description: 'Achieve a 20-win combo streak.',
      icon: Icons.whatshot_rounded,
      tier: AchievementTier.gold,
    ),

    // ── Mode Explorer ─────────────────────────────────────────────────────────
    AchievementDef(
      id: 'time_attacker',
      title: 'Speed Demon',
      description: 'Win 10 Time Attack levels.',
      icon: Icons.timer_rounded,
      tier: AchievementTier.bronze,
    ),
    AchievementDef(
      id: 'echo_master',
      title: 'Echo Master',
      description: 'Reach round 10 in Color Echo mode.',
      icon: Icons.surround_sound_rounded,
      tier: AchievementTier.silver,
    ),
    AchievementDef(
      id: 'chaos_survivor',
      title: 'Chaos Survivor',
      description: 'Survive 10 rounds in Chaos Lab mode.',
      icon: Icons.crisis_alert_rounded,
      tier: AchievementTier.silver,
    ),
    AchievementDef(
      id: 'all_modes',
      title: 'The Professor',
      description: 'Win at least one level in all 4 game modes.',
      icon: Icons.school_rounded,
      tier: AchievementTier.gold,
    ),

    // ── Minimalism ────────────────────────────────────────────────────────────
    AchievementDef(
      id: 'efficient_3',
      title: 'Efficient Mixer',
      description: 'Complete a level using 3 drops or fewer.',
      icon: Icons.compress_rounded,
      tier: AchievementTier.bronze,
    ),
    AchievementDef(
      id: 'no_hints',
      title: 'No Cheating!',
      description: 'Complete 20 levels without using any hints.',
      icon: Icons.visibility_off_rounded,
      tier: AchievementTier.silver,
    ),
    AchievementDef(
      id: 'hint_free_classic',
      title: 'Purist',
      description: 'Complete 50 classic levels with zero hints used.',
      icon: Icons.verified_rounded,
      tier: AchievementTier.gold,
    ),

    // ── Economy ───────────────────────────────────────────────────────────────
    AchievementDef(
      id: 'coin_saver_500',
      title: 'Pocket Full of Coins',
      description: 'Accumulate 500 coins.',
      icon: Icons.savings_rounded,
      tier: AchievementTier.bronze,
    ),
    AchievementDef(
      id: 'coin_saver_5000',
      title: 'Rich Alchemist',
      description: 'Accumulate 5,000 coins.',
      icon: Icons.monetization_on_rounded,
      tier: AchievementTier.silver,
    ),
    AchievementDef(
      id: 'coin_saver_25000',
      title: 'The Mint',
      description: 'Accumulate 25,000 coins.',
      icon: Icons.account_balance_rounded,
      tier: AchievementTier.gold,
    ),

    // ── Daily Dedication ──────────────────────────────────────────────────────
    AchievementDef(
      id: 'streak_3',
      title: 'Three-Day Habit',
      description: 'Log in 3 days in a row.',
      icon: Icons.calendar_today_rounded,
      tier: AchievementTier.bronze,
    ),
    AchievementDef(
      id: 'streak_7',
      title: 'Weekly Devotion',
      description: 'Maintain a 7-day login streak.',
      icon: Icons.date_range_rounded,
      tier: AchievementTier.silver,
    ),
    AchievementDef(
      id: 'streak_30',
      title: 'Dedicated Scientist',
      description: 'Maintain a 30-day login streak.',
      icon: Icons.celebration_rounded,
      tier: AchievementTier.gold,
    ),

    // ── Random Events ─────────────────────────────────────────────────────────
    AchievementDef(
      id: 'chaos_powered',
      title: 'Chaos-Powered',
      description: 'Win a level while a random event is active.',
      icon: Icons.electric_bolt_rounded,
      tier: AchievementTier.bronze,
    ),
    AchievementDef(
      id: 'survive_blackout',
      title: 'Lights Out Win',
      description: 'Win a level during a Blackout event.',
      icon: Icons.nightlight_rounded,
      tier: AchievementTier.silver,
    ),
  ];

  static AchievementDef? byId(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ─── Achievement Engine ───────────────────────────────────────────────────────

/// Central hub for checking, unlocking, and persisting achievements.
///
/// Usage: Call [AchievementEngine.check] from game events passing the current
/// context snapshot. The engine diffs against already-unlocked achievements
/// and returns any newly unlocked ids for the caller to trigger toasts.
class AchievementEngine {
  AchievementEngine._();
  static final AchievementEngine instance = AchievementEngine._();

  List<String> _unlocked = [];

  /// Load unlocked achievements from save.
  Future<void> init(List<String> alreadyUnlocked) async {
    _unlocked = List.from(alreadyUnlocked);
  }

  List<String> get unlockedIds => List.unmodifiable(_unlocked);

  bool isUnlocked(String id) => _unlocked.contains(id);

  /// Check a set of conditions and return newly unlocked achievement ids.
  Future<List<String>> check(AchievementContext ctx) async {
    final newlyUnlocked = <String>[];

    void tryUnlock(String id) {
      if (!_unlocked.contains(id)) {
        _unlocked.add(id);
        newlyUnlocked.add(id);
      }
    }

    // ── Getting Started ───────────────────────────────────────────────────────
    if (ctx.totalLevelsCompleted >= 1) tryUnlock('first_win');
    if (ctx.stars == 3) tryUnlock('first_perfect');
    if (ctx.totalLevelsCompleted >= 10) tryUnlock('mad_chemist');
    if (ctx.totalDropsUsed >= 500) tryUnlock('drop_collector');
    if (ctx.hasUsedHint) tryUnlock('first_hint');

    // ── Progression ───────────────────────────────────────────────────────────
    if (ctx.classicLevelsCompleted >= 25) tryUnlock('level_25');
    if (ctx.classicLevelsCompleted >= 50) tryUnlock('level_50');
    if (ctx.classicLevelsCompleted >= 100) tryUnlock('level_100');
    if (ctx.playerLevel >= 10) tryUnlock('player_level_10');
    if (ctx.playerLevel >= 50) tryUnlock('player_level_50');
    if (ctx.playerLevel >= 100) tryUnlock('player_level_100');
    if (ctx.prestigeCount >= 1) tryUnlock('prestige');

    // ── Stars ─────────────────────────────────────────────────────────────────
    if (ctx.totalStars >= 30) tryUnlock('perfect_10');
    if (ctx.totalStars >= 150) tryUnlock('perfect_50');

    // ── Combo ─────────────────────────────────────────────────────────────────
    if (ctx.highestCombo >= 3) tryUnlock('combo_3');
    if (ctx.highestCombo >= 10) tryUnlock('combo_king');
    if (ctx.highestCombo >= 20) tryUnlock('combo_legend');

    // ── Modes ─────────────────────────────────────────────────────────────────
    if (ctx.timeAttackWins >= 10) tryUnlock('time_attacker');
    if (ctx.echoRound >= 10) tryUnlock('echo_master');
    if (ctx.chaosRound >= 10) tryUnlock('chaos_survivor');
    if (ctx.hasPlayedAllModes) tryUnlock('all_modes');

    // ── Minimalism ────────────────────────────────────────────────────────────
    if (ctx.dropsUsedThisLevel <= 3) tryUnlock('efficient_3');
    if (ctx.levelsWithoutHints >= 20) tryUnlock('no_hints');
    if (ctx.classicPerfectNoHints >= 50) tryUnlock('hint_free_classic');

    // ── Economy ───────────────────────────────────────────────────────────────
    if (ctx.totalCoins >= 500) tryUnlock('coin_saver_500');
    if (ctx.totalCoins >= 5000) tryUnlock('coin_saver_5000');
    if (ctx.totalCoins >= 25000) tryUnlock('coin_saver_25000');

    // ── Daily ─────────────────────────────────────────────────────────────────
    if (ctx.loginStreak >= 3) tryUnlock('streak_3');
    if (ctx.loginStreak >= 7) tryUnlock('streak_7');
    if (ctx.loginStreak >= 30) tryUnlock('streak_30');

    // ── Random Events ─────────────────────────────────────────────────────────
    if (ctx.wonWithActiveEvent) tryUnlock('chaos_powered');
    if (ctx.wonDuringBlackout) tryUnlock('survive_blackout');

    if (newlyUnlocked.isNotEmpty) {
      await SaveManager.saveAchievements(_unlocked);
    }

    return newlyUnlocked;
  }
}

// ─── Achievement Context ──────────────────────────────────────────────────────

/// Snapshot of game state passed to [AchievementEngine.check].
class AchievementContext {
  final int stars;
  final int totalLevelsCompleted;
  final int classicLevelsCompleted;
  final int totalDropsUsed;
  final int dropsUsedThisLevel;
  final bool hasUsedHint;
  final int totalStars;
  final int playerLevel;
  final int prestigeCount;
  final int highestCombo;
  final int timeAttackWins;
  final int echoRound;
  final int chaosRound;
  final bool hasPlayedAllModes;
  final int levelsWithoutHints;
  final int classicPerfectNoHints;
  final int totalCoins;
  final int loginStreak;
  final bool wonWithActiveEvent;
  final bool wonDuringBlackout;

  const AchievementContext({
    this.stars = 0,
    this.totalLevelsCompleted = 0,
    this.classicLevelsCompleted = 0,
    this.totalDropsUsed = 0,
    this.dropsUsedThisLevel = 0,
    this.hasUsedHint = false,
    this.totalStars = 0,
    this.playerLevel = 0,
    this.prestigeCount = 0,
    this.highestCombo = 0,
    this.timeAttackWins = 0,
    this.echoRound = 0,
    this.chaosRound = 0,
    this.hasPlayedAllModes = false,
    this.levelsWithoutHints = 0,
    this.classicPerfectNoHints = 0,
    this.totalCoins = 0,
    this.loginStreak = 0,
    this.wonWithActiveEvent = false,
    this.wonDuringBlackout = false,
  });
}
