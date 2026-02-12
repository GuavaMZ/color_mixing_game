import 'package:flutter/material.dart';
import '../../helpers/theme_constants.dart';

class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? fillColor;
  final Color? borderColor;
  final double? borderWidth;
  final bool hasGlow;
  final Color? glowColor;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final double borderRadius;
  final double hoverScale;

  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.fillColor,
    this.borderColor,
    this.borderWidth,
    this.hasGlow = false,
    this.glowColor,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 24.0,
    this.hoverScale = 0.02,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _glow;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.0 + widget.hoverScale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _glow = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(AnimatedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hoverScale != oldWidget.hoverScale) {
      _scale = Tween<double>(
        begin: 1.0,
        end: 1.0 + widget.hoverScale,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleHover(bool isHovered) {
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: GestureDetector(
        onTapDown: (_) => _controller.reverse(),
        onTapUp: (_) => _controller.forward(),
        onTapCancel: () => _controller.reverse(),
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // 3D Tilt Effect
            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateX(_isHovered ? 0.05 : 0) // slight tilt X
              ..scale(_scale.value);

            final effectiveGlowColor =
                widget.glowColor ?? widget.borderColor ?? AppTheme.neonCyan;

            return Transform(
              transform: transform,
              alignment: Alignment.center,
              child: Container(
                margin: widget.margin,
                decoration:
                    AppTheme.cosmicCard(
                      borderRadius: widget.borderRadius,
                      fillColor: widget.fillColor,
                      borderColor:
                          widget.borderColor ??
                          Colors.white.withValues(alpha: 0.2),
                      borderWidth: widget.borderWidth ?? 1.0,
                      hasGlow: widget.hasGlow || _isHovered,
                      glowColor: effectiveGlowColor.withValues(
                        alpha: 0.4 * _glow.value + 0.2,
                      ),
                    ).copyWith(
                      boxShadow: _isHovered
                          ? [
                              BoxShadow(
                                color: effectiveGlowColor.withValues(
                                  alpha: 0.4 * _glow.value,
                                ),
                                blurRadius: 20 * _glow.value + 10,
                                spreadRadius: 2 * _glow.value,
                              ),
                            ]
                          : null,
                    ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  child: InkWell(
                    onTap: widget.onTap,
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    child: Padding(
                      padding: widget.padding,
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
