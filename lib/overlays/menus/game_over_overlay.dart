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

class GameOverOverlay extends StatelessWidget {
  final ColorMixerGame game;
  const GameOverOverlay({super.key, required this.game});

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
                          game.isTimeUp
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
                        game.isTimeUp
                            ? AppStrings.timeUp.getString(context)
                            : AppStrings.outOfDrops.getString(context),
                        style: AppTheme.heading2(
                          context,
                        ).copyWith(color: Colors.white, fontSize: 36),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      game.isTimeUp
                          ? AppStrings.timeUpDesc.getString(context)
                          : AppStrings.outOfDropsDesc.getString(context),
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyMedium(
                        context,
                      ).copyWith(color: Colors.white.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: 32),

                    Row(
                      children: [
                        Expanded(
                          child: EnhancedButton(
                            label: AppStrings.retry.getString(context),
                            icon: Icons.replay_rounded,
                            onTap: () {
                              if (LivesManager().lives <= 0) {
                                NoLivesDialog.show(context);
                                return;
                              }
                              AudioManager().playButton();
                              game.resetGame();
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
                              AudioManager().playButton();
                              if (game.currentMode == GameMode.colorEcho) {
                                game.returnToMainMenu();
                              } else {
                                game.navigateToPage(
                                  'LevelMap',
                                  isReverse: true,
                                );
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
