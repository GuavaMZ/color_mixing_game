import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:color_mixing_deductive/helpers/audio_manager.dart';
import 'package:color_mixing_deductive/helpers/daily_challenge_manager.dart';
import 'package:color_mixing_deductive/helpers/string_manager.dart';
import 'package:color_mixing_deductive/helpers/theme_constants.dart';
import 'package:color_mixing_deductive/components/ui/animated_card.dart';
import 'package:color_mixing_deductive/components/ui/enhanced_button.dart';
import '../../../color_mixer_game.dart';

class DailyChallengeOverlay extends StatelessWidget {
  final ColorMixerGame game;
  const DailyChallengeOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Backdrop with Blur (Mode Guide Style)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black),
            ),
          ),

          // Content Container
          Center(
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.spacing(context, 24),
                vertical: ResponsiveHelper.spacing(context, 40),
              ),
              constraints: BoxConstraints(
                maxWidth: 600,
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: AnimatedCard(
                onTap: () {}, // For glow
                hasGlow: true,
                borderRadius: 32,
                fillColor: AppTheme.primaryDark.withValues(alpha: 0.9),
                borderColor: AppTheme.neonCyan,
                padding: EdgeInsets.all(ResponsiveHelper.spacing(context, 24)),
                child: Column(
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 24),
                    Expanded(
                      child: FutureBuilder<DailyChallenge>(
                        future: DailyChallengeManager.getTodaysChallenge(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.neonCyan,
                              ),
                            );
                          }

                          final challenge = snapshot.data!;

                          return FutureBuilder<bool>(
                            future: DailyChallengeManager.isTodayCompleted(),
                            builder: (context, completedSnapshot) {
                              final isCompleted =
                                  completedSnapshot.data ?? false;

                              return SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Column(
                                  children: [
                                    // Streak Section
                                    _buildStreakSection(context),
                                    const SizedBox(height: 16),

                                    // Challenge Card Section
                                    _buildChallengeSection(
                                      context,
                                      challenge,
                                      isCompleted,
                                    ),
                                    const SizedBox(height: 16),

                                    // Instructions Section
                                    _buildInstructionsSection(context),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Footer
                    SizedBox(
                      width: double.infinity,
                      child: EnhancedButton(
                        label: AppStrings.gotIt.getString(context),
                        onTap: () {
                          AudioManager().playButton();
                          game.overlays.remove('DailyChallenge');
                        },
                      ),
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

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppStrings.dailyChallengeTitle.getString(context),
          style: AppTheme.heading2(context),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white70),
          onPressed: () {
            AudioManager().playButton();
            game.overlays.remove('DailyChallenge');
          },
        ),
      ],
    );
  }

  Widget _buildStreakSection(BuildContext context) {
    return FutureBuilder<int>(
      future: DailyChallengeManager.getStreak(),
      builder: (context, streakSnapshot) {
        final streak = streakSnapshot.data ?? 0;
        final color = streak > 0 ? Colors.orange : Colors.grey;

        return _buildGuideStyledContainer(
          icon: Icons.local_fire_department_rounded,
          color: color,
          title: '$streak ${AppStrings.dayStreak.getString(context)}',
          subtitle: AppStrings.keepItGoing.getString(context),
          context: context,
        );
      },
    );
  }

  Widget _buildChallengeSection(
    BuildContext context,
    DailyChallenge challenge,
    bool isCompleted,
  ) {
    return _buildGuideStyledContainer(
      icon: Icons.emoji_events_rounded,
      color: AppTheme.electricYellow,
      title: AppStrings.todaysChallenge.getString(context),
      subtitle: challenge.description,
      context: context,
      customContent: Column(
        children: [
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _GlowingCoinIcon(),
              const SizedBox(width: 10),
              Text(
                '${challenge.reward} ${AppStrings.rewardText.getString(context)}',
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (isCompleted) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: AppTheme.success),
                const SizedBox(width: 8),
                Text(
                  AppStrings.completedStatus.getString(context),
                  style: const TextStyle(
                    color: AppTheme.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInstructionsSection(BuildContext context) {
    return _buildGuideStyledContainer(
      icon: Icons.info_outline_rounded,
      color: AppTheme.neonCyan,
      title: AppStrings.howItWorks.getString(context),
      subtitle:
          '${AppStrings.inst1.getString(context)}\n'
          '${AppStrings.inst2.getString(context)}\n'
          '${AppStrings.inst3.getString(context)}\n'
          '${AppStrings.inst4.getString(context)}',
      context: context,
    );
  }

  Widget _buildGuideStyledContainer({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required BuildContext context,
    Widget? customContent,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.bodyLarge(context).copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: AppTheme.bodyMedium(context).copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (customContent != null) customContent,
        ],
      ),
    );
  }
}

class _GlowingCoinIcon extends StatefulWidget {
  @override
  State<_GlowingCoinIcon> createState() => _GlowingCoinIconState();
}

class _GlowingCoinIconState extends State<_GlowingCoinIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
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
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.3),
                blurRadius: 10 + (math.sin(_controller.value * math.pi) * 10),
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.monetization_on_rounded,
            color: Colors.amber,
            size: 28,
            shadows: [Shadow(color: Colors.amber, blurRadius: 10)],
          ),
        );
      },
    );
  }
}
