import 'package:flutter/material.dart';

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
      r = (redDrops * 255) / totalColorDrops;
      g = (greenDrops * 255) / totalColorDrops;
      b = (blueDrops * 255) / totalColorDrops;
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

    // 2. Apply Tint (White)
    // Strength depends on ratio of white drops to total drops
    if (whiteDrops > 0) {
      double tintStrength = whiteDrops / totalDrops;
      baseColor = Color.lerp(baseColor, Colors.white, tintStrength)!;
    }

    // 3. Apply Shade (Black)
    // Strength depends on ratio of black drops to total drops
    if (blackDrops > 0) {
      double shadeStrength = blackDrops / totalDrops;
      baseColor = Color.lerp(baseColor, Colors.black, shadeStrength)!;
    }

    return baseColor;
  }

  // دالة لخلط لونين بنسبة معينة
  static Color mix(Color current, Color added) {
    // 0.3 تعني أن اللون المضاف تأثيره 30% فقط في كل ضغطة
    return Color.lerp(current, added, 0.3)!;
  }

  // دالة لقياس مدى قرب اللاعب من الهدف (من 0 لـ 100)
  static double checkMatch(Color current, Color target) {
    // حساب الفرق المطلق بين قيم الـ RGB
    int rDiff = (current.red - target.red).abs();
    int gDiff = (current.green - target.green).abs();
    int bDiff = (current.blue - target.blue).abs();

    // تحويل الفرق لنسبة مئوية (0 هي تطابق تام)
    double totalDiff = (rDiff + gDiff + bDiff) / (255 * 3);
    return (1 - totalDiff) * 100;
  }
}
