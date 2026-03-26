import 'package:color_mixing_deductive/helpers/audio_manager.dart';
import 'package:color_mixing_deductive/helpers/string_manager.dart';
import 'package:color_mixing_deductive/helpers/theme_constants.dart';
import 'package:color_mixing_deductive/helpers/visual_effects.dart'; // StarField
import 'package:color_mixing_deductive/components/ui/animated_card.dart';
import 'package:color_mixing_deductive/components/ui/enhanced_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../../../color_mixer_game.dart';
import '../../core/lives_manager.dart';
import '../../overlays/system/no_lives_dialog.dart';

import '../../core/ad_manager.dart';

class GameOverOverlay extends StatefulWidget {
  final ColorMixerGame game;
  const GameOverOverlay({super.key, required this.game});

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay> {
  bool _reviveUsed = false;
  bool _isAdLoading = false;

  void _watchAdToRevive() {
    if (_isAdLoading) return;
    setState(() => _isAdLoading = true);

    AdManager().showRewardedAd(
      onUserEarnedReward: (ad, reward) {
        if (mounted) {
          setState(() {
            _reviveUsed = true;
            _isAdLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.reviveSuccess.getString(context)),
              backgroundColor: Colors.green,
            ),
          );
          // Reward logic
          widget.game.reviveWithDrops(15);
        }
      },
      onAdFailed: () {
        if (mounted && _isAdLoading) {
          setState(() => _isAdLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.adNotReady.getString(context)),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      },
    );

    // Stop spinner if ad failed to load (async fail silently handled inside AdManager for now,
    // but we can just timeout the spinner as a fail-safe or let user try again)
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _isAdLoading) {
        setState(() => _isAdLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.adNotReady.getString(context)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background
          Positioned.fill(child: Container(color: Colors.black)),
          const StarField(starCount: 50, color: Colors.white),

          Center(
            child: AnimatedCard(
              onTap: () {}, // For glow effect
              hasGlow: true,
              borderRadius: 32,
              fillColor: AppTheme.primaryDark.withValues(alpha: 0.9),
              padding: const EdgeInsets.all(32),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Enhanced icon with glow
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.neonMagenta.withValues(alpha: 0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.neonMagenta.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.game.isTimeUp
                              ? Icons.timer_off_outlined
                              : Icons.opacity_rounded,
                          color: AppTheme.neonMagenta,
                          size: 64,
                          shadows: [
                            Shadow(
                              color: AppTheme.neonMagenta.withValues(
                                alpha: 0.8,
                              ),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ShimmerEffect(
                      baseColor: Colors.white,
                      highlightColor: AppTheme.neonMagenta,
                      child: Text(
                        widget.game.isTimeUp
                            ? AppStrings.timeUp.getString(context)
                            : AppStrings.outOfDrops.getString(context),
                        style: AppTheme.heading2(
                          context,
                        ).copyWith(color: Colors.white, fontSize: 36),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.game.isTimeUp
                          ? AppStrings.timeUpDesc.getString(context)
                          : AppStrings.outOfDropsDesc.getString(context),
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyMedium(
                        context,
                      ).copyWith(color: Colors.white.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: 32),

                    // ── Phase 2: Rewarded Ad Revive ──────────────────────
                    if (!_reviveUsed &&
                        widget.game.currentMode == GameMode.classic) ...[
                      SizedBox(
                        width: double.infinity,
                        child: EnhancedButton(
                          label: _isAdLoading
                              ? '...'
                              : AppStrings.watchAdRevive.getString(context),
                          icon: Icons.personal_video_rounded,
                          color: Colors.amber,
                          onTap: _watchAdToRevive,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ──────────────────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: EnhancedButton(
                            label: AppStrings.retry.getString(context),
                            icon: Icons.replay_rounded,
                            onTap: () {
                              void proceedReset() {
                                if (LivesManager().lives <= 0) {
                                  NoLivesDialog.show(context);
                                  return;
                                }
                                AudioManager().playButton();
                                widget.game.resetGame();
                              }

                              if (AdManager().shouldShowInterstitial()) {
                                AdManager().showInterstitialAd(
                                  onAdDismissed: proceedReset,
                                );
                              } else {
                                proceedReset();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: EnhancedButton(
                            label: AppStrings.levelMapText.getString(context),
                            icon: Icons.map_rounded,
                            isOutlined: true,
                            onTap: () {
                              void proceedNav() {
                                AudioManager().playButton();
                                if (widget.game.currentMode ==
                                    GameMode.colorEcho) {
                                  widget.game.returnToMainMenu();
                                } else {
                                  widget.game.navigateToPage(
                                    'LevelMap',
                                    isReverse: true,
                                  );
                                }
                              }

                              if (AdManager().shouldShowInterstitial()) {
                                AdManager().showInterstitialAd(
                                  onAdDismissed: proceedNav,
                                );
                              } else {
                                proceedNav();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
