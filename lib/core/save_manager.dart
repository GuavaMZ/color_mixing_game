import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:color_mixing_deductive/core/security_service.dart';
import 'package:color_mixing_deductive/core/runtime_integrity_checker.dart';
import 'package:color_mixing_deductive/core/cloud_sync_service.dart';

/// Enhanced SaveManager with security validations, rate limiting, and anomaly detection.
///
/// Security features:
/// - Rate limiting to prevent rapid-fire save attacks
/// - Value validation and bounds checking
/// - Anomaly detection for impossible game states
/// - Checksums for critical data
/// - Automatic rollback on tampering detection
class SaveManager {
  SaveManager._();

  static const String _levelKey = 'player_progress';
  static const String _labConfigKey = 'lab_configuration';
  static const String _unlockedLabItemsKey = 'unlocked_lab_items';
  static const String _totalSpentKey = 'total_spent_coins';
  static const String _dailyChallengeCountKey =
      'daily_challenge_completed_count';

  static CloudSyncService? _syncService;

  /// Initialize the SaveManager with an optional CloudSyncService.
  static void initialize(CloudSyncService? syncService) {
    _syncService = syncService;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RATE LIMITING
  // ═══════════════════════════════════════════════════════════════════════════

  static final Map<String, _RateLimiter> _rateLimiters = {};
  static const Duration _defaultRateLimit = Duration(milliseconds: 500);
  static const Duration _coinsRateLimit = Duration(seconds: 2);

  static _RateLimiter _getLimiter(String key) {
    return _rateLimiters.putIfAbsent(
      key,
      () => _RateLimiter(
        key.contains('coins') ? _coinsRateLimit : _defaultRateLimit,
      ),
    );
  }

  static Future<void> _enforceRateLimit(String key) async {
    final limiter = _getLimiter(key);
    if (!limiter.canProceed()) {
      RuntimeIntegrityChecker.recordSuspiciousActivity(
        'rate_limit_violation',
        details: 'Key: $key, Wait: ${limiter.waitTimeMs}ms',
      );
      await Future.delayed(Duration(milliseconds: limiter.waitTimeMs));
    }
    limiter.recordAccess();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MIGRATION
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> _migrateIfNeeded(String key) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(key)) {
      final value = prefs.getString(key);
      if (value != null) {
        await SecurityService.write(key, value);
        await prefs.remove(key);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROGRESS SAVE/LOAD
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> saveProgress(Map<int, int> progress, String mode) async {
    await _enforceRateLimit('${_levelKey}_$mode');

    // Validate progress data
    if (!_validateProgress(progress)) {
      RuntimeIntegrityChecker.recordSuspiciousActivity(
        'invalid_progress',
        details: 'Mode: $mode',
      );
      return;
    }

    final encodedData = jsonEncode(
      progress.map((key, value) => MapEntry(key.toString(), value)),
    );
    await SecurityService.write('${_levelKey}_$mode', encodedData);

    // Trigger background cloud sync
    _triggerCloudSync('${_levelKey}_$mode', encodedData);
  }

  static bool _validateProgress(Map<int, int> progress) {
    // Check for impossible values
    if (progress.length > 1000) return false; // Sanity check

    for (final entry in progress.entries) {
      // Level numbers should be non-negative
      if (entry.key < 0) return false;

      // Stars should be -1 to 3 (or 0-3 for normal levels)
      if (entry.value < -1 || entry.value > 3) return false;
    }

    // Check for impossible progression (unlocked level too far ahead)
    // This would need game context, so we do basic checks only
    return true;
  }

  static Future<Map<int, int>> loadProgress(String mode) async {
    String key = '${_levelKey}_$mode';
    await _migrateIfNeeded(key);

    String? data = await SecurityService.read(key);

    if (data != null) {
      try {
        Map<String, dynamic> decoded = jsonDecode(data);

        // Validate star counts
        if (decoded.values.any((v) => v is! int || v < -1 || v > 3)) {
          RuntimeIntegrityChecker.recordSuspiciousActivity(
            'invalid_star_count',
            details: 'Mode: $mode',
          );
          return {0: 0};
        }

        return decoded.map(
          (key, value) => MapEntry(int.parse(key), value as int),
        );
      } catch (e) {
        return {0: 0};
      }
    }

    return {0: 0};
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STARS & COINS (CURRENCY)
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> saveTotalStars(int total) async {
    await _enforceRateLimit('total_stars');

    // Validate
    if (total < 0) {
      RuntimeIntegrityChecker.recordSuspiciousActivity(
        'negative_stars',
        details: 'value=$total',
      );
      total = 0;
    }

    // Maximum sanity check (adjust based on your game's max possible stars)
    const maxPossibleStars = 10000;
    if (total > maxPossibleStars) {
      RuntimeIntegrityChecker.recordSuspiciousActivity(
        'impossible_stars',
        details: 'value=$total, max=$maxPossibleStars',
      );
      total = maxPossibleStars;
    }

    await SecurityService.write('total_stars', total.toString());
    _triggerCloudSync('total_stars', total.toString());
  }

  static Future<int> loadTotalStars() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('total_stars')) {
      final val = prefs.getInt('total_stars');
      if (val != null) {
        await SecurityService.write('total_stars', val.toString());
        await prefs.remove('total_stars');
      }
    }

    final data = await SecurityService.read('total_stars');
    if (data != null) {
      final val = int.tryParse(data) ?? 0;
      return val < 0 ? 0 : val;
    }
    return 0;
  }

  static Future<void> saveTotalCoins(int coins) async {
    await _enforceRateLimit('total_coins');

    // Validate
    if (coins < 0) {
      RuntimeIntegrityChecker.recordSuspiciousActivity(
        'negative_coins',
        details: 'value=$coins',
      );
      coins = 0;
    }

    // Maximum sanity check (adjust based on your game's economy)
    const maxPossibleCoins = 1000000;
    if (coins > maxPossibleCoins) {
      RuntimeIntegrityChecker.recordSuspiciousActivity(
        'impossible_coins_rejected',
        details: 'value=$coins, max=$maxPossibleCoins',
      );
      return; // Reject outright instead of capping and saving
    }

    await SecurityService.write('total_coins', coins.toString());
    _triggerCloudSync('total_coins', coins.toString());
  }

  static Future<int> loadTotalCoins() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('total_coins')) {
      final val = prefs.getInt('total_coins');
      if (val != null) {
        await SecurityService.write('total_coins', val.toString());
        await prefs.remove('total_coins');
      }
    }

    final data = await SecurityService.read('total_coins');
    if (data != null) {
      final val = int.tryParse(data) ?? 0;
      return val < 0 ? 0 : val;
    }
    return 0;
  }

  /// Atomic coin transaction with validation
  static Future<bool> addCoins(int amount, {String? reason}) async {
    if (amount < 0) {
      RuntimeIntegrityChecker.recordSuspiciousActivity(
        'negative_coin_add',
        details: 'amount=$amount, reason=$reason',
      );
      return false;
    }

    final current = await loadTotalCoins();
    final newBalance = current + amount;

    // Validate transaction
    if (newBalance > 1000000) {
      RuntimeIntegrityChecker.recordSuspiciousActivity(
        'coin_overflow',
        details: 'current=$current, amount=$amount, new=$newBalance',
      );
      return false;
    }

    await saveTotalCoins(newBalance);
    return true;
  }

  /// Atomic coin spend with validation
  static Future<bool> spendCoins(int amount, {String? reason}) async {
    if (amount <= 0) {
      RuntimeIntegrityChecker.recordSuspiciousActivity(
        'invalid_coin_spend',
        details: 'amount=$amount, reason=$reason',
      );
      return false;
    }

    final current = await loadTotalCoins();
    if (current < amount) {
      RuntimeIntegrityChecker.recordSuspiciousActivity(
        'insufficient_coins',
        details: 'current=$current, needed=$amount, reason=$reason',
      );
      return false;
    }

    await saveTotalCoins(current - amount);

    // Track total spent
    final spent = await loadTotalSpent();
    await saveTotalSpent(spent + amount);
    return true;
  }

  static Future<void> saveTotalSpent(int amount) async {
    await SecurityService.write(_totalSpentKey, amount.toString());
  }

  static Future<int> loadTotalSpent() async {
    final data = await SecurityService.read(_totalSpentKey);
    return data != null ? (int.tryParse(data) ?? 0) : 0;
  }

  static Future<void> incrementDailyChallengeCount() async {
    final current = await loadDailyChallengeCount();
    await SecurityService.write(
      _dailyChallengeCountKey,
      (current + 1).toString(),
    );
  }

  static Future<int> loadDailyChallengeCount() async {
    final data = await SecurityService.read(_dailyChallengeCountKey);
    return data != null ? (int.tryParse(data) ?? 0) : 0;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PURCHASED ITEMS
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> savePurchasedSkins(List<String> skins) async {
    await _enforceRateLimit('purchased_skins');
    final data = jsonEncode(skins);
    await SecurityService.write('purchased_skins', data);
    _triggerCloudSync('purchased_skins', data);
  }

  static Future<List<String>> loadPurchasedSkins() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('purchased_skins')) {
      final val = prefs.getStringList('purchased_skins');
      if (val != null) {
        await SecurityService.write('purchased_skins', jsonEncode(val));
        await prefs.remove('purchased_skins');
      }
    }

    final data = await SecurityService.read('purchased_skins');
    if (data != null) {
      try {
        return (jsonDecode(data) as List).cast<String>();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  static Future<void> saveAchievements(List<String> achievements) async {
    await _enforceRateLimit('unlocked_achievements');
    await SecurityService.write(
      'unlocked_achievements',
      jsonEncode(achievements),
    );
    _triggerCloudSync('unlocked_achievements', jsonEncode(achievements));
  }

  static Future<List<String>> loadAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('unlocked_achievements')) {
      final val = prefs.getStringList('unlocked_achievements');
      if (val != null) {
        await SecurityService.write('unlocked_achievements', jsonEncode(val));
        await prefs.remove('unlocked_achievements');
      }
    }

    final data = await SecurityService.read('unlocked_achievements');
    if (data != null) {
      try {
        return (jsonDecode(data) as List).cast<String>();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SETTINGS
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> saveBlindMode(bool enabled) async {
    await SecurityService.write('blind_mode_enabled', enabled.toString());
  }

  static Future<bool> loadBlindMode() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('blind_mode_enabled')) {
      final val = prefs.getBool('blind_mode_enabled');
      if (val != null) {
        await SecurityService.write('blind_mode_enabled', val.toString());
        await prefs.remove('blind_mode_enabled');
      }
    }

    final data = await SecurityService.read('blind_mode_enabled');
    return data == 'true';
  }

  static Future<void> saveReducedMotion(bool enabled) async {
    await SecurityService.write('reduced_motion_enabled', enabled.toString());
  }

  static Future<bool> loadReducedMotion() async {
    final data = await SecurityService.read('reduced_motion_enabled');
    return data == 'true';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> saveHelpers(Map<String, int> helpers) async {
    await _enforceRateLimit('helper_counts');

    // Validate
    for (final entry in helpers.entries) {
      if (entry.value < 0 || entry.value > 999) {
        RuntimeIntegrityChecker.recordSuspiciousActivity(
          'invalid_helper_count',
          details: '${entry.key}=${entry.value}',
        );
        return;
      }
    }

    await SecurityService.write('helper_counts', jsonEncode(helpers));
  }

  static Future<Map<String, int>> loadHelpers() async {
    await _migrateIfNeeded('helper_counts');

    String? data = await SecurityService.read('helper_counts');
    if (data != null) {
      try {
        Map<String, dynamic> decoded = jsonDecode(data);

        // Validate helper counts
        if (decoded.values.any((v) => v is! int || v < 0)) {
          RuntimeIntegrityChecker.recordSuspiciousActivity(
            'negative_helper_count',
          );
          return {
            'extra_drops': 3,
            'help_drop': 3,
            'reveal_color': 3,
            'undo': 3,
          };
        }

        return decoded.map((key, value) => MapEntry(key, value as int));
      } catch (e) {}
    }
    return {'extra_drops': 3, 'help_drop': 3, 'reveal_color': 3, 'undo': 3};
  }

  static Future<void> saveRandomEvents(bool enabled) async {
    await SecurityService.write('random_events_enabled', enabled.toString());
  }

  static Future<bool> loadRandomEvents() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('random_events_enabled')) {
      final val = prefs.getBool('random_events_enabled');
      if (val != null) {
        await SecurityService.write('random_events_enabled', val.toString());
        await prefs.remove('random_events_enabled');
      }
    }

    final data = await SecurityService.read('random_events_enabled');
    return data == 'true';
  }

  static Future<void> saveSelectedSkin(String skinName) async {
    await SecurityService.write('selected_beaker_skin', skinName);
  }

  static Future<String?> loadSelectedSkin() async {
    await _migrateIfNeeded('selected_beaker_skin');
    return await SecurityService.read('selected_beaker_skin');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LAB UPGRADES
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> saveLabConfig(Map<String, String> config) async {
    await _enforceRateLimit(_labConfigKey);
    await SecurityService.write(_labConfigKey, jsonEncode(config));
  }

  static Future<Map<String, String>> loadLabConfig() async {
    await _migrateIfNeeded(_labConfigKey);

    String? data = await SecurityService.read(_labConfigKey);
    if (data != null) {
      try {
        Map<String, dynamic> decoded = jsonDecode(data);
        return decoded.map((key, value) => MapEntry(key, value as String));
      } catch (e) {}
    }

    return {
      'surface': 'surface_steel',
      'lighting': 'light_basic',
      'background': 'bg_default',
      'stand': 'stand_basic',
    };
  }

  static Future<void> saveUnlockedLabItems(List<String> items) async {
    await _enforceRateLimit(_unlockedLabItemsKey);
    await SecurityService.write(_unlockedLabItemsKey, jsonEncode(items));
  }

  static Future<List<String>> loadUnlockedLabItems() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_unlockedLabItemsKey)) {
      final val = prefs.getStringList(_unlockedLabItemsKey);
      if (val != null) {
        await SecurityService.write(_unlockedLabItemsKey, jsonEncode(val));
        await prefs.remove(_unlockedLabItemsKey);
      }
    }

    String? data = await SecurityService.read(_unlockedLabItemsKey);
    if (data != null) {
      try {
        return (jsonDecode(data) as List).cast<String>();
      } catch (e) {}
    }

    return ['surface_steel', 'light_basic', 'bg_default', 'stand_basic'];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GALLERY (COLOR DISCOVERY)
  // ═══════════════════════════════════════════════════════════════════════════

  static const String _discoveredColorsKey = 'discovered_colors';

  static Future<Set<int>> loadDiscoveredColors() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_discoveredColorsKey)) {
      final val = prefs.getStringList(_discoveredColorsKey);
      if (val != null) {
        await SecurityService.write(_discoveredColorsKey, jsonEncode(val));
        await prefs.remove(_discoveredColorsKey);
      }
    }

    final data = await SecurityService.read(_discoveredColorsKey);
    if (data != null) {
      try {
        final List<dynamic> decoded = jsonDecode(data);
        return decoded.map((id) => int.parse(id.toString())).toSet();
      } catch (e) {}
    }
    return {};
  }

  static Future<void> saveDiscoveredColor(int colorId) async {
    final discovered = await loadDiscoveredColors();
    discovered.add(colorId);
    await saveDiscoveredColors(discovered);
  }

  static Future<void> saveDiscoveredColors(Set<int> colorIds) async {
    await _enforceRateLimit(_discoveredColorsKey);

    // Validate color IDs
    if (colorIds.any((id) => id < 0 || id > 10000)) {
      RuntimeIntegrityChecker.recordSuspiciousActivity(
        'invalid_color_id',
        details: 'count=${colorIds.length}',
      );
      return;
    }

    final stringIds = colorIds.map((id) => id.toString()).toList();
    await SecurityService.write(_discoveredColorsKey, jsonEncode(stringIds));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GENERIC METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> saveBool(String key, bool value) async {
    await SecurityService.write(key, value.toString());
  }

  static Future<bool?> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(key)) {
      final val = prefs.getBool(key);
      if (val != null) {
        await SecurityService.write(key, val.toString());
        await prefs.remove(key);
      }
    }

    final data = await SecurityService.read(key);
    return data == 'true';
  }

  static Future<void> saveStringList(String key, List<String> value) async {
    await _enforceRateLimit(key);
    await SecurityService.write(key, jsonEncode(value));
  }

  static Future<List<String>?> getStringList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(key)) {
      final val = prefs.getStringList(key);
      if (val != null) {
        await SecurityService.write(key, jsonEncode(val));
        await prefs.remove(key);
      }
    }

    final data = await SecurityService.read(key);
    if (data != null) {
      try {
        return (jsonDecode(data) as List).cast<String>();
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REDEEM CODES
  // ═══════════════════════════════════════════════════════════════════════════

  static void _triggerCloudSync(String key, String localData) {
    if (_syncService == null) return;

    // We use the current timestamp for Last-Write-Wins
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Fire and forget cloud sync in background
    _syncService!
        .syncKey(key, localData, timestamp)
        .then((latestData) {
          if (latestData != null && latestData != localData) {
            // Cloud had newer data, we should ideally update local storage
            // but to avoid loops and complexity in this PR, we'll let the next load handle it
            // or we could call SecurityService.write(key, latestData) here.
            SecurityService.write(key, latestData);
          }
        })
        .catchError((_) {});
  }

  static const String _redeemedCodesKey = 'redeemed_codes';

  static Future<bool> isCodeRedeemed(String code) async {
    final codes = await _loadRedeemedCodes();
    return codes.contains(code.toUpperCase());
  }

  static Future<void> markCodeAsRedeemed(String code) async {
    await _enforceRateLimit(_redeemedCodesKey);
    final codes = await _loadRedeemedCodes();
    codes.add(code.toUpperCase());
    await SecurityService.write(_redeemedCodesKey, jsonEncode(codes));
  }

  static Future<List<String>> _loadRedeemedCodes() async {
    final data = await SecurityService.read(_redeemedCodesKey);
    if (data != null) {
      try {
        return (jsonDecode(data) as List).cast<String>();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PURCHASE HISTORY (IAP)
  // ═══════════════════════════════════════════════════════════════════════════

  static const String _purchaseHistoryKey = 'iap_purchase_history';

  static Future<void> savePurchaseHistory(
    List<Map<String, dynamic>> history,
  ) async {
    await _enforceRateLimit(_purchaseHistoryKey);
    await SecurityService.write(_purchaseHistoryKey, jsonEncode(history));
  }

  static Future<List<Map<String, dynamic>>> loadPurchaseHistory() async {
    final data = await SecurityService.read(_purchaseHistoryKey);
    if (data != null) {
      try {
        final List<dynamic> decoded = jsonDecode(data);
        return decoded.cast<Map<String, dynamic>>();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECURITY UTILITIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get security statistics for debugging
  static Future<Map<String, dynamic>> getSecurityStats() async {
    final securityStats = await SecurityService.getSecurityStats();
    return {
      ...securityStats,
      'rate_limiters': _rateLimiters.length,
      'security_events':
          RuntimeIntegrityChecker.getSecurityStatus()['events'] ?? [],
    };
  }
}

/// Rate limiter to prevent rapid-fire save attacks
class _RateLimiter {
  final Duration _limit;
  DateTime? _lastAccess;

  _RateLimiter(this._limit);

  bool canProceed() {
    if (_lastAccess == null) return true;
    final elapsed = DateTime.now().difference(_lastAccess!);
    return elapsed >= _limit;
  }

  int get waitTimeMs {
    if (_lastAccess == null) return 0;
    final elapsed = DateTime.now().difference(_lastAccess!);
    final remaining = _limit - elapsed;
    return remaining.inMilliseconds.clamp(0, _limit.inMilliseconds);
  }

  void recordAccess() {
    _lastAccess = DateTime.now();
  }
}
