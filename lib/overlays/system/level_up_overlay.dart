import 'dart:math';
import 'package:flutter/material.dart';
import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:color_mixing_deductive/core/xp_manager.dart';
import 'package:color_mixing_deductive/helpers/audio_manager.dart';
import 'package:color_mixing_deductive/helpers/string_manager.dart';
import 'package:color_mixing_deductive/helpers/theme_constants.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:color_mixing_deductive/helpers/global_variables.dart';

/// Full-screen animated overlay displayed when the player levels up.
///
/// Flow:
///  1. Slides in from below with particle burst
///  2. Shows new level + rank title with a shimmer scanner effect
///  3. Displays coins bonus awarded (if any)
///  4. Auto-dismisses after 3 seconds (or on tap)
class LevelUpOverlay extends StatefulWidget {
  final ColorMixerGame game;
  final int newLevel;
  final int coinsBonus;

  const LevelUpOverlay({
    super.key,
    required this.game,
    required this.newLevel,
    required this.coinsBonus,
  });

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _cardController;
  late AnimationController _pulseController;
  late AnimationController _particleController;

  late Animation<double> _bgFade;
  late Animation<Offset> _cardSlide;
  late Animation<double> _cardScale;
  late Animation<double> _pulse;
  late Animation<double> _particleFade;

  final List<_Particle> _particles = [];
  final Random _rng = GlobalConstants.sharedRandom;

  @override
  void initState() {
    super.initState();
    AudioManager().playButton();

    // Generate particles
    for (int i = 0; i < 30; i++) {
      _particles.add(_Particle(rng: _rng));
    }

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..forward();

    _bgFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _bgController, curve: Curves.easeOut));
    _cardSlide = Tween<Offset>(begin: const Offset(0, 1.5), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _cardController, curve: Curves.easeOutBack),
        );
    _cardScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutBack),
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.06).animate(_pulseController);
    _particleFade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _particleController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _bgController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _cardController.forward();
    });

    // Auto-dismiss
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _dismiss();
    });
  }

  void _dismiss() {
    _bgController.reverse();
    _cardController.reverse().then((_) {
      if (mounted) {
        widget.game.overlays.remove('LevelUp');
      }
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _cardController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final xp = XpManager.instance;
    final isMilestone = widget.newLevel % 10 == 0;
    final accentColor = isMilestone
        ? AppTheme.electricYellow
        : AppTheme.neonCyan;

    return GestureDetector(
      onTap: _dismiss,
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _bgController,
            _cardController,
            _pulseController,
            _particleController,
          ]),
          builder: (context, _) {
            return Stack(
              children: [
                // ── Dark Overlay ─────────────────────────────────────────────
                FadeTransition(
                  opacity: _bgFade,
                  child: Container(color: Colors.black.withValues(alpha: 0.8)),
                ),

                // ── Particles ─────────────────────────────────────────────────
                FadeTransition(
                  opacity: _particleFade,
                  child: CustomPaint(
                    size: MediaQuery.of(context).size,
                    painter: _ParticlePainter(
                      particles: _particles,
                      progress: _particleController.value,
                      color: accentColor,
                    ),
                  ),
                ),

                // ── Central Card ─────────────────────────────────────────────
                Center(
                  child: SlideTransition(
                    position: _cardSlide,
                    child: ScaleTransition(
                      scale: _cardScale,
                      child: ScaleTransition(
                        scale: _pulse,
                        child: _buildCard(
                          context,
                          xp,
                          accentColor,
                          isMilestone,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Tap anywhere hint ─────────────────────────────────────────
                Positioned(
                  bottom: 48,
                  left: 0,
                  right: 0,
                  child: FadeTransition(
                    opacity: _bgFade,
                    child: Center(
                      child: Text(
                        AppStrings.tapToContinue.getString(context),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    XpManager xp,
    Color accentColor,
    bool isMilestone,
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryMedium, AppTheme.primaryDark],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: accentColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.5),
              blurRadius: 40,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Label ───────────────────────────────────────────────────────
            Text(
              isMilestone
                  ? AppStrings.milestoneUnlocked.getString(context)
                  : AppStrings.levelUp.getString(context),
              style: TextStyle(
                color: accentColor,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 3.0,
              ),
            ),
            const SizedBox(height: 16),

            // ── Level Badge ──────────────────────────────────────────────────
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.3),
                    accentColor.withValues(alpha: 0.05),
                  ],
                ),
                border: Border.all(color: accentColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${widget.newLevel}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    shadows: [Shadow(color: accentColor, blurRadius: 12)],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Rank Title ───────────────────────────────────────────────────
            Text(xp.rankEmoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              xp.rankTitleKey.getString(context),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // ── XP Progress Bar ─────────────────────────────────────────────
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${AppStrings.levelLabel.getString(context)} ${widget.newLevel}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      '${AppStrings.levelLabel.getString(context)} ${widget.newLevel + 1}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.0, // Fresh start after level-up
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentColor,
                            accentColor.withValues(alpha: 0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Coins Bonus ─────────────────────────────────────────────────
            if (widget.coinsBonus > 0) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.electricYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.electricYellow.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.monetization_on_rounded,
                      color: Color(0xFFFFD700),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.coinsBonusAtLevelUp
                          .getString(context)
                          .replaceFirst('%s', '${widget.coinsBonus}'),
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Particle System ──────────────────────────────────────────────────────────

class _Particle {
  final double x;
  final double y;
  final double speed;
  final double angle;
  final double size;
  final double twist;

  _Particle({required Random rng})
    : x = 0.5 + (rng.nextDouble() - 0.5) * 0.3,
      y = 0.45 + (rng.nextDouble() - 0.5) * 0.2,
      speed = 0.2 + rng.nextDouble() * 0.5,
      angle = rng.nextDouble() * 2 * pi,
      size = 3 + rng.nextDouble() * 5,
      twist = (rng.nextDouble() - 0.5) * 2;
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color color;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final dx = cos(p.angle) * p.speed * progress * size.width * 0.6;
      final dy = sin(p.angle) * p.speed * progress * size.height * 0.6;
      final cx = p.x * size.width + dx;
      final cy = p.y * size.height + dy;
      final alpha = (1.0 - progress * progress).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(cx, cy), p.size * (1 - progress * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
