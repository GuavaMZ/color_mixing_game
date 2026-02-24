import 'dart:async';
import 'dart:convert';
import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:color_mixing_deductive/core/save_manager.dart';
import 'package:color_mixing_deductive/core/security_service.dart';
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
  final bool isOneTime; // Starter pack (free, one-time)
  final int bonusPercent;
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

/// All available coin bundles.
///
/// The [CoinBundle.id] values MUST match the product IDs created on
/// Google Play Console → Monetize → Products → In-app products.
/// The Starter Pack (isOneTime = true) is free and has no Play Store product.
const List<CoinBundle> kCoinBundles = [
  CoinBundle(
    id: 'starter_pack',
    name: 'Starter Pack',
    coins: 500,
    displayPrice: 'FREE',
    isOneTime: true,
    emoji: '🎁',
  ),
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
// The starter_pack is excluded — it is free and not a Play Store product.
final Set<String> _kProductIds = kCoinBundles
    .where((b) => !b.isOneTime)
    .map((b) => b.id)
    .toSet();

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
/// 3. Call [initiatePurchase] or [processStarterPack] to start a purchase.
class CoinStoreService {
  CoinStoreService._();
  static final CoinStoreService instance = CoinStoreService._();

  // ─── Keys ─────────────────────────────────────────────────────────────────
  static const String _receiptKey = 'iap_last_receipt';
  static const String _starterClaimedKey = 'starter_pack_claimed';

  static const List<int> _receiptKeyBytes = [
    0x69,
    0x61,
    0x70,
    0x5F,
    0x73,
    0x65,
    0x63,
    0x75,
    0x72,
    0x65,
    0x5F,
    0x72,
    0x65,
    0x63,
    0x65,
    0x69,
    0x70,
    0x74,
    0x5F,
    0x32,
    0x30,
    0x32,
    0x36,
  ];

  // ─── State ────────────────────────────────────────────────────────────────
  // ─── State ────────────────────────────────────────────────────────────────
  bool _initialized = false;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  ColorMixerGame? _game;

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

    final bool available = await InAppPurchase.instance.isAvailable();
    if (!available) {
      // Billing not available (e.g. emulator without Play Services setup,
      // or a release build not yet published). Silently skip — the UI
      // will fall back to displaying the hardcoded displayPrice.
      return;
    }

    // Subscribe to the purchase stream BEFORE loading products, so we don't
    // miss any events from pending transactions on startup.
    _purchaseSubscription = InAppPurchase.instance.purchaseStream.listen(
      _onPurchaseUpdate,
    );

    // Load product details from the Play Store
    final ProductDetailsResponse response = await InAppPurchase.instance
        .queryProductDetails(_kProductIds);

    for (final product in response.productDetails) {
      loadedProducts[product.id] = product;
    }
  }

  // ─── Purchase Entry Points ────────────────────────────────────────────────

  /// Start a real Google Play purchase for a paid [CoinBundle].
  ///
  /// The result will arrive asynchronously via [purchaseStream].
  Future<void> initiatePurchase(CoinBundle bundle) async {
    assert(!bundle.isOneTime, 'Use processStarterPack for the starter pack.');

    await initialize(); // Ensure initialized

    final ProductDetails? product = loadedProducts[bundle.id];
    if (product == null) {
      // Product not loaded — likely not set up on Play Console yet.
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
    // Coin bundles are consumable — they can be purchased multiple times.
    await InAppPurchase.instance.buyConsumable(purchaseParam: params);
    // Result handled by _onPurchaseUpdate
  }

  /// Award the free Starter Pack and mark it as claimed.
  ///
  /// Returns a [PurchaseResult] immediately (no Play Store interaction needed).
  Future<PurchaseResult> processStarterPack(CoinBundle bundle) async {
    assert(bundle.isOneTime, 'Use initiatePurchase for paid bundles.');

    final claimed = await isStarterPackClaimed();
    if (claimed) {
      return const PurchaseResult(
        success: false,
        coins: 0,
        error: 'Starter pack already claimed.',
      );
    }

    await _markStarterPackClaimed();
    return _awardCoins(bundle);
  }

  // ─── One-Time Claim ───────────────────────────────────────────────────────

  Future<bool> isStarterPackClaimed() async {
    final val = await SecurityService.read(_starterClaimedKey);
    return val == 'true';
  }

  Future<void> _markStarterPackClaimed() async {
    await SecurityService.write(_starterClaimedKey, 'true');
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
      return storedSig == expectedSig;
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
          // Waiting for user to complete payment — no action needed yet.
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // Find the matching bundle
          final bundle = kCoinBundles
              .where((b) => b.id == purchase.productID)
              .firstOrNull;

          if (bundle != null) {
            // NOTE: In production, send purchase.verificationData to your
            // backend server here and only award coins after server confirms.
            // For now we award client-side and write a tamper-proof local receipt.
            final receipt = _generateReceipt(
              bundle,
              purchase.verificationData.serverVerificationData,
            );
            await _storeReceipt(receipt);
            await _appendToHistory(bundle, bundle.coins);

            // Award coins directly here, so it works even if UI is closed!
            if (_game != null) {
              final int newBalance = _game!.totalCoins.value + bundle.coins;
              _game!.totalCoins.value = newBalance;
              await SaveManager.saveTotalCoins(newBalance);
            }

            _purchaseResultController.add(
              PurchaseResult(
                success: true,
                coins: bundle.coins,
                receipt: receipt,
              ),
            );
          }

          // CRITICAL: Always acknowledge / complete the purchase.
          // If you don't, Google Play automatically refunds it after 3 days.
          await InAppPurchase.instance.completePurchase(purchase);
          break;

        case PurchaseStatus.error:
          _purchaseResultController.add(
            PurchaseResult(
              success: false,
              coins: 0,
              error: purchase.error?.message ?? 'Purchase failed.',
            ),
          );
          break;

        case PurchaseStatus.canceled:
          _purchaseResultController.add(
            const PurchaseResult(success: false, coins: 0, error: 'canceled'),
          );
          break;
      }
    }
  }

  /// Awards coins locally. Used for starter pack and can be called from
  /// _onPurchaseUpdate after server verification in production.
  Future<PurchaseResult> _awardCoins(CoinBundle bundle) async {
    if (_game != null) {
      final int newBalance = _game!.totalCoins.value + bundle.coins;
      _game!.totalCoins.value = newBalance;
      await SaveManager.saveTotalCoins(newBalance);
    }

    final receipt = _generateReceipt(bundle, 'local');
    await _storeReceipt(receipt);
    await _appendToHistory(bundle, bundle.coins);

    return PurchaseResult(success: true, coins: bundle.coins, receipt: receipt);
  }

  String _generateReceipt(CoinBundle bundle, String serverToken) {
    final payload = {
      'bundle_id': bundle.id,
      'coins_awarded': bundle.coins,
      'timestamp': DateTime.now().toIso8601String(),
      'token': serverToken,
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

  void dispose() {
    _purchaseSubscription?.cancel();
    _purchaseResultController.close();
  }
}
