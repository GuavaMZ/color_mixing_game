import 'package:flutter_localization/flutter_localization.dart';
import '../../helpers/string_manager.dart';
import '../../core/color_science.dart';
import '../../../color_mixer_game.dart';
import '../../helpers/theme_constants.dart';
import '../../helpers/audio_manager.dart';
import '../../components/ui/enhanced_button.dart';
import '../../components/ui/animated_card.dart';
import 'package:flutter/material.dart';

class ChaosWinOverlay extends StatefulWidget {
  final ColorMixerGame game;
  const ChaosWinOverlay({super.key, required this.game});

  @override
  State<ChaosWinOverlay> createState() => _ChaosWinOverlayState();
}

class _ChaosWinOverlayState extends State<ChaosWinOverlay>
    with TickerProviderStateMixin {
  late AnimationController _controller;
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

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();
    _audio.playWin();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stability = widget.game.chaosStability;
    final rating = _getContainmentRating(context, stability);
    final ratingColor = _getRatingColor(stability);
    final wavelength = ColorScience.estimateWavelength(widget.game.targetColor);
    final bonus = (30 * stability).toInt();

    return Stack(
      children: [
        // Darkened background with slight orange/red tint
        Container(color: const Color(0xFF110800).withValues(alpha: 0.85)),

        Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: AnimatedCard(
                  onTap: () {},
                  hasGlow: true,
                  glowColor: AppTheme.electricYellow,
                  borderRadius: 24,
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Report Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.security_rounded,
                              color: AppTheme.electricYellow,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              AppStrings.containmentReport
                                  .getString(context)
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.electricYellow,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                        const Divider(
                          color: AppTheme.electricYellow,
                          thickness: 1,
                          height: 32,
                        ),

                        // Success Icon & Title
                        Text(
                          AppStrings.stabilized.getString(context),
                          style: AppTheme.heading2(context).copyWith(
                            color: Colors.white,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Containment Rating
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: ratingColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: ratingColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                AppStrings.containmentRating.getString(context),
                                style: TextStyle(
                                  color: ratingColor.withValues(alpha: 0.7),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                rating.toUpperCase(),
                                style: TextStyle(
                                  color: ratingColor,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 4,
                                  shadows: [
                                    Shadow(
                                      color: ratingColor.withValues(alpha: 0.5),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Technical Data
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Column(
                            children: [
                              _buildDataRow(
                                context,
                                "STABILITY RESERVE",
                                "${(stability * 100).toInt()}%",
                                stability > 0.6
                                    ? Colors.greenAccent
                                    : Colors.orangeAccent,
                              ),
                              const SizedBox(height: 12),
                              _buildDataRow(
                                context,
                                AppStrings.reactorFrequency.getString(context),
                                "${wavelength.toInt()} nm",
                                Colors.cyanAccent,
                              ),
                              const SizedBox(height: 12),
                              _buildDataRow(
                                context,
                                AppStrings.chaosBonus.getString(context),
                                "+$bonus lblCredits",
                                AppTheme.electricYellow,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: EnhancedButton(
                                label: AppStrings.menu.getString(context),
                                icon: Icons.home_rounded,
                                isOutlined: true,
                                onTap: () {
                                  _audio.playButton();
                                  widget.game.returnToMainMenu();
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: EnhancedButton(
                                label: AppStrings.reEngageReactor.getString(
                                  context,
                                ),
                                icon: Icons.bolt_rounded,
                                color: AppTheme.electricYellow,
                                textColor: Colors.black,
                                onTap: () {
                                  _audio.playButton();
                                  widget.game.startLevel();
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
          ),
        ),
      ],
    );
  }

  Widget _buildDataRow(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  String _getContainmentRating(BuildContext context, double stability) {
    if (stability >= 0.9) return AppStrings.flawless.getString(context);
    if (stability >= 0.5) return AppStrings.controlled.getString(context);
    return AppStrings.barelyContained.getString(context);
  }

  Color _getRatingColor(double stability) {
    if (stability >= 0.9) return Colors.cyanAccent;
    if (stability >= 0.5) return Colors.greenAccent;
    return Colors.orangeAccent;
  }
}
