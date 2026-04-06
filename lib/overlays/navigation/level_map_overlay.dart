import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../../../color_mixer_game.dart';
import '../../helpers/string_manager.dart';
import '../../helpers/theme_constants.dart';
import '../../helpers/audio_manager.dart';
import '../../core/lives_manager.dart';
import '../../core/save_manager.dart';
import '../../helpers/visual_effects.dart';
import '../../components/ui/responsive_components.dart';
import '../../overlays/system/no_lives_dialog.dart';

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
    widget.game.showPhaseSelect();
  }

  void _selectLevel(int index, List levels) {
    final levelId = levels[index].id;
    final status = widget.game.levelManager.levelStars[levelId] ?? -1;
    if (status == -1) return;

    if (LivesManager().lives <= 0) {
      NoLivesDialog.show(context, widget.game);
      return;
    }

    AudioManager().playButton();
    // Find the index in ALL classic levels, not just phase levels
    final allIndex = widget.game.levelManager.classicLevels.indexWhere(
      (l) => l.id == levelId,
    );
    if (allIndex >= 0) widget.game.transitionToLevel(allIndex);
  }

  void _toggleRandomEvents(bool value) {
    AudioManager().playButton();
    setState(() {
      widget.game.randomEventsEnabled = value;
    });
    SaveManager.saveRandomEvents(value);
  }

  @override
  Widget build(BuildContext context) {
    final lm = widget.game.levelManager;
    final selectedPhase = lm.selectedPhase;
    final levels = lm.levelsForPhase(selectedPhase);
    final columns = ResponsiveHelper.levelGridColumns(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(gradient: AppTheme.cosmicBackground),
          child: Stack(
            children: [
              // Replaced _AtmosphericBackground with StarField
              const StarField(starCount: 60, color: Colors.white),

              SafeArea(
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: EdgeInsets.all(
                        ResponsiveHelper.spacing(context, 16),
                      ),
                      child: Row(
                        children: [
                          // Back button using ResponsiveIconButton
                          ResponsiveIconButton(
                            onPressed: _goBack,
                            icon: Icons.arrow_back_ios_rounded,
                            color: AppTheme.neonCyan,
                            size: 22,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.1,
                            ),
                            borderColor: Colors.white.withValues(alpha: 0.1),
                          ),
                          const SizedBox(width: 16),
                          // Title
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Text(
                                //   AppStrings.levelMap.getString(context),
                                //   style: AppTheme.heading2(context),
                                // ),
                                Text(
                                  widget.game.currentMode == GameMode.timeAttack
                                      ? AppStrings.timeAttackMode.getString(
                                          context,
                                        )
                                      : AppStrings.classicMode.getString(
                                          context,
                                        ),
                                  style: TextStyle(
                                    color:
                                        widget.game.currentMode ==
                                            GameMode.timeAttack
                                        ? AppTheme.neonMagenta
                                        : AppTheme.neonCyan,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Lives display
                          _buildLivesDisplay(),
                          const SizedBox(width: 8),
                          // Progress indicator
                          // _ProgressBadge(
                          //   completed: widget
                          //       .game
                          //       .levelManager
                          //       .levelStars
                          //       .values
                          //       .where((s) => s > 0)
                          //       .length,
                          //   total: levels.length,
                          // ),
                        ],
                      ),
                    ),

                    // Random Events Toggle Row
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveHelper.spacing(context, 16),
                      ),
                      child: ShimmerEffect(
                        baseColor: Colors.white.withValues(alpha: 0.1),
                        highlightColor: widget.game.randomEventsEnabled
                            ? AppTheme.neonMagenta.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.15),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: AppTheme.cosmicGlass(
                            borderRadius: 20,
                            borderColor: widget.game.randomEventsEnabled
                                ? AppTheme.neonMagenta.withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.auto_fix_high_rounded,
                                color: AppTheme.neonMagenta,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppStrings.randomEvents.getString(
                                        context,
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    Text(
                                      AppStrings.chaoticAnomalies.getString(
                                        context,
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: widget.game.randomEventsEnabled,
                                onChanged: _toggleRandomEvents,
                                activeThumbColor: AppTheme.neonMagenta,
                                activeTrackColor: AppTheme.neonMagenta
                                    .withValues(alpha: 0.3),
                                inactiveThumbColor: Colors.white24,
                                inactiveTrackColor: Colors.black26,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Level grid
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveHelper.spacing(context, 16),
                        ),
                        child: GridView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 1.0,
                              ),
                          itemCount: levels.length,
                          itemBuilder: (context, index) {
                            final levelId = levels[index].id;
                            return _LevelCard(
                              index: index,
                              level: levels[index],
                              stars:
                                  widget
                                      .game
                                      .levelManager
                                      .levelStars[levelId] ??
                                  -1,
                              onTap: () => _selectLevel(index, levels),
                              delay: index * 50,
                              game: widget.game,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLivesDisplay() {
    return AnimatedBuilder(
      animation: LivesManager(),
      builder: (context, child) {
        final livesCount = LivesManager().lives;
        final isFull = livesCount >= LivesManager.maxLives;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: AppTheme.cosmicGlass(
            borderRadius: 15,
            borderColor: Colors.redAccent.withValues(alpha: 0.3),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.favorite_rounded,
                color: Colors.redAccent,
                size: 18,
              ),
              const SizedBox(width: 6),
              if (isFull)
                Text(
                  "$livesCount",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                )
              else
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$livesCount",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      LivesManager().timeUntilNextLife,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _LevelCard extends StatefulWidget {
  final int index;
  final dynamic level;
  final int stars;
  final VoidCallback onTap;
  final int delay;
  final ColorMixerGame game;

  const _LevelCard({
    required this.index,
    required this.level,
    required this.stars,
    required this.onTap,
    required this.delay,
    required this.game,
  });

  @override
  State<_LevelCard> createState() => _LevelCardState();
}

class _LevelCardState extends State<_LevelCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isPressed = false;

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

  bool get _isCurrentLevel {
    // Current level is the first level that has 0 stars (unlocked but not completed)
    final stars = widget.game.levelManager.levelStars[widget.level.id] ?? -1;
    return stars == 0;
  }

  List<Color> _getDifficultyGradient(double difficulty) {
    if (difficulty < 0.3) {
      return [AppTheme.success, AppTheme.success.withValues(alpha: 0.7)];
    } else if (difficulty < 0.5) {
      return [AppTheme.neonCyan, AppTheme.neonCyan.withValues(alpha: 0.7)];
    } else if (difficulty < 0.7) {
      return [
        AppTheme.electricYellow,
        AppTheme.electricYellow.withValues(alpha: 0.7),
      ];
    } else if (difficulty < 0.9) {
      return [const Color(0xFFFF7F00), const Color(0xFFFF7F00)];
    } else {
      return [
        AppTheme.neonMagenta,
        AppTheme.neonMagenta.withValues(alpha: 0.7),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = widget.stars == -1;
    final isCompleted = widget.stars > 0;
    final difficultyColors = _getDifficultyGradient(
      widget.level.difficultyFactor,
    );

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTapDown: isLocked ? null : (_) => setState(() => _isPressed = true),
          onTapUp: isLocked ? null : (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: isLocked ? null : widget.onTap,
          child: AnimatedScale(
            scale: _isPressed ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: AppTheme.premiumGlassDecoration(
                    borderRadius: 24,
                    borderColor: _isCurrentLevel
                        ? AppTheme.electricYellow
                        : isLocked
                        ? Colors.white.withValues(alpha: 0.1)
                        : isCompleted
                        ? AppTheme.electricYellow.withValues(alpha: 0.8)
                        : difficultyColors[0].withValues(alpha: 0.6),
                    glowColor: _isCurrentLevel
                        ? AppTheme.electricYellow
                        : difficultyColors[0],
                    hasGlow: _isCurrentLevel,
                  ),
                  child: Stack(
                    children: [
                      // Target Color Hint (Subtle background)
                      if (!isLocked)
                        Positioned(
                          bottom: -15,
                          right: -15,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: widget.level.targetColor.withValues(
                                alpha: 0.25,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: widget.level.targetColor.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Content
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isLocked) ...[
                              Icon(
                                Icons.lock_rounded,
                                color: Colors.white.withValues(alpha: 0.15),
                                size: 28,
                              ),
                            ] else ...[
                              Text(
                                '${widget.index + 1}',
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.fontSize(
                                    context,
                                    28,
                                  ),
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
                                      offset: const Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                    Shadow(
                                      color: difficultyColors[0].withValues(
                                        alpha: 0.6,
                                      ),
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
                                        : Colors.white.withValues(alpha: 0.1),
                                    size: 16,
                                    shadows: i < widget.stars
                                        ? [
                                            Shadow(
                                              color: AppTheme.electricYellow
                                                  .withValues(alpha: 0.5),
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
}
