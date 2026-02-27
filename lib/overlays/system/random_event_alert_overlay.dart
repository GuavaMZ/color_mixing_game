import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:color_mixing_deductive/helpers/event_rarity_system.dart';
import 'package:color_mixing_deductive/helpers/haptic_manager.dart';
import 'package:color_mixing_deductive/helpers/theme_constants.dart';
import 'package:flutter/material.dart';

/// Cinematic random event alert overlay.
/// Phase 1 (0–1.0 s): pulsing red vignette ring + "INCOMING ANOMALY" text.
/// Phase 2 (1.0–2.2 s): banner slides in naming the event with icon+rarity badge.
/// Auto-dismisses and hands control to game after 2.2 s.
class RandomEventAlertOverlay extends StatefulWidget {
  final ColorMixerGame game;

  const RandomEventAlertOverlay({super.key, required this.game});

  @override
  State<RandomEventAlertOverlay> createState() =>
      _RandomEventAlertOverlayState();
}

class _RandomEventAlertOverlayState extends State<RandomEventAlertOverlay>
    with TickerProviderStateMixin {
  // Phase 1 pulse animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Phase 2 banner slide-in
  late AnimationController _bannerController;
  late Animation<Offset> _bannerSlide;
  late Animation<double> _bannerFade;

  // Phase tracking
  bool _showBanner = false;
  EventConfig? _event;

  @override
  void initState() {
    super.initState();

    // Grab event immediately so it renders correctly
    _event = widget.game.pendingEvent.value;

    // Phase 1: pulse ring (repeats for 1.0 s)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    HapticManager().vibrate();

    // Transition to phase 2 after 1.0 s
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() => _showBanner = true);
      _bannerController.forward();
    });

    // Phase 2: banner slide
    _bannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bannerSlide = Tween<Offset>(begin: const Offset(0, -1.5), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _bannerController, curve: Curves.easeOutBack),
        );
    _bannerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bannerController, curve: Curves.easeOut),
    );

    // Auto-dismiss after 2.2 s total
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      widget.game.overlays.remove('RandomEventAlert');
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          // Phase 1: Pulsing red vignette ring
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _VignettePainter(
                  intensity: _pulseAnimation.value,
                  color: _event?.isPositive == true
                      ? AppTheme.success
                      : Colors.red,
                ),
              );
            },
          ),

          // Phase 1: INCOMING ANOMALY text
          if (!_showBanner)
            Center(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: (0.5 + _pulseAnimation.value * 0.5).clamp(
                      0.0,
                      1.0,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              (_event?.isPositive == true
                                      ? AppTheme.success
                                      : Colors.redAccent)
                                  .withValues(alpha: 0.8),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (_event?.isPositive == true
                                        ? AppTheme.success
                                        : Colors.red)
                                    .withValues(
                                      alpha: 0.3 + _pulseAnimation.value * 0.4,
                                    ),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        _event?.isPositive == true
                            ? '✦ POSITIVE ANOMALY'
                            : '⚠  INCOMING ANOMALY',
                        style: TextStyle(
                          color: _event?.isPositive == true
                              ? AppTheme.success
                              : Colors.redAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4.0,
                          decoration: TextDecoration.none,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.8),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // Phase 2: Event reveal banner
          if (_showBanner && _event != null)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.2,
              left: 24,
              right: 24,
              child: SlideTransition(
                position: _bannerSlide,
                child: FadeTransition(
                  opacity: _bannerFade,
                  child: _EventBanner(event: _event!),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Event Banner Card ─────────────────────────────────────────────────────

class _EventBanner extends StatelessWidget {
  final EventConfig event;
  const _EventBanner({required this.event});

  Color get _rarityColor {
    switch (event.rarity) {
      case EventRarity.common:
        return AppTheme.neonCyan;
      case EventRarity.uncommon:
        return AppTheme.electricYellow;
      case EventRarity.rare:
        return AppTheme.neonPurple;
      case EventRarity.epic:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = event.isPositive ? AppTheme.success : _rarityColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.8), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 30,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row: icon + event name
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                event.icon,
                style: const TextStyle(
                  fontSize: 40,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(width: 14),
              Flexible(
                child: Text(
                  event.label.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    decoration: TextDecoration.none,
                    shadows: [
                      Shadow(
                        color: color.withValues(alpha: 0.8),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Rarity badge row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RarityBadge(rarity: event.rarity, color: color),
              if (event.isPositive) ...[
                const SizedBox(width: 8),
                _buildTag('BONUS EVENT', AppTheme.success),
              ],
            ],
          ),

          const SizedBox(height: 10),

          // Divider line
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  color.withValues(alpha: 0.6),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Flavor sub-text
          Text(
            event.isPositive
                ? 'A rare opportunity has emerged in the lab!'
                : 'Brace yourself — conditions are deteriorating!',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.8,
              decoration: TextDecoration.none,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

class _RarityBadge extends StatelessWidget {
  final EventRarity rarity;
  final Color color;
  const _RarityBadge({required this.rarity, required this.color});

  String get _label {
    switch (rarity) {
      case EventRarity.common:
        return '● COMMON';
      case EventRarity.uncommon:
        return '◆ UNCOMMON';
      case EventRarity.rare:
        return '★ RARE';
      case EventRarity.epic:
        return '☠ EPIC';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

// ─── Vignette Painter ──────────────────────────────────────────────────────

class _VignettePainter extends CustomPainter {
  final double intensity;
  final Color color;

  _VignettePainter({required this.intensity, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.9,
        colors: [
          Colors.transparent,
          Colors.transparent,
          color.withValues(alpha: 0.08 + intensity * 0.35),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, paint);

    // Draw pulsing border ring
    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.15 + intensity * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6 + intensity * 10;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(3), const Radius.circular(0)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(_VignettePainter oldDelegate) =>
      oldDelegate.intensity != intensity || oldDelegate.color != color;
}
