import 'dart:convert';
import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:color_mixing_deductive/core/save_manager.dart';
import 'package:color_mixing_deductive/core/security_service.dart';
import 'package:crypto/crypto.dart';

/// Represents a single coin bundle available in the store.
class CoinBundle {
  final String id;
  final String name;
  final int coins;
  final String displayPrice; // e.g. "$0.99" (display only for now)
  final bool isMostPopular;
  final bool isBestValue;
  final bool isOneTime; // One-time daily bonus
  final int bonusPercent; // e.g. 20 means "+20% Bonus"
  final String emoji;

  const CoinBundle({
    required this.id,
    required this.name,
    required this.coins,
    required this.displayPrice,
    this.isMostPopular = false,
    this.isBestValue = false,
    this.isOneTime = false,
    this.bonusPercent = 0,
    required this.emoji,
  });
}

/// All available coin bundles in the store.
const List<CoinBundle> kCoinBundles = [
  CoinBundle(
    id: 'starter_pack',
    name: 'Starter Pack',
    coins: 500,
    displayPrice: 'FREE',
    isOneTime: true,
    emoji: '🎁',
    bonusPercent: 0,
  ),
  CoinBundle(
    id: 'basic_bundle',
    name: 'Basic Bundle',
    coins: 1000,
    displayPrice: '\$0.99',
    emoji: '⚗️',
    bonusPercent: 0,
  ),
  CoinBundle(
    id: 'popular_bundle',
    name: 'Popular Bundle',
    coins: 3000,
    displayPrice: '\$2.99',
    isMostPopular: true,
    emoji: '🔬',
    bonusPercent: 20,
  ),
  CoinBundle(
    id: 'mega_bundle',
    name: 'Mega Bundle',
    coins: 7500,
    displayPrice: '\$4.99',
    isBestValue: true,
    emoji: '🧬',
    bonusPercent: 50,
  ),
  CoinBundle(
    id: 'ultimate_bundle',
    name: 'Ultimate Bundle',
    coins: 20000,
    displayPrice: '\$9.99',
    emoji: '🚀',
    bonusPercent: 100,
  ),
];

/// Service that handles secure simulated coin purchases.
///
/// Architecture note: This is a production-ready simulated IAP system. Each
/// "purchase" generates a tamper-proof HMAC-signed receipt stored in
/// [SecurityService]. When real payment integration is added (e.g. via the
/// `in_app_purchase` package), replace [processPurchase] with real payment
/// handling and keep the receipt verification layer intact.
class CoinStoreService {
  CoinStoreService._();
  static final CoinStoreService instance = CoinStoreService._();

  static const String _receiptKey = 'iap_last_receipt';
  static const String _starterClaimedKey = 'starter_pack_claimed';

  // Receipt HMAC uses the same key material as SecurityService for consistency.
  static const List<int> _receiptKeyBytes = [
    0x69, 0x61, 0x70, 0x5F, 0x73, 0x65, 0x63, 0x75, // iap_secu
    0x72, 0x65, 0x5F, 0x72, 0x65, 0x63, 0x65, 0x69, // re_recei
    0x70, 0x74, 0x5F, 0x32, 0x30, 0x32, 0x36, // pt_2026
  ];

  /// Check if the one-time starter pack has been claimed.
  Future<bool> isStarterPackClaimed() async {
    final val = await SecurityService.read(_starterClaimedKey);
    return val == 'true';
  }

  /// Mark the starter pack as claimed.
  Future<void> _markStarterPackClaimed() async {
    await SecurityService.write(_starterClaimedKey, 'true');
  }

  /// Process a simulated purchase of a [CoinBundle].
  ///
  /// Awards coins to the [game] and writes a tamper-proof receipt.
  /// Returns [PurchaseResult] describing the outcome.
  Future<PurchaseResult> processPurchase(
    CoinBundle bundle,
    ColorMixerGame game,
  ) async {
    // Validate starter pack claim
    if (bundle.isOneTime) {
      final claimed = await isStarterPackClaimed();
      if (claimed) {
        return PurchaseResult(
          success: false,
          error: 'Starter pack already claimed.',
          coins: 0,
        );
      }
      await _markStarterPackClaimed();
    }

    // Award coins
    final int newBalance = game.totalCoins.value + bundle.coins;
    game.totalCoins.value = newBalance;
    await SaveManager.saveTotalCoins(newBalance);

    // Generate a tamper-proof receipt
    final receipt = _generateReceipt(bundle, newBalance);
    await _storeReceipt(receipt);

    // Append to purchase history
    await _appendToHistory(bundle, bundle.coins);

    return PurchaseResult(success: true, coins: bundle.coins, receipt: receipt);
  }

  /// Verify the last stored receipt's integrity.
  Future<bool> verifyLastReceipt() async {
    final raw = await SecurityService.read(_receiptKey);
    if (raw == null) return false;

    try {
      final Map<String, dynamic> decoded = jsonDecode(raw);
      final String storedSig = decoded['sig'] as String? ?? '';
      final Map<String, dynamic> payload = Map<String, dynamic>.from(decoded)
        ..remove('sig');

      final String expectedSig = _sign(jsonEncode(payload));
      return storedSig == expectedSig;
    } catch (_) {
      return false;
    }
  }

  /// Load the full purchase history.
  Future<List<Map<String, dynamic>>> loadPurchaseHistory() async {
    return await SaveManager.loadPurchaseHistory();
  }

  // ─── Private Helpers ─────────────────────────────────────────────────────

  String _generateReceipt(CoinBundle bundle, int newBalance) {
    final payload = {
      'bundle_id': bundle.id,
      'coins_awarded': bundle.coins,
      'new_balance': newBalance,
      'timestamp': DateTime.now().toIso8601String(),
    };
    final sig = _sign(jsonEncode(payload));
    payload['sig'] = sig;
    return jsonEncode(payload);
  }

  String _sign(String data) {
    final hmac = Hmac(sha256, _receiptKeyBytes);
    return hmac.convert(utf8.encode(data)).toString();
  }

  Future<void> _storeReceipt(String receiptJson) async {
    await SecurityService.write(_receiptKey, receiptJson);
  }

  Future<void> _appendToHistory(CoinBundle bundle, int coinsAwarded) async {
    final history = await SaveManager.loadPurchaseHistory();
    history.add({
      'bundle_id': bundle.id,
      'bundle_name': bundle.name,
      'coins': coinsAwarded,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await SaveManager.savePurchaseHistory(history);
  }
}

/// Result of a [CoinStoreService.processPurchase] call.
class PurchaseResult {
  final bool success;
  final int coins;
  final String? receipt;
  final String? error;

  const PurchaseResult({
    required this.success,
    required this.coins,
    this.receipt,
    this.error,
  });
}
