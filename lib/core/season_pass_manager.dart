import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────────────────────────────────────────

enum RewardType { coins, labTheme, beakerSkin, helperItem, cardPack }

class PassReward {
  final RewardType type;
  final String label;
  final String emoji;
  final int amount; // coins amount or item count
  final bool isPremium; // false = free tier, true = premium only

  const PassReward({
    required this.type,
    required this.label,
    required this.emoji,
    required this.amount,
    this.isPremium = false,
  });
}

class PassTier {
  final int tier; // 1–30
  final int xpRequired; // cumulative XP for this tier
  final PassReward freeReward;
  final PassReward? premiumReward; // null if no premium bonus at this tier

  const PassTier({
    required this.tier,
    required this.xpRequired,
    required this.freeReward,
    this.premiumReward,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Season Pass Tier Catalog (30 tiers)
// ─────────────────────────────────────────────────────────────────────────────

const List<PassTier> kPassTiers = [
  PassTier(
    tier: 1,
    xpRequired: 100,
    freeReward: PassReward(
      type: RewardType.coins,
      label: '50 Coins',
      emoji: '🪙',
      amount: 50,
    ),
  ),
  PassTier(
    tier: 2,
    xpRequired: 250,
    freeReward: PassReward(
      type: RewardType.coins,
      label: '75 Coins',
      emoji: '🪙',
      amount: 75,
    ),
  ),
  PassTier(
    tier: 3,
    xpRequired: 450,
    freeReward: PassReward(
      type: RewardType.helperItem,
      label: '2 Hint Drops',
      emoji: '💧',
      amount: 2,
    ),
  ),
  PassTier(
    tier: 4,
    xpRequired: 700,
    freeReward: PassReward(
      type: RewardType.coins,
      label: '100 Coins',
      emoji: '🪙',
      amount: 100,
    ),
  ),
  PassTier(
    tier: 5,
    xpRequired: 1000,
    freeReward: PassReward(
      type: RewardType.cardPack,
      label: 'Card Pack',
      emoji: '🃏',
      amount: 1,
    ),
    premiumReward: PassReward(
      type: RewardType.beakerSkin,
      label: 'Neon Skin',
      emoji: '✨',
      amount: 1,
      isPremium: true,
    ),
  ),
  PassTier(
    tier: 6,
    xpRequired: 1350,
    freeReward: PassReward(
      type: RewardType.coins,
      label: '125 Coins',
      emoji: '🪙',
      amount: 125,
    ),
  ),
  PassTier(
    tier: 7,
    xpRequired: 1750,
    freeReward: PassReward(
      type: RewardType.coins,
      label: '150 Coins',
      emoji: '🪙',
      amount: 150,
    ),
  ),
  PassTier(
    tier: 8,
    xpRequired: 2200,
    freeReward: PassReward(
      type: RewardType.helperItem,
      label: '3 Undo Uses',
      emoji: '↩️',
      amount: 3,
    ),
  ),
  PassTier(
    tier: 9,
    xpRequired: 2700,
    freeReward: PassReward(
      type: RewardType.coins,
      label: '175 Coins',
      emoji: '🪙',
      amount: 175,
    ),
  ),
  PassTier(
    tier: 10,
    xpRequired: 3250,
    freeReward: PassReward(
      type: RewardType.cardPack,
      label: 'Card Pack',
      emoji: '🃏',
      amount: 1,
    ),
    premiumReward: PassReward(
      type: RewardType.labTheme,
      label: 'Aurora Theme',
      emoji: '🌌',
      amount: 1,
      isPremium: true,
    ),
  ),
  PassTier(
    tier: 11,
    xpRequired: 3850,
    freeReward: PassReward(
      type: RewardType.coins,
      label: '200 Coins',
      emoji: '🪙',
      amount: 200,
    ),
  ),
  PassTier(
    tier: 12,
    xpRequired: 4500,
    freeReward: PassReward(
      type: RewardType.coins,
      label: '225 Coins',
      emoji: '🪙',
      amount: 225,
    ),
  ),
  PassTier(
    tier: 13,
    xpRequired: 5200,
    freeReward: PassReward(
      type: RewardType.helperItem,
      label: '3 Reveal Uses',
      emoji: '🔍',
      amount: 3,
    ),
  ),
  PassTier(
    tier: 14,
    xpRequired: 5950,
    freeReward: PassReward(
      type: RewardType.coins,
      label: '250 Coins',
      emoji: '🪙',
      amount: 250,
    ),
  ),
  PassTier(
    tier: 15,
    xpRequired: 6750,
    freeReward: PassReward(
      type: RewardType.cardPack,
      label: 'Rare Pack',
      emoji: '🎴',
      amount: 1,
    ),
    premiumReward: PassReward(
      type: RewardType.beakerSkin,
      label: 'Holographic Skin',
      emoji: '🌈',
      amount: 1,
      isPremium: true,
    ),
  ),
  PassTier(
    tier: 16,
    xpRequired: 7600,
    freeReward: PassReward(
      type: RewardType.coins,
      label: '300 Coins',
      emoji: '🪙',
      amount: 300,
    ),
  ),
  PassTier(
    tier: 17,
    xpRequired: 8500,
    freeReward: PassReward(
      type: RewardType.coins,
      label: '325 Coins',
      emoji: '🪙',
      amount: 325,
    ),
  ),
  PassTier(
    tier: 18,
    xpRequired: 9450,
    freeReward: PassReward(
      type: RewardType.helperItem,
      label: '5 Hint Drops',
      emoji: '💧',
      amount: 5,
    ),
  ),
  PassTier(
    tier: 19,
    xpRequired: 10450,
    freeReward: PassReward(
      type: RewardType.coins,
      label: '350 Coins',
      emoji: '🪙',
      amount: 350,
    ),
  ),
  PassTier(
    tier: 20,
    xpRequired: 11500,
    freeReward: PassReward(
      type: RewardType.cardPack,
      label: 'Rare Pack',
      emoji: '🎴',
      amount: 1,
    ),
    premiumReward: PassReward(
      type: RewardType.labTheme,
      label: 'Lava Theme',
      emoji: '🌋',
      amount: 1,
      isPremium: true,
    ),
  ),
  PassTier(
    tier: 21,
    xpRequired: 12600,
    freeReward: PassReward(
      type: RewardType.coins,
      label: '400 Coins',
      emoji: '🪙',
      amount: 400,
    ),
  ),
  PassTier(
    tier: 22,
    xpRequired: 13750,
    freeReward: PassReward(
      type: RewardType.coins,
      label: '425 Coins',
      emoji: '🪙',
      amount: 425,
    ),
  ),
  PassTier(
    tier: 23,
    xpRequired: 14950,
    freeReward: PassReward(
      type: RewardType.helperItem,
      label: '5 Undo Uses',
      emoji: '↩️',
      amount: 5,
    ),
  ),
  PassTier(
    tier: 24,
    xpRequired: 16200,
    freeReward: PassReward(
      type: RewardType.coins,
      label: '450 Coins',
      emoji: '🪙',
      amount: 450,
    ),
  ),
  PassTier(
    tier: 25,
    xpRequired: 17500,
    freeReward: PassReward(
      type: RewardType.cardPack,
      label: 'Legendary Pack',
      emoji: '⭐',
      amount: 1,
    ),
    premiumReward: PassReward(
      type: RewardType.beakerSkin,
      label: 'Galaxy Skin',
      emoji: '🌠',
      amount: 1,
      isPremium: true,
    ),
  ),
  PassTier(
    tier: 26,
    xpRequired: 18850,
    freeReward: PassReward(
      type: RewardType.coins,
      label: '500 Coins',
      emoji: '🪙',
      amount: 500,
    ),
  ),
  PassTier(
    tier: 27,
    xpRequired: 20250,
    freeReward: PassReward(
      type: RewardType.coins,
      label: '550 Coins',
      emoji: '🪙',
      amount: 550,
    ),
  ),
  PassTier(
    tier: 28,
    xpRequired: 21700,
    freeReward: PassReward(
      type: RewardType.helperItem,
      label: '5 Reveal Uses',
      emoji: '🔍',
      amount: 5,
    ),
  ),
  PassTier(
    tier: 29,
    xpRequired: 23200,
    freeReward: PassReward(
      type: RewardType.coins,
      label: '600 Coins',
      emoji: '🪙',
      amount: 600,
    ),
  ),
  PassTier(
    tier: 30,
    xpRequired: 25000,
    freeReward: PassReward(
      type: RewardType.coins,
      label: '1000 Coins',
      emoji: '💰',
      amount: 1000,
    ),
    premiumReward: PassReward(
      type: RewardType.beakerSkin,
      label: 'Grand Alchemist Skin',
      emoji: '👑',
      amount: 1,
      isPremium: true,
    ),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// SeasonPassManager Singleton
// ─────────────────────────────────────────────────────────────────────────────

class SeasonPassManager {
  SeasonPassManager._internal();
  static final SeasonPassManager instance = SeasonPassManager._internal();

  static const String _xpKey = 'sp_season_xp';
  static const String _tierKey = 'sp_current_tier';
  static const String _premiumKey = 'sp_is_premium';
  static const String _claimedKey = 'sp_claimed_tiers';
  static const String _seasonEndKey = 'sp_season_end';

  final ValueNotifier<int> totalXp = ValueNotifier(0);
  final ValueNotifier<int> currentTier = ValueNotifier(0);
  final ValueNotifier<bool> isPremium = ValueNotifier(false);
  final ValueNotifier<Set<int>> claimedTiers = ValueNotifier({});
  DateTime? _seasonEnd;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    totalXp.value = prefs.getInt(_xpKey) ?? 0;
    currentTier.value = prefs.getInt(_tierKey) ?? 0;
    isPremium.value = prefs.getBool(_premiumKey) ?? false;
    final claimed = prefs.getStringList(_claimedKey) ?? [];
    claimedTiers.value = claimed.map(int.parse).toSet();

    // Season lifecycle
    final endStr = prefs.getString(_seasonEndKey);
    if (endStr != null) {
      _seasonEnd = DateTime.tryParse(endStr);
    }
    if (_seasonEnd == null || DateTime.now().isAfter(_seasonEnd!)) {
      await _startNewSeason(prefs);
    }
  }

  Future<void> _startNewSeason(SharedPreferences prefs) async {
    _seasonEnd = DateTime(DateTime.now().year, DateTime.now().month + 1, 1);
    totalXp.value = 0;
    currentTier.value = 0;
    claimedTiers.value = {};
    await prefs.setInt(_xpKey, 0);
    await prefs.setInt(_tierKey, 0);
    await prefs.setString(_seasonEndKey, _seasonEnd!.toIso8601String());
    await prefs.setStringList(_claimedKey, []);
  }

  /// Call after a win loop finishes awarding XP.
  Future<void> addPassXp(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    totalXp.value += amount;
    await prefs.setInt(_xpKey, totalXp.value);
    _recalculateTier(prefs);
  }

  void _recalculateTier(SharedPreferences prefs) {
    int newTier = 0;
    for (final t in kPassTiers) {
      if (totalXp.value >= t.xpRequired) {
        newTier = t.tier;
      } else {
        break;
      }
    }
    if (newTier != currentTier.value) {
      currentTier.value = newTier;
      prefs.setInt(_tierKey, newTier);
    }
  }

  /// Returns true if the reward can be claimed right now.
  bool canClaim(int tier, {bool premium = false}) {
    if (currentTier.value < tier) return false;
    final key = premium ? tier * 1000 : tier;
    return !claimedTiers.value.contains(key);
  }

  Future<void> claimTier(int tier, {bool premium = false}) async {
    final key = premium ? tier * 1000 : tier;
    if (claimedTiers.value.contains(key)) return;
    claimedTiers.value = {...claimedTiers.value, key};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _claimedKey,
      claimedTiers.value.map((e) => e.toString()).toList(),
    );
  }

  Future<void> upgradeToPremium() async {
    isPremium.value = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, true);
  }

  // How much XP into the current tier progress (0.0 → 1.0)
  double get tierProgress {
    if (currentTier.value >= kPassTiers.length) return 1.0;
    final current = currentTier.value > 0
        ? kPassTiers[currentTier.value - 1].xpRequired
        : 0;
    final next = kPassTiers[currentTier.value].xpRequired;
    final span = next - current;
    if (span <= 0) return 1.0;
    return ((totalXp.value - current) / span).clamp(0.0, 1.0);
  }

  DateTime? get seasonEnd => _seasonEnd;

  String get timeUntilSeasonEnd {
    if (_seasonEnd == null) return '—';
    final diff = _seasonEnd!.difference(DateTime.now());
    if (diff.inDays > 0) return '${diff.inDays}d ${diff.inHours % 24}h';
    if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes % 60}m';
    return '${diff.inMinutes}m';
  }
}
