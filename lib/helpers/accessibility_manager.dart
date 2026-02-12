import 'package:color_mixing_deductive/core/save_manager.dart';

/// Manages accessibility settings for the game
class AccessibilityManager {
  static final AccessibilityManager _instance =
      AccessibilityManager._internal();
  factory AccessibilityManager() => _instance;
  AccessibilityManager._internal();

  // Colorblind modes
  ColorblindMode _colorblindMode = ColorblindMode.none;
  ColorblindMode get colorblindMode => _colorblindMode;

  // High contrast mode
  bool _highContrastMode = false;
  bool get highContrastMode => _highContrastMode;

  // Reduced motion
  bool _reducedMotion = false;
  bool get reducedMotion => _reducedMotion;

  /// Initialize from saved settings
  Future<void> init() async {
    final modeIndex = await SaveManager.getBool('colorblind_mode_index');
    if (modeIndex != null) {
      _colorblindMode = ColorblindMode.values[modeIndex ? 1 : 0];
    }

    _highContrastMode =
        await SaveManager.getBool('high_contrast_mode') ?? false;
    _reducedMotion = await SaveManager.getBool('reduced_motion') ?? false;
  }

  /// Set colorblind mode
  Future<void> setColorblindMode(ColorblindMode mode) async {
    _colorblindMode = mode;
    await SaveManager.saveBool('colorblind_mode_index', mode.index > 0);
  }

  /// Toggle high contrast mode
  Future<void> setHighContrastMode(bool enabled) async {
    _highContrastMode = enabled;
    await SaveManager.saveBool('high_contrast_mode', enabled);
  }

  /// Toggle reduced motion
  Future<void> setReducedMotion(bool enabled) async {
    _reducedMotion = enabled;
    await SaveManager.saveBool('reduced_motion', enabled);
  }

  /// Get animation duration multiplier (reduced if motion is reduced)
  double getAnimationMultiplier() {
    return _reducedMotion ? 0.5 : 1.0;
  }

  /// Should show particle effects?
  bool shouldShowParticles() {
    return !_reducedMotion;
  }
}

/// Colorblind mode types
enum ColorblindMode {
  none,
  protanopia, // Red-blind
  deuteranopia, // Green-blind
  tritanopia, // Blue-blind
}

/// Extension to get user-friendly names
extension ColorblindModeExtension on ColorblindMode {
  String get displayName {
    switch (this) {
      case ColorblindMode.none:
        return 'None';
      case ColorblindMode.protanopia:
        return 'Protanopia (Red-blind)';
      case ColorblindMode.deuteranopia:
        return 'Deuteranopia (Green-blind)';
      case ColorblindMode.tritanopia:
        return 'Tritanopia (Blue-blind)';
    }
  }
}
