import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../../helpers/string_manager.dart';
import '../../helpers/theme_constants.dart';
import '../../core/lives_manager.dart';
import '../../core/ad_manager.dart';
import '../../helpers/audio_manager.dart';
import '../../components/ui/enhanced_button.dart';

class NoLivesDialog extends StatelessWidget {
  const NoLivesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
          const SizedBox(height: 16),
          Text(
            AppStrings.watchAdDesc.getString(context),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.neonCyan, fontSize: 12),
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: LivesManager(),
            builder: (context, _) {
              final time = LivesManager().timeUntilNextLife;
              final displayTime = time == AppStrings.full
                  ? AppStrings.full.getString(context)
                  : time;
              return Text(
                "${AppStrings.nextLifeIn.getString(context)}$displayTime",
                style: const TextStyle(
                  color: AppTheme.electricYellow,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              );
            },
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
      actions: [
        Column(
          children: [
            EnhancedButton(
              label: AppStrings.watchAdButton.getString(context),
              icon: Icons.play_circle_fill_rounded,
              onTap: () {
                AudioManager().playButton();
                AdManager().showRewardedAd(
                  onUserEarnedReward: (ad, reward) {
                    LivesManager().addLives(1);
                    Navigator.pop(context);
                  },
                  onAdFailed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Ad not ready yet. Please try again later.",
                        ),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                AppStrings.ok.getString(context),
                style: const TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static void show(BuildContext context) {
    showDialog(context: context, builder: (context) => const NoLivesDialog());
  }
}
