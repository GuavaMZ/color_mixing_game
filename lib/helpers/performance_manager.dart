import 'package:flutter/foundation.dart';

/// Performance monitoring and optimization manager
class PerformanceManager {
  static final PerformanceManager _instance = PerformanceManager._internal();
  factory PerformanceManager() => _instance;
  PerformanceManager._internal();

  // Performance mode settings
  bool _lowPerformanceMode = false;
  bool get isLowPerformanceMode => _lowPerformanceMode;

  // FPS tracking — ring buffer (O(1) insert, no list shifting)
  static const int _ringSize = 60;
  final List<double> _fpsRing = List<double>.filled(_ringSize, 60.0, growable: false);
  int _ringHead = 0;
  double _currentFps = 60.0;
  double get currentFps => _currentFps;

  double get averageFps {
    double sum = 0;
    for (final f in _fpsRing) sum += f;
    return sum / _ringSize;
  }

  // Performance thresholds
  static const double _lowFpsThreshold = 30.0;

  /// Update FPS tracking — call every frame from the game loop with (1.0 / dt)
  void updateFps(double fps) {
    _currentFps = fps;
    _fpsRing[_ringHead] = fps;
    _ringHead = (_ringHead + 1) % _ringSize;

    // Auto-detect low performance after ring is populated (60 frames)
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
    debugPrint('🔧 Low Performance Mode: ENABLED (Auto: avg ${averageFps.toStringAsFixed(1)} FPS)');
  }

  /// Disable low performance mode
  void disableLowPerformanceMode() {
    _lowPerformanceMode = false;
    debugPrint('🔧 Low Performance Mode: DISABLED');
  }

  /// Adaptive particle count — components should read this instead of hard-coding
  int get particleCount => _lowPerformanceMode ? 6 : 15;

  /// Whether expensive glass shaders should be used
  bool get useGlassShaders => !_lowPerformanceMode;

  /// Whether animated wave effects should be used
  bool get useWaveAnimation => !_lowPerformanceMode;

  /// Get particle count multiplier based on performance mode
  double getParticleMultiplier() {
    return _lowPerformanceMode ? 0.5 : 1.0;
  }

  /// Get update rate multiplier
  int getUpdateRateMultiplier() {
    return _lowPerformanceMode ? 2 : 1;
  }

  /// Should skip this frame for non-critical updates?
  bool shouldSkipFrame(int frameCount) {
    if (!_lowPerformanceMode) return false;
    return frameCount % getUpdateRateMultiplier() != 0;
  }

  /// Reset performance tracking
  void reset() {
    _fpsRing.fillRange(0, _ringSize, 60.0);
    _ringHead = 0;
    _currentFps = 60.0;
  }
}
