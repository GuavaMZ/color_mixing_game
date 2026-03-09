import 'package:flutter/material.dart';
import 'package:color_mixing_deductive/core/save_manager.dart';
import 'package:color_mixing_deductive/helpers/string_manager.dart';
import 'package:flutter_localization/flutter_localization.dart';

// ─── Achievement Tier ─────────────────────────────────────────────────────────

enum AchievementTier { bronze, silver, gold }

extension AchievementTierX on AchievementTier {
  Color get color => switch (this) {
    AchievementTier.bronze => const Color(0xFFCD7F32),
    AchievementTier.silver => const Color(0xFFC0C0C0),
    AchievementTier.gold => const Color(0xFFFFD700),
  };

  String labelKey(BuildContext context) => switch (this) {
    AchievementTier.bronze => AppStrings.tierBronze.getString(context),
    AchievementTier.silver => AppStrings.tierSilver.getString(context),
    AchievementTier.gold => AppStrings.tierGold.getString(context),
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
      title: AppStrings.archFirstWinTitle,
      description: AppStrings.archFirstWinDesc,
      icon: Icons.science_rounded,
      tier: AchievementTier.bronze,
    ),
    AchievementDef(
      id: 'first_perfect',
      title: AppStrings.archFirstPerfectTitle,
      description: AppStrings.archFirstPerfectDesc,
      icon: Icons.star_rounded,
      tier: AchievementTier.bronze,
    ),
    AchievementDef(
      id: 'mad_chemist',
      title: AppStrings.archMadChemistTitle,
      description: AppStrings.archMadChemistDesc,
      icon: Icons.biotech_rounded,
      tier: AchievementTier.bronze,
    ),
    AchievementDef(
      id: 'drop_collector',
      title: AppStrings.archDropCollectorTitle,
      description: AppStrings.archDropCollectorDesc,
      icon: Icons.water_drop_rounded,
      tier: AchievementTier.bronze,
    ),
    AchievementDef(
      id: 'first_hint',
      title: AppStrings.archFirstHintTitle,
      description: AppStrings.archFirstHintDesc,
      icon: Icons.lightbulb_rounded,
      tier: AchievementTier.bronze,
    ),

    // ── Progression ───────────────────────────────────────────────────────────
    AchievementDef(
      id: 'level_25',
      title: AppStrings.archLevel25Title,
      description: AppStrings.archLevel25Desc,
      icon: Icons.layers_rounded,
      tier: AchievementTier.bronze,
    ),
    AchievementDef(
      id: 'level_50',
      title: AppStrings.archLevel50Title,
      description: AppStrings.archLevel50Desc,
      icon: Icons.filter_5_rounded,
      tier: AchievementTier.silver,
    ),
    AchievementDef(
      id: 'level_100',
      title: AppStrings.archLevel100Title,
      description: AppStrings.archLevel100Desc,
      icon: Icons.military_tech_rounded,
      tier: AchievementTier.gold,
    ),
    AchievementDef(
      id: 'player_level_10',
      title: AppStrings.archPlayerLevel10Title,
      description: AppStrings.archPlayerLevel10Desc,
      icon: Icons.trending_up_rounded,
      tier: AchievementTier.bronze,
    ),
    AchievementDef(
      id: 'player_level_50',
      title: AppStrings.archPlayerLevel50Title,
      description: AppStrings.archPlayerLevel50Desc,
      icon: Icons.auto_awesome_rounded,
      tier: AchievementTier.silver,
    ),
    AchievementDef(
      id: 'player_level_100',
      title: AppStrings.archPlayerLevel100Title,
      description: AppStrings.archPlayerLevel100Desc,
      icon: Icons.workspace_premium_rounded,
      tier: AchievementTier.gold,
    ),
    AchievementDef(
      id: 'prestige',
      title: AppStrings.archPrestigeTitle,
      description: AppStrings.archPrestigeDesc,
      icon: Icons.diamond_rounded,
      tier: AchievementTier.gold,
    ),

    // ── Stars ─────────────────────────────────────────────────────────────────
    AchievementDef(
      id: 'perfect_10',
      title: AppStrings.archPerfect10Title,
      description: AppStrings.archPerfect10Desc,
      icon: Icons.grade_rounded,
      tier: AchievementTier.silver,
    ),
    AchievementDef(
      id: 'perfect_50',
      title: AppStrings.archPerfect50Title,
      description: AppStrings.archPerfect50Desc,
      icon: Icons.stars_rounded,
      tier: AchievementTier.gold,
    ),

    // ── Combo System ──────────────────────────────────────────────────────────
    AchievementDef(
      id: 'combo_3',
      title: AppStrings.archCombo3Title,
      description: AppStrings.archCombo3Desc,
      icon: Icons.bolt_rounded,
      tier: AchievementTier.bronze,
    ),
    AchievementDef(
      id: 'combo_king',
      title: AppStrings.archComboKingTitle,
      description: AppStrings.archComboKingDesc,
      icon: Icons.local_fire_department_rounded,
      tier: AchievementTier.silver,
    ),
    AchievementDef(
      id: 'combo_legend',
      title: AppStrings.archComboLegendTitle,
      description: AppStrings.archComboLegendDesc,
      icon: Icons.whatshot_rounded,
      tier: AchievementTier.gold,
    ),

    // ── Mode Explorer ─────────────────────────────────────────────────────────
    AchievementDef(
      id: 'time_attacker',
      title: AppStrings.archTimeAttackerTitle,
      description: AppStrings.archTimeAttackerDesc,
      icon: Icons.timer_rounded,
      tier: AchievementTier.bronze,
    ),
    AchievementDef(
      id: 'echo_master',
      title: AppStrings.archEchoMasterTitle,
      description: AppStrings.archEchoMasterDesc,
      icon: Icons.surround_sound_rounded,
      tier: AchievementTier.silver,
    ),
    AchievementDef(
      id: 'chaos_survivor',
      title: AppStrings.archChaosSurvivorTitle,
      description: AppStrings.archChaosSurvivorDesc,
      icon: Icons.crisis_alert_rounded,
      tier: AchievementTier.silver,
    ),
    AchievementDef(
      id: 'all_modes',
      title: AppStrings.archAllModesTitle,
      description: AppStrings.archAllModesDesc,
      icon: Icons.school_rounded,
      tier: AchievementTier.gold,
    ),

    // ── Minimalism ────────────────────────────────────────────────────────────
    AchievementDef(
      id: 'efficient_3',
      title: AppStrings.archEfficient3Title,
      description: AppStrings.archEfficient3Desc,
      icon: Icons.compress_rounded,
      tier: AchievementTier.bronze,
    ),
    AchievementDef(
      id: 'no_hints',
      title: AppStrings.archNoHintsTitle,
      description: AppStrings.archNoHintsDesc,
      icon: Icons.visibility_off_rounded,
      tier: AchievementTier.silver,
    ),
    AchievementDef(
      id: 'hint_free_classic',
      title: AppStrings.archHintFreeClassicTitle,
      description: AppStrings.archHintFreeClassicDesc,
      icon: Icons.verified_rounded,
      tier: AchievementTier.gold,
    ),

    // ── Economy ───────────────────────────────────────────────────────────────
    AchievementDef(
      id: 'coin_saver_500',
      title: AppStrings.archCoinSaver500Title,
      description: AppStrings.archCoinSaver500Desc,
      icon: Icons.savings_rounded,
      tier: AchievementTier.bronze,
    ),
    AchievementDef(
      id: 'coin_saver_5000',
      title: AppStrings.archCoinSaver5000Title,
      description: AppStrings.archCoinSaver5000Desc,
      icon: Icons.monetization_on_rounded,
      tier: AchievementTier.silver,
    ),
    AchievementDef(
      id: 'coin_saver_25000',
      title: AppStrings.archCoinSaver25000Title,
      description: AppStrings.archCoinSaver25000Desc,
      icon: Icons.account_balance_rounded,
      tier: AchievementTier.gold,
    ),

    // ── Daily Dedication ──────────────────────────────────────────────────────
    AchievementDef(
      id: 'streak_3',
      title: AppStrings.archStreak3Title,
      description: AppStrings.archStreak3Desc,
      icon: Icons.calendar_today_rounded,
      tier: AchievementTier.bronze,
    ),
    AchievementDef(
      id: 'streak_7',
      title: AppStrings.archStreak7Title,
      description: AppStrings.archStreak7Desc,
      icon: Icons.date_range_rounded,
      tier: AchievementTier.silver,
    ),
    AchievementDef(
      id: 'streak_30',
      title: AppStrings.archStreak30Title,
      description: AppStrings.archStreak30Desc,
      icon: Icons.celebration_rounded,
      tier: AchievementTier.gold,
    ),

    // ── Random Events ─────────────────────────────────────────────────────────
    AchievementDef(
      id: 'chaos_powered',
      title: AppStrings.archChaosPoweredTitle,
      description: AppStrings.archChaosPoweredDesc,
      icon: Icons.electric_bolt_rounded,
      tier: AchievementTier.bronze,
    ),
    AchievementDef(
      id: 'survive_blackout',
      title: AppStrings.archSurviveBlackoutTitle,
      description: AppStrings.archSurviveBlackoutDesc,
      icon: Icons.nightlight_rounded,
      tier: AchievementTier.silver,
    ),

    // ─── Phase 2: Missing & Advanced Achievements ─────────────────────────────
    AchievementDef(
      id: 'lab_survivor',
      title: AppStrings.archLabSurvivorTitle,
      description: AppStrings.archLabSurvivorDesc,
      icon: Icons.biotech_outlined,
      tier: AchievementTier.bronze,
    ),
    AchievementDef(
      id: 'spectral_sync',
      title: AppStrings.archSpectralSyncTitle,
      description: AppStrings.archSpectralSyncDesc,
      icon: Icons.waves_rounded,
      tier: AchievementTier.gold,
    ),
    AchievementDef(
      id: 'master_chemist',
      title: AppStrings.archMasterChemistTitle,
      description: AppStrings.archMasterChemistDesc,
      icon: Icons.verified_user_rounded,
      tier: AchievementTier.silver,
    ),
    AchievementDef(
      id: 'blind_master',
      title: AppStrings.archBlindMasterTitle,
      description: AppStrings.archBlindMasterDesc,
      icon: Icons.visibility_off_outlined,
      tier: AchievementTier.gold,
    ),
    AchievementDef(
      id: 'shopaholic',
      title: AppStrings.archShopaholicTitle,
      description: AppStrings.archShopaholicDesc,
      icon: Icons.shopping_bag_rounded,
      tier: AchievementTier.gold,
    ),
    AchievementDef(
      id: 'stability_expert',
      title: AppStrings.archStabilityExpertTitle,
      description: AppStrings.archStabilityExpertDesc,
      icon: Icons.balance_rounded,
      tier: AchievementTier.silver,
    ),
    AchievementDef(
      id: 'speed_runner',
      title: AppStrings.archSpeedRunnerTitle,
      description: AppStrings.archSpeedRunnerDesc,
      icon: Icons.speed_rounded,
      tier: AchievementTier.silver,
    ),
    AchievementDef(
      id: 'star_collector',
      title: AppStrings.archStarCollectorTitle,
      description: AppStrings.archStarCollectorDesc,
      icon: Icons.auto_awesome_rounded,
      tier: AchievementTier.bronze,
    ),
    AchievementDef(
      id: 'perfectionist',
      title: AppStrings.archPerfectionistTitle,
      description: AppStrings.archPerfectionistDesc,
      icon: Icons.check_circle_rounded,
      tier: AchievementTier.bronze,
    ),
    AchievementDef(
      id: 'veteran',
      title: AppStrings.archVeteranTitle,
      description: AppStrings.archVeteranDesc,
      icon: Icons.history_edu_rounded,
      tier: AchievementTier.bronze,
    ),
    AchievementDef(
      id: 'color_collector',
      title: AppStrings.archColorCollectorTitle,
      description: AppStrings.archColorCollectorDesc,
      icon: Icons.palette_rounded,
      tier: AchievementTier.silver,
    ),
    AchievementDef(
      id: 'wealthy_scientist',
      title: AppStrings.archWealthyScientistTitle,
      description: AppStrings.archWealthyScientistDesc,
      icon: Icons.savings_outlined,
      tier: AchievementTier.silver,
    ),
    AchievementDef(
      id: 'big_spender',
      title: AppStrings.archBigSpenderTitle,
      description: AppStrings.archBigSpenderDesc,
      icon: Icons.payments_rounded,
      tier: AchievementTier.silver,
    ),
    AchievementDef(
      id: 'daily_scholar',
      title: AppStrings.archDailyScholarTitle,
      description: AppStrings.archDailyScholarDesc,
      icon: Icons.menu_book_rounded,
      tier: AchievementTier.silver,
    ),
    AchievementDef(
      id: 'century_club',
      title: AppStrings.archCenturyClubTitle,
      description: AppStrings.archCenturyClubDesc,
      icon: Icons.auto_graph_rounded,
      tier: AchievementTier.gold,
    ),
    AchievementDef(
      id: 'chaos_master',
      title: AppStrings.archChaosMasterTitle,
      description: AppStrings.archChaosMasterDesc,
      icon: Icons.warning_amber_rounded,
      tier: AchievementTier.gold,
    ),
    AchievementDef(
      id: 'echo_maestro',
      title: AppStrings.archEchoMaestroTitle,
      description: AppStrings.archEchoMaestroDesc,
      icon: Icons.music_note_rounded,
      tier: AchievementTier.gold,
    ),
    AchievementDef(
      id: 'helper_hoarder',
      title: AppStrings.archHelperHoarderTitle,
      description: AppStrings.archHelperHoarderDesc,
      icon: Icons.inventory_2_rounded,
      tier: AchievementTier.gold,
    ),
    AchievementDef(
      id: 'zero_waste',
      title: AppStrings.archZeroWasteTitle,
      description: AppStrings.archZeroWasteDesc,
      icon: Icons.recycling_rounded,
      tier: AchievementTier.gold,
    ),
    AchievementDef(
      id: 'legendary_status',
      title: AppStrings.archLegendaryStatusTitle,
      description: AppStrings.archLegendaryStatusDesc,
      icon: Icons.military_tech_outlined,
      tier: AchievementTier.gold,
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

    // ── Advanced / Phase 2 ────────────────────────────────────────────────────
    if (ctx.chaosLabPlays >= 5) tryUnlock('lab_survivor');
    if (ctx.matchPercentage >= 100 && ctx.echoRound > 0) {
      tryUnlock('spectral_sync');
    }
    if (ctx.currentLevelIndex >= 49) tryUnlock('master_chemist');
    if (ctx.isBlindMode && ctx.stars == 3) tryUnlock('blind_master');
    if (ctx.unlockedSkinsCount >= 6) tryUnlock('shopaholic');
    if (ctx.extraDropsUsed == 1) tryUnlock('stability_expert');
    if (ctx.levelDuration.inSeconds < 5 && ctx.levelDuration.inSeconds > 0) {
      tryUnlock('speed_runner');
    }
    if (ctx.totalStars >= 50) tryUnlock('star_collector');
    if (ctx.stars == 3) tryUnlock('perfectionist');
    if (ctx.totalLevelsCompleted >= 10) tryUnlock('veteran');
    if (ctx.discoveredColorsCount >= 50) tryUnlock('color_collector');
    if (ctx.totalCoins >= 5000) tryUnlock('wealthy_scientist');
    if (ctx.totalSpent >= 2000) tryUnlock('big_spender');
    if (ctx.dailyChallengeCount >= 7) tryUnlock('daily_scholar');
    if (ctx.currentLevelIndex >= 99) tryUnlock('century_club');
    if (ctx.chaosStability < 0.15) tryUnlock('chaos_master');
    if (ctx.echoRound >= 10) tryUnlock('echo_maestro');
    if (ctx.has10OfEachHelper) tryUnlock('helper_hoarder');
    if (ctx.dropsUsedThisLevel == ctx.minDropsNeeded &&
        ctx.minDropsNeeded > 0) {
      tryUnlock('zero_waste');
    }
    if (ctx.totalLevelsCompleted >= 500) tryUnlock('legendary_status');

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
  final int chaosLabPlays;
  final double matchPercentage;
  final int currentLevelIndex;
  final bool isBlindMode;
  final int unlockedSkinsCount;
  final int extraDropsUsed;
  final Duration levelDuration;
  final int discoveredColorsCount;
  final int totalSpent;
  final int dailyChallengeCount;
  final double chaosStability;
  final bool has10OfEachHelper;
  final int minDropsNeeded;

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
    this.chaosLabPlays = 0,
    this.matchPercentage = 0,
    this.currentLevelIndex = 0,
    this.isBlindMode = false,
    this.unlockedSkinsCount = 0,
    this.extraDropsUsed = 0,
    this.levelDuration = Duration.zero,
    this.discoveredColorsCount = 0,
    this.totalSpent = 0,
    this.dailyChallengeCount = 0,
    this.chaosStability = 1.0,
    this.has10OfEachHelper = false,
    this.minDropsNeeded = 0,
  });
}
