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
            color: (borderColor != Colors.white ? borderColor : neonCyan)
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
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static bool isMobile(BuildContext context) => screenWidth(context) < 600;
  static bool isTablet(BuildContext context) =>
      screenWidth(context) >= 600 && screenWidth(context) < 1024;
  static bool isDesktop(BuildContext context) => screenWidth(context) >= 1024;

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
      scale = 0.85;
    } else if (width < 400) {
      scale = 0.92;
    } else if (width > 600) {
      scale = 1.1;
    } else if (width > 900) {
      scale = 1.2;
    }

    return baseSize * scale;
  }

  /// Responsive spacing
  static double spacing(BuildContext context, double baseSpacing) {
    return responsive(
      context,
      mobile: baseSpacing,
      tablet: baseSpacing * 1.25,
      desktop: baseSpacing * 1.5,
    );
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

  /// Get safe padding considering notches and system UI
  static EdgeInsets safePadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Responsive button height
  static double buttonHeight(BuildContext context) {
    return responsive(context, mobile: 50.0, tablet: 56.0, desktop: 60.0);
  }

  /// Responsive card width for level map
  static double levelCardSize(BuildContext context) {
    final width = screenWidth(context);
    if (width < 360) return 65;
    if (width < 400) return 72;
    if (width < 600) return 80;
    return 100;
  }

  /// Number of columns for level grid
  static int levelGridColumns(BuildContext context) {
    return responsive(context, mobile: 4, tablet: 5, desktop: 6);
  }
}
