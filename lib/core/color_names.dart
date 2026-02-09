import 'package:flutter/material.dart';

class ColorNameGenerator {
  static final Map<int, String> _classicLevelNames = {
    1: "Crimson Red",
    2: "Emerald Green",
    3: "Azure Blue",
    4: "Lemon Yellow",
    5: "Cyan",
    6: "Magenta",
    7: "Lime Green",
    8: "Violet",
    9: "Orange",
    10: "Teal",
    11: "Pink",
    12: "Chartreuse",
    13: "Spring Green",
    14: "Indigo",
    15: "Rose",
    16: "Aquamarine",
    17: "Amber",
    18: "Electric Blue",
    19: "Scarlet",
    20: "Forest Green",
    21: "Midnight Blue",
    22: "Gold",
    23: "Silver", // Often gray/white mixes
    24: "Bronze",
    25: "Turquoise",
    26: "Lavender",
    27: "Maroon",
    28: "Olive",
    29: "Navy",
    30: "Coral",
    31: "Salmon",
    32: "Khaki",
    33: "Plum",
    34: "Orchid",
    35: "Sienna",
    36: "Chocolate",
    37: "Sandy Brown",
    38: "Tan",
    39: "Wheat",
    40: "Beige",
    41: "Mint",
    42: "Apricot",
    43: "Peach",
    44: "Mauve",
    45: "Taupe",
    46: "Sepia",
    47: "Slate Gray",
    48: "Charcoal",
    49: "Ivory",
    50: "Ebony",
  };

  static String getNameForLevel(int levelId) {
    if (_classicLevelNames.containsKey(levelId)) {
      return _classicLevelNames[levelId]!;
    }
    // Fallback for higher levels
    return "Unknown Specimen #$levelId";
  }

  static String getDescriptionForLevel(int levelId) {
    if (_classicLevelNames.containsKey(levelId)) {
      return "A distinct hue discovered in the classic spectrum analysis.";
    }
    return "A complex compound color requiring advanced synthesis.";
  }
}
