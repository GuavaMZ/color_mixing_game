import 'package:color_mixing_deductive/core/achievement_engine.dart';
import 'package:color_mixing_deductive/helpers/string_manager.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:color_mixing_deductive/helpers/theme_constants.dart';
import 'package:flutter/material.dart';

/// Achievement notification banner that slides in from the top.
///
/// Supports three [AchievementTier] styles (Bronze / Silver / Gold)
/// so the badge color communicates rarity at a glance.
class AchievementNotification extends StatefulWidget {
  final VoidCallback onDismiss;
  final String title;
  final String subtitle;
  final IconData icon;
  final AchievementTier tier;

  const AchievementNotification({
    super.key,
    required this.onDismiss,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.tier = AchievementTier.gold,
  });

  @override
  State<AchievementNotification> createState() =>
      _AchievementNotificationState();
}

class _AchievementNotificationState extends State<AchievementNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: const Offset(0, 0.2),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Badge gradient per tier
  List<Color> get _badgeColors => switch (widget.tier) {
    AchievementTier.bronze => [
      const Color(0xFFCD7F32),
      const Color(0xFF8B4513),
    ],
    AchievementTier.silver => [
      const Color(0xFFC0C0C0),
      const Color(0xFF808080),
    ],
    AchievementTier.gold => [const Color(0xFFFFD700), const Color(0xFFB8860B)],
  };

  Color get _glowColor => switch (widget.tier) {
    AchievementTier.bronze => const Color(0xFFCD7F32),
    AchievementTier.silver => const Color(0xFFC0C0C0),
    AchievementTier.gold => Colors.amber,
  };

  Color get _borderColor => switch (widget.tier) {
    AchievementTier.bronze => const Color(0xFFCD7F32),
    AchievementTier.silver => const Color(0xFFC0C0C0),
    AchievementTier.gold => AppTheme.electricYellow,
  };

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: AppTheme.cosmicCard(
              borderRadius: 16,
              fillColor: AppTheme.primaryDark,
              borderColor: _borderColor,
              hasGlow: true,
              glowColor: _glowColor,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tier Badge Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _badgeColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _glowColor.withValues(alpha: 0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(widget.icon, color: Colors.black, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            AppStrings.achievementUnlockedTitle.getString(
                              context,
                            ),
                            style: TextStyle(
                              color: _borderColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _glowColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.tier.labelKey(context).toUpperCase(),
                              style: TextStyle(
                                color: _glowColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
