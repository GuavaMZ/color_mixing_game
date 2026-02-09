import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../color_mixer_game.dart';
import '../helpers/string_manager.dart';
import '../helpers/theme_constants.dart';
import '../helpers/audio_manager.dart';
import '../core/lives_manager.dart';
import '../core/save_manager.dart';

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
    widget.game.returnToMainMenu();
  }

  void _selectLevel(int index) {
    final status = widget.game.levelManager.levelStars[index] ?? -1;
    if (status == -1) return; // Locked

    if (LivesManager().lives <= 0) {
      _showNoLivesDialog();
      return;
    }

    AudioManager().playButton();
    widget.game.levelManager.currentLevelIndex = index;
    widget.game.startLevel();
    widget.game.transitionTo('LevelMap', 'Controls');
  }

  void _toggleRandomEvents(bool value) {
    AudioManager().playButton();
    setState(() {
      widget.game.randomEventsEnabled = value;
    });
    SaveManager.saveRandomEvents(value);
  }

  void _showNoLivesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.primaryDark.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppTheme.neonMagenta, width: 2),
        ),
        title: Text(
          AppStrings.outOfLives.getString(context),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.favorite_rounded,
              color: AppTheme.neonMagenta,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.noLivesDesc.getString(context),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            AnimatedBuilder(
              animation: LivesManager(),
              builder: (context, _) => Text(
                "${AppStrings.nextLifeIn.getString(context)}${LivesManager().timeUntilNextLife}",
                style: const TextStyle(
                  color: AppTheme.neonCyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppStrings.ok.getString(context),
              style: const TextStyle(
                color: AppTheme.neonCyan,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
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
          child: Stack(
            children: [
              const _AtmosphericBackground(),
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
                          // Back button
                          _BackButton(onTap: _goBack),
                          const SizedBox(width: 16),
                          // Title
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.levelMap.getString(context),
                                  style: AppTheme.heading2(context),
                                ),
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
                          _ProgressBadge(
                            completed: widget
                                .game
                                .levelManager
                                .levelStars
                                .values
                                .where((s) => s > 0)
                                .length,
                            total: levels.length,
                          ),
                        ],
                      ),
                    ),

                    // Random Events Toggle Row
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveHelper.spacing(context, 16),
                      ),
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
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "RANDOM EVENTS",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  Text(
                                    "CHAOTIC ANOMALIES EVERY 15s",
                                    style: TextStyle(
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
                              activeColor: AppTheme.neonMagenta,
                              activeTrackColor: AppTheme.neonMagenta.withValues(
                                alpha: 0.3,
                              ),
                              inactiveThumbColor: Colors.white24,
                              inactiveTrackColor: Colors.black26,
                            ),
                          ],
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
                            return _LevelCard(
                              index: index,
                              level: levels[index],
                              stars:
                                  widget.game.levelManager.levelStars[index] ??
                                  -1,
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

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cosmicGlass(
        borderRadius: 15,
        borderColor: Colors.white.withValues(alpha: 0.1),
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
        borderColor: AppTheme.neonMagenta.withValues(alpha: 0.5),
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
          decoration: AppTheme.cosmicCard(
            borderRadius: 24,
            fillColor: isLocked
                ? AppTheme.primaryDark.withValues(alpha: 0.5)
                : isCompleted
                ? difficultyColors[0].withValues(alpha: 0.25)
                : difficultyColors[0].withValues(alpha: 0.15),
            borderColor: isLocked
                ? Colors.white.withValues(alpha: 0.1)
                : isCompleted
                ? AppTheme.electricYellow
                : difficultyColors[0].withValues(alpha: 0.8),
            borderWidth: isCompleted ? 2.5 : 1.5,
            hasGlow: !isLocked,
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
                      color: Colors.white.withValues(alpha: 0.2),
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
                            color: isLocked
                                ? Colors.transparent
                                : difficultyColors[0].withValues(alpha: 0.8),
                            blurRadius: isCompleted ? 15 : 8,
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
                                    color: AppTheme.electricYellow.withValues(
                                      alpha: 0.5,
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
        AppTheme.success.withValues(alpha: 0.7),
      ]; // Neon Green
    } else if (difficulty < 0.5) {
      return [
        AppTheme.neonCyan,
        AppTheme.neonCyan.withValues(alpha: 0.7),
      ]; // Neon Cyan
    } else if (difficulty < 0.7) {
      return [
        AppTheme.electricYellow,
        AppTheme.electricYellow.withValues(alpha: 0.7),
      ]; // Electric Yellow
    } else if (difficulty < 0.9) {
      return [const Color(0xFFFF7F00), const Color(0xFFFF7F00)]; // Neon Orange
    } else {
      return [
        AppTheme.neonMagenta,
        AppTheme.neonMagenta.withValues(alpha: 0.7),
      ]; // Neon Magenta
    }
  }
}

class _AtmosphericBackground extends StatelessWidget {
  const _AtmosphericBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(15, (i) {
        final random = Random();
        final size = 20.0 + random.nextDouble() * 100;
        final top = random.nextDouble() * 800;
        final left = random.nextDouble() * 400;
        final opacity = 0.05 + random.nextDouble() * 0.1;

        return Positioned(
          top: top,
          left: left,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: opacity),
                  Colors.white.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
