import 'package:flutter/material.dart';

class LevelModel {
  final int id;
  final int maxDrops;
  final double difficultyFactor; // من 0 لـ 1 (بتحدد تعقيد اللون الهدف)
  final List<Color> availableColors;

  LevelModel({
    required this.id,
    required this.maxDrops,
    required this.difficultyFactor,
    required this.availableColors,
  });
}
