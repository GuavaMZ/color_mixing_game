import 'dart:ui';
import 'package:flutter/material.dart';
import '../color_mixer_game.dart';
import '../helpers/theme_constants.dart';
import '../helpers/audio_manager.dart';

class AchievementData {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const AchievementData({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.color = AppTheme.neonCyan,
  });
}

class AchievementsOverlay extends StatelessWidget {
  final ColorMixerGame game;

  static const List<AchievementData> allAchievements = [
    AchievementData(
      id: 'mad_chemist',
      title: "Mad Chemist",
      description: "First successful mixture!",
      icon: Icons.science_rounded,
    ),
    AchievementData(
      id: 'speed_runner',
      title: "Speed Runner",
      description: "Complete a level in under 5 seconds.",
      icon: Icons.bolt_rounded,
      color: Colors.cyanAccent,
    ),
    AchievementData(
      id: 'star_collector',
      title: "Star Collector",
      description: "Collect 50 stars in total.",
      icon: Icons.auto_awesome_rounded,
      color: Colors.amber,
    ),
    AchievementData(
      id: 'perfectionist',
      title: "Perfectionist",
      description: "Get 3 stars on any level.",
      icon: Icons.emoji_events_rounded,
      color: Colors.orangeAccent,
    ),
    AchievementData(
      id: 'veteran',
      title: "Veteran",
      description: "Complete 10 levels in the game.",
      icon: Icons.military_tech_rounded,
      color: Colors.purpleAccent,
    ),
  ];

  const AchievementsOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Blur Background
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.primaryDark.withValues(alpha: 0.8),
                      AppTheme.primaryMedium.withValues(alpha: 0.9),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    itemCount: allAchievements.length,
                    itemBuilder: (context, index) {
                      final achievement = allAchievements[index];
                      final isUnlocked = game.unlockedAchievements.contains(
                        achievement.id,
                      );
                      return _buildAchievementCard(
                        context,
                        achievement,
                        isUnlocked,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          _buildIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () {
              AudioManager().playButton();
              game.overlays.remove('Achievements');
            },
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: AppTheme.cosmicCard(
                borderRadius: 16,
                fillColor: AppTheme.primaryDark.withValues(alpha: 0.7),
                borderColor: AppTheme.neonCyan.withValues(alpha: 0.3),
                hasGlow: true,
              ),
              child: const Text(
                "ACHIEVEMENTS",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.neonCyan,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(
    BuildContext context,
    AchievementData achievement,
    bool isUnlocked,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.cosmicCard(
        borderRadius: 20,
        fillColor: isUnlocked
            ? AppTheme.primaryDark.withValues(alpha: 0.8)
            : AppTheme.primaryDark.withValues(alpha: 0.6),
        borderColor: isUnlocked
            ? achievement.color.withValues(alpha: 0.7)
            : Colors.white.withValues(alpha: 0.08),
        hasGlow: isUnlocked,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Icon Badge
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnlocked
                    ? achievement.color.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.3),
                border: Border.all(
                  color: isUnlocked
                      ? achievement.color.withValues(alpha: 0.8)
                      : Colors.white24,
                  width: 2,
                ),
                boxShadow: isUnlocked
                    ? [
                        BoxShadow(
                          color: achievement.color.withValues(alpha: 0.3),
                          blurRadius: 12,
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                isUnlocked ? achievement.icon : Icons.lock_outline_rounded,
                color: isUnlocked ? achievement.color : Colors.white38,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.title,
                    style: AppTheme.buttonText(context, isLarge: true).copyWith(
                      color: isUnlocked ? Colors.white : Colors.white38,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement.description,
                    style: TextStyle(
                      color: isUnlocked ? Colors.white70 : Colors.white24,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isUnlocked)
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.greenAccent,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: AppTheme.cosmicGlass(
        borderRadius: 15,
        borderColor: Colors.white.withValues(alpha: 0.1),
        isInteractive: true,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}
