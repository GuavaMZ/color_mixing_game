import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages VIP Scientist subscription status.
///
/// VIP benefits:
/// - Interstitial ads are suppressed.
/// - Coin bonus multiplier of 1.2x applies on every win.
///
/// Persistence is via SharedPreferences. In a production build,
/// pair this with CoinStoreService (vip_monthly product) to set isVip on purchase.
class VipManager {
  VipManager._internal();
  static final VipManager instance = VipManager._internal();

  static const String _vipKey = 'vip_is_active';
  static const String _expiryKey = 'vip_expiry_date';

  final ValueNotifier<bool> isVip = ValueNotifier(false);
  DateTime? _expiryDate;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final storedExpiry = prefs.getString(_expiryKey);
    if (storedExpiry != null) {
      _expiryDate = DateTime.tryParse(storedExpiry);
    }

    // Auto-deactivate on expiry
    if (_expiryDate != null && DateTime.now().isAfter(_expiryDate!)) {
      await _deactivate(prefs);
    } else {
      isVip.value = prefs.getBool(_vipKey) ?? false;
    }
  }

  /// Activate VIP for 30 days from now. Call this on successful IAP.
  Future<void> activate() async {
    _expiryDate = DateTime.now().add(const Duration(days: 30));
    isVip.value = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vipKey, true);
    await prefs.setString(_expiryKey, _expiryDate!.toIso8601String());
  }

  Future<void> _deactivate(SharedPreferences prefs) async {
    isVip.value = false;
    _expiryDate = null;
    await prefs.setBool(_vipKey, false);
    await prefs.remove(_expiryKey);
  }

  /// Returns 1.2 for VIPs, 1.0 for everyone else.
  double get coinMultiplier => isVip.value ? 1.2 : 1.0;

  /// Formatted expiry string for display in Settings.
  String get expiryLabel {
    if (_expiryDate == null) return '—';
    final diff = _expiryDate!.difference(DateTime.now());
    if (diff.inDays > 0) return '${diff.inDays} days left';
    if (diff.inHours > 0) return '${diff.inHours} hours left';
    return 'Expires soon';
  }
}
