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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: Colors.black.withValues(alpha: 0.7)),
        Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: AnimatedCard(
                  onTap: () {},
                  hasGlow: true,
                  glowColor: AppTheme.electricYellow,
                  borderRadius: 32,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.electricYellow.withValues(
                              alpha: 0.1,
                            ),
                            border: Border.all(
                              color: AppTheme.electricYellow.withValues(
                                alpha: 0.3,
                              ),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.check_circle_outline_rounded,
                            color: AppTheme.electricYellow,
                            size: 64,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "STABILIZED",
                          style: AppTheme.heading1(
                            context,
                          ).copyWith(color: Colors.white, letterSpacing: 2),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Chaos reactor successfully contained. Lab integrity maintained.",
                          textAlign: TextAlign.center,
                          style: AppTheme.bodyMedium(
                            context,
                          ).copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: EnhancedButton(
                                label: "RETRY",
                                icon: Icons.replay_rounded,
                                isOutlined: true,
                                onTap: () {
                                  _audio.playButton();
                                  widget.game.resetGame();
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: EnhancedButton(
                                label: "MENU",
                                icon: Icons.home_rounded,
                                onTap: () {
                                  _audio.playButton();
                                  widget.game.returnToMainMenu();
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
}
