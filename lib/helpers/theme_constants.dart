import 'package:flutter/material.dart';

/// Centralized theme constants for consistent styling across the app
class AppTheme {
  // === COLORS ===
  static const Color primaryDark = Color(0xFF1A1A2E);
  static const Color primaryMedium = Color(0xFF16213E);
  static const Color primaryLight = Color(0xFF0F3460);
  static const Color accent = Color(0xFF4facfe);
  static const Color accentSecondary = Color(0xFF667eea);
  static const Color success = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFF87171);

  // === GRADIENTS ===
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x40FFFFFF), Color(0x10FFFFFF)],
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
  );

  // === GLASSMORPHISM ===
  static BoxDecoration glassDecoration({
    double borderRadius = 20,
    Color? borderColor,
    double borderWidth = 1.5,
  }) {
    return BoxDecoration(
      gradient: glassGradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? Colors.white.withOpacity(0.3),
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
    );
  }

  // === SHADOWS ===
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 15,
      offset: const Offset(0, 5),
    ),
  ];

  static List<BoxShadow> glowShadow(Color color) => [
    BoxShadow(color: color.withOpacity(0.5), blurRadius: 20, spreadRadius: 2),
  ];

  // === ANIMATIONS ===
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 350);
  static const Duration animationSlow = Duration(milliseconds: 600);
  static const Duration animationVerySlow = Duration(milliseconds: 1000);

  static const Curve animationCurve = Curves.easeOutCubic;
  static const Curve bounceCurve = Curves.elasticOut;

  // === TEXT STYLES ===
  static TextStyle heading1(BuildContext context) => TextStyle(
    fontSize: ResponsiveHelper.fontSize(context, 48),
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 2,
    shadows: [Shadow(color: accentSecondary.withOpacity(0.5), blurRadius: 20)],
  );

  static TextStyle heading2(BuildContext context) => TextStyle(
    fontSize: ResponsiveHelper.fontSize(context, 32),
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 1.5,
  );

  static TextStyle heading3(BuildContext context) => TextStyle(
    fontSize: ResponsiveHelper.fontSize(context, 24),
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle bodyLarge(BuildContext context) => TextStyle(
    fontSize: ResponsiveHelper.fontSize(context, 18),
    fontWeight: FontWeight.w500,
    color: Colors.white.withOpacity(0.9),
  );

  static TextStyle bodyMedium(BuildContext context) => TextStyle(
    fontSize: ResponsiveHelper.fontSize(context, 16),
    fontWeight: FontWeight.normal,
    color: Colors.white.withOpacity(0.8),
  );

  static TextStyle bodySmall(BuildContext context) => TextStyle(
    fontSize: ResponsiveHelper.fontSize(context, 14),
    fontWeight: FontWeight.normal,
    color: Colors.white.withOpacity(0.7),
  );

  static TextStyle caption(BuildContext context) => TextStyle(
    fontSize: ResponsiveHelper.fontSize(context, 12),
    fontWeight: FontWeight.normal,
    color: Colors.white.withOpacity(0.6),
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
