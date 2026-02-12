import 'dart:math';
import 'package:flutter/material.dart';

/// Manages visual effects like particles, confetti, and shimmers
class VisualEffectManager {
  static final VisualEffectManager _instance = VisualEffectManager._internal();
  factory VisualEffectManager() => _instance;
  VisualEffectManager._internal();

  /// Create a confetti explosion at a specific position
  List<Widget> createConfetti(Offset position, {int count = 20}) {
    final random = Random();
    return List.generate(count, (index) {
      final angle = random.nextDouble() * 2 * pi;
      final speed = random.nextDouble() * 100 + 50;
      final color = Colors.primaries[random.nextInt(Colors.primaries.length)];

      return ConfettiParticle(
        position: position,
        angle: angle,
        speed: speed,
        color: color,
      );
    });
  }
}

class ConfettiParticle extends StatefulWidget {
  final Offset position;
  final double angle;
  final double speed;
  final Color color;

  const ConfettiParticle({
    super.key,
    required this.position,
    required this.angle,
    required this.speed,
    required this.color,
  });

  @override
  State<ConfettiParticle> createState() => _ConfettiParticleState();
}

class _ConfettiParticleState extends State<ConfettiParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Offset _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _offset = Offset(
      cos(widget.angle) * widget.speed,
      sin(widget.angle) * widget.speed,
    );

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
      animation: _animation,
      builder: (context, child) {
        final move = _offset * _animation.value;
        return Positioned(
          left: widget.position.dx + move.dx,
          top: widget.position.dy + move.dy,
          child: Opacity(
            opacity: 1.0 - _animation.value,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A shimmer effect widget
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration period;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.baseColor = Colors.white,
    this.highlightColor = Colors.white,
    this.period = const Duration(milliseconds: 1500),
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.period, vsync: this)
      ..repeat();
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
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Animated star field background
class StarField extends StatefulWidget {
  final int starCount;
  final Color color;

  const StarField({super.key, this.starCount = 50, this.color = Colors.white});

  @override
  State<StarField> createState() => _StarFieldState();
}

class _StarFieldState extends State<StarField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Star> _stars = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 20000), // Very slow rotation
      vsync: this,
    )..repeat();

    for (int i = 0; i < widget.starCount; i++) {
      _stars.add(_generateStar());
    }
  }

  _Star _generateStar() {
    return _Star(
      x: _random.nextDouble(),
      y: _random.nextDouble(),
      size: _random.nextDouble() * 3 + 1,
      opacity: _random.nextDouble() * 0.7 + 0.3,
      speed: _random.nextDouble() * 0.2 + 0.05,
    );
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
        return CustomPaint(
          size: Size.infinite,
          painter: _StarPainter(
            stars: _stars,
            color: widget.color,
            animationValue: _controller.value,
          ),
        );
      },
    );
  }
}

class _Star {
  double x;
  double y;
  double size;
  double opacity;
  double speed;

  _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.speed,
  });
}

class _StarPainter extends CustomPainter {
  final List<_Star> stars;
  final Color color;
  final double animationValue;

  _StarPainter({
    required this.stars,
    required this.color,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    for (var star in stars) {
      // Simple parallax scrolling effect
      double dy = (star.y + animationValue * star.speed) % 1.0;

      paint.color = color.withValues(alpha: star.opacity);
      canvas.drawCircle(
        Offset(star.x * size.width, dy * size.height),
        star.size / 2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) => true;
}

/// A container that fills with a liquid animation
class LiquidFill extends StatefulWidget {
  final double value; // 0.0 to 1.0
  final Color color;
  final Widget? child;

  const LiquidFill({
    super.key,
    required this.value,
    required this.color,
    this.child,
  });

  @override
  State<LiquidFill> createState() => _LiquidFillState();
}

class _LiquidFillState extends State<LiquidFill>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
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
        return ClipPath(
          clipper: _WaveClipper(
            value: widget.value,
            wavePhase: _controller.value * 2 * pi,
          ),
          child: Container(
            color: widget.color.withValues(alpha: 0.8),
            child: widget.child,
          ),
        );
      },
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  final double value;
  final double wavePhase;

  _WaveClipper({required this.value, required this.wavePhase});

  @override
  Path getClip(Size size) {
    final path = Path();
    final y = size.height * (1 - value);

    path.moveTo(0, y);

    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        y + sin((i / size.width * 2 * pi) + wavePhase) * size.height * 0.05,
      );
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _WaveClipper oldClipper) {
    return value != oldClipper.value || wavePhase != oldClipper.wavePhase;
  }
}

class ParticleExplosion extends StatefulWidget {
  final Widget child;
  final Color color;
  final bool trigger;

  const ParticleExplosion({
    super.key,
    required this.child,
    required this.color,
    this.trigger = false,
  });

  @override
  State<ParticleExplosion> createState() => _ParticleExplosionState();
}

class _ParticleExplosionState extends State<ParticleExplosion>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(ParticleExplosion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _explode();
    }
  }

  void _explode() {
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (_controller.isAnimating)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ExplosionPainter(
                    progress: _controller.value,
                    color: widget.color,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ExplosionPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ExplosionPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 1.0 - progress);
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * pi;
      final distance = 10 + progress * 50;
      final radius = 4 * (1.0 - progress);

      final dx = center.dx + cos(angle) * distance;
      final dy = center.dy + sin(angle) * distance;

      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ExplosionPainter oldDelegate) => true;
}
