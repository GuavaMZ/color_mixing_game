import 'dart:ui';
import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:color_mixing_deductive/helpers/string_manager.dart';
import 'package:color_mixing_deductive/helpers/theme_constants.dart';
import 'package:color_mixing_deductive/helpers/audio_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

class ControlsOverlay extends StatelessWidget {
  const ControlsOverlay({super.key, required this.game});

  final ColorMixerGame game;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, child) => Stack(
        children: [
          // Top section - Target color
          Positioned(
            top:
                ResponsiveHelper.safePadding(context).top +
                ResponsiveHelper.spacing(context, 16),
            left: 0,
            right: 0,
            child: Center(child: _buildTargetColorDisplay(context)),
          ),

          // Pause button (Cosmic Style)
          Positioned(
            top:
                ResponsiveHelper.safePadding(context).top +
                ResponsiveHelper.spacing(context, 16),
            right: ResponsiveHelper.spacing(context, 16),
            child: _CosmicButton(
              onTap: () {
                AudioManager().playButton();
                game.overlays.add('PauseMenu'); // Open new menu
              },
              child: Icon(
                Icons.menu_rounded, // Changed icon
                color: AppTheme.neonCyan,
                size: 24,
              ),
              width: 50,
              height: 50,
              color: AppTheme.cardColor.withValues(alpha: 0.5),
              borderColor: AppTheme.neonCyan.withValues(alpha: 0.5),
              borderRadius: 14,
            ),
          ),

          // ... (TimeAttack code unchanged)

          // Bottom controls area (Compact)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ), // Reduced margin
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  24,
                ), // Slightly smaller radius
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: EdgeInsets.only(
                      bottom: ResponsiveHelper.safePadding(
                        context,
                      ).bottom, // Reduced padding
                      top: 10, // Reduced padding
                      left: 16,
                      right: 16,
                    ),
                    decoration: AppTheme.cosmicGlass(
                      borderRadius: 24,
                      borderColor: Colors.white.withValues(alpha: 0.15),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Match percentage display
                        ValueListenableBuilder<double>(
                          valueListenable: game.matchPercentage,
                          builder: (context, value, child) => Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: _MatchPercentageDisplay(
                              value: value,
                              context: context,
                            ),
                          ),
                        ),

                        // Color buttons row
                        _buildControlsRow(context),

                        // SizedBox(height: ResponsiveHelper.spacing(context, 20)),

                        // Reset button
                        ValueListenableBuilder<int>(
                          valueListenable: game.totalDrops,
                          builder: (context, value, child) {
                            if (value > 0) {
                              return _CosmicButton(
                                onTap: game.resetMixing,
                                color: AppTheme.cardColor.withValues(
                                  alpha: 0.6,
                                ),
                                borderColor: Colors.white.withValues(
                                  alpha: 0.3,
                                ),
                                width: 150,
                                height: 50,
                                borderRadius: 25,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.refresh_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      AppStrings.reset.getString(context),
                                      style: AppTheme.bodyMedium(
                                        context,
                                      ).copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return const SizedBox(height: 50);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetColorDisplay(BuildContext context) {
    final currentLevel = game.levelManager.currentLevel;
    final circleSize = ResponsiveHelper.responsive<double>(
      context,
      mobile: 110.0,
      tablet: 130.0,
      desktop: 150.0,
    );

    return ValueListenableBuilder<double>(
      valueListenable: game.matchPercentage,
      builder: (context, matchValue, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Level info header (Neon Badge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryDark.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.neonCyan.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.neonCyan.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Level number
                  Text(
                    "${AppStrings.levelText.getString(context)} ${currentLevel.id}",
                    style: TextStyle(
                      color: AppTheme.neonCyan,
                      fontSize: ResponsiveHelper.fontSize(context, 16),
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Difficulty stars
                  ...List.generate(
                    currentLevel.difficultyStars,
                    (index) => Icon(
                      Icons.star_rounded,
                      color: AppTheme.electricYellow,
                      size: 16,
                      shadows: [
                        Shadow(
                          color: AppTheme.electricYellow.withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: ResponsiveHelper.spacing(context, 20)),

            // Circular progress indicator around target color
            SizedBox(
              width: circleSize,
              height: circleSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glow Layer
                  Container(
                    width: circleSize,
                    height: circleSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: game.targetColor.withValues(alpha: 0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                  // Progress circle
                  SizedBox(
                    width: circleSize,
                    height: circleSize,
                    child: TweenAnimationBuilder<double>(
                      duration: AppTheme.animationNormal,
                      curve: Curves.easeOutCubic,
                      tween: Tween(begin: 0, end: matchValue / 100),
                      builder: (context, value, child) {
                        return CircularProgressIndicator(
                          value: value,
                          strokeWidth: 4,
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
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

                  // Target color circle with complex border
                  Container(
                    width: circleSize * 0.85,
                    height: circleSize * 0.85,
                    decoration: BoxDecoration(
                      color: game.targetColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                      gradient: RadialGradient(
                        colors: [
                          game.targetColor.withValues(alpha: 0.7),
                          game.targetColor,
                        ],
                        center: Alignment.topLeft,
                        radius: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                  ),
                  // Glossy Reflection
                  Positioned(
                    top: circleSize * 0.15,
                    right: circleSize * 0.2,
                    child: Container(
                      width: circleSize * 0.2,
                      height: circleSize * 0.1,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.all(Radius.circular(50)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: ResponsiveHelper.spacing(context, 12)),

            // Drops counter (Integrated)
            _buildDropsCounter(context),

            // Hint display (if available)
            if (currentLevel.hint.isNotEmpty) ...[
              SizedBox(height: ResponsiveHelper.spacing(context, 10)),
              _buildHintDisplay(context, currentLevel.hint),
            ],
          ],
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

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isFull ? Icons.do_not_disturb_on : Icons.science,
                color: statusColor,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                "$drops / ${game.maxDrops}",
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
      },
    );
  }

  Widget _buildHintDisplay(BuildContext context, String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      constraints: BoxConstraints(
        maxWidth: ResponsiveHelper.screenWidth(context) * 0.7,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cosmicPurple.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.cosmicPurple.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, color: AppTheme.accentColor, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              hint,
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
    final currentLevel = game.levelManager.currentLevel;

    return ValueListenableBuilder<bool>(
      valueListenable: game.dropsLimitReached,
      builder: (context, isLimitReached, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: currentLevel.availableColors.map((color) {
            String type = "";
            if (color == Colors.red) {
              type = "red";
            } else if (color == Colors.green) {
              type = "green";
            } else if (color == Colors.blue) {
              type = "blue";
            }

            final buttonSize = ResponsiveHelper.responsive<double>(
              context,
              mobile: 72.0,
              tablet: 82.0,
              desktop: 90.0,
            );

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.spacing(context, 10),
              ),
              child: Opacity(
                opacity: isLimitReached ? 0.4 : 1.0,
                child: _CosmicButton(
                  onTap: isLimitReached ? null : () => game.addDrop(type),
                  width: buttonSize,
                  height: buttonSize,
                  borderRadius: buttonSize / 2,
                  color: color,
                  isCircular: true,
                  disableDepthConfig: true, // Special sizing for these
                  child: Icon(
                    Icons.water_drop,
                    color: Colors.white,
                    size: buttonSize * 0.45,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _CosmicButton extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;
  final double width;
  final double height;
  final Color color;
  final Color? borderColor;
  final double borderRadius;
  final bool isCircular;
  final bool disableDepthConfig; // For complex shapes

  const _CosmicButton({
    required this.onTap,
    required this.child,
    required this.width,
    required this.height,
    required this.color,
    this.borderColor,
    this.borderRadius = 16,
    this.isCircular = false,
    this.disableDepthConfig = false,
  });

  @override
  State<_CosmicButton> createState() => _CosmicButtonState();
}

class _CosmicButtonState extends State<_CosmicButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final shadowHeight = 4.0;

    // Gradient Logic
    LinearGradient fillGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        widget.color.withValues(alpha: 0.9), // Lighter top
        widget.color, // Normal
        widget.color
            .withValues(alpha: 0.8)
            .withBlue(0)
            .withRed(0)
            .withGreen(0), // Darker bottom
      ],
      stops: [0.0, 0.5, 1.0],
    );

    return GestureDetector(
      onTapDown: widget.onTap != null
          ? (_) => setState(() => _isPressed = true)
          : null,
      onTapUp: widget.onTap != null
          ? (_) => setState(() => _isPressed = false)
          : null,
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: Container(
        width: widget.width,
        height: widget.height + (widget.disableDepthConfig ? 0 : shadowHeight),
        // alignment: Alignment.topCenter,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Shadow Layer (Bottom) - Only if not pressed fully
            if (!widget.disableDepthConfig)
              Positioned(
                left: 2,
                right: 2,
                top: shadowHeight,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                  ),
                ),
              ),

            // Button Face (Top)
            AnimatedContainer(
              duration: const Duration(milliseconds: 60),
              curve: Curves.easeInOut,
              margin: EdgeInsets.only(
                top: _isPressed ? shadowHeight : 0,
                bottom: _isPressed ? 0 : shadowHeight,
              ),
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                gradient: fillGradient,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color:
                      widget.borderColor ?? Colors.white.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  // Inner Glow (Top Edge)
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    offset: Offset(0, 1),
                    blurRadius: 0,
                    spreadRadius: 0, // Inset feel simulated
                  ),
                  // Outer Glow (Neon)
                  if (!_isPressed && widget.onTap != null)
                    BoxShadow(
                      color: (widget.borderColor ?? widget.color).withValues(
                        alpha: 0.3,
                      ),
                      offset: Offset(0, 2),
                      blurRadius: 10,
                    ),
                ],
              ),
              child: Stack(
                children: [
                  // Glossy Shine
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: widget.height * 0.4,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.2),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(widget.borderRadius),
                        ),
                      ),
                    ),
                  ),
                  Center(child: widget.child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchPercentageDisplay extends StatelessWidget {
  final double value;
  final BuildContext context;

  const _MatchPercentageDisplay({required this.value, required this.context});

  @override
  Widget build(BuildContext context) {
    // Interpolate color from Magenta to Green
    final color = Color.lerp(
      AppTheme.neonMagenta,
      AppTheme.success,
      value / 100,
    )!;

    return TweenAnimationBuilder<double>(
      duration: AppTheme.animationNormal,
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: value),
      builder: (context, animatedValue, child) {
        return Column(
          children: [
            // Shadowed Text for Neon effect
            Text(
              "${animatedValue.toStringAsFixed(0)}%",
              style: TextStyle(
                fontSize: ResponsiveHelper.fontSize(context, 48),
                color: color,
                fontWeight: FontWeight.w900,
                decoration: TextDecoration.none,
                fontFamily: 'Segoe UI', // Clean rounded
                shadows: [
                  Shadow(
                    color: color.withValues(alpha: 0.6),
                    offset: const Offset(0, 0),
                    blurRadius: 15,
                  ),
                ],
              ),
            ),
            Text(
              AppStrings.precentageMatch.getString(context).toUpperCase(),
              style: TextStyle(
                fontSize: ResponsiveHelper.fontSize(context, 12),
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
                letterSpacing: 2.0,
              ),
            ),
          ],
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
        final time = game.timeLeft.ceil();
        final isLow = time <= 10;
        final color = isLow ? AppTheme.neonMagenta : AppTheme.neonCyan;

        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          tween: Tween(begin: 1.0, end: isLow ? 1.1 : 1.0),
          builder: (context, scale, child) {
            return Transform.scale(
              scale: isLow ? (1.0 + (game.timeLeft % 1.0) * 0.1) : 1.0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: color, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined, color: color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "$time",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        decoration: TextDecoration.none,
                        shadows: [
                          Shadow(
                            color: color.withValues(alpha: 0.6),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
