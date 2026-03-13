import 'package:flutter_test/flutter_test.dart';
import 'package:color_mixing_deductive/core/color_logic.dart';
import 'package:flutter/material.dart';

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

    // ═══════════════════════════════════════════════════════════════════════════
    // EDGE CASE TESTS
    // ═══════════════════════════════════════════════════════════════════════════

    test('Zero drops returns transparent', () {
      final color = ColorLogic.createMixedColor(0, 0, 0);
      expect(color, equals(Colors.transparent));
    });

    test('Only white drops returns white', () {
      final color = ColorLogic.createMixedColor(0, 0, 0, whiteDrops: 5);
      expect(color, equals(Colors.white));
    });

    test('Only black drops returns black', () {
      final color = ColorLogic.createMixedColor(0, 0, 0, blackDrops: 5);
      expect(color, equals(Colors.black));
    });

    test('White + Black only returns grey', () {
      final color = ColorLogic.createMixedColor(0, 0, 0,
          whiteDrops: 5, blackDrops: 5);
      // Equal parts white and black should give medium grey
      expect((color.r * 255).round(), closeTo(127, 5));
      expect((color.g * 255).round(), closeTo(127, 5));
      expect((color.b * 255).round(), closeTo(127, 5));
    });

    test('Equal RGB creates grey/white', () {
      final color = ColorLogic.createMixedColor(5, 5, 5);
      // Equal RGB should create white/light grey
      expect((color.r * 255).round(), 255);
      expect((color.g * 255).round(), 255);
      expect((color.b * 255).round(), 255);
    });

    test('Single drop of each primary color', () {
      final color = ColorLogic.createMixedColor(1, 1, 1);
      // Equal parts should create white
      expect((color.r * 255).round(), 255);
      expect((color.g * 255).round(), 255);
      expect((color.b * 255).round(), 255);
    });

    test('Yellow (Red + Green equal)', () {
      final color = ColorLogic.createMixedColor(5, 5, 0);
      expect((color.r * 255).round(), 255);
      expect((color.g * 255).round(), 255);
      expect((color.b * 255).round(), 0);
    });

    test('Magenta (Red + Blue equal)', () {
      final color = ColorLogic.createMixedColor(5, 0, 5);
      expect((color.r * 255).round(), 255);
      expect((color.g * 255).round(), 0);
      expect((color.b * 255).round(), 255);
    });

    test('Cyan (Green + Blue equal)', () {
      final color = ColorLogic.createMixedColor(0, 5, 5);
      expect((color.r * 255).round(), 0);
      expect((color.g * 255).round(), 255);
      expect((color.b * 255).round(), 255);
    });

    test('Light pink (Red + mostly white)', () {
      final color = ColorLogic.createMixedColor(2, 0, 0, whiteDrops: 8);
      expect((color.r * 255).round(), 255);
      expect((color.g * 255).round(), closeTo(204, 5)); // 80% of 255
      expect((color.b * 255).round(), closeTo(204, 5));
    });

    test('Dark blue (Blue + mostly black)', () {
      final color = ColorLogic.createMixedColor(0, 0, 8, blackDrops: 2);
      expect((color.r * 255).round(), 0);
      expect((color.g * 255).round(), 0);
      expect((color.b * 255).round(), closeTo(204, 10)); // 80% of 255
    });

    test('checkMatch perfect match returns 100', () {
      const color1 = Color.fromARGB(255, 255, 128, 64);
      const color2 = Color.fromARGB(255, 255, 128, 64);
      final match = ColorLogic.checkMatch(color1, color2);
      expect(match, equals(100.0));
    });

    test('checkMatch identical colors returns 100', () {
      const color = Colors.red;
      final match = ColorLogic.checkMatch(color, color);
      expect(match, equals(100.0));
    });

    test('checkMatch very different colors returns low value', () {
      const color1 = Colors.white;
      const color2 = Colors.black;
      final match = ColorLogic.checkMatch(color1, color2);
      expect(match, lessThan(10.0));
    });

    test('checkMatch similar colors returns high value', () {
      const color1 = Color.fromARGB(255, 255, 0, 0);
      const color2 = Color.fromARGB(255, 250, 0, 0);
      final match = ColorLogic.checkMatch(color1, color2);
      expect(match, greaterThan(95.0));
    });

    test('generateRandomHardColor returns valid color', () {
      final color = ColorLogic.generateRandomHardColor();
      expect(color.r, greaterThanOrEqualTo(0.0));
      expect(color.r, lessThanOrEqualTo(1.0));
      expect(color.g, greaterThanOrEqualTo(0.0));
      expect(color.g, lessThanOrEqualTo(1.0));
      expect(color.b, greaterThanOrEqualTo(0.0));
      expect(color.b, lessThanOrEqualTo(1.0));
    });

    test('Maximum drops does not overflow', () {
      final color = ColorLogic.createMixedColor(100, 100, 100);
      expect((color.r * 255).round(), 255);
      expect((color.g * 255).round(), 255);
      expect((color.b * 255).round(), 255);
    });

    test('Asymmetric color mixing', () {
      final color = ColorLogic.createMixedColor(10, 5, 1);
      // Red should dominate, green secondary, blue minimal
      expect((color.r * 255).round(), 255);
      expect((color.g * 255).round(), closeTo(127, 10)); // ~50% of red
      expect((color.b * 255).round(), closeTo(25, 10)); // ~10% of red
    });
  });
}
