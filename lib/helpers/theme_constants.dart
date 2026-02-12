import 'package:flutter/material.dart';

/// Centralized theme constants for consistent styling across the app
class AppTheme {
  // === COSMIC LABORATORY PALETTE ===
  static const Color primaryDark = Color(0xFF0B0E14); // Deepest Void
  static const Color primaryMedium = Color(0xFF15192B); // Deep Navy
  static const Color primaryLight = Color(0xFF2A2E45); // Lighter Navy

  static const Color neonCyan = Color(0xFF00F0FF); // Electric Cyan
  static const Color neonMagenta = Color(0xFFFF0099); // Electric Magenta
  static const Color electricYellow = Color(0xFFFAFF00); // Voltage Yellow
  static const Color neonPurple = Color(0xFFBF00FF); // Electric Purple
  static const Color cosmicPurple = Color(0xFF7000FF); // Deep Purple
  static const Color success = Color(0xFF00FF94); // Neon Green

  // Legacy mappings for compatibility (updating to cosmic tones)
  static const Color primaryColor = neonCyan;
  static const Color secondaryColor = cosmicPurple;
  static const Color accentColor = electricYellow;
  static const Color cardColor = Color(0xFF1E2235);
  static const Color backgroundColor = primaryDark;

  // === GRADIENTS ===
  // Missing gradients requested by user
  static const LinearGradient backgroundGradient = cosmicBackground; // Alias

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF00F0FF), // Neon Cyan
      Color(0xFF0099FF), // Deep Blue
    ],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFF0099), // Neon Magenta
      Color(0xFF7000FF), // Cosmic Purple
    ],
  );

  static const LinearGradient cosmicBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F1525), // Void
      Color(0xFF1F1835), // Deep Purple Haze
      Color(0xFF0B0E14), // Void
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x4015192B), // primaryMedium 25%
      Color(0x1A15192B), // primaryMedium 10%
    ],
  );

  static const LinearGradient neonBorderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x8000F0FF), // Cyan 50%
      Color(0x80FF0099), // Magenta 50%
    ],
  );

  // === COSMIC GLASS DECORATION ===
  static BoxDecoration cosmicGlass({
    double borderRadius = 20,
    Color? borderColor,
    bool isInteractive = false,
  }) {
    return BoxDecoration(
      gradient: glassGradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? Colors.white.withValues(alpha: 0.15),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.5),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
        // Subtle inner rim light
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.05),
          blurRadius: 0,
          spreadRadius: -1.5,
        ),
        if (isInteractive)
          BoxShadow(
            color: neonCyan.withValues(alpha: 0.15),
            blurRadius: 15,
            spreadRadius: 2,
          ),
      ],
    );
  }

  static Widget primaryButton({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
    Color? color,
    double? width,
    double? height,
  }) {
    return Container(
      width: width,
      height: height ?? ResponsiveHelper.buttonHeight(context),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: primaryGradient,
        boxShadow: [
          BoxShadow(
            color: neonCyan.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: Text(text, style: buttonText(context, isLarge: true)),
      ),
    );
  }

  // Primary Card Style for Buttons/Containers
  static BoxDecoration cosmicCard({
    double borderRadius = 24,
    Color? fillColor,
    Color borderColor = Colors.white,
    double borderWidth = 1.8,
    bool hasGlow = false,
    Color? glowColor,
  }) {
    final effectiveBorderColor = borderColor == Colors.white
        ? Colors.white.withValues(alpha: 0.3)
        : borderColor;

    return BoxDecoration(
      color:
          fillColor?.withValues(alpha: 0.9) ??
          primaryMedium.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: effectiveBorderColor, width: borderWidth),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.6),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
        if (hasGlow)
          BoxShadow(
            color:
                (glowColor ??
                        (borderColor != Colors.white ? borderColor : neonCyan))
                    .withValues(alpha: 0.4),
            blurRadius: 25,
            spreadRadius: -1,
          ),
        // Inner Glow
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.05),
          offset: const Offset(1, 1),
          blurRadius: 1,
        ),
      ],
    );
  }

  // --- ANIMATIONS ---
  static const Duration animationNormal = Duration(milliseconds: 400);
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Curve cosmicCurve = Curves.easeOutQuart;

  // --- TEXT STYLES ---
  static TextStyle heading1(BuildContext context) => TextStyle(
    fontSize: ResponsiveHelper.fontSize(context, 42),
    fontWeight: FontWeight.w900,
    color: Colors.white,
    letterSpacing: 2.0,
    decoration: TextDecoration.none,
    fontFamily: 'Roboto',
    shadows: [
      Shadow(
        color: neonCyan.withValues(alpha: 0.8),
        blurRadius: 20,
        offset: const Offset(0, 0),
      ),
      Shadow(
        color: Colors.black.withValues(alpha: 0.6),
        offset: const Offset(2, 2),
        blurRadius: 6,
      ),
    ],
  );

  static TextStyle heading2(BuildContext context) => TextStyle(
    fontSize: ResponsiveHelper.fontSize(context, 28),
    fontWeight: FontWeight.w800,
    color: Colors.white,
    letterSpacing: 1.5,
    decoration: TextDecoration.none,
    shadows: [
      Shadow(
        color: cosmicPurple.withValues(alpha: 0.7),
        blurRadius: 15,
        offset: const Offset(0, 0),
      ),
    ],
  );

  static TextStyle heading3(BuildContext context) => TextStyle(
    fontSize: ResponsiveHelper.fontSize(context, 24),
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 1.0,
    decoration: TextDecoration.none,
    shadows: [
      Shadow(
        color: cosmicPurple.withValues(alpha: 0.6),
        blurRadius: 12,
        offset: const Offset(0, 0),
      ),
    ],
  );

  static TextStyle buttonText(
    BuildContext context, {
    Color? color,
    bool isLarge = false,
  }) => TextStyle(
    fontSize: ResponsiveHelper.fontSize(context, isLarge ? 18 : 15),
    fontWeight: FontWeight.w900,
    color: color ?? Colors.white,
    letterSpacing: 1.2,
    decoration: TextDecoration.none,
    shadows: [
      Shadow(
        color: Colors.black.withValues(alpha: 0.4),
        offset: const Offset(0, 2),
        blurRadius: 2,
      ),
    ],
  );

  static TextStyle bodyLarge(BuildContext context) => TextStyle(
    fontSize: ResponsiveHelper.fontSize(context, 18),
    fontWeight: FontWeight.w700,
    color: Colors.white.withValues(alpha: 0.95),
    letterSpacing: 0.8,
    decoration: TextDecoration.none,
  );

  static TextStyle bodyMedium(BuildContext context) => TextStyle(
    fontSize: ResponsiveHelper.fontSize(context, 16),
    fontWeight: FontWeight.w600,
    color: Colors.white.withValues(alpha: 0.85),
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static TextStyle bodySmall(BuildContext context) => TextStyle(
    fontSize: ResponsiveHelper.fontSize(context, 14),
    fontWeight: FontWeight.w500,
    color: Colors.white.withValues(alpha: 0.7),
    decoration: TextDecoration.none,
  );

  static TextStyle caption(BuildContext context) => TextStyle(
    fontSize: ResponsiveHelper.fontSize(context, 12),
    fontWeight: FontWeight.w600,
    color: neonCyan.withValues(alpha: 0.8),
    letterSpacing: 1.5,
    decoration: TextDecoration.none,
  );
}

/// Helper class for responsive design
class ResponsiveHelper {
  // === BREAKPOINTS ===
  static const double breakpointSmall = 360.0;
  static const double breakpointMobile = 600.0;
  static const double breakpointTablet = 1024.0;

  // === TOUCH TARGETS ===
  static const double minTouchTarget = 48.0; // Material Design minimum
  static const double recommendedTouchTarget =
      56.0; // Recommended for primary actions
  static const double minTouchSpacing = 8.0; // Minimum spacing between targets

  // === GRID SYSTEM ===
  static const double baseGridUnit = 8.0; // 8dp grid system

  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static bool isSmallPhone(BuildContext context) =>
      screenWidth(context) < breakpointSmall;
  static bool isMobile(BuildContext context) =>
      screenWidth(context) < breakpointMobile;
  static bool isTablet(BuildContext context) =>
      screenWidth(context) >= breakpointMobile &&
      screenWidth(context) < breakpointTablet;
  static bool isDesktop(BuildContext context) =>
      screenWidth(context) >= breakpointTablet;

  /// Get responsive value based on screen size
  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }

  /// Responsive font size with scaling
  static double fontSize(BuildContext context, double baseSize) {
    final width = screenWidth(context);
    double scale = 1.0;

    if (width < 360) {
      scale = 0.85; // Small phones
    } else if (width < 400) {
      scale = 0.92; // Budget phones
    } else if (width >= 600 && width < 900) {
      scale = 1.1; // Tablets
    } else if (width >= 900) {
      scale = 1.2; // Large tablets
    }

    return baseSize * scale;
  }

  /// Responsive spacing based on grid system
  static double spacing(BuildContext context, double baseSpacing) {
    return responsive(
      context,
      mobile: baseSpacing,
      tablet: baseSpacing * 1.25,
      desktop: baseSpacing * 1.5,
    );
  }

  /// Grid-based spacing (multiples of 8dp)
  static double gridSpacing(BuildContext context, int units) {
    return spacing(context, baseGridUnit * units);
  }

  /// Responsive icon size
  static double iconSize(BuildContext context, double baseSize) {
    return responsive(
      context,
      mobile: baseSize,
      tablet: baseSize * 1.2,
      desktop: baseSize * 1.4,
    );
  }

  /// Ensure minimum touch target size
  static double touchTarget(BuildContext context, {double? size}) {
    final baseSize = size ?? recommendedTouchTarget;
    return baseSize < minTouchTarget ? minTouchTarget : baseSize;
  }

  /// Get safe padding considering notches and system UI
  static EdgeInsets safePadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Responsive button height
  static double buttonHeight(BuildContext context) {
    return responsive(
      context,
      mobile: recommendedTouchTarget,
      tablet: 60.0,
      desktop: 64.0,
    );
  }

  /// Responsive card width for level map
  static double levelCardSize(BuildContext context) {
    final width = screenWidth(context);
    if (width < 360) return 65;
    if (width < 400) return 72;
    if (width < 600) return 80;
    if (width < 900) return 100;
    return 120;
  }

  /// Number of columns for level grid
  static int levelGridColumns(BuildContext context) {
    final width = screenWidth(context);
    if (width < 360) return 3; // Very small phones
    if (width < 600) return 4; // Standard phones
    if (width < 900) return 5; // Large phones/small tablets
    return 6; // Tablets
  }

  /// Adaptive padding for containers
  static EdgeInsets containerPadding(BuildContext context) {
    return EdgeInsets.all(gridSpacing(context, 2)); // 16dp base
  }

  /// Adaptive margin for cards
  static EdgeInsets cardMargin(BuildContext context) {
    return EdgeInsets.all(gridSpacing(context, 1)); // 8dp base
  }

  /// Responsive border radius
  static double borderRadius(BuildContext context, double baseRadius) {
    return responsive(
      context,
      mobile: baseRadius,
      tablet: baseRadius * 1.2,
      desktop: baseRadius * 1.4,
    );
  }

  /// Get optimal number of columns for a grid
  static int gridColumns(
    BuildContext context, {
    int mobileColumns = 2,
    int tabletColumns = 3,
    int desktopColumns = 4,
  }) {
    return responsive(
      context,
      mobile: mobileColumns,
      tablet: tabletColumns,
      desktop: desktopColumns,
    );
  }

  /// Calculate item width for grid with spacing
  static double gridItemWidth(
    BuildContext context,
    int columns,
    double spacing,
  ) {
    final screenW = screenWidth(context);
    final totalSpacing = spacing * (columns + 1);
    return (screenW - totalSpacing) / columns;
  }

  /// Responsive dialog width
  static double dialogWidth(BuildContext context) {
    final width = screenWidth(context);
    if (width < 360) return width * 0.9;
    if (width < 600) return width * 0.85;
    if (width < 900) return 500;
    return 600;
  }

  /// Check if text will overflow and needs scaling
  static bool willTextOverflow(String text, TextStyle style, double maxWidth) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return textPainter.width > maxWidth;
  }

  /// Get scaled text style to fit width
  static TextStyle fitTextToWidth(
    BuildContext context,
    String text,
    TextStyle baseStyle,
    double maxWidth,
  ) {
    if (!willTextOverflow(text, baseStyle, maxWidth)) {
      return baseStyle;
    }

    // Scale down font size until it fits
    double fontSize = baseStyle.fontSize ?? 14.0;
    while (fontSize > 10.0) {
      fontSize -= 0.5;
      final scaledStyle = baseStyle.copyWith(fontSize: fontSize);
      if (!willTextOverflow(text, scaledStyle, maxWidth)) {
        return scaledStyle;
      }
    }

    return baseStyle.copyWith(fontSize: 10.0);
  }
}
