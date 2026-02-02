import 'package:flutter/material.dart';

Size displaySize(BuildContext context) {
  return MediaQuery.of(context).size;
}

double displayHeight(BuildContext context) {
  return displaySize(context).height;
}

double displayWidth(BuildContext context) {
  return displaySize(context).width;
}

// Responsive breakpoints
bool isSmallPhone(BuildContext context) => displayWidth(context) < 360;
bool isPhone(BuildContext context) => displayWidth(context) < 600;
bool isTablet(BuildContext context) =>
    displayWidth(context) >= 600 && displayWidth(context) < 1024;
bool isDesktop(BuildContext context) => displayWidth(context) >= 1024;

// Responsive font size scaling
double scaledFontSize(BuildContext context, double baseSize) {
  final width = displayWidth(context);
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

// Responsive spacing
double scaledSpacing(BuildContext context, double baseSpacing) {
  if (isDesktop(context)) return baseSpacing * 1.5;
  if (isTablet(context)) return baseSpacing * 1.25;
  return baseSpacing;
}

// Safe area padding
EdgeInsets safeAreaPadding(BuildContext context) {
  return MediaQuery.of(context).padding;
}
