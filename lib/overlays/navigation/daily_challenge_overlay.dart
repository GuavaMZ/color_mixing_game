import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:color_mixing_deductive/helpers/audio_manager.dart';
import 'package:color_mixing_deductive/helpers/daily_challenge_manager.dart';
import 'package:color_mixing_deductive/helpers/string_manager.dart';
import 'package:color_mixing_deductive/helpers/theme_constants.dart';
import 'package:color_mixing_deductive/helpers/visual_effects.dart';
import 'package:color_mixing_deductive/components/ui/responsive_components.dart';
import 'package:color_mixing_deductive/components/ui/animated_card.dart';
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
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.cosmicBackground,
            ),
          ),
          // StarField for depth
          const Positioned.fill(
            child: StarField(starCount: 40, color: Colors.white),
          ),
          // Background Blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.black.withValues(alpha: 0.2)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),

                // Content
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
                          final isCompleted = completedSnapshot.data ?? false;

                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                // Streak display
                                FutureBuilder<int>(
                                  future: DailyChallengeManager.getStreak(),
                                  builder: (context, streakSnapshot) {
                                    final streak = streakSnapshot.data ?? 0;
                                    return AnimatedCard(
                                      padding: const EdgeInsets.all(20),
                                      fillColor: Colors.orange.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderColor: Colors.orange.withValues(
                                        alpha: 0.4,
                                      ),
                                      hasGlow: streak > 0,
                                      glowColor: Colors.orange,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          _PulseFireIcon(),
                                          const SizedBox(width: 16),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '$streak ${AppStrings.dayStreak.getString(context)}',
                                                style:
                                                    AppTheme.heading2(
                                                      context,
                                                    ).copyWith(
                                                      color: Colors.white,
                                                      fontSize: 26,
                                                    ),
                                              ),
                                              Text(
                                                AppStrings.keepItGoing
                                                    .getString(context),
                                                style:
                                                    AppTheme.bodySmall(
                                                      context,
                                                    ).copyWith(
                                                      color: Colors.orange
                                                          .withValues(
                                                            alpha: 0.8,
                                                          ),
                                                      letterSpacing: 1.2,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),

                                const SizedBox(height: 30),

                                // Challenge card
                                AnimatedCard(
                                  padding: const EdgeInsets.all(24),
                                  fillColor: AppTheme.neonCyan.withValues(
                                    alpha: 0.05,
                                  ),
                                  borderColor: AppTheme.neonCyan.withValues(
                                    alpha: 0.4,
                                  ),
                                  hasGlow: true,
                                  child: Column(
                                    children: [
                                      Stack(
                                        alignment: Alignment.topCenter,
                                        clipBehavior: Clip.none,
                                        children: [
                                          const Icon(
                                            Icons.emoji_events_rounded,
                                            color: AppTheme.neonCyan,
                                            size: 70,
                                            shadows: [
                                              Shadow(
                                                color: AppTheme.neonCyan,
                                                blurRadius: 20,
                                              ),
                                            ],
                                          ),
                                          Positioned(
                                            top: -8,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 1,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.neonCyan,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Text(
                                                'MISSION',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 1.5,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        AppStrings.todaysChallenge.getString(
                                          context,
                                        ),
                                        style: AppTheme.caption(context)
                                            .copyWith(
                                              fontSize: 13,
                                              color: AppTheme.neonCyan
                                                  .withValues(alpha: 0.7),
                                            ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        challenge.description,
                                        textAlign: TextAlign.center,
                                        style: AppTheme.heading3(
                                          context,
                                        ).copyWith(fontSize: 22, height: 1.3),
                                      ),
                                      const SizedBox(height: 28),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                        const SizedBox(height: 24),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withValues(
                                              alpha: 0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.green,
                                              width: 2,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.check_circle,
                                                color: Colors.green,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                AppStrings.completedStatus
                                                    .getString(context),
                                                style: const TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 30),

                                // Instructions
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(24),
                                  decoration: AppTheme.cosmicGlass(
                                    borderRadius: 24,
                                    borderColor: Colors.white.withValues(
                                      alpha: 0.1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppStrings.howItWorks.getString(
                                          context,
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        '• ${AppStrings.inst1.getString(context)}\n'
                                        '• ${AppStrings.inst2.getString(context)}\n'
                                        '• ${AppStrings.inst3.getString(context)}\n'
                                        '• ${AppStrings.inst4.getString(context)}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                          height: 1.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              ResponsiveIconButton(
                icon: Icons.arrow_back_rounded,
                onPressed: () {
                  AudioManager().playButton();
                  game.overlays.remove('DailyChallenge');
                },
                color: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  AppStrings.dailyChallengeTitle
                      .getString(context)
                      .toUpperCase(),
                  style: AppTheme.heading3(context).copyWith(
                    letterSpacing: 3,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: AppTheme.neonCyan.withValues(alpha: 0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 1.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.neonCyan.withValues(alpha: 0.0),
                  AppTheme.neonCyan.withValues(alpha: 0.5),
                  AppTheme.neonCyan.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseFireIcon extends StatefulWidget {
  @override
  State<_PulseFireIcon> createState() => _PulseFireIconState();
}

class _PulseFireIconState extends State<_PulseFireIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
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
        return Transform.scale(
          scale: 1.0 + (_controller.value * 0.15),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.orange.withValues(alpha: 0.1),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(
                    alpha: 0.3 * _controller.value,
                  ),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Colors.orange,
              size: 42,
            ),
          ),
        );
      },
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
