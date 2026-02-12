import 'package:color_mixing_deductive/helpers/audio_manager.dart';
import 'package:color_mixing_deductive/helpers/string_manager.dart';
import 'package:color_mixing_deductive/helpers/theme_constants.dart';
import 'package:color_mixing_deductive/helpers/visual_effects.dart'; // StarField
import 'package:color_mixing_deductive/components/ui/animated_card.dart'; // AnimatedCard
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../../../color_mixer_game.dart';
import '../../core/lives_manager.dart';

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
          Container(color: Colors.black.withValues(alpha: 0.8)),
          const StarField(starCount: 50, color: Colors.white),

          Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: AppTheme.cosmicCard(
                borderRadius: 32,
                fillColor: AppTheme.primaryDark.withValues(alpha: 0.9),
                borderColor: AppTheme.neonCyan,
                hasGlow: true,
              ),
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
                            color: AppTheme.neonMagenta.withValues(alpha: 0.8),
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
                        child: _buildActionButton(
                          context,
                          label: AppStrings.retry.getString(context),
                          icon: Icons.replay_rounded,
                          color: AppTheme.primaryColor,
                          onTap: () {
                            if (LivesManager().lives <= 0) {
                              _showNoLivesDialog(context);
                              return;
                            }
                            AudioManager().playButton();
                            game.resetGame();
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionButton(
                          context,
                          label: AppStrings.levelMapText.getString(context),
                          icon: Icons.map_rounded,
                          color: AppTheme.secondaryColor,
                          onTap: () {
                            AudioManager().playButton();
                            game.overlays.remove('GameOver');
                            if (game.currentMode == GameMode.colorEcho) {
                              game.returnToMainMenu();
                            } else {
                              game.overlays.add('LevelMap');
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
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedCard(
      onTap: onTap,
      fillColor: color.withValues(alpha: 0.2),
      borderColor: color,
      borderWidth: 1.5,
      hasGlow: true,
      glowColor: color,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 22,
              shadows: [
                Shadow(color: color.withValues(alpha: 0.6), blurRadius: 8),
              ],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTheme.buttonText(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNoLivesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.primaryDark.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppTheme.neonMagenta, width: 2),
        ),
        title: Text(
          AppStrings.outOfLives.getString(context),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.favorite_rounded,
              color: AppTheme.neonMagenta,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.noLivesDesc.getString(context),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            AnimatedBuilder(
              animation: LivesManager(),
              builder: (context, _) => Text(
                "${AppStrings.nextLifeIn.getString(context)}${LivesManager().timeUntilNextLife}",
                style: const TextStyle(
                  color: AppTheme.neonCyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppStrings.ok.getString(context),
              style: const TextStyle(
                color: AppTheme.neonCyan,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
