import 'dart:math';
import 'package:flutter/material.dart';
import 'package:color_mixing_deductive/core/color_logic.dart';
import 'package:color_mixing_deductive/core/color_entry.dart';

/// Generates a comprehensive palette of all unique colors possible in the game
class ColorPaletteGenerator {
  static List<ColorEntry>? _cachedPalette;
  static const double _uniquenessThreshold = 5.0; // RGB distance threshold

  /// Get the complete color palette (cached)
  static List<ColorEntry> getCompletePalette() {
    _cachedPalette ??= _generatePalette();
    return _cachedPalette!;
  }

  /// Clear cache (for testing or regeneration)
  static void clearCache() {
    _cachedPalette = null;
  }

  /// Generate the complete color palette
  static List<ColorEntry> _generatePalette() {
    final List<ColorEntry> palette = [];
    int idCounter = 1;

    // Phase 1: Primary Colors (3 colors)
    palette.addAll(_generatePrimaryColors(idCounter));
    idCounter += palette.length;

    // Phase 2: Secondary Colors (Binary mixes: RG, RB, GB)
    final secondaryColors = _generateSecondaryColors(idCounter, palette);
    palette.addAll(secondaryColors);
    idCounter += secondaryColors.length;

    // Phase 3: Tertiary Colors (RGB combinations)
    final tertiaryColors = _generateTertiaryColors(idCounter, palette);
    palette.addAll(tertiaryColors);
    idCounter += tertiaryColors.length;

    // Phase 4: Tinted Colors (Colors + White)
    final tintedColors = _generateTintedColors(idCounter, palette);
    palette.addAll(tintedColors);
    idCounter += tintedColors.length;

    // Phase 5: Shaded Colors (Colors + Black)
    final shadedColors = _generateShadedColors(idCounter, palette);
    palette.addAll(shadedColors);
    idCounter += shadedColors.length;

    // Phase 6: Complex Colors (RGB + W/K combinations)
    final complexColors = _generateComplexColors(idCounter, palette);
    palette.addAll(complexColors);

    return palette;
  }

  /// Generate primary colors: Pure R, G, B
  static List<ColorEntry> _generatePrimaryColors(int startId) {
    return [
      ColorEntry(
        id: startId,
        color: ColorLogic.createMixedColor(5, 0, 0),
        recipe: {'red': 5, 'green': 0, 'blue': 0, 'white': 0, 'black': 0},
        category: 'primary',
        name: 'Pure Red',
        description: 'The fundamental red primary color',
      ),
      ColorEntry(
        id: startId + 1,
        color: ColorLogic.createMixedColor(0, 5, 0),
        recipe: {'red': 0, 'green': 5, 'blue': 0, 'white': 0, 'black': 0},
        category: 'primary',
        name: 'Pure Green',
        description: 'The fundamental green primary color',
      ),
      ColorEntry(
        id: startId + 2,
        color: ColorLogic.createMixedColor(0, 0, 5),
        recipe: {'red': 0, 'green': 0, 'blue': 5, 'white': 0, 'black': 0},
        category: 'primary',
        name: 'Pure Blue',
        description: 'The fundamental blue primary color',
      ),
    ];
  }

  /// Generate secondary colors: RG, RB, GB combinations
  static List<ColorEntry> _generateSecondaryColors(
    int startId,
    List<ColorEntry> existing,
  ) {
    final List<ColorEntry> colors = [];
    int id = startId;

    // Binary combinations: RG, RB, GB
    final combinations = [
      {'name': 'Yellow', 'r': true, 'g': true, 'b': false},
      {'name': 'Magenta', 'r': true, 'g': false, 'b': true},
      {'name': 'Cyan', 'r': false, 'g': true, 'b': true},
    ];

    for (var combo in combinations) {
      // Try different ratios: 1:1, 2:1, 1:2, 3:1, 1:3, 3:2, 2:3
      final ratios = [
        [1, 1],
        [2, 1],
        [1, 2],
        [3, 1],
        [1, 3],
        [3, 2],
        [2, 3],
        [4, 1],
        [1, 4],
      ];

      for (var ratio in ratios) {
        int r = (combo['r'] as bool) ? ratio[0] : 0;
        int g = (combo['g'] as bool) ? ratio[0] : 0;
        int b = (combo['b'] as bool) ? ratio[0] : 0;

        // Set second component
        if (combo['r'] as bool && combo['g'] as bool) {
          g = ratio[1];
        } else if (combo['r'] as bool && combo['b'] as bool) {
          b = ratio[1];
        } else if (combo['g'] as bool && combo['b'] as bool) {
          b = ratio[1];
        }

        final color = ColorLogic.createMixedColor(r, g, b);
        if (_isUniqueColor(color, existing) && _isUniqueColor(color, colors)) {
          colors.add(
            ColorEntry(
              id: id++,
              color: color,
              recipe: {'red': r, 'green': g, 'blue': b, 'white': 0, 'black': 0},
              category: 'secondary',
              name: _generateSecondaryName(r, g, b),
              description: 'A secondary color blend',
            ),
          );
        }
      }
    }

    return colors;
  }

  /// Generate tertiary colors: RGB combinations
  static List<ColorEntry> _generateTertiaryColors(
    int startId,
    List<ColorEntry> existing,
  ) {
    final List<ColorEntry> colors = [];
    int id = startId;

    // RGB combinations with varying ratios
    for (int r = 1; r <= 4; r++) {
      for (int g = 1; g <= 4; g++) {
        for (int b = 1; b <= 4; b++) {
          final color = ColorLogic.createMixedColor(r, g, b);
          if (_isUniqueColor(color, existing) &&
              _isUniqueColor(color, colors)) {
            colors.add(
              ColorEntry(
                id: id++,
                color: color,
                recipe: {
                  'red': r,
                  'green': g,
                  'blue': b,
                  'white': 0,
                  'black': 0,
                },
                category: 'tertiary',
                name: _generateTertiaryName(r, g, b),
                description: 'A complex tertiary color',
              ),
            );
          }
        }
      }
    }

    return colors;
  }

  /// Generate tinted colors: Base colors + White
  static List<ColorEntry> _generateTintedColors(
    int startId,
    List<ColorEntry> existing,
  ) {
    final List<ColorEntry> colors = [];
    int id = startId;

    // Take base colors and add white
    for (int r = 1; r <= 3; r++) {
      for (int g = 0; g <= 3; g++) {
        for (int b = 0; b <= 3; b++) {
          if (r + g + b == 0) continue;

          for (int w = 1; w <= 4; w++) {
            final color = ColorLogic.createMixedColor(r, g, b, whiteDrops: w);
            if (_isUniqueColor(color, existing) &&
                _isUniqueColor(color, colors)) {
              colors.add(
                ColorEntry(
                  id: id++,
                  color: color,
                  recipe: {
                    'red': r,
                    'green': g,
                    'blue': b,
                    'white': w,
                    'black': 0,
                  },
                  category: 'tinted',
                  name: _generateTintedName(r, g, b, w),
                  description: 'A lightened tint variation',
                ),
              );
            }
          }
        }
      }
    }

    return colors;
  }

  /// Generate shaded colors: Base colors + Black
  static List<ColorEntry> _generateShadedColors(
    int startId,
    List<ColorEntry> existing,
  ) {
    final List<ColorEntry> colors = [];
    int id = startId;

    // Take base colors and add black
    for (int r = 1; r <= 3; r++) {
      for (int g = 0; g <= 3; g++) {
        for (int b = 0; b <= 3; b++) {
          if (r + g + b == 0) continue;

          for (int k = 1; k <= 4; k++) {
            final color = ColorLogic.createMixedColor(r, g, b, blackDrops: k);
            if (_isUniqueColor(color, existing) &&
                _isUniqueColor(color, colors)) {
              colors.add(
                ColorEntry(
                  id: id++,
                  color: color,
                  recipe: {
                    'red': r,
                    'green': g,
                    'blue': b,
                    'white': 0,
                    'black': k,
                  },
                  category: 'shaded',
                  name: _generateShadedName(r, g, b, k),
                  description: 'A darkened shade variation',
                ),
              );
            }
          }
        }
      }
    }

    return colors;
  }

  /// Generate complex colors: RGB + W + K combinations
  static List<ColorEntry> _generateComplexColors(
    int startId,
    List<ColorEntry> existing,
  ) {
    final List<ColorEntry> colors = [];
    int id = startId;

    // RGB + both white and black
    for (int r = 1; r <= 2; r++) {
      for (int g = 1; g <= 2; g++) {
        for (int b = 1; b <= 2; b++) {
          for (int w = 1; w <= 2; w++) {
            for (int k = 1; k <= 2; k++) {
              final color = ColorLogic.createMixedColor(
                r,
                g,
                b,
                whiteDrops: w,
                blackDrops: k,
              );
              if (_isUniqueColor(color, existing) &&
                  _isUniqueColor(color, colors)) {
                colors.add(
                  ColorEntry(
                    id: id++,
                    color: color,
                    recipe: {
                      'red': r,
                      'green': g,
                      'blue': b,
                      'white': w,
                      'black': k,
                    },
                    category: 'complex',
                    name: _generateComplexName(r, g, b, w, k),
                    description: 'A sophisticated complex blend',
                  ),
                );
              }
            }
          }
        }
      }
    }

    return colors;
  }

  /// Check if color is unique (not too similar to existing colors)
  static bool _isUniqueColor(Color color, List<ColorEntry> existing) {
    for (var entry in existing) {
      if (_colorDistance(color, entry.color) < _uniquenessThreshold) {
        return false;
      }
    }
    return true;
  }

  /// Calculate perceptual distance between two colors
  static double _colorDistance(Color a, Color b) {
    int rDiff = (a.red - b.red).abs();
    int gDiff = (a.green - b.green).abs();
    int bDiff = (a.blue - b.blue).abs();
    return (rDiff + gDiff + bDiff) / 3.0;
  }

  // Naming helpers
  static String _generateSecondaryName(int r, int g, int b) {
    if (r > 0 && g > 0) {
      if (r > g * 2) return 'Orange Red';
      if (g > r * 2) return 'Chartreuse';
      return 'Yellow';
    }
    if (r > 0 && b > 0) {
      if (r > b * 2) return 'Red Violet';
      if (b > r * 2) return 'Blue Violet';
      return 'Magenta';
    }
    if (g > 0 && b > 0) {
      if (g > b * 2) return 'Spring Green';
      if (b > g * 2) return 'Azure';
      return 'Cyan';
    }
    return 'Secondary';
  }

  static String _generateTertiaryName(int r, int g, int b) {
    final dominant = max(max(r, g), b);
    if (r == dominant && g == dominant) return 'Amber';
    if (r == dominant && b == dominant) return 'Rose';
    if (g == dominant && b == dominant) return 'Teal';
    if (r == dominant) return 'Crimson';
    if (g == dominant) return 'Emerald';
    if (b == dominant) return 'Sapphire';
    return 'Tertiary Blend';
  }

  static String _generateTintedName(int r, int g, int b, int w) {
    final base = _generateTertiaryName(r, g, b);
    if (w >= 3) return 'Pale $base';
    if (w >= 2) return 'Light $base';
    return 'Pastel $base';
  }

  static String _generateShadedName(int r, int g, int b, int k) {
    final base = _generateTertiaryName(r, g, b);
    if (k >= 3) return 'Deep $base';
    if (k >= 2) return 'Dark $base';
    return 'Shaded $base';
  }

  static String _generateComplexName(int r, int g, int b, int w, int k) {
    final base = _generateTertiaryName(r, g, b);
    if (w > k) return 'Muted $base';
    if (k > w) return 'Dusty $base';
    return 'Toned $base';
  }
}
