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
    widget.game.transitionTo('LevelMap', 'MainMenu');
  }

  void _selectLevel(int index) {
    final status = widget.game.levelManager.levelStars[index] ?? -1;
    if (status == -1) return; // Locked

    AudioManager().playButton();
    widget.game.levelManager.currentLevelIndex = index;
    widget.game.startLevel();
    widget.game.transitionTo('LevelMap', 'Controls');
  }

  @override
  Widget build(BuildContext context) {
    final levels = widget.game.levelManager.levels;
    final columns = ResponsiveHelper.levelGridColumns(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.cosmicBackground),
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
    return Container(
      decoration: AppTheme.cosmicGlass(
        borderRadius: 15,
        borderColor: Colors.white.withOpacity(0.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.arrow_back_ios_rounded,
              color: AppTheme.neonCyan,
              size: 22,
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
      decoration: AppTheme.cosmicGlass(
        borderRadius: 20,
        borderColor: AppTheme.neonMagenta.withOpacity(0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            color: AppTheme.electricYellow,
            size: 20,
          ),
          const SizedBox(width: 6),
          Text(
            '$completed / $total',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
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

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AppTheme.cosmicCurve),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Staggered animation - capped at 1000ms for performance
    Future.delayed(Duration(milliseconds: widget.delay.clamp(0, 1000)), () {
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
    final difficultyColors = _getDifficultyGradient(
      widget.level.difficultyFactor,
    );

    // Cosmic Level Card Look
    // Locked: Dark, Low opacity
    // Unlocked: Neon Border, faint glow
    // Completed: Bright Neon, filled star

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: isLocked
                ? Colors.white.withOpacity(0.05)
                : difficultyColors[0].withOpacity(0.2), // Subtle tint
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isLocked
                  ? Colors.white.withOpacity(0.1)
                  : (isCompleted
                        ? AppTheme.electricYellow
                        : difficultyColors[0]),
              width: 1.5,
            ),
            boxShadow: [
              if (!isLocked)
                BoxShadow(
                  color:
                      (isCompleted
                              ? AppTheme.electricYellow
                              : difficultyColors[0])
                          .withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: -2,
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLocked ? null : widget.onTap,
              borderRadius: BorderRadius.circular(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLocked) ...[
                    Icon(
                      Icons.lock_rounded,
                      color: Colors.white.withOpacity(0.2),
                      size: 28,
                    ),
                  ] else ...[
                    Text(
                      '${widget.index + 1}',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.fontSize(context, 24),
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: difficultyColors[0].withOpacity(0.8),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        return Icon(
                          i < widget.stars
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: i < widget.stars
                              ? AppTheme.electricYellow
                              : Colors.white.withOpacity(0.1),
                          size: 16,
                          shadows: i < widget.stars
                              ? [
                                  Shadow(
                                    color: AppTheme.electricYellow.withOpacity(
                                      0.5,
                                    ),
                                    blurRadius: 5,
                                  ),
                                ]
                              : null,
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
    );
  }

  List<Color> _getDifficultyGradient(double difficulty) {
    // Return colors matching the cosmic theme based on difficulty
    if (difficulty < 0.3) {
      return [
        AppTheme.success,
        AppTheme.success.withOpacity(0.7),
      ]; // Neon Green
    } else if (difficulty < 0.5) {
      return [
        AppTheme.neonCyan,
        AppTheme.neonCyan.withOpacity(0.7),
      ]; // Neon Cyan
    } else if (difficulty < 0.7) {
      return [
        AppTheme.electricYellow,
        AppTheme.electricYellow.withOpacity(0.7),
      ]; // Electric Yellow
    } else if (difficulty < 0.9) {
      return [const Color(0xFFFF7F00), const Color(0xFFFF7F00)]; // Neon Orange
    } else {
      return [
        AppTheme.neonMagenta,
        AppTheme.neonMagenta.withOpacity(0.7),
      ]; // Neon Magenta
    }
  }
}
