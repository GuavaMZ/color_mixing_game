import 'package:flutter/material.dart';

/// Represents a single color entry in the gallery
class ColorEntry {
  final int id;
  final Color color;
  final Map<String, int> recipe;
  final String category;
  final String name;
  final String description;

  const ColorEntry({
    required this.id,
    required this.color,
    required this.recipe,
    required this.category,
    required this.name,
    required this.description,
  });

  /// Get Hex Code (e.g., #FF0000)
  String get hexCode {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  /// Get HSV Color
  HSVColor get hsv => HSVColor.fromColor(color);

  /// Get CMYK Values (C, M, Y, K) as percentage integers
  List<int> get cmyk {
    double r = color.red / 255.0;
    double g = color.green / 255.0;
    double b = color.blue / 255.0;

    double k =
        1.0 - [r, g, b].reduce((curr, next) => curr > next ? curr : next);
    if (k == 1.0) return [0, 0, 0, 100];

    double c = (1.0 - r - k) / (1.0 - k);
    double m = (1.0 - g - k) / (1.0 - k);
    double y = (1.0 - b - k) / (1.0 - k);

    return [
      (c * 100).round(),
      (m * 100).round(),
      (y * 100).round(),
      (k * 100).round(),
    ];
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'color': color.value,
      'recipe': recipe,
      'category': category,
      'name': name,
      'description': description,
    };
  }

  /// Create from JSON
  factory ColorEntry.fromJson(Map<String, dynamic> json) {
    return ColorEntry(
      id: json['id'] as int,
      color: Color(json['color'] as int),
      recipe: Map<String, int>.from(json['recipe'] as Map),
      category: json['category'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
    );
  }
}
