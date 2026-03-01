import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:color_mixing_deductive/core/coin_store.dart';
import 'package:color_mixing_deductive/core/save_manager.dart';
import 'package:color_mixing_deductive/helpers/audio_manager.dart';
import 'package:color_mixing_deductive/helpers/string_manager.dart';
import 'package:color_mixing_deductive/helpers/theme_constants.dart';
import 'package:color_mixing_deductive/helpers/visual_effects.dart';
import 'package:color_mixing_deductive/components/ui/animated_card.dart';
import 'package:color_mixing_deductive/components/ui/coins_widget.dart';
import 'package:color_mixing_deductive/components/ui/responsive_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../../color_mixer_game.dart';

class CoinStoreOverlay extends StatefulWidget {
  final ColorMixerGame game;
  const CoinStoreOverlay({super.key, required this.game});

  @override
  State<CoinStoreOverlay> createState() => _CoinStoreOverlayState();
}

class _CoinStoreOverlayState extends State<CoinStoreOverlay>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  bool _isProcessing = false;
  List<Map<String, dynamic>> _purchaseHistory = [];
  StreamSubscription<PurchaseResult>? _purchaseSub;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _loadState();
    _initBilling();
  }

  Future<void> _initBilling() async {
    await CoinStoreService.instance.initialize();
    if (!mounted) return;
    // Refresh UI so real prices from Play are shown
    setState(() {});
    // Listen to purchase outcomes
    _purchaseSub = CoinStoreService.instance.purchaseStream.listen(
      _onPurchaseResult,
    );
  }

  void _onPurchaseResult(PurchaseResult result) {
    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (result.success) {
      // Award coins to game
      final int newBalance = widget.game.totalCoins.value + result.coins;
      widget.game.totalCoins.value = newBalance;
      SaveManager.saveTotalCoins(newBalance);

      AudioManager().playWin();
      // Find the bundle that was just purchased
      final bundle = kCoinBundles.firstWhere(
        (b) => b.coins == result.coins,
        orElse: () => kCoinBundles.first,
      );
      _purchaseHistory.insert(0, {
        'bundle_id': bundle.id,
        'bundle_name': bundle.name,
        'coins': result.coins,
        'timestamp': DateTime.now().toIso8601String(),
      });
      _showSuccessDialogForCoins(result.coins, bundle);
    } else if (result.error != null && result.error != 'canceled') {
      _showErrorSnackbar(result.error!);
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.neonMagenta,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _loadState() async {
    final history = await CoinStoreService.instance.loadPurchaseHistory();
    if (mounted) {
      setState(() {
        _purchaseHistory = history;
      });
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _pulseController.dispose();
    _purchaseSub?.cancel();
    super.dispose();
  }

  Future<void> _handlePurchase(CoinBundle bundle) async {
    if (_isProcessing) return;

    // ── Paid bundle — launch real Google Play billing flow ─────────────────
    setState(() => _isProcessing = true);
    // The result arrives asynchronously via purchaseStream → _onPurchaseResult
    await CoinStoreService.instance.initiatePurchase(bundle);
    // Leave _isProcessing = true until the stream resolves.
    // The stream listener will set it back to false.
  }

  void _showSuccessDialogForCoins(int coins, CoinBundle bundle) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PurchaseSuccessDialog(
        bundle: bundle,
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _showPurchaseHistorySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          _PurchaseHistorySheet(history: _purchaseHistory, context: context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.backgroundGradient,
              ),
            ),
          ),
          const Positioned.fill(
            child: StarField(starCount: 60, color: Colors.white),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(color: Colors.black.withValues(alpha: 0.3)),
            ),
          ),

          // Gold shimmer orbs
          ..._buildGoldOrbs(),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    children: [
                      _buildSubtitle(context),
                      const SizedBox(height: 24),
                      ...kCoinBundles.map(
                        (bundle) => _CoinBundleCard(
                          bundle: bundle,
                          isProcessing: _isProcessing,
                          shimmerController: _shimmerController,
                          pulseController: _pulseController,
                          onTap: () => _handlePurchase(bundle),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildRestoreButton(context),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.neonCyan),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ResponsiveIconButton(
            onPressed: () {
              AudioManager().playButton();
              widget.game.returnToMainMenu();
            },
            icon: Icons.arrow_back_rounded,
            color: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            borderColor: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.monetization_on_rounded,
                      color: Colors.amber,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.coinStore.getString(context).toUpperCase(),
                      style: AppTheme.heading3(context).copyWith(
                        fontSize: 20,
                        letterSpacing: 3,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.amber.withValues(alpha: 0.6),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  height: 1.5,
                  width: 60,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber, AppTheme.neonCyan],
                    ),
                  ),
                ),
              ],
            ),
          ),
          CoinsWidget(
            coinsNotifier: widget.game.totalCoins,
            iconSize: 18,
            fontSize: 15,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Opacity(
          opacity: 0.6 + _pulseController.value * 0.4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  Colors.amber.withValues(alpha: 0.1),
                  Colors.orange.withValues(alpha: 0.05),
                ],
              ),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_open_rounded,
                  color: Colors.amber,
                  size: 16,
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: ResponsiveHelper.isMobile(context) ? 250 : 350,
                  child: Text(
                    AppStrings.coinStoreSubtitle.getString(context),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 0.5,
                      overflow: TextOverflow.clip,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRestoreButton(BuildContext context) {
    return TextButton.icon(
      onPressed: _showPurchaseHistorySheet,
      icon: const Icon(Icons.history_rounded, color: Colors.white54, size: 18),
      label: Text(
        AppStrings.restorePurchases.getString(context),
        style: const TextStyle(color: Colors.white54, fontSize: 13),
      ),
    );
  }

  List<Widget> _buildGoldOrbs() {
    return List.generate(3, (i) {
      final random = math.Random(i * 42);
      return Positioned(
        left: random.nextDouble() * 300 - 50,
        top: random.nextDouble() * 600 - 50,
        child: AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, _) {
            return Opacity(
              opacity:
                  (math.sin(_shimmerController.value * math.pi * 2 + i) * 0.5 +
                      0.5) *
                  0.15,
              child: Container(
                width: 150 + i * 40.0,
                height: 150 + i * 40.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.amber.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }
}

// ─── Bundle Card ─────────────────────────────────────────────────────────────

class _CoinBundleCard extends StatelessWidget {
  final CoinBundle bundle;
  final bool isProcessing;
  final AnimationController shimmerController;
  final AnimationController pulseController;
  final VoidCallback onTap;

  const _CoinBundleCard({
    required this.bundle,
    required this.isProcessing,
    required this.shimmerController,
    required this.pulseController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color accentColor = _getAccentColor();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AnimatedCard(
        onTap: isProcessing ? () {} : onTap,
        hasGlow: bundle.isMostPopular || bundle.isBestValue,
        fillColor: Colors.black.withValues(alpha: 0.35),
        borderColor: accentColor.withValues(alpha: 0.5),
        borderWidth: bundle.isMostPopular || bundle.isBestValue ? 2 : 1.5,
        child: Stack(
          children: [
            // Background gradient
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Shimmer effect for featured bundles
            if ((bundle.isMostPopular || bundle.isBestValue))
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: shimmerController,
                  builder: (context, _) {
                    final shift = shimmerController.value;
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment(-1 + shift * 3, -1),
                            end: Alignment(shift * 3, 1),
                            colors: [
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.04),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Main content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Emoji & coin count
                  _buildCoinDisplay(context, accentColor),

                  const SizedBox(width: 16),

                  // Name & bonus
                  Expanded(child: _buildInfoSection(context)),

                  // Price / Action button
                  _buildActionButton(context, accentColor),
                ],
              ),
            ),

            // Badges
            if (bundle.isMostPopular)
              _buildBadge(
                context,
                AppStrings.mostPopular.getString(context),
                const Color(0xFFFF6B35),
              ),
            if (bundle.isBestValue)
              _buildBadge(
                context,
                AppStrings.bestValue.getString(context),
                const Color(0xFF00D4AA),
              ),
          ],
        ),
      ),
    );
  }

  Color _getAccentColor() {
    if (bundle.id == 'basic_bundle') return AppTheme.neonCyan;
    if (bundle.id == 'popular_bundle') return const Color(0xFFFF6B35);
    if (bundle.id == 'mega_bundle') return const Color(0xFF00D4AA);
    if (bundle.id == 'ultimate_bundle') return Colors.amber;
    return Colors.white;
  }

  Widget _buildCoinDisplay(BuildContext context, Color accent) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(bundle.emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.monetization_on_rounded,
              color: Colors.amber,
              size: 14,
            ),
            const SizedBox(width: 2),
            Text(
              _formatCoins(bundle.coins),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          bundle.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
        if (bundle.bonusPercent > 0) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.greenAccent.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              '+${bundle.bonusPercent}% ${AppStrings.bonus.getString(context)}',
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, Color accent) {
    final String label = bundle.displayPrice;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.8),
            accent.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String text, Color color) {
    return Positioned(
      top: 0,
      right: 12,
      child: Container(
        transform: Matrix4.translationValues(0, -1, 0),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8),
          ],
        ),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  String _formatCoins(int coins) {
    if (coins >= 1000) {
      final k = coins / 1000;
      return k == k.truncate() ? '${k.toInt()}K' : '${k.toStringAsFixed(1)}K';
    }
    return coins.toString();
  }
}

// ─── Purchase Success Dialog ──────────────────────────────────────────────────

class _PurchaseSuccessDialog extends StatefulWidget {
  final CoinBundle bundle;
  final VoidCallback onDismiss;

  const _PurchaseSuccessDialog({required this.bundle, required this.onDismiss});

  @override
  State<_PurchaseSuccessDialog> createState() => _PurchaseSuccessDialogState();
}

class _PurchaseSuccessDialogState extends State<_PurchaseSuccessDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _coinController;
  late Animation<double> _scaleAnim;
  late Animation<double> _coinCountAnim;
  List<_FloatingCoin> _coins = [];

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _coinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _coinCountAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _coinController, curve: Curves.easeOut));

    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _coinController.forward();
      _spawnCoins();
    });
  }

  void _spawnCoins() {
    final rng = math.Random();
    setState(() {
      _coins = List.generate(
        12,
        (i) => _FloatingCoin(
          x: rng.nextDouble(),
          delay: rng.nextDouble() * 0.5,
          speed: 0.5 + rng.nextDouble() * 0.5,
        ),
      );
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _coinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int targetCoins = widget.bundle.coins;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryDark.withValues(alpha: 0.97),
                const Color(0xFF1A1A40).withValues(alpha: 0.97),
              ],
            ),
            border: Border.all(
              color: Colors.amber.withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.3),
                blurRadius: 30,
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Floating coin particles
              // Main content and particles
              Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 16),

                        // Success icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.amber.withValues(alpha: 0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.monetization_on_rounded,
                            color: Colors.amber,
                            size: 52,
                            shadows: [
                              Shadow(color: Colors.amber, blurRadius: 20),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          widget.bundle.emoji,
                          style: const TextStyle(fontSize: 36),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          AppStrings.purchaseSuccess.getString(context),
                          style: AppTheme.heading3(
                            context,
                          ).copyWith(color: Colors.white, fontSize: 20),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 8),

                        // Animated coin count
                        AnimatedBuilder(
                          animation: _coinCountAnim,
                          builder: (context, _) {
                            final displayed =
                                (targetCoins * _coinCountAnim.value).toInt();
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.monetization_on_rounded,
                                  color: Colors.amber,
                                  size: 28,
                                  shadows: [
                                    Shadow(
                                      color: Colors.amber.withValues(
                                        alpha: 0.8,
                                      ),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '+$displayed',
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    shadows: [
                                      Shadow(
                                        color: Colors.amber,
                                        blurRadius: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 8),

                        Text(
                          AppStrings.enjoyYourCoins.getString(context),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: widget.onDismiss,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              AppStrings.ok.getString(context).toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Coin particles
                  IgnorePointer(
                    child: SizedBox(
                      height: 300,
                      child: Stack(
                        children: [
                          ..._coins.map(
                            (c) => _AnimatedCoinParticle(
                              coin: c,
                              controller: _coinController,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingCoin {
  final double x;
  final double delay;
  final double speed;
  _FloatingCoin({required this.x, required this.delay, required this.speed});
}

class _AnimatedCoinParticle extends AnimatedWidget {
  final _FloatingCoin coin;
  const _AnimatedCoinParticle({
    required this.coin,
    required AnimationController controller,
  }) : super(listenable: controller);

  @override
  Widget build(BuildContext context) {
    final controller = listenable as AnimationController;
    final progress = ((controller.value - coin.delay) / (1 - coin.delay)).clamp(
      0.0,
      1.0,
    );

    if (progress <= 0) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width * 0.6;
    final x = coin.x * screenWidth;
    final y = 250.0 - (progress * 280.0 * coin.speed);
    final opacity = (1 - progress).clamp(0.0, 1.0);

    return Positioned(
      left: x,
      top: y,
      child: Opacity(
        opacity: opacity,
        child: const Icon(
          Icons.monetization_on_rounded,
          color: Colors.amber,
          size: 18,
        ),
      ),
    );
  }
}

// ─── Purchase History Sheet ───────────────────────────────────────────────────

class _PurchaseHistorySheet extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  final BuildContext context;

  const _PurchaseHistorySheet({required this.history, required this.context});

  @override
  Widget build(BuildContext ctx) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark.withValues(alpha: 0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(
                  Icons.history_rounded,
                  color: AppTheme.neonCyan,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  AppStrings.purchaseHistory.getString(context),
                  style: AppTheme.heading3(
                    context,
                  ).copyWith(fontSize: 18, color: Colors.white),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Expanded(
            child: history.isEmpty
                ? Center(
                    child: Text(
                      AppStrings.noPurchasesYet.getString(context),
                      style: const TextStyle(color: Colors.white38),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: history.length,
                    separatorBuilder: (_, _) =>
                        const Divider(color: Colors.white12),
                    itemBuilder: (_, i) {
                      final entry = history[i];
                      final date = DateTime.tryParse(
                        entry['timestamp'] as String? ?? '',
                      );
                      final dateStr = date != null
                          ? '${date.day}/${date.month}/${date.year}'
                          : '—';

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.monetization_on_rounded,
                          color: Colors.amber,
                        ),
                        title: Text(
                          entry['bundle_name'] as String? ?? 'Bundle',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          dateStr,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.monetization_on_rounded,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '+${entry['coins']}',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
