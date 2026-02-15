import 'package:color_mixing_deductive/helpers/theme_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CoinsWidget extends StatelessWidget {
  final ValueListenable<int> coinsNotifier;
  final bool useEnhancedStyle; // Whether to use the enhanced style or basic style
  final double? iconSize;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;
  final bool showIcon;

  const CoinsWidget({
    super.key,
    required this.coinsNotifier,
    this.useEnhancedStyle = false,
    this.iconSize,
    this.fontSize,
    this.padding,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: coinsNotifier,
      builder: (context, coins, _) {
        if (useEnhancedStyle) {
          // Enhanced style with gradient background and glow effects
          return Container(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.amber.withValues(alpha: 0.2),
                      Colors.orange.withValues(alpha: 0.2),
                    ],
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showIcon)
                      Icon(
                        Icons.monetization_on_rounded,
                        color: Colors.amber,
                        size: iconSize ?? 24,
                        shadows: [
                          Shadow(
                            color: Colors.amber.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    if (showIcon) const SizedBox(width: 8),
                    Text(
                      "$coins",
                      style: AppTheme.buttonText(
                        context,
                      ).copyWith(
                        color: Colors.white,
                        fontSize: fontSize ?? 20,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.amber.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          // Basic style matching main menu
          return Container(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: AppTheme.cosmicGlass(
              borderRadius: 20,
              borderColor: Colors.amber.withValues(alpha: 0.3),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showIcon)
                  Icon(
                    Icons.monetization_on_rounded,
                    color: Colors.amber,
                    size: iconSize ?? 20,
                  ),
                if (showIcon) const SizedBox(width: 8),
                Text(
                  "$coins",
                  style: AppTheme.bodyLarge(
                    context,
                  ).copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontSize: fontSize ?? 16,
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}