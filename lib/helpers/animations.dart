import 'package:flutter/material.dart';

/// Common animation curves and helpers
class AppAnimations {
  // Standard curves
  static const Curve bounce = Curves.elasticOut;
  static const Curve smooth = Curves.easeOutCubic;
  static const Curve sharp = Curves.easeOutQuint;

  // Durations
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 800);

  /// Create a staggered animation delay
  static Future<void> stagger(int index, {int step = 50}) async {
    await Future.delayed(Duration(milliseconds: index * step));
  }
}

/// A widget that fades and slides its child in
class SlideFadeIn extends StatefulWidget {
  final Widget child;
  final int delay;
  final Offset offset;

  const SlideFadeIn({
    super.key,
    required this.child,
    this.delay = 0,
    this.offset = const Offset(0, 20),
  });

  @override
  State<SlideFadeIn> createState() => _SlideFadeInState();
}

class _SlideFadeInState extends State<SlideFadeIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.normal,
      vsync: this,
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: widget.offset, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.smooth),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Transform.translate(
        offset: _slide
            .value, // Will be driven by AnimatedBuilder if needed, but here simple usage
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: _slide.value,
              child: widget.child,
            );
          },
        ),
      ),
    );
  }
}
