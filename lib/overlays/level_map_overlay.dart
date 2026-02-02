import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../color_mixer_game.dart';
import '../helpers/string_manager.dart';
import '../helpers/theme_constants.dart';
import '../helpers/audio_manager.dart';

class LevelMapOverlay extends StatefulWidget {
  final ColorMixerGame game;
  const LevelMapOverlay({super.key, required this.game});

  @override
  State<LevelMapOverlay> createState() => _LevelMapOverlayState();
}

class _LevelMapOverlayState extends State<LevelMapOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goBack() {
    AudioManager().playButton();
    _controller.reverse().then((_) {
      widget.game.overlays.remove('LevelMap');
      widget.game.overlays.add('MainMenu');
    });
  }

  void _selectLevel(int index) {
    final status = widget.game.levelManager.levelStars[index] ?? -1;
    if (status == -1) return; // Locked

    AudioManager().playButton();
    widget.game.levelManager.currentLevelIndex = index;
    widget.game.startLevel();
    widget.game.overlays.remove('LevelMap');
    widget.game.overlays.add('Controls');
  }

  @override
  Widget build(BuildContext context) {
    final levels = widget.game.levelManager.levels;
    final columns = ResponsiveHelper.levelGridColumns(context);
    final cardSize = ResponsiveHelper.levelCardSize(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.all(
                    ResponsiveHelper.spacing(context, 16),
                  ),
                  child: Row(
                    children: [
                      // Back button
                      _BackButton(onTap: _goBack),
                      const SizedBox(width: 16),
                      // Title
                      Expanded(
                        child: Text(
                          AppStrings.levelMap.getString(context),
                          style: AppTheme.heading2(context),
                        ),
                      ),
                      // Progress indicator
                      _ProgressBadge(
                        completed: widget.game.levelManager.levelStars.values
                            .where((s) => s > 0)
                            .length,
                        total: levels.length,
                      ),
                    ],
                  ),
                ),

                // Level grid
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveHelper.spacing(context, 16),
                    ),
                    child: GridView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: levels.length,
                      itemBuilder: (context, index) {
                        return _LevelCard(
                          index: index,
                          level: levels[index],
                          stars:
                              widget.game.levelManager.levelStars[index] ?? -1,
                          onTap: () => _selectLevel(index),
                          delay: index * 50,
                        );
                      },
                    ),
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

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Colors.white.withOpacity(0.8),
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressBadge extends StatelessWidget {
  final int completed;
  final int total;

  const _ProgressBadge({required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
          const SizedBox(width: 6),
          Text(
            '$completed / $total',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelCard extends StatefulWidget {
  final int index;
  final dynamic level;
  final int stars;
  final VoidCallback onTap;
  final int delay;

  const _LevelCard({
    required this.index,
    required this.level,
    required this.stars,
    required this.onTap,
    required this.delay,
  });

  @override
  State<_LevelCard> createState() => _LevelCardState();
}

class _LevelCardState extends State<_LevelCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Staggered animation
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = widget.stars == -1;
    final isCompleted = widget.stars > 0;

    // Gradient based on difficulty
    final difficultyColors = _getDifficultyGradient(
      widget.level.difficultyFactor,
    );

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              decoration: BoxDecoration(
                gradient: isLocked
                    ? LinearGradient(
                        colors: [
                          Colors.grey.withOpacity(0.2),
                          Colors.grey.withOpacity(0.1),
                        ],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          difficultyColors[0].withOpacity(0.3),
                          difficultyColors[1].withOpacity(0.15),
                        ],
                      ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isLocked
                      ? Colors.grey.withOpacity(0.3)
                      : isCompleted
                      ? Colors.amber.withOpacity(0.5)
                      : difficultyColors[0].withOpacity(0.5),
                  width: isCompleted ? 2 : 1.5,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isLocked ? null : widget.onTap,
                  borderRadius: BorderRadius.circular(16),
                  splashColor: difficultyColors[0].withOpacity(0.2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isLocked) ...[
                        Icon(
                          Icons.lock_rounded,
                          color: Colors.white.withOpacity(0.4),
                          size: 28,
                        ),
                      ] else ...[
                        // Level number
                        Text(
                          '${widget.index + 1}',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.fontSize(context, 24),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: difficultyColors[0].withOpacity(0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Stars
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (i) {
                            return Icon(
                              i < widget.stars
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: i < widget.stars
                                  ? Colors.amber
                                  : Colors.white.withOpacity(0.3),
                              size: 14,
                            );
                          }),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _getDifficultyGradient(double difficulty) {
    if (difficulty < 0.3) {
      return [const Color(0xFF4ADE80), const Color(0xFF22C55E)]; // Green - Easy
    } else if (difficulty < 0.5) {
      return [
        const Color(0xFF4facfe),
        const Color(0xFF00f2fe),
      ]; // Blue - Medium
    } else if (difficulty < 0.7) {
      return [
        const Color(0xFFFBBF24),
        const Color(0xFFF59E0B),
      ]; // Yellow - Hard
    } else if (difficulty < 0.9) {
      return [
        const Color(0xFFF97316),
        const Color(0xFFEA580C),
      ]; // Orange - Very Hard
    } else {
      return [const Color(0xFFF87171), const Color(0xFFEF4444)]; // Red - Expert
    }
  }
}
