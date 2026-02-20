import 'package:flutter_localization/flutter_localization.dart';
import '../../helpers/string_manager.dart';
import '../../core/color_science.dart';
import '../../../color_mixer_game.dart';
import '../../helpers/theme_constants.dart';
import '../../helpers/audio_manager.dart';
import '../../components/ui/enhanced_button.dart';
import '../../components/ui/animated_card.dart';
import 'package:flutter/material.dart';

class EchoWinOverlay extends StatefulWidget {
  final ColorMixerGame game;
  const EchoWinOverlay({super.key, required this.game});

  @override
  State<EchoWinOverlay> createState() => _EchoWinOverlayState();
}

class _EchoWinOverlayState extends State<EchoWinOverlay>
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
    final match = widget.game.matchPercentage.value;
    final wavelength = ColorScience.estimateWavelength(widget.game.targetColor);
    final tempMap = ColorScience.getColorTemperature(widget.game.targetColor);
    final kelvin = tempMap['kelvin'] as int;
    final fact = ColorScience.getColorFact(widget.game.targetColor);

    return Stack(
      children: [
        // Darkened background with slight cyan tint
        Container(color: const Color(0xFF000011).withValues(alpha: 0.85)),

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
                  glowColor: AppTheme.neonCyan,
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
                              Icons.analytics_outlined,
                              color: AppTheme.neonCyan,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              AppStrings.spectralAnalysis
                                  .getString(context)
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.neonCyan,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                        const Divider(
                          color: Colors.cyan,
                          thickness: 1,
                          height: 32,
                        ),

                        // Success Icon & Title
                        Text(
                          AppStrings.echoSynced.getString(context),
                          style: AppTheme.heading2(context).copyWith(
                            color: Colors.white,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Data Grid
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.neonCyan.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              _buildDataRow(
                                context,
                                AppStrings.syncAccuracy.getString(context),
                                "${match.toStringAsFixed(1)}%",
                                AppTheme.neonCyan,
                              ),
                              const SizedBox(height: 12),
                              _buildDataRow(
                                context,
                                AppStrings.wavelengthLabel.getString(context),
                                "${wavelength.toInt()} nm",
                                Colors.orangeAccent,
                              ),
                              const SizedBox(height: 12),
                              _buildDataRow(
                                context,
                                AppStrings.colorTempLabel.getString(context),
                                "$kelvin K",
                                Colors.blueAccent,
                              ),
                              const SizedBox(height: 12),
                              _buildDataRow(
                                context,
                                AppStrings.totalScore.getString(context),
                                widget.game.echoScore.toInt().toString(),
                                AppTheme.neonMagenta,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Did You Know Section
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.neonCyan.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.neonCyan.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "DID YOU KNOW?",
                                style: TextStyle(
                                  color: AppTheme.neonCyan.withValues(
                                    alpha: 0.7,
                                  ),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                fact,
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
                                label: AppStrings.nextEcho.getString(context),
                                icon: Icons.skip_next_rounded,
                                color: AppTheme.neonCyan,
                                onTap: () {
                                  _audio.playButton();
                                  widget.game.nextEchoRound();
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
            shadows: [
              Shadow(color: color.withValues(alpha: 0.4), blurRadius: 4),
            ],
          ),
        ),
      ],
    );
  }
}
