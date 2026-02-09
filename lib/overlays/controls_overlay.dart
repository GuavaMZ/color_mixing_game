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
              width: 50,
              height: 50,
              color: AppTheme.cardColor.withValues(alpha: 0.5),
              borderColor: AppTheme.neonCyan.withValues(alpha: 0.5),
              borderRadius: 14,
              child: Icon(
                Icons.menu_rounded, // Changed icon
                color: AppTheme.neonCyan,
                size: 24,
              ),
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
              // margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: EdgeInsets.only(bottom: 32),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: EdgeInsets.only(
                    bottom: ResponsiveHelper.safePadding(context).bottom + 8,
                    top: 12,
                    left: 12,
                    right: 12,
                  ),
                  decoration: BoxDecoration(
                    // color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                    // border: Border.all(
                    //   color: Colors.white.withValues(alpha: 0.1),
                    //   width: 1,
                    // ),
                    // gradient: LinearGradient(
                    //   begin: Alignment.topCenter,
                    //   end: Alignment.bottomCenter,
                    //   colors: [
                    //     Colors.black.withValues(alpha: 0.6),
                    //     Colors.black.withValues(alpha: 0.8),
                    //   ],
                    // ),
                    // boxShadow: [
                    //   BoxShadow(
                    //     color: AppTheme.neonCyan.withValues(alpha: 0.1),
                    //     blurRadius: 15,
                    //     spreadRadius: -5,
                    //   ),
                    // ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Match percentage display - Integrated & Compact
                      ValueListenableBuilder<double>(
                        valueListenable: game.matchPercentage,
                        builder: (context, value, child) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _MatchPercentageDisplay(
                            value: value,
                            context: context,
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
  }

  Widget _buildTargetColorDisplay(BuildContext context) {
    final currentLevel = game.levelManager.currentLevel;
    final circleSize = ResponsiveHelper.responsive<double>(
      context,
      mobile: 90.0,
      tablet: 110.0,
      desktop: 130.0,
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
              decoration: AppTheme.cosmicCard(
                borderRadius: 20,
                fillColor: AppTheme.primaryDark.withValues(alpha: 0.8),
                borderColor: AppTheme.neonCyan.withValues(alpha: 0.6),
                hasGlow: true,
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
                          backgroundColor: AppTheme.primaryMedium.withValues(
                            alpha: 0.2,
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
          decoration: AppTheme.cosmicCard(
            borderRadius: 12,
            fillColor: Colors.black.withValues(alpha: 0.4),
            borderColor: statusColor.withValues(alpha: 0.5),
            borderWidth: 1,
            hasGlow: isFull || isLow,
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
    // Fixed 5-button palette: Black, Red, Green, Blue, White
    final palette = [
      {'color': Colors.black, 'type': 'black'},
      {'color': Colors.red, 'type': 'red'},
      {'color': Colors.green, 'type': 'green'},
      {'color': Colors.blue, 'type': 'blue'},
      {'color': Colors.white, 'type': 'white'},
    ];

    return ValueListenableBuilder<bool>(
      valueListenable: game.dropsLimitReached,
      builder: (context, isLimitReached, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: palette.map((item) {
            final color = item['color'] as Color;
            final type = item['type'] as String;

            // Reduced button sizes (Minimal)
            final buttonSize = ResponsiveHelper.responsive<double>(
              context,
              mobile: 48.0,
              tablet: 54.0,
              desktop: 60.0,
            );

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.spacing(context, 5),
              ),
              child: Opacity(
                opacity: isLimitReached ? 0.4 : 1.0,
                child: _EnhancedDropButton(
                  onTap: isLimitReached ? null : () => game.addDrop(type),
                  size: buttonSize,
                  color: color,
                ),
              ),
            );
          }).toList(),
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
              // 1. Undo (Cyan)
              _buildHelperButton(
                id: 'undo',
                icon: Icons.undo_rounded,
                color: AppTheme.neonCyan,
                count: counts['undo'] ?? 0,
                onTap: () => game.undoLastDrop(),
              ),
              const SizedBox(height: 8),

              // 2. Extra Drops (Magenta)
              _buildHelperButton(
                id: 'extra_drops',
                icon: Icons.add_circle_outline,
                color: AppTheme.neonMagenta,
                count: counts['extra_drops'] ?? 0,
                onTap: () => game.addExtraDrops(),
              ),
              const SizedBox(height: 8),

              // 3. Drop Color (Green)
              _buildHelperButton(
                id: 'help_drop',
                icon: Icons.water_drop_outlined,
                color: AppTheme.success,
                count: counts['help_drop'] ?? 0,
                onTap: () => game.addHelpDrop(),
              ),
              const SizedBox(height: 8),

              // 4. Reveal (Yellow)
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

    return Opacity(
      opacity: isVisible ? (hasCount ? 1.0 : 0.3) : 0.0,
      child: IgnorePointer(
        ignoring: !isVisible || !hasCount,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            _CosmicButton(
              onTap: onTap,
              width: 40,
              height: 40,
              color: color.withValues(alpha: 0.15),
              borderColor: color.withValues(alpha: 0.5),
              borderRadius: 12,
              child: Icon(icon, color: color, size: 20),
            ),
            if (isVisible)
              Transform.translate(
                offset: const Offset(4, -4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    count.toString(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
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
        Color.lerp(widget.color, Colors.black, 0.3)!, // Proper darkening
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
                fontSize: ResponsiveHelper.fontSize(context, 32),
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
                  // Outer Ambient Glow
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

                  // Glass Background for Timer
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

                  // Background ring (track)
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

                  // Progress ring (Neon)
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

                  // The "Clock Hand" Dot
                  // Rotate it based on progress
                  Transform.rotate(
                    angle: (1.0 - progress) * 2 * 3.14159,
                    child: SizedBox(
                      width: size - 4,
                      height: size - 4,
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              margin: const EdgeInsets.only(top: 0),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: color,
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Countdown Text
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

// Enhanced Drop Button with Premium Styling
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

    return GestureDetector(
      onTapDown: widget.onTap != null
          ? (_) => setState(() => _isPressed = true)
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
        scale: _isPressed ? 0.92 : 1.0,
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
                Color.lerp(widget.color, Colors.black, 0.3)!,
              ],
              stops: const [0.0, 0.6, 1.0],
              center: Alignment.topLeft,
            ),
            border: Border.all(
              width: 2.5,
              color: widget.color == Colors.black
                  ? Colors.grey.shade700
                  : Colors.white.withValues(alpha: 0.4),
            ),
            boxShadow: [
              // Colored glow
              BoxShadow(
                color: widget.color.withValues(alpha: 0.4),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 2),
              ),
              // Dark shadow for depth
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
              // Inner highlight
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.2),
                blurRadius: 0,
                spreadRadius: -2,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Glossy shine
              Positioned(
                top: widget.size * 0.15,
                left: widget.size * 0.15,
                child: Container(
                  width: widget.size * 0.35,
                  height: widget.size * 0.2,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(widget.size),
                  ),
                ),
              ),
              // Water drop icon
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
    );
  }
}
