import 'package:flutter/material.dart';
import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:color_mixing_deductive/helpers/theme_constants.dart';
import 'package:color_mixing_deductive/helpers/tournament_manager.dart';

class TournamentOverlay extends StatefulWidget {
  final ColorMixerGame game;
  const TournamentOverlay({Key? key, required this.game}) : super(key: key);

  @override
  _TournamentOverlayState createState() => _TournamentOverlayState();
}

class _TournamentOverlayState extends State<TournamentOverlay> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.cosmicGlass(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'WEEKLY TOURNAMENT',
                style: AppTheme.heading2(
                  context,
                ).copyWith(color: AppTheme.electricYellow),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<int>(
                valueListenable: TournamentManager.instance.scoreNotifier,
                builder: (context, score, _) {
                  return Column(
                    children: [
                      Text(
                        'Theme: ${TournamentManager.instance.currentTheme}',
                        style: AppTheme.bodyLarge(
                          context,
                        ).copyWith(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ends in: ${TournamentManager.instance.getTimeRemainingString()}',
                        style: AppTheme.bodySmall(
                          context,
                        ).copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'PERSONAL BEST',
                        style: AppTheme.bodySmall(
                          context,
                        ).copyWith(color: Colors.white54, letterSpacing: 1.5),
                      ),
                      Text(
                        score.toString(),
                        style: AppTheme.heading1(
                          context,
                        ).copyWith(color: AppTheme.neonCyan),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonCyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  widget.game.overlays.remove('Tournament');
                  // Trigger tournament mode start logic
                  widget.game.startTournamentMode();
                },
                child: const Text(
                  'ENTER TOURNAMENT (Free)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => widget.game.overlays.remove('Tournament'),
                child: Text(
                  'CLOSE',
                  style: AppTheme.bodyMedium(
                    context,
                  ).copyWith(color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
