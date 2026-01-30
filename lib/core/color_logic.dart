import 'package:flutter/material.dart';

class ColorLogic {
  static Color createMixedColor(int redDrops, int greenDrops, int blueDrops) {
    int total = redDrops + greenDrops + blueDrops;
    if (total == 0) {
      return Colors.transparent;
    }

    // Correct RGB averaging
    double r = (redDrops * 255) / total;
    double g = (greenDrops * 255) / total;
    double b = (blueDrops * 255) / total;

    return Color.fromARGB(255, r.toInt(), g.toInt(), b.toInt());
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
