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
