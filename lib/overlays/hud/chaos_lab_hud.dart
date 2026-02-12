import 'dart:ui';
import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:color_mixing_deductive/helpers/theme_constants.dart';
import 'package:color_mixing_deductive/helpers/audio_manager.dart';
import 'package:flutter/material.dart';

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

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
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

            // Pause button
            Positioned(
              top:
                  ResponsiveHelper.safePadding(context).top +
                  ResponsiveHelper.spacing(context, 16),
              right: ResponsiveHelper.spacing(context, 16),
              child: _buildPauseButton(context),
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
          ],
        );
      },
    );
  }

  Widget _buildWarningPanel(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red.withValues(alpha: 0.9),
                  Colors.orange.withValues(alpha: 0.9),
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
                        shadows: [Shadow(color: Colors.black, blurRadius: 4)],
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
                            : 'SYSTEM FAILURE',
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
                              : Colors.yellow,
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
        );
      },
    );
  }

  Widget _buildPauseButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AudioManager().playButton();
        widget.game.overlays.add('PauseMenu');
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.6),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(color: Colors.red.withValues(alpha: 0.4), blurRadius: 15),
          ],
        ),
        child: const Icon(Icons.menu_rounded, color: Colors.red, size: 24),
      ),
    );
  }

  Widget _buildChaosTimer(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ValueNotifier(widget.game.timeLeft.toInt()),
      builder: (context, time, child) {
        final isLow = time <= 10;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isLow ? Colors.red : Colors.orange,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isLow ? Colors.red : Colors.orange).withValues(
                  alpha: 0.4,
                ),
                blurRadius: 15,
              ),
            ],
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
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getIntensityColor(intensity).withValues(alpha: 0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _getIntensityColor(intensity).withValues(alpha: 0.4),
            blurRadius: 15,
          ),
        ],
      ),
      child: Row(
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
                    isActive ? Icons.star : Icons.star_border,
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
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.red.withValues(
                alpha: stability < 0.3
                    ? 0.5 + _pulseAnimation.value * 0.3
                    : 0.5,
              ),
              width: stability < 0.3 ? 3 : 2,
            ),
            boxShadow: stability < 0.3
                ? [
                    BoxShadow(
                      color: Colors.red.withValues(
                        alpha: _pulseAnimation.value * 0.5,
                      ),
                      blurRadius: 20,
                      spreadRadius: 3,
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              Icon(
                Icons.science_outlined,
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
                          color: Colors.white.withValues(alpha: 0.2),
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
                              : [],
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
      child: Container(
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
    if (widget.game.isLeaking) return 'STRUCTURAL BREACH';
    if (widget.game.isControlsInverted) return 'INTERFACE REVERSED';
    if (widget.game.isEvaporating) return 'THERMAL OVERLOAD';
    if (widget.game.isGravityFlux) return 'GRAVITY ANOMALY';
    if (widget.game.isUiGlitching) return 'DATA CORRUPTION';
    return 'INSTABILITY DETECTED';
  }
}
