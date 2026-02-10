import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../color_mixer_game.dart';
import '../../helpers/theme_constants.dart';

class TransitionOverlay extends StatefulWidget {
  final ColorMixerGame game;
  const TransitionOverlay({super.key, required this.game});

  @override
  State<TransitionOverlay> createState() => _TransitionOverlayState();
}

class _TransitionOverlayState extends State<TransitionOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  VoidCallback? _onMidpoint;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(
        milliseconds: 1000,
      ), // Longer for the iris effect
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutQuart),
    );

    widget.game.setTransitionCallback(_startTransition);
  }

  void _startTransition(VoidCallback onMidpoint) {
    _onMidpoint = onMidpoint;
    _controller.forward().then((_) {
      if (_onMidpoint != null) _onMidpoint!();
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _controller.reverse();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          if (_animation.value == 0) return const SizedBox.shrink();

          return Stack(
            children: [
              // Main Blade Iris
              CustomPaint(
                painter: _IrisPainter(progress: _animation.value),
                size: Size.infinite,
              ),

              // Digital Scanlines and Glow
              Center(
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(
                      alpha: _animation.value * 0.4,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _IrisPainter extends CustomPainter {
  final double progress;
  _IrisPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius =
        math.sqrt(size.width * size.width + size.height * size.height) / 2;

    // Smooth the iris transition
    // At progress 1.0, it should be fully closed
    final holeRadius = maxRadius * (1.0 - progress);

    final bgPaint = Paint()..color = AppTheme.primaryDark;

    // Draw background everywhere except the hole
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: center, radius: holeRadius))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, bgPaint);

    // Decorative Hexagonal Rings
    final ringPaint = Paint()
      ..color = AppTheme.neonCyan.withValues(alpha: progress * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    if (progress > 0.1) {
      // Draw 3 hex rings that close in
      for (int i = 0; i < 3; i++) {
        final r = holeRadius + (i * 30 * progress) + 10;
        _drawPolygon(canvas, center, 6, r, progress * 2 + (i * 0.2), ringPaint);
      }
    }

    // Iris Blades (Simulated with simple radial lines if needed, but hex looks cooler)
  }

  void _drawPolygon(
    Canvas canvas,
    Offset center,
    int sides,
    double radius,
    double rotation,
    Paint paint,
  ) {
    final path = Path();
    final angle = (2 * math.pi) / sides;

    for (int i = 0; i < sides; i++) {
      final x = center.dx + radius * math.cos(i * angle + rotation);
      final y = center.dy + radius * math.sin(i * angle + rotation);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_IrisPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
