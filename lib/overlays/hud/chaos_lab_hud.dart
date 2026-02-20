import 'dart:ui';
import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:color_mixing_deductive/helpers/theme_constants.dart';
import 'package:color_mixing_deductive/helpers/audio_manager.dart';
import 'package:color_mixing_deductive/helpers/visual_effects.dart'; // ShimmerEffect
import 'package:color_mixing_deductive/components/ui/responsive_components.dart'; // ResponsiveHelper
import 'package:flutter/material.dart';
import 'package:color_mixing_deductive/helpers/string_manager.dart';
import 'package:color_mixing_deductive/core/color_science.dart';
import 'package:flutter_localization/flutter_localization.dart';

class ChaosLabHUD extends StatefulWidget {
  const ChaosLabHUD({super.key, required this.game});

  final ColorMixerGame game;

  @override
  State<ChaosLabHUD> createState() => _ChaosLabHUDState();
}

class _ChaosLabHUDState extends State<ChaosLabHUD>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.game,
      builder: (context, child) {
        // Adjust pulse speed based on stability
        final stability = widget.game.chaosStability.clamp(0.0, 1.0);
        _pulseController.duration = Duration(
          milliseconds: (300 + stability * 700).toInt(),
        );

        return Stack(
          children: [
            // Warning Panel - Top Center
            Positioned(
              top:
                  ResponsiveHelper.safePadding(context).top +
                  ResponsiveHelper.spacing(context, 16),
              left: 0,
              right: 0,
              child: _buildWarningPanel(context),
            ),

            // Pause button using ResponsiveIconButton
            Positioned(
              top:
                  ResponsiveHelper.safePadding(context).top +
                  ResponsiveHelper.spacing(context, 16),
              right: ResponsiveHelper.spacing(context, 16),
              child: ResponsiveIconButton(
                onPressed: () {
                  AudioManager().playButton();
                  widget.game.overlays.add('PauseMenu');
                },
                icon: Icons.menu_rounded,
                color: Colors.redAccent,
                backgroundColor: Colors.red.withValues(alpha: 0.2),
                borderColor: Colors.red.withValues(alpha: 0.6),
                size: 24,
              ),
            ),

            // Chaos Timer - Top Left
            Positioned(
              top:
                  ResponsiveHelper.safePadding(context).top +
                  ResponsiveHelper.spacing(context, 16),
              left: ResponsiveHelper.spacing(context, 16),
              child: _buildChaosTimer(context),
            ),

            // Chaos Intensity Indicator - Below Timer
            Positioned(
              top:
                  ResponsiveHelper.safePadding(context).top +
                  ResponsiveHelper.spacing(context, 80),
              left: ResponsiveHelper.spacing(context, 16),
              child: _buildChaosIntensity(context),
            ),

            // Instability Meter - Right Side
            Positioned(
              right: ResponsiveHelper.spacing(context, 16),
              top: MediaQuery.of(context).size.height * 0.35,
              child: _buildInstabilityMeter(context),
            ),

            // Bottom controls
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.only(bottom: 32),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: EdgeInsets.only(
                      bottom: ResponsiveHelper.safePadding(context).bottom + 8,
                      top: 12,
                      left: 12,
                      right: 12,
                    ),
                    decoration: AppTheme.cosmicGlass(
                      borderRadius: 24,
                      borderColor: Colors.red.withValues(
                        alpha: 0.3 * (1 - stability),
                      ), // Red glow when unstable
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Match percentage
                        ValueListenableBuilder<double>(
                          valueListenable: widget.game.matchPercentage,
                          builder: (context, value, child) =>
                              _buildMatchDisplay(context, value),
                        ),
                        const SizedBox(height: 8),
                        // Color controls
                        _buildColorControls(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Stability Recovered Toast
            Positioned(
              right: ResponsiveHelper.spacing(context, 80),
              top: MediaQuery.of(context).size.height * 0.45,
              child: ValueListenableBuilder<bool>(
                valueListenable: widget.game.stabilityRecovered,
                builder: (context, _, __) {
                  return _StabilityRecoveryToast(key: UniqueKey());
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWarningPanel(BuildContext context) {
    if (widget.game.chaosStability >= 0.5 &&
        !widget.game.isBlackout &&
        !widget.game.isMirrored &&
        !widget.game.hasWind) {
      return const SizedBox.shrink(); // Hide if stable and no disasters
    }

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Center(
            child: ShimmerEffect(
              baseColor: Colors.red,
              highlightColor: Colors.yellow,
              period: const Duration(milliseconds: 1000),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.withValues(alpha: 0.8),
                      Colors.orange.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.yellow, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.6),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Warning icon (animated)
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.yellow,
                            size: 32,
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 4),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    // Warning text
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.game.chaosStability < 0.3
                                ? 'CRITICAL SYSTEM FAILURE'
                                : 'SYSTEM INSTABILITY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: ResponsiveHelper.fontSize(context, 16),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              decoration: TextDecoration.none,
                              shadows: const [
                                Shadow(color: Colors.black, blurRadius: 4),
                              ],
                            ),
                          ),
                          Text(
                            _getCurrentDisasterText(),
                            style: TextStyle(
                              color: widget.game.chaosStability < 0.3
                                  ? Colors.redAccent
                                  : Colors.yellowAccent,
                              fontSize: ResponsiveHelper.fontSize(context, 12),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              decoration: TextDecoration.none,
                            ),
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
      },
    );
  }

  Widget _buildChaosTimer(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ValueNotifier(widget.game.timeLeft.toInt()),
      builder: (context, time, child) {
        final isLow = time <= 10;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: AppTheme.cosmicCard(
            borderRadius: 12,
            fillColor: Colors.black.withValues(alpha: 0.7),
            borderColor: isLow ? Colors.red : Colors.orange,
            borderWidth: 2,
            hasGlow: true,
            glowColor: isLow ? Colors.red : Colors.orange,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer,
                color: isLow ? Colors.red : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              if (isLow)
                ShimmerEffect(
                  baseColor: Colors.red,
                  highlightColor: Colors.white,
                  child: Text(
                    '${time}s',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: ResponsiveHelper.fontSize(context, 18),
                      fontWeight: FontWeight.w900,
                      decoration: TextDecoration.none,
                    ),
                  ),
                )
              else
                Text(
                  '${time}s',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveHelper.fontSize(context, 18),
                    fontWeight: FontWeight.w900,
                    decoration: TextDecoration.none,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChaosIntensity(BuildContext context) {
    final stability = widget.game.chaosStability.clamp(0.0, 1.0);
    final intensity = ((1.0 - stability) * 5).ceil().clamp(1, 5);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: AppTheme.cosmicCard(
        borderRadius: 12,
        fillColor: Colors.black.withValues(alpha: 0.7),
        borderColor: _getIntensityColor(intensity).withValues(alpha: 0.6),
        borderWidth: 2,
        hasGlow: true,
        glowColor: _getIntensityColor(intensity),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CHAOS',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: ResponsiveHelper.fontSize(context, 10),
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 8),
              ...List.generate(5, (index) {
                final isActive = index < intensity;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Icon(
                        isActive
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded, // Improved icon
                        color: isActive
                            ? _getIntensityColor(intensity)
                            : Colors.grey.withValues(alpha: 0.3),
                        size: isActive ? 14 * _pulseAnimation.value : 14,
                        shadows: isActive
                            ? [
                                Shadow(
                                  color: _getIntensityColor(intensity),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      );
                    },
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 4),
          ValueListenableBuilder<String>(
            valueListenable: widget.game.chaosPhase,
            builder: (context, phase, child) {
              String phaseText = phase;
              Color phaseColor = _getIntensityColor(intensity);
              if (phase == 'STABLE')
                phaseText = AppStrings.stable.getString(context);
              if (phase == 'CAUTION')
                phaseText = AppStrings.caution.getString(context);
              if (phase == 'CRITICAL')
                phaseText = AppStrings.critical.getString(context);

              return Text(
                phaseText,
                style: TextStyle(
                  color: phaseColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  fontFamily: 'monospace',
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getIntensityColor(int intensity) {
    switch (intensity) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.yellow;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.deepOrange;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInstabilityMeter(BuildContext context) {
    final stability = widget.game.chaosStability.clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: 50,
          height: 200,
          padding: const EdgeInsets.all(8),
          decoration: AppTheme.cosmicCard(
            borderRadius: 12,
            fillColor: Colors.black.withValues(alpha: 0.7),
            borderColor: stability < 0.3
                ? Colors.red.withValues(
                    alpha: 0.5 + _pulseAnimation.value * 0.3,
                  )
                : Colors.white.withValues(alpha: 0.2),
            borderWidth: stability < 0.3 ? 3 : 2,
            hasGlow: stability < 0.3,
            glowColor: Colors.red,
          ),
          child: Column(
            children: [
              Icon(
                Icons.science, // Corrected icon
                color: stability < 0.3 ? Colors.red : Colors.orange,
                size: 20,
              ),
              const SizedBox(height: 4),
              // Stability percentage
              Text(
                '${(stability * 100).toInt()}%',
                style: TextStyle(
                  color: stability < 0.3 ? Colors.red : Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'λ ${ColorScience.estimateWavelength(widget.game.targetColor).toInt()}nm',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 8,
                  fontFamily: 'monospace',
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Background
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    // Threshold markers
                    ...[0.3, 0.5, 0.7].map((threshold) {
                      return Positioned(
                        bottom: threshold * (200 - 60),
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      );
                    }),
                    // Fill
                    FractionallySizedBox(
                      heightFactor: stability,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: stability < 0.3
                                ? [Colors.red, Colors.deepOrange]
                                : stability < 0.5
                                ? [Colors.orange, Colors.yellow]
                                : [Colors.blue, Colors.cyan, Colors.white],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: stability < 0.3
                              ? [
                                  BoxShadow(
                                    color: Colors.red.withValues(alpha: 0.5),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.cyan.withValues(alpha: 0.3),
                                    blurRadius: 5,
                                  ),
                                ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMatchDisplay(BuildContext context, double value) {
    final color = Color.lerp(Colors.red, Colors.green, value / 100)!;

    return Column(
      children: [
        Text(
          '${value.toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: ResponsiveHelper.fontSize(context, 32),
            color: color,
            fontWeight: FontWeight.w900,
            decoration: TextDecoration.none,
            shadows: [
              Shadow(color: color.withValues(alpha: 0.6), blurRadius: 15),
            ],
          ),
        ),
        Text(
          'MATCH',
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
  }

  Widget _buildColorControls(BuildContext context) {
    final palette = [
      {'color': Colors.black, 'type': 'black'},
      {'color': Colors.red, 'type': 'red'},
      {'color': Colors.green, 'type': 'green'},
      {'color': Colors.blue, 'type': 'blue'},
      {'color': Colors.white, 'type': 'white'},
    ];

    return ValueListenableBuilder<bool>(
      valueListenable: widget.game.dropsLimitReached,
      builder: (context, isLimitReached, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: palette.map((item) {
            final color = item['color'] as Color;
            final type = item['type'] as String;
            final buttonSize = 48.0;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Opacity(
                opacity: isLimitReached ? 0.4 : 1.0,
                child: _buildColorButton(
                  context,
                  color,
                  type,
                  buttonSize,
                  isLimitReached,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildColorButton(
    BuildContext context,
    Color color,
    String type,
    double size,
    bool isDisabled,
  ) {
    return GestureDetector(
      onTap: isDisabled ? null : () => widget.game.addDrop(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.9),
              color,
              Color.lerp(color, Colors.black, 0.3)!,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10),
          ],
        ),
      ),
    );
  }

  String _getCurrentDisasterText() {
    if (widget.game.isBlackout) return 'POWER FAILURE DETECTED';
    if (widget.game.isMirrored) return 'OPTICAL AXIS INVERTED';
    if (widget.game.hasWind) return 'HIGH PRESSURE LEAK';
    return 'STABILITY DECREASING';
  }
}

class _StabilityRecoveryToast extends StatefulWidget {
  const _StabilityRecoveryToast({super.key});

  @override
  State<_StabilityRecoveryToast> createState() =>
      _StabilityRecoveryToastState();
}

class _StabilityRecoveryToastState extends State<_StabilityRecoveryToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -1),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: SlideTransition(
            position: _slide,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green, width: 1.5),
              ),
              child: Text(
                AppStrings.stabilityRecovered.getString(context).toUpperCase(),
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
