import 'package:flutter/material.dart';
import '../color_mixer_game.dart';

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
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    widget.game.setTransitionCallback(_startTransition);
  }

  void _startTransition(VoidCallback onMidpoint) {
    _onMidpoint = onMidpoint;
    _controller.forward().then((_) {
      if (_onMidpoint != null) _onMidpoint!();
      _controller.reverse();
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
          return Container(color: Colors.black.withOpacity(_animation.value));
        },
      ),
    );
  }
}
