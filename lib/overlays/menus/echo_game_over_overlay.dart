import 'package:flutter_localization/flutter_localization.dart';
import '../../helpers/string_manager.dart';
import '../../../color_mixer_game.dart';
import '../../helpers/theme_constants.dart';
import '../../helpers/audio_manager.dart';
import '../../components/ui/enhanced_button.dart';
import '../../components/ui/animated_card.dart';
import 'package:flutter/material.dart';

class EchoGameOverOverlay extends StatefulWidget {
  final ColorMixerGame game;
  const EchoGameOverOverlay({super.key, required this.game});

  @override
  State<EchoGameOverOverlay> createState() => _EchoGameOverOverlayState();
}

class _EchoGameOverOverlayState extends State<EchoGameOverOverlay>
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
    final drift = 100.0 - match;
    final tip = _getSurvivalTip(context);

    return Stack(
      children: [
        // Darkened background with magenta tint
        Container(color: const Color(0xFF110011).withValues(alpha: 0.85)),

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
                  glowColor: AppTheme.neonMagenta,
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
                              Icons.troubleshoot_rounded,
                              color: AppTheme.neonMagenta,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              AppStrings.signalDiagnostics
                                  .getString(context)
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.neonMagenta,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                        const Divider(
                          color: AppTheme.neonMagenta,
                          thickness: 1,
                          height: 32,
                        ),

                        // Error Icon & Title
                        Text(
                          AppStrings.syncLost.getString(context),
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
                              color: AppTheme.neonMagenta.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              _buildDiagnosticRow(
                                context,
                                AppStrings.causeOfFailure.getString(context),
                                AppStrings.signalDrift.getString(context),
                                Colors.redAccent,
                              ),
                              const SizedBox(height: 12),
                              _buildDiagnosticRow(
                                context,
                                AppStrings.syncAccuracy.getString(context),
                                "${match.toStringAsFixed(1)}%",
                                Colors.white70,
                              ),
                              const SizedBox(height: 12),
                              _buildDiagnosticRow(
                                context,
                                "SPECTRAL DRIFT",
                                "+${drift.toStringAsFixed(1)} ΔE",
                                AppTheme.neonMagenta,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Survival Tip
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.neonMagenta.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.neonMagenta.withValues(
                                alpha: 0.1,
                              ),
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
                                  color: AppTheme.neonMagenta.withValues(
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
                                color: AppTheme.neonMagenta,
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

  String _getSurvivalTip(BuildContext context) {
    // Basic logic to pick a tip for Echo mode
    final tips = [
      "Use small droplets of Red/Green/Blue for fine tuning.",
      "Sync loss occurs when you run out of drops or time.",
      "The wavelength indicator helps identify the target's spectral region.",
      "Watch the 'ALMOST' pulse; it indicates you are 80%+ synced.",
      "White and Black drops can shift luminance without changing hue significantly.",
    ];
    return tips[widget.game.echoRound % tips.length];
  }
}
