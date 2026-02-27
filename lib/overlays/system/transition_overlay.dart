import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../color_mixer_game.dart';
import 'package:vector_math/vector_math_64.dart' show Vector2;
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
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutQuart,
    );

    widget.game.setTransitionCallback((cb, {bool isReverse = false}) {
      _startTransition(cb);
    });
  }

  void _startTransition(VoidCallback onMidpoint) {
    if (!mounted) return;
    _onMidpoint = onMidpoint;
    _controller.forward(from: 0.0).then((_) {
      if (!mounted) return;
      _onMidpoint?.call();
      Future.delayed(const Duration(milliseconds: 150), () {
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final v = _animation.value;
        if (v == 0) return const SizedBox.shrink();
        return IgnorePointer(
          ignoring: v > 0.1,
          child: CustomPaint(
            painter: _IrisPainter(progress: v),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class _IrisPainter extends CustomPainter {
  final double progress;
  _IrisPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = Vector2(size.width, size.height).length / 2;
    final holeR = maxR * (1.0 - progress);

    // Dark background with iris hole cut out
    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addOval(Rect.fromCircle(center: center, radius: holeR))
        ..fillType = PathFillType.evenOdd,
      Paint()..color = AppTheme.primaryDark,
    );

    // Subtle dark overlay on top
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black.withValues(alpha: progress * 0.3),
    );

    if (progress > 0.1) {
      // Decorative neon hex rings around the iris edge
      final ringPaint = Paint()
        ..color = AppTheme.neonCyan.withValues(alpha: progress * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      for (int i = 0; i < 3; i++) {
        final r = holeR + (i * 28 * progress) + 8;
        final rot = progress * 1.5 + i * 0.2;
        _drawHex(canvas, center, r, rot, ringPaint);
      }
    }
  }

  void _drawHex(Canvas canvas, Offset center, double r, double rot, Paint p) {
    const sides = 6;
    final path = Path();
    final angle = (2 * math.pi) / sides;
    for (int i = 0; i < sides; i++) {
      final x = center.dx + r * math.cos(i * angle + rot);
      final y = center.dy + r * math.sin(i * angle + rot);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_IrisPainter old) => old.progress != progress;
}
