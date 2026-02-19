import 'dart:math';
import 'package:flutter/material.dart';

/// Scientific color analysis utilities for Color Lab.
///
/// Provides wavelength estimation, color temperature classification,
/// complementary color calculation, harmony detection, CIE Delta-E
/// perceptual distance, and educational color facts.
class ColorScience {
  // ───────────────────────────────────────────────────────────────
  //  CIE L*a*b* & Delta-E (CIE76)
  // ───────────────────────────────────────────────────────────────

  /// Convert an sRGB [Color] to CIE L*a*b* (D65 illuminant).
  static List<double> rgbToLab(Color c) {
    // 1. Linearize sRGB → XYZ
    double r = _linearize(c.red / 255.0);
    double g = _linearize(c.green / 255.0);
    double b = _linearize(c.blue / 255.0);

    // sRGB → XYZ (D65)
    double x = (0.4124564 * r + 0.3575761 * g + 0.1804375 * b) / 0.95047;
    double y = (0.2126729 * r + 0.7151522 * g + 0.0721750 * b) / 1.00000;
    double z = (0.0193339 * r + 0.1191920 * g + 0.9503041 * b) / 1.08883;

    // 2. XYZ → L*a*b*
    x = _labF(x);
    y = _labF(y);
    z = _labF(z);

    double lStar = 116.0 * y - 16.0;
    double aStar = 500.0 * (x - y);
    double bStar = 200.0 * (y - z);

    return [lStar, aStar, bStar];
  }

  /// CIE76 Delta-E perceptual distance between two colors.
  ///
  /// Returns 0 for identical colors. Typical values:
  /// - 0–2: imperceptible difference
  /// - 2–10: small difference
  /// - 10–50: noticeable difference
  /// - 50+: very different colors
  static double deltaE76(Color a, Color b) {
    final labA = rgbToLab(a);
    final labB = rgbToLab(b);

    final dL = labA[0] - labB[0];
    final dA = labA[1] - labB[1];
    final dB = labA[2] - labB[2];

    return sqrt(dL * dL + dA * dA + dB * dB);
  }

  static double _linearize(double v) {
    return v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
  }

  static double _labF(double t) {
    const double delta = 6.0 / 29.0;
    if (t > delta * delta * delta) {
      return pow(t, 1.0 / 3.0).toDouble();
    }
    return t / (3.0 * delta * delta) + 4.0 / 29.0;
  }

  // ───────────────────────────────────────────────────────────────
  //  Wavelength Estimation
  // ───────────────────────────────────────────────────────────────

  /// Estimate the dominant wavelength of a color (380–780 nm).
  ///
  /// Maps hue angle to approximate spectral wavelength.
  /// Non-spectral purples/magentas return an average of red & violet ends.
  static int estimateWavelength(Color color) {
    final hsv = HSVColor.fromColor(color);
    final double hue = hsv.hue; // 0–360

    // Hue-to-wavelength mapping (approximate, based on visible spectrum)
    if (hue <= 15) return 700; // Deep red
    if (hue <= 45) return 620; // Orange
    if (hue <= 70) return 580; // Yellow
    if (hue <= 100) return 560; // Yellow-green
    if (hue <= 150) return 530; // Green
    if (hue <= 180) return 510; // Cyan-green
    if (hue <= 210) return 490; // Cyan
    if (hue <= 250) return 470; // Blue
    if (hue <= 280) return 450; // Indigo
    if (hue <= 310) return 420; // Violet
    // 310–360: Non-spectral (magenta/pink) — average of red & violet
    return 560; // Mid-spectrum average for non-spectral
  }

  /// Return a human-readable spectral region name.
  static String getSpectralRegion(int wavelength) {
    if (wavelength >= 620) return 'Red';
    if (wavelength >= 590) return 'Orange';
    if (wavelength >= 570) return 'Yellow';
    if (wavelength >= 495) return 'Green';
    if (wavelength >= 475) return 'Blue';
    if (wavelength >= 450) return 'Indigo';
    return 'Violet';
  }

  // ───────────────────────────────────────────────────────────────
  //  Color Temperature
  // ───────────────────────────────────────────────────────────────

  /// Classify a color's perceived temperature.
  ///
  /// Returns a map with:
  /// - `label`: "Warm", "Cool", or "Neutral"
  /// - `kelvin`: approximate correlated color temperature (2000–10000 K)
  /// - `icon`: suggested icon code point (fire, snowflake, or balance)
  static Map<String, dynamic> getColorTemperature(Color color) {
    final hsv = HSVColor.fromColor(color);
    final double hue = hsv.hue;
    final double sat = hsv.saturation;

    // Low saturation = neutral
    if (sat < 0.15) {
      return {'label': 'neutral', 'kelvin': 6500, 'icon': 0xe1b5};
    }

    // Warm: reds, oranges, yellows (0–70° and 330–360°)
    if (hue <= 70 || hue >= 330) {
      int kelvin =
          2000 + ((70 - (hue <= 70 ? hue : hue - 360).abs()) * 40).round();
      return {
        'label': 'warm',
        'kelvin': kelvin.clamp(2000, 5000),
        'icon': 0xe518,
      };
    }

    // Cool: blues, cyans, some greens (170–290°)
    if (hue >= 170 && hue < 290) {
      int kelvin = 7000 + ((hue - 170) * 25).round();
      return {
        'label': 'cool',
        'kelvin': kelvin.clamp(7000, 10000),
        'icon': 0xef47,
      };
    }

    // Transition zones
    return {'label': 'neutral', 'kelvin': 6500, 'icon': 0xe1b5};
  }

  // ───────────────────────────────────────────────────────────────
  //  Color Harmony
  // ───────────────────────────────────────────────────────────────

  /// Get the complementary color (180° opposite on the hue wheel).
  static Color getComplementaryColor(Color color) {
    final hsv = HSVColor.fromColor(color);
    final newHue = (hsv.hue + 180.0) % 360.0;
    return HSVColor.fromAHSV(1.0, newHue, hsv.saturation, hsv.value).toColor();
  }

  /// Determine the color harmony relationship between two colors.
  ///
  /// Returns one of: 'complementary', 'analogous', 'triadic',
  /// 'splitComplementary', or 'neutral'.
  static String getHarmonyType(Color a, Color b) {
    final hsvA = HSVColor.fromColor(a);
    final hsvB = HSVColor.fromColor(b);

    double diff = (hsvA.hue - hsvB.hue).abs();
    if (diff > 180) diff = 360 - diff;

    // Low saturation on either = hard to classify
    if (hsvA.saturation < 0.1 || hsvB.saturation < 0.1) return 'neutral';

    if (diff < 30) return 'analogous';
    if (diff >= 150 && diff <= 210) return 'complementary';
    if (diff >= 110 && diff < 150) return 'splitComplementary';
    if ((diff >= 100 && diff < 140) || (diff >= 220 && diff < 260)) {
      return 'triadic';
    }

    return 'neutral';
  }

  // ───────────────────────────────────────────────────────────────
  //  "Did You Know?" Color Facts
  // ───────────────────────────────────────────────────────────────

  /// Get a color-science fact relevant to the given color.
  static String getColorFact(Color color) {
    final hsv = HSVColor.fromColor(color);
    final hue = hsv.hue;
    final rng = Random();

    // Facts curated by hue region + general pool
    final List<String> facts;

    if (hue <= 30 || hue >= 330) {
      // Red / Pink
      facts = [
        'Red light has the longest wavelength (~700 nm) of any visible color.',
        'Red is the first color humans historically named after black and white.',
        'Your eye has more cone cells sensitive to red (L-cones) than any other type.',
        'Mars appears red due to iron oxide (rust) on its surface.',
      ];
    } else if (hue <= 70) {
      // Orange / Yellow
      facts = [
        'Yellow is the most visible color from a distance — that\'s why taxis are yellow!',
        'Sodium street lamps emit a nearly pure yellow at 589 nm.',
        'The human eye can distinguish more shades of green and yellow than any other color.',
        'Orange was named after the fruit, not the other way around.',
      ];
    } else if (hue <= 160) {
      // Green
      facts = [
        'Plants are green because chlorophyll reflects green wavelengths (~530 nm).',
        'Human eyes have the highest sensitivity around 555 nm — bright green.',
        'Night vision goggles display in green because our eyes resolve more green shades.',
        'The word "green" comes from the Old English "grēne", meaning "to grow".',
      ];
    } else if (hue <= 260) {
      // Blue / Cyan
      facts = [
        'The sky appears blue due to Rayleigh scattering of shorter wavelengths.',
        'Blue is the rarest colour in nature — very few organisms produce blue pigment.',
        'Blue LEDs won the 2014 Nobel Prize in Physics (Akasaki, Amano & Nakamura).',
        'Ancient civilizations rarely had a word for "blue" — it was one of the last colors named.',
      ];
    } else {
      // Purple / Violet
      facts = [
        'Violet light has the shortest visible wavelength (~380 nm) and highest energy.',
        'True purple does not exist in the rainbow — it requires mixing red and blue.',
        'Tyrian purple dye was once worth more than gold — made from sea snail mucus.',
        'UV "black lights" emit light just beyond violet, making fluorescent colors glow.',
      ];
    }

    // Mix in 2 general facts
    final general = [
      'White light contains all wavelengths of the visible spectrum (380–780 nm).',
      'The CIE L*a*b* color space was designed to be perceptually uniform in 1976.',
      'A healthy human eye can distinguish roughly 10 million different colors.',
      'Color mixing with light (additive: RGB) differs from mixing paint (subtractive: CMY).',
      'The color wheel was invented by Sir Isaac Newton in 1666.',
    ];

    final allFacts = [...facts, ...general];
    return allFacts[rng.nextInt(allFacts.length)];
  }
}
