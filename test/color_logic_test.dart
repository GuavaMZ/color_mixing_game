import 'package:flutter_test/flutter_test.dart';
import 'package:color_mixing_deductive/core/color_logic.dart';

void main() {
  group('ColorLogic 5-Color Mixing Tests', () {
    test('Pure Red mixing', () {
      final color = ColorLogic.createMixedColor(5, 0, 0);
      expect((color.r * 255).round(), 255);
      expect((color.g * 255).round(), 0);
      expect((color.b * 255).round(), 0);
    });

    test('Red + White (Tint)', () {
      // 5 Red + 5 White. Total drops = 10.
      // Base calculated from 5 Red (no other colors) = Red (255, 0, 0).
      // Tint strength = 5/10 = 0.5.
      // Result = lerp(Red, White, 0.5) = (255, 127, 127).
      final color = ColorLogic.createMixedColor(5, 0, 0, whiteDrops: 5);

      expect(
        (color.r * 255).round(),
        255,
      ); // Red stays 255 because White adds 255
      expect(
        (color.g * 255).round(),
        closeTo(127, 2),
      ); // 0 -> 255 lerp 0.5 = 127.5
      expect((color.b * 255).round(), closeTo(127, 2));
    });

    test('Red + Black (Shade)', () {
      // 5 Red + 5 Black. Total drops = 10.
      // Base = Red (255, 0, 0).
      // Shade strength = 5/10 = 0.5.
      // Result = lerp(Red, Black, 0.5) = (127, 0, 0).
      final color = ColorLogic.createMixedColor(5, 0, 0, blackDrops: 5);

      expect(
        (color.r * 255).round(),
        closeTo(127, 2),
      ); // 255->0 lerp 0.5 = 127.5
      expect((color.g * 255).round(), 0);
      expect((color.b * 255).round(), 0);
    });

    test('Red + White + Black (Grey Scale or Tone)', () {
      // 10 Red + 5 White + 5 Black. Total 20.
      // Base = Red (255, 0, 0).

      // Order of operations in ColorLogic:
      // 1. Tint: White/Total = 5/20 = 0.25 (25% tint).
      //    Base -> White (25%).
      //    R: 255->255 (255)
      //    G: 0->255 (25% of 255 = 63.75)
      //    B: 0->255 (63.75)
      //    Intermediate: (255, 63, 63)

      // 2. Shade: Black/Total = 5/20 = 0.25 (25% shade).
      //    Intermediate -> Black (25%).
      //    R: 255 -> 0 (75% remaining = 191)
      //    G: 63 -> 0 (75% remaining = 47)
      //    B: 63 -> 0 (75% remaining = 47)

      final color = ColorLogic.createMixedColor(
        10,
        0,
        0,
        whiteDrops: 5,
        blackDrops: 5,
      );

      expect((color.r * 255).round(), closeTo(191, 5));
      expect((color.g * 255).round(), closeTo(63, 5));
      expect((color.b * 255).round(), closeTo(63, 5));
    });
  });
}
