import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:color_mixing_deductive/core/color_science.dart';
import 'package:color_mixing_deductive/core/color_logic.dart';

void main() {
  group('ColorScience - CIE Delta-E76', () {
    test('Identical colors have delta-E of 0', () {
      const color = Color(0xFFFF0000);
      expect(ColorScience.deltaE76(color, color), 0.0);
    });

    test('Very similar colors have low delta-E', () {
      const a = Color(0xFF808080);
      const b = Color(0xFF818181);
      final deltaE = ColorScience.deltaE76(a, b);
      expect(deltaE, lessThan(2.0));
    });

    test('Pure red vs pure green has high delta-E', () {
      const red = Color(0xFFFF0000);
      const green = Color(0xFF00FF00);
      final deltaE = ColorScience.deltaE76(red, green);
      expect(deltaE, greaterThan(50.0));
    });

    test('Black vs white has high delta-E', () {
      const black = Color(0xFF000000);
      const white = Color(0xFFFFFFFF);
      final deltaE = ColorScience.deltaE76(black, white);
      expect(deltaE, greaterThan(90.0)); // L* goes 0 to 100
    });

    test('RGB to Lab for black returns L=0', () {
      final lab = ColorScience.rgbToLab(const Color(0xFF000000));
      expect(lab[0], closeTo(0.0, 0.5));
    });

    test('RGB to Lab for white returns L≈100', () {
      final lab = ColorScience.rgbToLab(const Color(0xFFFFFFFF));
      expect(lab[0], closeTo(100.0, 0.5));
    });
  });

  group('ColorScience - Wavelength Estimation', () {
    test('Red yields wavelength near 700nm', () {
      final wl = ColorScience.estimateWavelength(const Color(0xFFFF0000));
      expect(wl, greaterThanOrEqualTo(620));
      expect(wl, lessThanOrEqualTo(700));
    });

    test('Green yields wavelength near 530nm', () {
      final wl = ColorScience.estimateWavelength(const Color(0xFF00FF00));
      expect(wl, greaterThanOrEqualTo(510));
      expect(wl, lessThanOrEqualTo(560));
    });

    test('Blue yields wavelength near 470nm', () {
      final wl = ColorScience.estimateWavelength(const Color(0xFF0000FF));
      expect(wl, greaterThanOrEqualTo(450));
      expect(wl, lessThanOrEqualTo(490));
    });

    test('Wavelength always within visible spectrum', () {
      // Test a variety of colors
      final colors = [
        const Color(0xFFFF0000),
        const Color(0xFF00FF00),
        const Color(0xFF0000FF),
        const Color(0xFFFFFF00),
        const Color(0xFFFF00FF),
        const Color(0xFF00FFFF),
        const Color(0xFF808080),
      ];
      for (final c in colors) {
        final wl = ColorScience.estimateWavelength(c);
        expect(wl, greaterThanOrEqualTo(380));
        expect(wl, lessThanOrEqualTo(780));
      }
    });

    test('Spectral region names are valid', () {
      final validNames = [
        'Red',
        'Orange',
        'Yellow',
        'Green',
        'Blue',
        'Indigo',
        'Violet',
      ];
      for (int wl = 380; wl <= 780; wl += 10) {
        expect(validNames, contains(ColorScience.getSpectralRegion(wl)));
      }
    });
  });

  group('ColorScience - Color Temperature', () {
    test('Red is classified as warm', () {
      final temp = ColorScience.getColorTemperature(const Color(0xFFFF0000));
      expect(temp['label'], 'warm');
    });

    test('Blue is classified as cool', () {
      final temp = ColorScience.getColorTemperature(const Color(0xFF0000FF));
      expect(temp['label'], 'cool');
    });

    test('Grey is classified as neutral', () {
      final temp = ColorScience.getColorTemperature(const Color(0xFF808080));
      expect(temp['label'], 'neutral');
    });

    test('Temperature kelvin values are reasonable', () {
      final temp = ColorScience.getColorTemperature(const Color(0xFFFF4400));
      final kelvin = temp['kelvin'] as int;
      expect(kelvin, greaterThanOrEqualTo(2000));
      expect(kelvin, lessThanOrEqualTo(10000));
    });
  });

  group('ColorScience - Color Harmony', () {
    test('Complementary colors are detected (red vs cyan)', () {
      final harmony = ColorScience.getHarmonyType(
        const Color(0xFFFF0000), // Red
        const Color(0xFF00FFFF), // Cyan
      );
      expect(harmony, 'complementary');
    });

    test('Analogous colors are detected', () {
      final harmony = ColorScience.getHarmonyType(
        const Color(0xFFFF0000), // Red
        const Color(0xFFFF4400), // Orange-red
      );
      expect(harmony, 'analogous');
    });

    test('Low saturation returns neutral', () {
      final harmony = ColorScience.getHarmonyType(
        const Color(0xFF808080), // Grey
        const Color(0xFFFF0000), // Red
      );
      expect(harmony, 'neutral');
    });
  });

  group('ColorScience - Complementary Color', () {
    test('Complementary of red is cyan-ish', () {
      final comp = ColorScience.getComplementaryColor(const Color(0xFFFF0000));
      // Red hue=0° → complementary hue=180° → Cyan
      final compHsv = HSVColor.fromColor(comp);
      expect(compHsv.hue, closeTo(180.0, 5.0));
    });
  });

  group('ColorScience - Color Facts', () {
    test('Returns a non-empty string', () {
      final fact = ColorScience.getColorFact(const Color(0xFFFF0000));
      expect(fact, isNotEmpty);
    });

    test('Different colors can give different facts', () {
      // Getting random facts, so just ensure no crashes
      final colors = [
        const Color(0xFFFF0000),
        const Color(0xFF00FF00),
        const Color(0xFF0000FF),
        const Color(0xFFFFFF00),
        const Color(0xFF800080),
      ];
      for (final c in colors) {
        expect(ColorScience.getColorFact(c), isNotEmpty);
      }
    });
  });

  group('ColorLogic.checkMatch with Delta-E', () {
    test('Identical colors give 100% match', () {
      const target = Color(0xFFFF0000);
      expect(ColorLogic.checkMatch(target, target), 100.0);
    });

    test('Very similar colors give high match', () {
      const a = Color(0xFF808080);
      const b = Color(0xFF828282);
      final match = ColorLogic.checkMatch(a, b);
      expect(match, greaterThan(95.0));
    });

    test('Very different colors give low match', () {
      const a = Color(0xFFFF0000);
      const b = Color(0xFF00FF00);
      final match = ColorLogic.checkMatch(a, b);
      expect(match, lessThan(10.0));
    });

    test('Match is always between 0 and 100', () {
      final colors = [
        const Color(0xFFFF0000),
        const Color(0xFF00FF00),
        const Color(0xFF0000FF),
        const Color(0xFF000000),
        const Color(0xFFFFFFFF),
      ];
      for (var a in colors) {
        for (var b in colors) {
          final match = ColorLogic.checkMatch(a, b);
          expect(match, greaterThanOrEqualTo(0.0));
          expect(match, lessThanOrEqualTo(100.0));
        }
      }
    });
  });
}
