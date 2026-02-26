import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:color_mixing_deductive/core/save_manager.dart';
import 'package:color_mixing_deductive/core/security_service.dart';
import 'package:color_mixing_deductive/core/runtime_integrity_checker.dart';
import 'package:crypto/crypto.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Represents a single coin bundle available in the store.
class CoinBundle {
  final String id;
  final String name;
  final int coins;
  final String displayPrice; // Fallback display — overwritten by real IAP price
  final bool isMostPopular;
  final bool isBestValue;
  final int bonusPercent;
  final String emoji;

  const CoinBundle({
    required this.id,
    required this.name,
    required this.coins,
    required this.displayPrice,
    this.isMostPopular = false,
    this.isBestValue = false,
    this.bonusPercent = 0,
    required this.emoji,
  });
}

/// All available coin bundles.
///
/// The [CoinBundle.id] values MUST match the product IDs created on
/// Google Play Console → Monetize → Products → In-app products.
const List<CoinBundle> kCoinBundles = [
  CoinBundle(
    id: 'basic_bundle',
    name: 'Basic Bundle',
    coins: 1000,
    displayPrice: '\$0.99',
    emoji: '⚗️',
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

// Product IDs that need to be loaded from the Play Store.
final Set<String> _kProductIds = kCoinBundles.map((b) => b.id).toSet();

/// Enum representing the current state of a purchase attempt.
enum PurchaseFlowState { idle, pending, success, error }

/// Result returned after completing (or failing) a purchase.
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

/// Main service that manages the coin store and Google Play Billing.
///
/// Usage:
/// 1. Call [CoinStoreService.instance.initialize] once at app startup (or when
///    the store is first opened).
/// 2. Observe [purchaseStream] for purchase outcomes.
/// 3. Call [initiatePurchase] to start a purchase.
class CoinStoreService {
  CoinStoreService._();
  static final CoinStoreService instance = CoinStoreService._();

  // ─── Keys ─────────────────────────────────────────────────────────────────
  static const String _receiptKey = 'iap_last_receipt';

  // Enhanced key for receipt signing (64 bytes of entropy)
  static final List<int> _receiptKeyBytes = List<int>.unmodifiable(
    <int>[
      0x69, 0x61, 0x70, 0x5F, 0x73, 0x65, 0x63, 0x75, // iap_secu
      0x72, 0x65, 0x5F, 0x72, 0x65, 0x63, 0x65, 0x69, // re_recei
      0x70, 0x74, 0x5F, 0x32, 0x30, 0x32, 0x36, 0x5F, // pt_2026_
      0x73, 0x65, 0x63, 0x75, 0x72, 0x65, 0x5F, 0x76, // secure_v
      0x32, 0x5F, 0x65, 0x6E, 0x68, 0x61, 0x6E, 0x63, // 2_enhanc
      0x65, 0x64, 0x5F, 0x6B, 0x65, 0x79, 0x5F, 0x68, // ed_key_h
      0x61, 0x73, 0x68, 0x5F, 0x73, 0x65, 0x63, 0x72, // ash_secr
      0x65, 0x74, 0x5F, 0x73, 0x61, 0x6C, 0x74, 0x5F, // et_salt_
      0x72, 0x61, 0x6E, 0x64, 0x6F, 0x6D, 0x5F, 0x62, // random_b
      0x79, 0x74, 0x65, 0x73, 0x5F, 0x66, 0x6F, 0x72, // ytes_for
      0x5F, 0x63, 0x6F, 0x6C, 0x6F, 0x72, 0x5F, 0x6D, // _color_m
      0x69, 0x78, 0x69, 0x6E, 0x67, 0x5F, 0x67, 0x61, // ixing_ga
      0x6D, 0x65, 0x5F, 0x32, 0x30, 0x32, 0x36, 0x5F, // me_2026_
      0x73, 0x65, 0x63, 0x75, 0x72, 0x69, 0x74, 0x79, // security
    ]..shuffle(math.Random(42)), // Deterministic shuffle for consistency
  );

  // ─── State ────────────────────────────────────────────────────────────────
  bool _initialized = false;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  ColorMixerGame? _game;

  // Purchase tracking for duplicate prevention
  static final Set<String> _pendingPurchases = {};
  static final Map<String, DateTime> _recentPurchases = {};
  static const _purchaseDedupWindow = Duration(seconds: 30);

  /// Products loaded from the Play Store, keyed by product ID.
  /// Use this to display real prices in the UI.
  final Map<String, ProductDetails> loadedProducts = {};

  /// Stream that emits a [PurchaseResult] every time a purchase completes
  /// (whether successfully or with an error).
  final StreamController<PurchaseResult> _purchaseResultController =
      StreamController<PurchaseResult>.broadcast();

  Stream<PurchaseResult> get purchaseStream => _purchaseResultController.stream;

  /// Supply the game reference so background purchases can award coins locally.
  void attachGame(ColorMixerGame game) {
    _game = game;
  }

  /// Initialize the billing client and load products from the Play Store.
  ///
  /// Safe to call multiple times — will no-op if already initialized.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Initialize security service first
    await SecurityService.initialize();

    final bool available = await InAppPurchase.instance.isAvailable();
    if (!available) {
      return;
    }

    _purchaseSubscription = InAppPurchase.instance.purchaseStream.listen(
      _onPurchaseUpdate,
    );

    final ProductDetailsResponse response = await InAppPurchase.instance
        .queryProductDetails(_kProductIds);

    for (final product in response.productDetails) {
      loadedProducts[product.id] = product;
    }

    // Clean up old pending purchases
    _cleanupPendingPurchases();
  }

  /// Clean up pending purchases older than the dedup window
  void _cleanupPendingPurchases() {
    final now = DateTime.now();
    _recentPurchases.removeWhere(
      (_, timestamp) => now.difference(timestamp) > _purchaseDedupWindow,
    );
  }

  // ─── Purchase Entry Points ────────────────────────────────────────────────

  /// Start a real Google Play purchase for a paid [CoinBundle].
  ///
  /// The result will arrive asynchronously via [purchaseStream].
  Future<void> initiatePurchase(CoinBundle bundle) async {
    await initialize();

    // Check for duplicate purchase attempt
    if (_recentPurchases.containsKey(bundle.id)) {
      final lastPurchase = _recentPurchases[bundle.id]!;
      if (DateTime.now().difference(lastPurchase) < _purchaseDedupWindow) {
        RuntimeIntegrityChecker.recordSuspiciousActivity(
          'duplicate_purchase_attempt',
          details: 'bundle=${bundle.id}',
        );
        _purchaseResultController.add(
          const PurchaseResult(
            success: false,
            coins: 0,
            error: 'Purchase in progress. Please wait.',
          ),
        );
        return;
      }
    }

    final ProductDetails? product = loadedProducts[bundle.id];
    if (product == null) {
      RuntimeIntegrityChecker.recordSuspiciousActivity(
        'purchase_product_not_found',
        details: 'bundle=${bundle.id}',
      );
      _purchaseResultController.add(
        const PurchaseResult(
          success: false,
          coins: 0,
          error:
              'Product not available. Please check your internet connection.',
        ),
      );
      return;
    }

    final PurchaseParam params = PurchaseParam(productDetails: product);
    _pendingPurchases.add(bundle.id);
    await InAppPurchase.instance.buyConsumable(purchaseParam: params);
  }

  // ─── History & Receipts ───────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> loadPurchaseHistory() async {
    return SaveManager.loadPurchaseHistory();
  }

  Future<bool> verifyLastReceipt() async {
    final raw = await SecurityService.read(_receiptKey);
    if (raw == null) return false;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final storedSig = decoded['sig'] as String? ?? '';
      final payload = Map<String, dynamic>.from(decoded)..remove('sig');
      final expectedSig = _sign(jsonEncode(payload));

      if (storedSig != expectedSig) {
        RuntimeIntegrityChecker.recordSuspiciousActivity(
          'receipt_signature_mismatch',
          details: 'Receipt tampering detected',
        );
        return false;
      }

      // Additional validation: check timestamp freshness
      final timestampStr = decoded['timestamp'] as String?;
      if (timestampStr != null) {
        final timestamp = DateTime.tryParse(timestampStr);
        if (timestamp != null) {
          final age = DateTime.now().difference(timestamp);
          // Warn if receipt is from future or very old
          if (age.isNegative || age.inDays > 365) {
            RuntimeIntegrityChecker.recordSuspiciousActivity(
              'receipt_timestamp_anomaly',
              details: 'timestamp=$timestampStr',
            );
          }
        }
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Internal ────────────────────────────────────────────────────────────

  /// Handles all events from the Google Play purchase stream.
  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final bundle = kCoinBundles
              .where((b) => b.id == purchase.productID)
              .firstOrNull;

          if (bundle != null) {
            // Verify this isn't a duplicate
            final purchaseKey = '${purchase.productID}_${purchase.purchaseID}';
            if (_recentPurchases.containsKey(purchaseKey)) {
              RuntimeIntegrityChecker.recordSuspiciousActivity(
                'duplicate_purchase_detected',
                details:
                    'product=${purchase.productID}, id=${purchase.purchaseID}',
              );
              // Still complete the purchase to avoid issues with Google Play
              await InAppPurchase.instance.completePurchase(purchase);
              continue;
            }

            // Generate and store receipt with enhanced validation
            final receipt = _generateReceipt(
              bundle,
              purchase.verificationData.serverVerificationData,
              purchaseID: purchase.purchaseID,
            );
            await _storeReceipt(receipt);
            await _appendToHistory(bundle, bundle.coins);

            // Award coins with validation
            final int currentCoins = await SaveManager.loadTotalCoins();
            final int newBalance = currentCoins + bundle.coins;

            // Validate coin award
            if (newBalance > 1000000) {
              RuntimeIntegrityChecker.recordSuspiciousActivity(
                'coin_award_overflow',
                details:
                    'current=$currentCoins, award=${bundle.coins}, new=$newBalance',
              );
            }

            await SaveManager.saveTotalCoins(newBalance);

            if (_game != null) {
              _game!.totalCoins.value = newBalance;
            }

            // Mark as recently purchased
            _recentPurchases[purchaseKey] = DateTime.now();
            _pendingPurchases.remove(bundle.id);

            _purchaseResultController.add(
              PurchaseResult(
                success: true,
                coins: bundle.coins,
                receipt: receipt,
              ),
            );
          }

          // CRITICAL: Always acknowledge / complete the purchase.
          await InAppPurchase.instance.completePurchase(purchase);
          break;

        case PurchaseStatus.error:
          _pendingPurchases.clear();
          _purchaseResultController.add(
            PurchaseResult(
              success: false,
              coins: 0,
              error: purchase.error?.message ?? 'Purchase failed.',
            ),
          );
          break;

        case PurchaseStatus.canceled:
          _pendingPurchases.removeWhere((key) => true); // Clear all pending
          _purchaseResultController.add(
            const PurchaseResult(success: false, coins: 0, error: 'canceled'),
          );
          break;
      }
    }
  }

  String _generateReceipt(
    CoinBundle bundle,
    String serverToken, {
    String? purchaseID,
    int? purchaseTime,
  }) {
    final payload = {
      'bundle_id': bundle.id,
      'bundle_name': bundle.name,
      'coins_awarded': bundle.coins,
      'timestamp': DateTime.now().toIso8601String(),
      'token': serverToken,
      'purchase_id': purchaseID,
      'purchase_time': purchaseTime,
      'nonce': _generateNonce(), // Add random nonce for uniqueness
    };
    final sig = _sign(jsonEncode(payload));
    payload['sig'] = sig;
    return jsonEncode(payload);
  }

  String _sign(String data) {
    final hmac = Hmac(sha256, _receiptKeyBytes);
    return hmac.convert(utf8.encode(data)).toString();
  }

  String _generateNonce() {
    final random = math.Random();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
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

  void dispose() {
    _purchaseSubscription?.cancel();
    _purchaseResultController.close();
  }
}
