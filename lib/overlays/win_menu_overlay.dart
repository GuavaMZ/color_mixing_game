import 'dart:ui';
import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:color_mixing_deductive/helpers/string_manager.dart';
import 'package:color_mixing_deductive/helpers/theme_constants.dart';
import 'package:color_mixing_deductive/helpers/audio_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

class WinMenuOverlay extends StatefulWidget {
  final ColorMixerGame game;
  const WinMenuOverlay({super.key, required this.game});

  @override
  State<WinMenuOverlay> createState() => _WinMenuOverlayState();
}

class _WinMenuOverlayState extends State<WinMenuOverlay>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _starsController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  final AudioManager _audio = AudioManager();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _starsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    // Delay star animation
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _starsController.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _starsController.dispose();
    super.dispose();
  }

  String _getResultMessage(int stars, BuildContext context) {
    if (stars == 3) return AppStrings.perfectScore.getString(context);
    if (stars == 2) return AppStrings.greatJob.getString(context);
    return AppStrings.goodWork.getString(context);
  }

  @override
  Widget build(BuildContext context) {
    final stars = widget.game.calculateStars();
    final drops = widget.game.totalDrops.value;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.spacing(context, 24),
              ),
              padding: EdgeInsets.all(ResponsiveHelper.spacing(context, 24)),
              decoration: AppTheme.cartoonDecoration(
                borderRadius: 35,
                fillColor: AppTheme.cardColor,
                borderWidth: 4,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Trophy icon with glow
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.amber.withOpacity(0.4),
                          Colors.amber.withOpacity(0.1),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 800),
                      tween: Tween(begin: 0.5, end: 1.0),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Icon(
                            Icons.emoji_events_rounded,
                            color: Colors.amber,
                            size: ResponsiveHelper.iconSize(context, 80),
                            shadows: [
                              Shadow(
                                color: Colors.amber.withOpacity(0.6),
                                blurRadius: 25,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  SizedBox(height: ResponsiveHelper.spacing(context, 16)),

                  // Win text
                  Text(
                    AppStrings.wonText.getString(context),
                    style: AppTheme.heading1(context).copyWith(
                      fontSize: ResponsiveHelper.fontSize(context, 48),
                    ),
                  ),

                  SizedBox(height: ResponsiveHelper.spacing(context, 20)),

                  // Animated Stars
                  AnimatedBuilder(
                    animation: _starsController,
                    builder: (context, child) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (index) {
                          final delay = index * 0.2;
                          final progress =
                              ((_starsController.value - delay) / 0.4).clamp(
                                0.0,
                                1.0,
                              );
                          final isEarned = index < stars;

                          return TweenAnimationBuilder<double>(
                            duration: Duration.zero,
                            tween: Tween(begin: 0, end: progress),
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: isEarned
                                    ? Curves.elasticOut.transform(value)
                                    : 0.8,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  child: Icon(
                                    isEarned
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    color: isEarned
                                        ? Colors.amber
                                        : Colors.white.withOpacity(0.3),
                                    size: ResponsiveHelper.iconSize(
                                      context,
                                      50,
                                    ),
                                    shadows: isEarned
                                        ? [
                                            Shadow(
                                              color: Colors.amber.withOpacity(
                                                0.6,
                                              ),
                                              blurRadius: 15,
                                            ),
                                          ]
                                        : [],
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                      );
                    },
                  ),

                  SizedBox(height: ResponsiveHelper.spacing(context, 12)),

                  // Result message
                  Text(
                    _getResultMessage(stars, context),
                    style: AppTheme.bodyLarge(
                      context,
                    ).copyWith(color: Colors.white.withOpacity(0.9)),
                  ),

                  SizedBox(height: ResponsiveHelper.spacing(context, 16)),

                  // Stats container
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    decoration: AppTheme.cartoonDecoration(
                      borderRadius: 16,
                      fillColor: Colors.white.withOpacity(0.1),
                      borderWidth: 3,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.water_drop_rounded,
                          color: Colors.cyan.shade200,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "${AppStrings.dropsUsed.getString(context)}: $drops",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: ResponsiveHelper.fontSize(context, 16),
                            decoration: TextDecoration.none,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: ResponsiveHelper.spacing(context, 28)),

                  // Action buttons
                  Row(
                    children: [
                      // Replay button
                      Expanded(
                        flex: 2,
                        child: _ActionButton(
                          label: AppStrings.replayLevel.getString(context),
                          icon: Icons.replay_rounded,
                          isOutlined: true,
                          onTap: () {
                            _audio.playButton();
                            widget.game.resetGame();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Next level button
                      Expanded(
                        flex: 2,
                        child: _ActionButton(
                          label: AppStrings.newLevel.getString(context),
                          icon: Icons.arrow_forward_rounded,
                          onTap: () {
                            _audio.playButton();
                            widget.game.goToNextLevel();
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
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isOutlined;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cartoonDecoration(
        borderRadius: 16,
        fillColor: isOutlined
            ? Colors.white.withOpacity(0.1)
            : AppTheme.primaryColor,
        borderWidth: 3,
        borderColor: Colors.white,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.spacing(context, 16),
              vertical: ResponsiveHelper.spacing(context, 14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.fontSize(context, 15),
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
