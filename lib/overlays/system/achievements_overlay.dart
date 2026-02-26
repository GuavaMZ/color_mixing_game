import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../../../color_mixer_game.dart';
import '../../helpers/string_manager.dart';
import '../../helpers/theme_constants.dart';
import '../../helpers/audio_manager.dart';
import '../../helpers/visual_effects.dart'; // StarField
import '../../components/ui/responsive_components.dart'; // ResponsiveIconButton
import '../../components/ui/animated_card.dart'; // AnimatedCard

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

class AchievementsOverlay extends StatefulWidget {
  final ColorMixerGame game;

  static const List<AchievementData> allAchievements = [
    AchievementData(
      id: 'mad_chemist',
      title: AppStrings.achievement1Title,
      description: AppStrings.achievement1Desc,
      icon: Icons.science_rounded,
    ),
    AchievementData(
      id: 'speed_runner',
      title: AppStrings.achievement2Title,
      description: AppStrings.achievement2Desc,
      icon: Icons.bolt_rounded,
      color: Colors.cyanAccent,
    ),
    AchievementData(
      id: 'star_collector',
      title: AppStrings.achievement3Title,
      description: AppStrings.achievement3Desc,
      icon: Icons.auto_awesome_rounded,
      color: Colors.amber,
    ),
    AchievementData(
      id: 'perfectionist',
      title: AppStrings.achievement4Title,
      description: AppStrings.achievement4Desc,
      icon: Icons.emoji_events_rounded,
      color: Colors.orangeAccent,
    ),
    AchievementData(
      id: 'veteran',
      title: AppStrings.achievement5Title,
      description: AppStrings.achievement5Desc,
      icon: Icons.military_tech_rounded,
      color: Colors.purpleAccent,
    ),
    AchievementData(
      id: 'combo_king',
      title: AppStrings.achievement6Title,
      description: AppStrings.achievement6Desc,
      icon: Icons.workspace_premium_rounded,
      color: Colors.orange,
    ),
    AchievementData(
      id: 'lab_survivor',
      title: AppStrings.achievement7Title,
      description: AppStrings.achievement7Desc,
      icon: Icons.science_rounded,
      color: Colors.lightGreenAccent,
    ),
    AchievementData(
      id: 'spectral_sync',
      title: AppStrings.achievement8Title,
      description: AppStrings.achievement8Desc,
      icon: Icons.sync_rounded,
      color: Colors.blueAccent,
    ),
    AchievementData(
      id: 'master_chemist',
      title: AppStrings.achievement9Title,
      description: AppStrings.achievement9Desc,
      icon: Icons.auto_awesome_rounded,
      color: Colors.yellowAccent,
    ),
    AchievementData(
      id: 'blind_master',
      title: AppStrings.achievement10Title,
      description: AppStrings.achievement10Desc,
      icon: Icons.visibility_off_rounded,
      color: Colors.grey,
    ),
    AchievementData(
      id: 'shopaholic',
      title: AppStrings.achievement11Title,
      description: AppStrings.achievement11Desc,
      icon: Icons.shopping_bag_rounded,
      color: Colors.pinkAccent,
    ),
    AchievementData(
      id: 'stability_expert',
      title: AppStrings.achievement12Title,
      description: AppStrings.achievement12Desc,
      icon: Icons.vertical_align_center_rounded,
      color: Colors.tealAccent,
    ),
  ];

  const AchievementsOverlay({super.key, required this.game});

  @override
  State<AchievementsOverlay> createState() => _AchievementsOverlayState();
}

class _AchievementsOverlayState extends State<AchievementsOverlay> {
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

          // StarField
          const Positioned.fill(
            child: StarField(starCount: 50, color: Colors.white),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    itemCount: AchievementsOverlay.allAchievements.length,
                    itemBuilder: (context, index) {
                      final achievement =
                          AchievementsOverlay.allAchievements[index];
                      final isUnlocked = widget.game.unlockedAchievements
                          .contains(achievement.id);
                      return _AchievementCard(
                        achievement: achievement,
                        isUnlocked: isUnlocked,
                        delay: index * 40, // Slightly faster staggered delay
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
    final int unlockedCount = widget.game.unlockedAchievements.length;
    final int totalCount = AchievementsOverlay.allAchievements.length;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Row(
            children: [
              ResponsiveIconButton(
                onPressed: () {
                  AudioManager().playButton();
                  widget.game.overlays.remove('Achievements');
                },
                icon: Icons.arrow_back_rounded,
                color: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Hero(
                  tag: 'achievements_title',
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: AppTheme.cosmicCard(
                      borderRadius: 20,
                      fillColor: AppTheme.primaryDark.withValues(alpha: 0.6),
                      borderColor: AppTheme.neonCyan.withValues(alpha: 0.3),
                    ),
                    child: Center(
                      child: Text(
                        AppStrings.achievementsTitle
                            .getString(context)
                            .toUpperCase(),
                        style: AppTheme.heading3(context).copyWith(
                          color: AppTheme.neonCyan,
                          letterSpacing: 3.0,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: AppTheme.cosmicGlass(
              borderRadius: 16,
              borderColor: AppTheme.neonCyan.withValues(alpha: 0.1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: unlockedCount / totalCount,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.neonCyan.withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '$unlockedCount / $totalCount',
                  style: AppTheme.buttonText(
                    context,
                    isLarge: true,
                  ).copyWith(color: AppTheme.neonCyan, letterSpacing: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatefulWidget {
  final AchievementData achievement;
  final bool isUnlocked;
  final int delay;

  const _AchievementCard({
    required this.achievement,
    required this.isUnlocked,
    required this.delay,
  });

  @override
  State<_AchievementCard> createState() => _AchievementCardState();
}

class _AchievementCardState extends State<_AchievementCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 50,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(opacity: _fadeAnimation.value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: AnimatedCard(
          onTap: () {
            if (widget.isUnlocked) {
              AudioManager().playButton();
            }
          },
          fillColor: widget.isUnlocked
              ? widget.achievement.color.withValues(alpha: 0.1)
              : AppTheme.primaryDark.withValues(alpha: 0.4),
          borderColor: widget.isUnlocked
              ? widget.achievement.color.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.05),
          hasGlow: widget.isUnlocked,
          glowColor: widget.achievement.color,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Icon Badge
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Glow for unlocked
                    if (widget.isUnlocked)
                      _BadgeGlow(color: widget.achievement.color),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.isUnlocked
                            ? widget.achievement.color.withValues(alpha: 0.15)
                            : Colors.black.withValues(alpha: 0.4),
                        border: Border.all(
                          color: widget.isUnlocked
                              ? widget.achievement.color
                              : Colors.white12,
                          width: 2.5,
                        ),
                        boxShadow: widget.isUnlocked
                            ? [
                                BoxShadow(
                                  color: widget.achievement.color.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 15,
                                  spreadRadius: 1,
                                ),
                              ]
                            : [],
                      ),
                      child: Icon(
                        widget.isUnlocked
                            ? widget.achievement.icon
                            : Icons.lock_rounded,
                        color: widget.isUnlocked
                            ? Colors.white
                            : Colors.white24,
                        size: 30,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.achievement.title.getString(context),
                        style: AppTheme.buttonText(context, isLarge: true)
                            .copyWith(
                              color: widget.isUnlocked
                                  ? Colors.white
                                  : Colors.white38,
                              fontSize: 18,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.achievement.description.getString(context),
                        style: TextStyle(
                          color: widget.isUnlocked
                              ? Colors.white70
                              : Colors.white24,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.isUnlocked)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.greenAccent,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgeGlow extends StatefulWidget {
  final Color color;
  const _BadgeGlow({required this.color});

  @override
  State<_BadgeGlow> createState() => _BadgeGlowState();
}

class _BadgeGlowState extends State<_BadgeGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                widget.color.withValues(alpha: 0.4),
                widget.color.withValues(alpha: 0.0),
              ],
            ),
          ),
          child: Transform.rotate(
            angle: _controller.value * 2 * math.pi,
            child: child,
          ),
        );
      },
      child: Stack(
        children: List.generate(4, (index) {
          final angle = (index * math.pi / 2);
          return Positioned(
            left: 30 + 25 * math.cos(angle) - 2,
            top: 30 + 25 * math.sin(angle) - 2,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
              ),
            ),
          );
        }),
      ),
    );
  }
}
