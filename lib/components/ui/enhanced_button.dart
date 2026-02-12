import 'package:flutter/material.dart';
import '../../helpers/theme_constants.dart';

class EnhancedButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? color;
  final Color? textColor;
  final double? width;
  final double height;
  final bool isLoading;
  final bool isOutlined;

  const EnhancedButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.color,
    this.textColor,
    this.width,
    this.height = 56,
    this.isLoading = false,
    this.isOutlined = false,
  });

  @override
  State<EnhancedButton> createState() => _EnhancedButtonState();
}

class _EnhancedButtonState extends State<EnhancedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? AppTheme.neonCyan;
    final effectiveTextColor = widget.textColor ?? Colors.white;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: widget.isLoading ? null : widget.onTap,
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: widget.width,
            height: widget.height,
            decoration: widget.isOutlined
                ? AppTheme.cosmicCard(
                    borderRadius: 16,
                    fillColor: _isHovered
                        ? effectiveColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderColor: effectiveColor,
                    hasGlow: _isHovered,
                  )
                : BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        effectiveColor,
                        effectiveColor.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: effectiveColor.withValues(
                          alpha: _isHovered ? 0.6 : 0.4,
                        ),
                        blurRadius: _isHovered ? 20 : 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Center(
                  child: widget.isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              effectiveTextColor,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(
                                widget.icon,
                                color: effectiveTextColor,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                            ],
                            Text(
                              widget.label,
                              style: AppTheme.buttonText(context).copyWith(
                                color: effectiveTextColor,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
