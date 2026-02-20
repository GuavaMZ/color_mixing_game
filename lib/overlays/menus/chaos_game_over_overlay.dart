import 'package:flutter_localization/flutter_localization.dart';
import '../../helpers/string_manager.dart';
import '../../../color_mixer_game.dart';
import '../../helpers/theme_constants.dart';
import '../../helpers/audio_manager.dart';
import '../../components/ui/enhanced_button.dart';
import '../../components/ui/animated_card.dart';
import 'package:flutter/material.dart';

class ChaosGameOverOverlay extends StatefulWidget {
  final ColorMixerGame game;
  const ChaosGameOverOverlay({super.key, required this.game});

  @override
  State<ChaosGameOverOverlay> createState() => _ChaosGameOverOverlayState();
}

class _ChaosGameOverOverlayState extends State<ChaosGameOverOverlay>
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
    _audio.playGameOver();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.game.matchPercentage.value;
    final cause = _getCauseOfFailure(context);
    final tip = _getSurvivalTip(context);

    return Stack(
      children: [
        // Darkened background with deep red tint
        Container(color: const Color(0xFF110000).withValues(alpha: 0.85)),

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
                  glowColor: Colors.redAccent,
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
                              Icons.report_gmailerrorred_rounded,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              AppStrings.meltdownReport
                                  .getString(context)
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                        const Divider(
                          color: Colors.redAccent,
                          thickness: 1,
                          height: 32,
                        ),

                        // Error Icon & Title
                        Text(
                          AppStrings.meltdown.getString(context),
                          style: AppTheme.heading2(context).copyWith(
                            color: Colors.white,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Diagnostics Grid
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.redAccent.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              _buildDiagnosticRow(
                                context,
                                AppStrings.causeOfFailure.getString(context),
                                cause.toUpperCase(),
                                Colors.redAccent,
                              ),
                              const SizedBox(height: 12),
                              _buildDiagnosticRow(
                                context,
                                "CONTAINMENT AT LOSS",
                                "${(widget.game.chaosStability * 100).toInt()}%",
                                Colors.white70,
                              ),
                              const SizedBox(height: 12),
                              _buildDiagnosticRow(
                                context,
                                "MATCH ACCURACY",
                                "${match.toStringAsFixed(1)}%",
                                Colors.white70,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Survival Tip
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.redAccent.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.survivalTip
                                    .getString(context)
                                    .toUpperCase(),
                                style: TextStyle(
                                  color: Colors.redAccent.withValues(
                                    alpha: 0.7,
                                  ),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tip,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
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
                                label: AppStrings.retry.getString(context),
                                icon: Icons.replay_rounded,
                                color: Colors.redAccent,
                                onTap: () {
                                  _audio.playButton();
                                  widget.game.resetGame();
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

  Widget _buildDiagnosticRow(
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

  String _getCauseOfFailure(BuildContext context) {
    if (widget.game.chaosStability <= 0) return "Containment Meltdown";
    if (widget.game.timeLeft <= 0)
      return AppStrings.timeExpired.getString(context);
    if (widget.game.totalDrops.value >= widget.game.maxDrops)
      return AppStrings.dropsExceeded.getString(context);
    return "Unknown System Error";
  }

  String _getSurvivalTip(BuildContext context) {
    final tips = [
      "Accurate drops recover stability! Focus on matching the target color.",
      "Watch the chaos phases: STABLE -> CAUTION -> CRITICAL.",
      "Blackouts, wind, and reflections trigger faster at low stability.",
      "Don't panic! Even small adjustments can prevent a meltdown.",
      "The reactor frequency (wavelength) gives you a hint about the target color.",
    ];
    return tips[widget.game.chaosRound % tips.length];
  }
}
