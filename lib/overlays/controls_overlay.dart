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
          // Top section - Target color with circular progress
          Positioned(
            top:
                ResponsiveHelper.safePadding(context).top +
                ResponsiveHelper.spacing(context, 16),
            left: 0,
            right: 0,
            child: Center(child: _buildTargetColorDisplay(context)),
          ),

          // Pause button
          Positioned(
            top:
                ResponsiveHelper.safePadding(context).top +
                ResponsiveHelper.spacing(context, 16),
            right: ResponsiveHelper.spacing(context, 16),
            child: _buildPauseButton(context),
          ),

          // Bottom controls area with glass morphism
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: EdgeInsets.only(
                    bottom: ResponsiveHelper.safePadding(context).bottom + 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: ResponsiveHelper.spacing(context, 20)),

                      // Match percentage display with animated counter
                      ValueListenableBuilder<double>(
                        valueListenable: game.matchPercentage,
                        builder: (context, value, child) => Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: _MatchPercentageDisplay(
                            value: value,
                            context: context,
                          ),
                        ),
                      ),

                      // Color buttons row
                      _buildControlsRow(context),

                      SizedBox(height: ResponsiveHelper.spacing(context, 16)),

                      // Reset button (shown when drops > 0)
                      ValueListenableBuilder<int>(
                        valueListenable: game.totalDrops,
                        builder: (context, value, child) {
                          if (value > 0) {
                            return _buildResetButton(context);
                          }
                          return const SizedBox(height: 40);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPauseButton(BuildContext context) {
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
              onTap: () {
                AudioManager().playButton();
                game.overlays.remove('Controls');
                game.overlays.add('LevelMap');
              },
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  Icons.grid_view_rounded,
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

  Widget _buildTargetColorDisplay(BuildContext context) {
    final currentLevel = game.levelManager.currentLevel;
    final circleSize = ResponsiveHelper.responsive<double>(
      context,
      mobile: 100.0,
      tablet: 120.0,
      desktop: 140.0,
    );

    return ValueListenableBuilder<double>(
      valueListenable: game.matchPercentage,
      builder: (context, matchValue, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Level info header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Level number
                  Text(
                    "${AppStrings.levelText.getString(context)} ${currentLevel.id}",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: ResponsiveHelper.fontSize(context, 16),
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Difficulty stars
                  ...List.generate(
                    currentLevel.difficultyStars,
                    (index) => Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 14,
                      shadows: [
                        Shadow(
                          color: Colors.amber.withOpacity(0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: ResponsiveHelper.spacing(context, 16)),

            // Circular progress indicator around target color
            SizedBox(
              width: circleSize,
              height: circleSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
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
                          strokeWidth: 5,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color.lerp(
                              const Color(0xFFF87171),
                              const Color(0xFF4ADE80),
                              value,
                            )!,
                          ),
                        );
                      },
                    ),
                  ),

                  // Target color circle with glow
                  Container(
                    width: circleSize * 0.78,
                    height: circleSize * 0.78,
                    decoration: BoxDecoration(
                      color: game.targetColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: game.targetColor.withOpacity(0.6),
                          blurRadius: 20,
                          spreadRadius: 3,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: ResponsiveHelper.spacing(context, 12)),

            Text(
              AppStrings.targetColorText.getString(context),
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveHelper.fontSize(context, 16),
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
                letterSpacing: 1.2,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),

            SizedBox(height: ResponsiveHelper.spacing(context, 10)),

            // Drops counter
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
        final isLow = remaining <= 2 && drops > 0;

        return AnimatedContainer(
          duration: AppTheme.animationFast,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isLow
                ? Colors.red.withOpacity(0.3)
                : Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isLow
                  ? Colors.red.withOpacity(0.6)
                  : Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.water_drop,
                color: isLow ? Colors.red.shade200 : Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                "$drops / ${game.maxDrops}",
                style: TextStyle(
                  color: isLow ? Colors.red.shade100 : Colors.white,
                  fontSize: ResponsiveHelper.fontSize(context, 16),
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
              if (isLow) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.warning_rounded,
                  color: Colors.red.shade200,
                  size: 18,
                ),
              ],
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
        color: Colors.blue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: Colors.yellow.shade200,
            size: 16,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              hint,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: ResponsiveHelper.fontSize(context, 12),
                decoration: TextDecoration.none,
                fontStyle: FontStyle.italic,
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

  Widget _buildColorButton(
    Color color,
    String type,
    BuildContext context,
    VoidCallback onTap,
  ) {
    final buttonSize = ResponsiveHelper.responsive<double>(
      context,
      mobile: 70.0,
      tablet: 80.0,
      desktop: 90.0,
    );

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.animationFast,
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(0.9), color, color.withOpacity(0.85)],
            center: const Alignment(-0.3, -0.3),
            stops: const [0.0, 0.6, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.6),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.4), width: 3),
        ),
        child: Icon(
          Icons.water_drop,
          color: Colors.white.withOpacity(0.9),
          size: buttonSize * 0.45,
          shadows: [
            Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildResetButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: game.resetMixing,
          borderRadius: BorderRadius.circular(25),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.refresh_rounded,
                  color: Colors.white.withOpacity(0.9),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  AppStrings.reset.getString(context),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: ResponsiveHelper.fontSize(context, 16),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlsRow(BuildContext context) {
    final currentLevel = game.levelManager.currentLevel;
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

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.spacing(context, 10),
          ),
          child: _buildColorButton(
            color,
            type,
            context,
            () => game.addDrop(type),
          ),
        );
      }).toList(),
    );
  }
}

class _MatchPercentageDisplay extends StatelessWidget {
  final double value;
  final BuildContext context;

  const _MatchPercentageDisplay({required this.value, required this.context});

  @override
  Widget build(BuildContext context) {
    final color = Color.lerp(
      const Color(0xFFF87171),
      const Color(0xFF4ADE80),
      value / 100,
    )!;

    return TweenAnimationBuilder<double>(
      duration: AppTheme.animationNormal,
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: value),
      builder: (context, animatedValue, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "${animatedValue.toStringAsFixed(0)}%",
              style: TextStyle(
                fontSize: ResponsiveHelper.fontSize(context, 28),
                color: color,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
                shadows: [
                  Shadow(color: color.withOpacity(0.4), blurRadius: 12),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppStrings.precentageMatch.getString(context),
              style: TextStyle(
                fontSize: ResponsiveHelper.fontSize(context, 16),
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        );
      },
    );
  }
}
