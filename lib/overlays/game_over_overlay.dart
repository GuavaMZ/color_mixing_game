import 'package:color_mixing_deductive/helpers/audio_manager.dart';
import 'package:color_mixing_deductive/helpers/theme_constants.dart';
import 'package:flutter/material.dart';
import '../color_mixer_game.dart';

class GameOverOverlay extends StatelessWidget {
  final ColorMixerGame game;
  const GameOverOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: AppTheme.cartoonDecoration(
            borderRadius: 32,
            fillColor: AppTheme.cardColor,
            borderColor: AppTheme.primaryColor,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white10,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.timer_off_outlined,
                  color: AppTheme.primaryColor,
                  size: 80,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Time's Up!",
                style: AppTheme.heading2(
                  context,
                ).copyWith(color: Colors.white, fontSize: 36),
              ),
              const SizedBox(height: 12),
              Text(
                "You weren't fast enough this time. Try again!",
                textAlign: TextAlign.center,
                style: AppTheme.bodyMedium(
                  context,
                ).copyWith(color: Colors.white.withOpacity(0.7)),
              ),
              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context,
                      label: "Retry",
                      icon: Icons.replay_rounded,
                      color: AppTheme.primaryColor,
                      onTap: () {
                        AudioManager().playButton();
                        game.overlays.remove('GameOver');
                        game.startLevel();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionButton(
                      context,
                      label: "Map",
                      icon: Icons.map_rounded,
                      color: AppTheme.secondaryColor,
                      onTap: () {
                        AudioManager().playButton();
                        game.overlays.remove('GameOver');
                        game.overlays.add('LevelMap');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: AppTheme.cartoonDecoration(
        borderRadius: 16,
        fillColor: color,
        borderWidth: 3,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
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
