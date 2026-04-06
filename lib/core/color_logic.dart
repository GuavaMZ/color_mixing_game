import 'dart:math';
import 'package:flutter/material.dart';
import 'package:color_mixing_deductive/core/color_science.dart';
import 'package:color_mixing_deductive/helpers/global_variables.dart';

class ColorLogic {
  static Color createMixedColor(
    int redDrops,
    int greenDrops,
    int blueDrops, {
    int whiteDrops = 0,
    int blackDrops = 0,
  }) {
    int totalColorDrops = redDrops + greenDrops + blueDrops;
    int totalDrops = totalColorDrops + whiteDrops + blackDrops;

    if (totalDrops == 0) {
      return Colors.transparent;
    }

    // 1. Calculate base RGB color (normalized by color drops only)
    double r = 0;
    double g = 0;
    double b = 0;

    if (totalColorDrops > 0) {
      // Use max-normalization to keep colors vibrant
      int maxDrops = [redDrops, greenDrops, blueDrops].reduce(max);
      r = (redDrops * 255) / maxDrops;
      g = (greenDrops * 255) / maxDrops;
      b = (blueDrops * 255) / maxDrops;
    } else {
      // If no color drops, start from neutral grey or handled by tint/shade
      // But typically, white + black = grey.
      // Let's assume neutral base if only white/black exist.
      r = 127;
      g = 127;
      b = 127;

      // Edge case: Only White -> White
      if (whiteDrops > 0 && blackDrops == 0) return Colors.white;
      // Edge case: Only Black -> Black
      if (blackDrops > 0 && whiteDrops == 0) return Colors.black;
    }

    Color baseColor = Color.fromARGB(255, r.toInt(), g.toInt(), b.toInt());

    // 2 & 3. Apply Tint (White) and Shade (Black) proportionately
    if (whiteDrops > 0 || blackDrops > 0) {
      double colorWeight = totalColorDrops / totalDrops;
      double whiteWeight = whiteDrops / totalDrops;
      double blackWeight = blackDrops / totalDrops;

      // Base color contributes its weighted amount
      double finalR =
          (r * colorWeight) + (255 * whiteWeight) + (0 * blackWeight);
      double finalG =
          (g * colorWeight) + (255 * whiteWeight) + (0 * blackWeight);
      double finalB =
          (b * colorWeight) + (255 * whiteWeight) + (0 * blackWeight);

      baseColor = Color.fromARGB(
        255,
        finalR.toInt(),
        finalG.toInt(),
        finalB.toInt(),
      );
    }

    return baseColor;
  }

  // دالة لخلط لونين بنسبة معينة
  static Color mix(Color current, Color added) {
    // 0.3 تعني أن اللون المضاف تأثيره 30% فقط في كل ضغطة
    return Color.lerp(current, added, 0.3)!;
  }

  // Perceptual color match using CIE76 Delta-E
  // Delta-E ≤ 2 is imperceptible to human eyes → 100%
  // Delta-E ≥ 50 is completely different → 0%
  static double checkMatch(Color current, Color target) {
    final double deltaE = ColorScience.deltaE76(current, target);

    // Map Delta-E to a 0–100 percentage (lower deltaE = higher match)
    const double perfectThreshold = 2.0; // Imperceptible difference
    const double maxDelta = 50.0; // Completely different

    if (deltaE <= perfectThreshold) return 100.0;
    if (deltaE >= maxDelta) return 0.0;

    // Linear interpolation between thresholds
    return ((1.0 -
                (deltaE - perfectThreshold) / (maxDelta - perfectThreshold)) *
            100.0)
        .clamp(0.0, 100.0);
  }

  static Color generateRandomHardColor() {
    final random = GlobalConstants.sharedRandom;
    // A hard color usually has mixed values across R, G, B
    // We avoid primary/secondary by giving each channel a decent range
    int r = 40 + random.nextInt(170);
    int g = 40 + random.nextInt(170);
    int b = 40 + random.nextInt(170);
    return Color.fromARGB(255, r, g, b);
  }
}
