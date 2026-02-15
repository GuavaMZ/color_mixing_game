import 'dart:ui';
import 'dart:math';
import 'package:color_mixing_deductive/helpers/haptic_manager.dart';

import '../../../color_mixer_game.dart';
import '../../components/ui/banner_ad_widget.dart';
import '../../helpers/string_manager.dart';
import '../../helpers/theme_constants.dart';
import '../../helpers/audio_manager.dart';
import '../../helpers/visual_effects.dart';
import '../../components/ui/responsive_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

class ControlsOverlay extends StatelessWidget {
  const ControlsOverlay({super.key, required this.game});

  final ColorMixerGame game;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, child) {
        // Earthquake and Glitch Jitter Logic
        Offset uiOffset = Offset.zero;
        if (game.isEarthquake) {
          uiOffset = Offset(game.earthquakeOffset.x, game.earthquakeOffset.y);
        } else if (game.isUiGlitching) {
          final random = Random();
          uiOffset = Offset(
            (random.nextDouble() - 0.5) * 15,
            (random.nextDouble() - 0.5) * 15,
          );
        }

        return Transform.translate(
          offset: uiOffset,
          child: Stack(
            children: [
              // Banner Ad at the top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(child: Center(child: BannerAdWidget())),
              ),

              // Top section - Target color
              Positioned(
                top:
                    ResponsiveHelper.safePadding(context).top +
                    ResponsiveHelper.spacing(context, 16) +
                    50, // Added offset for Ad
                left: 0,
                right: 0,
                child: Center(child: _buildTargetColorDisplay(context)),
              ),

              // Pause button using ResponsiveIconButton for consistency
              Positioned(
                top:
                    ResponsiveHelper.safePadding(context).top +
                    ResponsiveHelper.spacing(context, 16),
                right: ResponsiveHelper.spacing(context, 16),
                child: ResponsiveIconButton(
                  onPressed: () {
                    AudioManager().playButton();
                    game.overlays.add('PauseMenu');
                  },
                  icon: Icons.menu_rounded,
                  color: AppTheme.neonCyan,
                  size: 24,
                  backgroundColor: AppTheme.cardColor.withValues(alpha: 0.5),
                  borderColor: AppTheme.neonCyan.withValues(alpha: 0.5),
                ),
              ),

              // Time Attack Timer (Conditional)
              if (game.currentMode == GameMode.timeAttack)
                Positioned(
                  top:
                      ResponsiveHelper.safePadding(context).top +
                      ResponsiveHelper.spacing(context, 16),
                  left: ResponsiveHelper.spacing(context, 16),
                  child: _TimeAttackTimer(game: game),
                ),

              // Combo Counter
              ValueListenableBuilder<int>(
                valueListenable: game.comboCount,
                builder: (context, combo, child) {
                  if (combo < 3) return const SizedBox.shrink();
                  return Positioned(
                    top:
                        ResponsiveHelper.safePadding(context).top +
                        ResponsiveHelper.spacing(context, 80),
                    left: ResponsiveHelper.spacing(context, 16),
                    child: _ComboDisplay(combo: combo),
                  );
                },
              ),

              // Power-up Dock (Right Side) - Vertical Layout
              Positioned(
                right: ResponsiveHelper.spacing(context, 16),
                top: MediaQuery.of(context).size.height * 0.35,
                child: _buildPowerUpDock(context),
              ),

              // Bottom controls area (Control Panel)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 32),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: EdgeInsets.only(
                        bottom:
                            ResponsiveHelper.safePadding(context).bottom + 8,
                        top: 12,
                        left: 12,
                        right: 12,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Match percentage display
                          ValueListenableBuilder<double>(
                            valueListenable: game.matchPercentage,
                            builder: (context, value, child) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _MatchPercentageDisplay(
                                value: value,
                                context: context,
                                game: game,
                              ),
                            ),
                          ),

                          // Color buttons row
                          _buildControlsRow(context),

                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTargetColorDisplay(BuildContext context) {
    final currentLevel = game.levelManager.currentLevel;
    final circleSize = ResponsiveHelper.responsive<double>(
      context,
      mobile: 100.0,
      tablet: 120.0,
      desktop: 140.0,
    );

    if (game.isBlackout) {
      return SizedBox(height: circleSize);
    }

    return ValueListenableBuilder<double>(
      valueListenable: game.matchPercentage,
      builder: (context, matchValue, child) {
        return Semantics(
          label:
              '${AppStrings.levelText.getString(context)} ${currentLevel.id}. ${AppStrings.precentageMatch.getString(context)}: ${matchValue.toStringAsFixed(0)}%',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Level info header
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveHelper.spacing(context, 20),
                  vertical: ResponsiveHelper.spacing(context, 6),
                ),
                decoration: AppTheme.cosmicCard(
                  borderRadius: 20,
                  fillColor: AppTheme.primaryDark.withValues(alpha: 0.8),
                  borderColor: AppTheme.neonCyan.withValues(alpha: 0.6),
                  hasGlow: true,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${AppStrings.levelText.getString(context)} ${currentLevel.id}",
                      style: TextStyle(
                        color: AppTheme.neonCyan,
                        fontSize: ResponsiveHelper.fontSize(
                          context,
                          ResponsiveHelper.responsive(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18,
                          ),
                        ),
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.spacing(context, 10)),
                    ...List.generate(
                      currentLevel.difficultyStars,
                      (index) => Icon(
                        Icons.star_rounded,
                        color: AppTheme.electricYellow,
                        size: ResponsiveHelper.responsive(
                          context,
                          mobile: 14,
                          tablet: 16,
                          desktop: 18,
                        ),
                        shadows: [
                          Shadow(
                            color: AppTheme.electricYellow.withValues(
                              alpha: 0.5,
                            ),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: ResponsiveHelper.spacing(context, 20)),

              // Liquid Target Display
              SizedBox(
                width: circleSize,
                height: circleSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow Layer
                    ShimmerEffect(
                      baseColor: game.targetColor.withValues(alpha: 0.2),
                      highlightColor: game.targetColor.withValues(alpha: 0.5),
                      child: Container(
                        width: circleSize,
                        height: circleSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: game.targetColor.withValues(alpha: 0.2),
                        ),
                      ),
                    ),

                    // Classic Target Circle
                    Container(
                      width: circleSize,
                      height: circleSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: game.targetColor,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: game.targetColor.withValues(alpha: 0.6),
                            blurRadius: 25,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.2),
                            blurRadius: 0,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                    ),

                    // Progress circle (Simplified for Classic Look)
                    SizedBox(
                      width: circleSize + 12,
                      height: circleSize + 12,
                      child: TweenAnimationBuilder<double>(
                        duration: AppTheme.animationNormal,
                        curve: Curves.easeOutCubic,
                        tween: Tween(begin: 0, end: matchValue / 100),
                        builder: (context, value, child) {
                          return CircularProgressIndicator(
                            value: value,
                            strokeWidth: 6,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.1,
                            ),
                            strokeCap: StrokeCap.round,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color.lerp(
                                AppTheme.neonMagenta,
                                AppTheme.success,
                                value,
                              )!,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: ResponsiveHelper.spacing(context, 12)),

              // Drops counter
              _buildDropsCounter(context),

              // Hint display
              if (currentLevel.hint.isNotEmpty) ...[
                SizedBox(height: ResponsiveHelper.spacing(context, 10)),
                _buildHintDisplay(context, currentLevel.hint),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDropsCounter(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: game.totalDrops,
      builder: (context, drops, child) {
        final remaining = game.maxDrops - drops;
        final isLow = remaining <= 3 && drops > 0;
        final isFull = drops >= game.maxDrops;

        Color statusColor = AppTheme.neonCyan;
        if (isLow) statusColor = AppTheme.electricYellow;
        if (isFull) statusColor = AppTheme.neonMagenta;

        return _buildCapsule(
          context,
          statusColor,
          isFull ? Icons.do_not_disturb_on : Icons.science,
          "$drops / ${game.maxDrops}",
          hasGlow: isFull || isLow,
        );
      },
    );
  }

  Widget _buildCapsule(
    BuildContext context,
    Color color,
    IconData icon,
    String text, {
    bool hasGlow = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: AppTheme.cosmicCard(
        borderRadius: 12,
        fillColor: Colors.black.withValues(alpha: 0.4),
        borderColor: color.withValues(alpha: 0.5),
        borderWidth: 1,
        hasGlow: hasGlow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: ResponsiveHelper.fontSize(context, 14),
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHintDisplay(BuildContext context, String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      constraints: BoxConstraints(
        maxWidth: ResponsiveHelper.screenWidth(context) * 0.7,
      ),
      decoration: AppTheme.cosmicCard(
        borderRadius: 12,
        fillColor: AppTheme.cosmicPurple.withValues(alpha: 0.2),
        borderColor: AppTheme.cosmicPurple.withValues(alpha: 0.5),
        borderWidth: 1,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, color: AppTheme.accentColor, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              hint.getString(context),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: ResponsiveHelper.fontSize(context, 13),
                decoration: TextDecoration.none,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsRow(BuildContext context) {
    final palette = [
      {'color': Colors.black, 'type': 'black', 'label': 'Black'},
      {'color': Colors.red, 'type': 'red', 'label': 'Red'},
      {'color': Colors.green, 'type': 'green', 'label': 'Green'},
      {'color': Colors.blue, 'type': 'blue', 'label': 'Blue'},
      {'color': Colors.white, 'type': 'white', 'label': 'White'},
    ];

    return ValueListenableBuilder<bool>(
      valueListenable: game.dropsLimitReached,
      builder: (context, isLimitReached, _) {
        return Semantics(
          label: AppStrings.colorButtons.getString(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: palette.map((item) {
              final color = item['color'] as Color;
              final type = item['type'] as String;
              final label = item['label'] as String;

              final buttonSize = ResponsiveHelper.responsive<double>(
                context,
                mobile: 56.0, // Slightly larger for better touch targets
                tablet: 64.0,
                desktop: 72.0,
              );

              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveHelper.spacing(context, 8),
                ),
                child: Opacity(
                  opacity: isLimitReached ? 0.4 : 1.0,
                  child: Semantics(
                    label: label,
                    button: true,
                    child: ExcludeSemantics(
                      child: _EnhancedDropButton(
                        onTap: isLimitReached
                            ? null
                            : () {
                                String effectiveType = type;
                                if (game.isControlsInverted) {
                                  if (type == 'red')
                                    effectiveType = 'blue';
                                  else if (type == 'blue')
                                    effectiveType = 'red';
                                }
                                game.addDrop(effectiveType);
                              },
                        size: buttonSize,
                        color: color,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildPowerUpDock(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: AppTheme.cosmicGlass(
        borderRadius: 16,
        borderColor: Colors.white.withValues(alpha: 0.1),
        isInteractive: true,
      ),
      child: ValueListenableBuilder<Map<String, int>>(
        valueListenable: game.helperCounts,
        builder: (context, counts, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelperButton(
                id: 'undo',
                icon: Icons.undo_rounded,
                color: AppTheme.neonCyan,
                count: counts['undo'] ?? 0,
                onTap: () => game.undoLastDrop(),
              ),
              const SizedBox(height: 8),
              _buildHelperButton(
                id: 'extra_drops',
                icon: Icons.add_circle_outline,
                color: AppTheme.neonMagenta,
                count: counts['extra_drops'] ?? 0,
                onTap: () => game.addExtraDrops(),
              ),
              const SizedBox(height: 8),
              _buildHelperButton(
                id: 'help_drop',
                icon: Icons.water_drop_outlined,
                color: AppTheme.success,
                count: counts['help_drop'] ?? 0,
                onTap: () => game.addHelpDrop(),
              ),
              const SizedBox(height: 8),
              _buildHelperButton(
                id: 'reveal_color',
                icon: Icons.visibility_outlined,
                color: AppTheme.electricYellow,
                count: counts['reveal_color'] ?? 0,
                onTap: game.isBlindMode ? () => game.revealHiddenColor() : null,
                isVisible: game.isBlindMode,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHelperButton({
    required String id,
    required IconData icon,
    required Color color,
    required int count,
    required VoidCallback? onTap,
    bool isVisible = true,
  }) {
    final bool hasCount = count > 0;
    String semanticLabel = '';

    // Define semantic labels for each helper
    switch (id) {
      case 'undo':
        semanticLabel =
            '${AppStrings.undo.getString(game.buildContext!)} ($count)';
        break;
      case 'extra_drops':
        semanticLabel =
            '${AppStrings.extraDrops.getString(game.buildContext!)} ($count)';
        break;
      case 'help_drop':
        semanticLabel =
            '${AppStrings.helpDrop.getString(game.buildContext!)} ($count)';
        break;
      case 'reveal_color':
        semanticLabel =
            '${AppStrings.revealColor.getString(game.buildContext!)} ($count)';
        break;
      default:
        semanticLabel = '$id ($count)';
    }

    return Opacity(
      opacity: isVisible ? (hasCount ? 1.0 : 0.4) : 0.0,
      child: IgnorePointer(
        ignoring: !isVisible || !hasCount,
        child: Semantics(
          label: semanticLabel,
          button: true,
          child: ExcludeSemantics(
            child: Stack(
              alignment: Alignment.topRight,
              clipBehavior: Clip.none,
              children: [
                ResponsiveIconButton(
                  onPressed: onTap,
                  icon: icon,
                  size: ResponsiveHelper.responsive(
                    game.buildContext!,
                    mobile: 20,
                    tablet: 22,
                    desktop: 24,
                  ),
                  padding: ResponsiveHelper.responsive(
                    game.buildContext!,
                    mobile: 10,
                    tablet: 12,
                    desktop: 14,
                  ),
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.1),
                  borderColor: color.withValues(alpha: 0.5),
                ),
                if (isVisible)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveHelper.spacing(
                          game.buildContext!,
                          6,
                        ),
                        vertical: ResponsiveHelper.spacing(
                          game.buildContext!,
                          2,
                        ),
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: ResponsiveHelper.fontSize(
                            game.buildContext!,
                            ResponsiveHelper.responsive(
                              game.buildContext!,
                              mobile: 10,
                              tablet: 11,
                              desktop: 12,
                            ),
                          ),
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
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

class _MatchPercentageDisplay extends StatelessWidget {
  final double value;
  final BuildContext context;
  final ColorMixerGame game;

  const _MatchPercentageDisplay({
    required this.value,
    required this.context,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    // Interpolate color from Magenta to Green
    final color = Color.lerp(
      AppTheme.neonMagenta,
      AppTheme.success,
      value / 100,
    )!;

    // Determine if we should show the glitch effect
    final displayValue = game.isUiGlitching
        ? "${(Random().nextInt(99) + 1)}%"
        : (game.isBlackout ? "??%" : "${value.toStringAsFixed(0)}%");

    return TweenAnimationBuilder<double>(
      duration: AppTheme.animationNormal,
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: value),
      builder: (context, animatedValue, child) {
        return Semantics(
          label:
              '${AppStrings.precentageMatch.getString(context)}: ${displayValue}',
          child: Column(
            children: [
              Text(
                displayValue,
                style: TextStyle(
                  fontSize: ResponsiveHelper.fontSize(
                    context,
                    ResponsiveHelper.responsive(
                      context,
                      mobile: 32,
                      tablet: 36,
                      desktop: 40,
                    ),
                  ),
                  color: color,
                  fontWeight: FontWeight.w900,
                  decoration: TextDecoration.none,
                  fontFamily: 'Segoe UI',
                  shadows: [
                    Shadow(color: color.withValues(alpha: 0.6), blurRadius: 15),
                  ],
                ),
              ),
              Text(
                AppStrings.precentageMatch.getString(context).toUpperCase(),
                style: TextStyle(
                  fontSize: ResponsiveHelper.fontSize(
                    context,
                    ResponsiveHelper.responsive(
                      context,
                      mobile: 10,
                      tablet: 12,
                      desktop: 14,
                    ),
                  ),
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TimeAttackTimer extends StatelessWidget {
  final ColorMixerGame game;
  const _TimeAttackTimer({required this.game});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, child) {
        final time = game.timeLeft;
        final progress = (time / game.maxTime).clamp(0.0, 1.0);
        final isLow = time <= 10;
        final color = isLow ? AppTheme.neonMagenta : AppTheme.neonCyan;
        final size = 70.0;

        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          tween: Tween(begin: 1.0, end: isLow ? 1.05 : 1.0),
          builder: (context, scale, child) {
            return Transform.scale(
              scale: isLow
                  ? (1.0 + (progress < 0.2 ? (game.timeLeft % 0.5) * 0.1 : 0.0))
                  : 1.0,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: size + 20,
                    height: size + 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.15),
                          blurRadius: 25,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),

                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.3),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                  ),

                  SizedBox(
                    width: size - 4,
                    height: size - 4,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 4,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryMedium.withValues(alpha: 0.2),
                      ),
                    ),
                  ),

                  SizedBox(
                    width: size - 4,
                    height: size - 4,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      strokeCap: StrokeCap.round,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),

                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time.ceil().toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                          decoration: TextDecoration.none,
                          letterSpacing: -1,
                          shadows: [
                            Shadow(
                              color: color.withValues(alpha: 0.8),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "SEC",
                        style: TextStyle(
                          color: color.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w900,
                          fontSize: 9,
                          decoration: TextDecoration.none,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _EnhancedDropButton extends StatefulWidget {
  final VoidCallback? onTap;
  final double size;
  final Color color;

  const _EnhancedDropButton({
    required this.onTap,
    required this.size,
    required this.color,
  });

  @override
  State<_EnhancedDropButton> createState() => _EnhancedDropButtonState();
}

class _EnhancedDropButtonState extends State<_EnhancedDropButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isLight =
        widget.color == Colors.white ||
        widget.color == Colors.green ||
        widget.color == Colors.cyan;
    final iconColor = isLight
        ? Colors.black.withValues(alpha: 0.6)
        : Colors.white;

    return Semantics(
      button: true,
      child: GestureDetector(
        onTapDown: widget.onTap != null
            ? (_) {
                setState(() => _isPressed = true);
                HapticManager().light();
              }
            : null,
        onTapUp: widget.onTap != null
            ? (_) {
                setState(() => _isPressed = false);
                widget.onTap!();
                AudioManager().playDrop();
              }
            : null,
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.9 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  widget.color.withValues(alpha: 0.9),
                  widget.color,
                  Color.lerp(widget.color, Colors.black, 0.4)!,
                ],
                stops: const [0.0, 0.6, 1.0],
                center: Alignment.topLeft,
              ),
              border: Border.all(
                width: 2,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.6),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 8),
                ),
                if (!_isPressed)
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 5,
                    spreadRadius: -2,
                    offset: const Offset(0, -2),
                  ),
              ],
            ),
            child: Stack(
              children: [
                // Shine
                Positioned(
                  top: widget.size * 0.15,
                  left: widget.size * 0.15,
                  child: Container(
                    width: widget.size * 0.35,
                    height: widget.size * 0.2,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(widget.size),
                    ),
                  ),
                ),

                Center(
                  child: Icon(
                    Icons.water_drop,
                    color: iconColor,
                    size: widget.size * 0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
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

class _ComboDisplay extends StatelessWidget {
  final int combo;

  const _ComboDisplay({required this.combo});

  @override
  Widget build(BuildContext context) {
    Color comboColor = AppTheme.neonCyan;
    if (combo >= 10) {
      comboColor = AppTheme.neonMagenta;
    } else if (combo >= 5) {
      comboColor = AppTheme.neonPurple;
    }

    return ShimmerEffect(
      baseColor: comboColor.withValues(alpha: 0.8),
      highlightColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: comboColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: comboColor.withValues(alpha: 0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              color: comboColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              '${combo}x COMBO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
