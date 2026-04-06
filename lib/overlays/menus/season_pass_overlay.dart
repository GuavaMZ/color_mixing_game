import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../../../color_mixer_game.dart';
import '../../helpers/theme_constants.dart';
import '../../helpers/audio_manager.dart';
import '../../helpers/visual_effects.dart';
import '../../helpers/string_manager.dart';
import '../../components/ui/responsive_components.dart';
import '../../core/season_pass_manager.dart';
import '../../core/save_manager.dart';

class SeasonPassOverlay extends StatefulWidget {
  final ColorMixerGame game;
  const SeasonPassOverlay({super.key, required this.game});

  @override
  State<SeasonPassOverlay> createState() => _SeasonPassOverlayState();
}

class _SeasonPassOverlayState extends State<SeasonPassOverlay>
    with SingleTickerProviderStateMixin {
  final _manager = SeasonPassManager.instance;
  late AnimationController _shimmerCtrl;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Jump to current tier
    final tier = _manager.currentTier.value;
    final startPage = (tier - 3).clamp(0, 29);
    _pageController = PageController(
      viewportFraction: 0.28,
      initialPage: startPage,
    );
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _close() {
    AudioManager().playButton();
    widget.game.returnToMainMenu();
  }

  Future<void> _handleClaim(int tier, {bool premium = false}) async {
    if (!_manager.canClaim(tier, premium: premium)) return;
    AudioManager().playWin();
    await _manager.claimTier(tier, premium: premium);

    // Award the reward
    final tierData = kPassTiers[tier - 1];
    final reward = premium ? tierData.premiumReward! : tierData.freeReward;
    if (reward.type == RewardType.coins) {
      bool success = await SaveManager.addCoins(
        reward.amount,
        reason: 'Season pass reward',
      );
      if (success) {
        widget.game.totalCoins.value = await SaveManager.loadTotalCoins();
      }
    } else if (reward.type == RewardType.helperItem) {
      final helperId = reward.label.contains('Hint')
          ? 'help_drop'
          : reward.label.contains('Undo')
          ? 'undo'
          : 'reveal_color';
      widget.game.addHelpers(helperId, reward.amount);
    }
    if (mounted) setState(() {});
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
          const StarField(starCount: 80, color: Colors.white),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildProgressBar(),
                const SizedBox(height: 8),
                Expanded(child: _buildTierTrack()),
                _buildPremiumCTA(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          ResponsiveIconButton(
            icon: Icons.arrow_back_rounded,
            onPressed: _close,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerEffect(
                  baseColor: Colors.white,
                  highlightColor: const Color(0xFFFFD700),
                  child: Text(
                    AppStrings.seasonPassTitle.getString(context),
                    style: AppTheme.heading2(context).copyWith(fontSize: 22),
                  ),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: _manager.isPremium,
                  builder: (context, premium, child) => Text(
                    premium
                        ? '👑 ${AppStrings.premiumActive.getString(context)} — ${_manager.timeUntilSeasonEnd} left'
                        : '⏳ ${_manager.timeUntilSeasonEnd} ${AppStrings.remaining.getString(context)}',
                    style: AppTheme.bodySmall(context).copyWith(
                      color: premium ? const Color(0xFFFFD700) : Colors.white60,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ValueListenableBuilder<int>(
            valueListenable: _manager.totalXp,
            builder: (context, xp, child) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: AppTheme.cosmicGlass(borderRadius: 16),
              child: Column(
                children: [
                  Text(
                    '$xp',
                    style: AppTheme.heading3(
                      context,
                    ).copyWith(color: const Color(0xFFFFD700), fontSize: 18),
                  ),
                  Text(
                    'XP',
                    style: AppTheme.caption(
                      context,
                    ).copyWith(color: Colors.white54, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ValueListenableBuilder<int>(
        valueListenable: _manager.currentTier,
        builder: (context, tier, child) {
          final progress = _manager.tierProgress;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${AppStrings.tierLabel.getString(context)} $tier / 30',
                    style: AppTheme.bodySmall(
                      context,
                    ).copyWith(color: Colors.white70),
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: AppTheme.bodySmall(context).copyWith(
                      color: AppTheme.neonCyan,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonCyan.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12, // Increased height for premium feel
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(AppTheme.neonCyan),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTierTrack() {
    return PageView.builder(
      controller: _pageController,
      itemCount: kPassTiers.length,
      itemBuilder: (context, index) {
        final tierData = kPassTiers[index];
        return _buildTierCard(tierData);
      },
    );
  }

  Widget _buildTierCard(PassTier tierData) {
    return ValueListenableBuilder<int>(
      valueListenable: _manager.currentTier,
      builder: (context, currentTier, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: _manager.isPremium,
          builder: (context, isPremium, child) {
            return ValueListenableBuilder<Set<int>>(
              valueListenable: _manager.claimedTiers,
              builder: (context, claimed, child) {
                final isUnlocked = currentTier >= tierData.tier;
                final isFreeClaimed = claimed.contains(tierData.tier);
                final isPremiumClaimed = claimed.contains(tierData.tier * 1000);
                final isCurrentTier = currentTier == tierData.tier;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isCurrentTier
                          ? const Color(0xFFFFD700)
                          : isUnlocked
                          ? AppTheme.neonCyan.withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.08),
                      width: isCurrentTier ? 2 : 1,
                    ),
                    color: isUnlocked
                        ? AppTheme.primaryMedium.withValues(alpha: 0.6)
                        : Colors.white.withValues(
                            alpha: 0.03,
                          ), // Lighter frosted look
                    boxShadow: [
                      if (isCurrentTier)
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      if (isUnlocked && !isCurrentTier)
                        BoxShadow(
                          color: AppTheme.neonCyan.withValues(alpha: 0.2),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        // Tier badge
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: isUnlocked
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFFFD700),
                                      Color(0xFFFF8C00),
                                    ],
                                  )
                                : null,
                            color: isUnlocked ? null : Colors.white12,
                          ),
                          child: Center(
                            child: Text(
                              '${tierData.tier}',
                              style: TextStyle(
                                color: isUnlocked
                                    ? Colors.black
                                    : Colors.white38,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ==== FREE REWARD ====
                        _RewardCard(
                          reward: tierData.freeReward,
                          isUnlocked: isUnlocked,
                          isClaimed: isFreeClaimed,
                          onClaim: () => _handleClaim(tierData.tier),
                          canClaim: _manager.canClaim(tierData.tier),
                        ),

                        // ==== PREMIUM REWARD ====
                        if (tierData.premiumReward != null) ...[
                          const SizedBox(height: 8),
                          _RewardCard(
                            reward: tierData.premiumReward!,
                            isUnlocked: isUnlocked && isPremium,
                            isClaimed: isPremiumClaimed,
                            onClaim: () =>
                                _handleClaim(tierData.tier, premium: true),
                            canClaim:
                                isPremium &&
                                _manager.canClaim(tierData.tier, premium: true),
                            isPremiumCard: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPremiumCTA() {
    // TEMPORARILY HIDDEN
    return const SizedBox.shrink();
    /*
    return ValueListenableBuilder<bool>(
      valueListenable: _manager.isPremium,
      builder: (context, isPremium, child) {
        if (isPremium) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  AudioManager().playButton();
                  _showPremiumDialog();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.workspace_premium_rounded,
                        color: Colors.black,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppStrings.goPremium.getString(context),
                        style: AppTheme.heading3(context).copyWith(
                          color: Colors.black,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '\$2.99',
                          style: AppTheme.bodySmall(context).copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    */
  }

/*
  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.primaryDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: const Color(0xFFFFD700), width: 2),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFFFD700),
            ),
            const SizedBox(width: 8),
            Text(
              AppStrings.premiumTitle.getString(context),
              style: AppTheme.heading2(context).copyWith(fontSize: 20),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _perkRow('🌈', AppStrings.premiumPerk1.getString(context)),
            _perkRow('✨', AppStrings.premiumPerk2.getString(context)),
            _perkRow('👑', AppStrings.premiumPerk3.getString(context)),
            _perkRow('🃏', AppStrings.premiumPerk4.getString(context)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppStrings.cancel.getString(context),
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              // TODO: hook to CoinStoreService.instance.initiatePurchase for season_pass_premium
              // For now unlock locally for demonstration
              await _manager.upgradeToPremium();
              if (mounted) setState(() {});
            },
            child: Text(AppStrings.goPremium.getString(context)),
          ),
        ],
      ),
    );
  }

  Widget _perkRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
  */
}

// ─────────────────────────────────────────────────────────────────────────────
// Reward Card Widget
// ─────────────────────────────────────────────────────────────────────────────

class _RewardCard extends StatelessWidget {
  final PassReward reward;
  final bool isUnlocked;
  final bool isClaimed;
  final bool canClaim;
  final VoidCallback onClaim;
  final bool isPremiumCard;

  const _RewardCard({
    required this.reward,
    required this.isUnlocked,
    required this.isClaimed,
    required this.canClaim,
    required this.onClaim,
    this.isPremiumCard = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isPremiumCard
        ? const Color(0xFFFFD700)
        : Colors.white24;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: isPremiumCard ? 1.5 : 1.0,
        ),
        color: isPremiumCard
            ? const Color(0xFFFFD700).withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.08),
        boxShadow: isPremiumCard && isUnlocked && !isClaimed
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          if (isPremiumCard)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFFFD700),
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'PREMIUM',
                    style: TextStyle(
                      color: const Color(0xFFFFD700),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          Text(reward.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 4),
          Text(
            reward.label,
            textAlign: TextAlign.center,
            style: AppTheme.caption(context).copyWith(
              color: isUnlocked ? Colors.white : Colors.white38,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          if (isClaimed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Claimed',
                    style: TextStyle(color: Colors.green, fontSize: 11),
                  ),
                ],
              ),
            )
          else if (!isUnlocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: Colors.white24,
                size: 14,
              ),
            )
          else
            GestureDetector(
              onTap: canClaim ? onClaim : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: canClaim
                      ? (isPremiumCard
                            ? const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                              )
                            : AppTheme.primaryGradient)
                      : null,
                  color: canClaim ? null : Colors.white12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Claim',
                  style: TextStyle(
                    color: canClaim ? Colors.white : Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
