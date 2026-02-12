import 'package:flutter/foundation.dart';

/// Performance monitoring and optimization manager
class PerformanceManager {
  static final PerformanceManager _instance = PerformanceManager._internal();
  factory PerformanceManager() => _instance;
  PerformanceManager._internal();

  // Performance mode settings
  bool _lowPerformanceMode = false;
  bool get isLowPerformanceMode => _lowPerformanceMode;

  // FPS tracking
  final List<double> _fpsHistory = [];
  double _currentFps = 60.0;
  double get currentFps => _currentFps;
  double get averageFps {
    if (_fpsHistory.isEmpty) return 60.0;
    return _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length;
  }

  // Performance thresholds
  static const double _lowFpsThreshold = 30.0;
  static const int _fpsHistorySize = 60; // Track last 60 frames

  /// Update FPS tracking
  void updateFps(double fps) {
    _currentFps = fps;
    _fpsHistory.add(fps);

    // Keep history size manageable
    if (_fpsHistory.length > _fpsHistorySize) {
      _fpsHistory.removeAt(0);
    }

    // Auto-detect low performance
    if (averageFps < _lowFpsThreshold && !_lowPerformanceMode) {
      _enableLowPerformanceMode();
    }
  }

  /// Manually enable low performance mode
  void enableLowPerformanceMode() {
    _lowPerformanceMode = true;
    debugPrint('🔧 Low Performance Mode: ENABLED (Manual)');
  }

  /// Auto-enable low performance mode
  void _enableLowPerformanceMode() {
    _lowPerformanceMode = true;
    debugPrint('🔧 Low Performance Mode: ENABLED (Auto-detected low FPS)');
  }

  /// Disable low performance mode
  void disableLowPerformanceMode() {
    _lowPerformanceMode = false;
    debugPrint('🔧 Low Performance Mode: DISABLED');
  }

  /// Get particle count multiplier based on performance mode
  double getParticleMultiplier() {
    return _lowPerformanceMode ? 0.5 : 1.0;
  }

  /// Get update rate multiplier
  int getUpdateRateMultiplier() {
    return _lowPerformanceMode
        ? 2
        : 1; // Skip every other frame in low perf mode
  }

  /// Should skip this frame for non-critical updates?
  bool shouldSkipFrame(int frameCount) {
    if (!_lowPerformanceMode) return false;
    return frameCount % getUpdateRateMultiplier() != 0;
  }

  /// Reset performance tracking
  void reset() {
    _fpsHistory.clear();
    _currentFps = 60.0;
  }
}
