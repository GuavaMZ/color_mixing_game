import 'dart:math';
import 'package:flutter/material.dart';
import 'package:color_mixing_deductive/helpers/theme_constants.dart';

/// Reusable responsive button component with proper touch targets
class ResponsiveButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final Color? textColor;
  final bool isLarge;
  final bool isOutlined;
  final double? width;
  final double? height;

  const ResponsiveButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color,
    this.textColor,
    this.isLarge = false,
    this.isOutlined = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final buttonHeight = height ?? ResponsiveHelper.buttonHeight(context);
    final effectiveColor = color ?? AppTheme.neonCyan;
    final effectiveTextColor = textColor ?? Colors.white;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: width ?? 0,
        minHeight: buttonHeight,
      ),
      child: Container(
        decoration: isOutlined
            ? AppTheme.cosmicCard(
                borderRadius: ResponsiveHelper.borderRadius(context, 16),
                fillColor: Colors.transparent,
                borderColor: effectiveColor,
                hasGlow: onPressed != null,
              )
            : BoxDecoration(
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.borderRadius(context, 16),
                ),
                gradient: LinearGradient(
                  colors: [
                    effectiveColor,
                    effectiveColor.withValues(alpha: 0.8),
                  ],
                ),
                boxShadow: onPressed != null
                    ? [
                        BoxShadow(
                          color: effectiveColor.withValues(alpha: 0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.borderRadius(context, 16),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.gridSpacing(context, 2),
                vertical: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: effectiveTextColor,
                      size: ResponsiveHelper.iconSize(
                        context,
                        isLarge ? 24 : 20,
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.gridSpacing(context, 1)),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: AppTheme.buttonText(
                        context,
                        isLarge: isLarge,
                      ).copyWith(color: effectiveTextColor),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Responsive icon button with minimum touch target
class ResponsiveIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? size;
  final double? padding;
  final String? tooltip;
  final bool showBadge;

  const ResponsiveIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.borderColor,
    this.size,
    this.padding,
    this.tooltip,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final touchSize = ResponsiveHelper.touchTarget(context, size: size);
    final iconColor = color ?? AppTheme.neonCyan;

    // Calculate size including padding if touchSize isn't forcing it
    final containerSize = size != null && padding != null
        ? size! + (padding! * 2)
        : touchSize;
    final effectiveSize = max(touchSize, containerSize);

    final button = Container(
      width: effectiveSize,
      height: effectiveSize,
      decoration: AppTheme.cosmicGlass(
        borderRadius: effectiveSize / 4,
        borderColor: borderColor ?? iconColor.withValues(alpha: 0.3),
      ),
      child: Material(
        color: backgroundColor ?? Colors.transparent,
        borderRadius: BorderRadius.circular(effectiveSize / 4),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(effectiveSize / 4),
          child: Padding(
            padding: EdgeInsets.all(padding ?? 0),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: iconColor,
                  size: ResponsiveHelper.iconSize(context, size ?? 24),
                ),
                if (showBadge)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withValues(alpha: 0.8),
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}

/// Responsive card container
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final Color? borderColor;
  final bool hasGlow;
  final VoidCallback? onTap;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.borderColor,
    this.hasGlow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding =
        padding ?? ResponsiveHelper.containerPadding(context);
    final effectiveMargin = margin ?? ResponsiveHelper.cardMargin(context);

    return Container(
      margin: effectiveMargin,
      decoration: AppTheme.cosmicCard(
        borderRadius: ResponsiveHelper.borderRadius(context, 20),
        fillColor: color,
        borderColor: borderColor ?? Colors.white.withValues(alpha: 0.2),
        hasGlow: hasGlow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.borderRadius(context, 20),
          ),
          child: Padding(padding: effectivePadding, child: child),
        ),
      ),
    );
  }
}

/// Responsive grid layout
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double spacing;
  final double runSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.spacing = 12,
    this.runSpacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveHelper.gridColumns(
      context,
      mobileColumns: mobileColumns ?? 2,
      tabletColumns: tabletColumns ?? 3,
      desktopColumns: desktopColumns ?? 4,
    );

    return GridView.count(
      crossAxisCount: columns,
      mainAxisSpacing: runSpacing,
      crossAxisSpacing: spacing,
      childAspectRatio: 1.0,
      children: children,
    );
  }
}

/// Responsive text that scales to fit
class ResponsiveText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final double maxWidth;
  final TextAlign? textAlign;
  final int? maxLines;

  const ResponsiveText({
    super.key,
    required this.text,
    this.style,
    required this.maxWidth,
    this.textAlign,
    this.maxLines,
  });

  @override
  State<ResponsiveText> createState() => _ResponsiveTextState();
}

class _ResponsiveTextState extends State<ResponsiveText> {
  TextStyle? _fittedStyle;
  String? _lastText;
  TextStyle? _lastStyle;
  double? _lastMaxWidth;

  @override
  Widget build(BuildContext context) {
    final baseStyle = widget.style ?? AppTheme.bodyLarge(context);

    // Performance optimization: only re-calculate fitting if inputs changed
    if (_fittedStyle == null ||
        _lastText != widget.text ||
        _lastStyle != baseStyle ||
        _lastMaxWidth != widget.maxWidth) {
      _lastText = widget.text;
      _lastStyle = baseStyle;
      _lastMaxWidth = widget.maxWidth;
      _fittedStyle = ResponsiveHelper.fitTextToWidth(
        context,
        widget.text,
        baseStyle,
        widget.maxWidth,
      );
    }

    return Text(
      widget.text,
      style: _fittedStyle,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
