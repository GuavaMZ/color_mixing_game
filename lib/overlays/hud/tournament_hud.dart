import 'package:flutter/material.dart';
import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:color_mixing_deductive/helpers/theme_constants.dart';

class TournamentHUD extends StatelessWidget {
  final ColorMixerGame game;
  const TournamentHUD({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 100,
      right: 20,
      child: ValueListenableBuilder<double>(
        valueListenable: game.matchPercentage,
        builder: (context, matchPct, _) {
          return ValueListenableBuilder<int>(
            valueListenable: game.comboCount,
            builder: (context, combo, _) {
              // Calculate real-time score estimate
              int estimatedScore = (matchPct.toInt() * 10 * (combo + 1))
                  .toInt();

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: AppTheme.cosmicGlass(borderRadius: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'TOURNAMENT SCORE',
                      style: AppTheme.bodySmall(context).copyWith(
                        color: AppTheme.electricYellow,
                        fontSize: 10,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      estimatedScore.toString(),
                      style: AppTheme.heading2(
                        context,
                      ).copyWith(color: Colors.white, fontSize: 24),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
