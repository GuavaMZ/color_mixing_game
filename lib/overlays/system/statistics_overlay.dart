import 'package:color_mixing_deductive/helpers/audio_manager.dart';
import 'package:color_mixing_deductive/helpers/statistics_manager.dart';
import 'package:color_mixing_deductive/helpers/string_manager.dart';
import 'package:color_mixing_deductive/helpers/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import '../../../color_mixer_game.dart';

class StatisticsOverlay extends StatelessWidget {
  final ColorMixerGame game;
  const StatisticsOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0E27), Color(0xFF1a1a2e)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        AudioManager().playButton();
                        game.overlays.remove('Statistics');
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.statisticsTitle.getString(context),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Stats content
              Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: StatisticsManager.getAllStats(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.neonCyan,
                        ),
                      );
                    }

                    final stats = snapshot.data!;
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _StatCard(
                            icon: Icons.emoji_events,
                            title: AppStrings.levelsCompleted.getString(
                              context,
                            ),
                            value: '${stats['totalLevels']}',
                            color: AppTheme.neonCyan,
                          ),
                          _StatCard(
                            icon: Icons.star,
                            title: AppStrings.perfectMatches.getString(context),
                            value: '${stats['perfectMatches']}',
                            color: AppTheme.neonPurple,
                          ),
                          _StatCard(
                            icon: Icons.water_drop,
                            title: AppStrings.totalDropsUsed.getString(context),
                            value: '${stats['totalDrops']}',
                            color: AppTheme.neonMagenta,
                          ),
                          _StatCard(
                            icon: Icons.local_fire_department,
                            title: AppStrings.highestCombo.getString(context),
                            value: '${stats['highestCombo']}x',
                            color: Colors.orange,
                          ),
                          FutureBuilder<double>(
                            future: StatisticsManager.getAverageAccuracy(),
                            builder: (context, accuracySnapshot) {
                              return _StatCard(
                                icon: Icons.percent,
                                title: AppStrings.averageAccuracy.getString(
                                  context,
                                ),
                                value:
                                    '${(accuracySnapshot.data ?? 0).toStringAsFixed(1)}%',
                                color: Colors.green,
                              );
                            },
                          ),
                          FutureBuilder<String>(
                            future: StatisticsManager.getFavoriteMode(),
                            builder: (context, modeSnapshot) {
                              return _StatCard(
                                icon: Icons.favorite,
                                title: AppStrings.favoriteMode.getString(
                                  context,
                                ),
                                value: modeSnapshot.data ?? 'None',
                                color: Colors.pink,
                              );
                            },
                          ),

                          const SizedBox(height: 20),
                          Text(
                            AppStrings.modePlayCounts.getString(context),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),

                          _ModeStatRow(
                            AppStrings.classicMode.getString(context),
                            stats['classicPlays'],
                          ),
                          _ModeStatRow(
                            AppStrings.timeAttackMode.getString(context),
                            stats['timeAttackPlays'],
                          ),
                          _ModeStatRow(
                            AppStrings.colorEcho.getString(context),
                            stats['colorEchoPlays'],
                          ),
                          _ModeStatRow(
                            AppStrings.chaosLabTitle.getString(context),
                            stats['chaosLabPlays'],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeStatRow extends StatelessWidget {
  final String mode;
  final int count;

  const _ModeStatRow(this.mode, this.count);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              mode,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
          Text(
            '$count ${AppStrings.playsText.getString(context)}',
            style: const TextStyle(
              color: AppTheme.neonCyan,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
