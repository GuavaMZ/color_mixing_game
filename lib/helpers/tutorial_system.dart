import 'package:color_mixing_deductive/core/save_manager.dart';
import 'package:flutter/material.dart';

/// Manages the tutorial/onboarding experience for first-time players
class TutorialSystem {
  static const String _tutorialKey = 'tutorial_completed';
  static const String _tooltipsKey = 'tooltips_shown';

  /// Check if user has completed the tutorial
  static Future<bool> isTutorialCompleted() async {
    return await SaveManager.getBool(_tutorialKey) ?? false;
  }

  /// Mark tutorial as completed
  static Future<void> completeTutorial() async {
    await SaveManager.saveBool(_tutorialKey, true);
  }

  /// Check if a specific tooltip has been shown
  static Future<bool> hasShownTooltip(String tooltipId) async {
    final shown = await SaveManager.getStringList(_tooltipsKey) ?? [];
    return shown.contains(tooltipId);
  }

  /// Mark a tooltip as shown
  static Future<void> markTooltipShown(String tooltipId) async {
    final shown = await SaveManager.getStringList(_tooltipsKey) ?? [];
    if (!shown.contains(tooltipId)) {
      shown.add(tooltipId);
      await SaveManager.saveStringList(_tooltipsKey, shown);
    }
  }

  /// Reset tutorial progress (for testing)
  static Future<void> resetTutorial() async {
    await SaveManager.saveBool(_tutorialKey, false);
    await SaveManager.saveStringList(_tooltipsKey, []);
  }
}

/// Tutorial step data
class TutorialStep {
  final String title;
  final String description;
  final IconData icon;
  final Alignment position;
  final VoidCallback? onComplete;

  const TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
    this.position = Alignment.center,
    this.onComplete,
  });
}

/// Tutorial steps for the game
class TutorialSteps {
  static const List<TutorialStep> mainTutorial = [
    TutorialStep(
      title: 'Welcome to Color Lab!',
      description: 'Mix colors to match the target. Let\'s learn the basics!',
      icon: Icons.science,
      position: Alignment.center,
    ),
    TutorialStep(
      title: 'Target Color',
      description:
          'This is the color you need to create. Match it perfectly to win!',
      icon: Icons.palette,
      position: Alignment.topCenter,
    ),
    TutorialStep(
      title: 'Color Drops',
      description:
          'Tap these buttons to add color drops to your beaker. Mix Red, Green, and Blue!',
      icon: Icons.water_drop,
      position: Alignment.bottomCenter,
    ),
    TutorialStep(
      title: 'Match Percentage',
      description: 'This shows how close you are to the target. Aim for 100%!',
      icon: Icons.percent,
      position: Alignment.topLeft,
    ),
    TutorialStep(
      title: 'Helpers',
      description:
          'Use helpers like Undo, Extra Drops, or Hints when you\'re stuck!',
      icon: Icons.help_outline,
      position: Alignment.topRight,
    ),
  ];
}
