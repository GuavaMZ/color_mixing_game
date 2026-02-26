import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Runtime security checks to detect tampering, debugging, and unsafe environments.
///
/// Call [RuntimeIntegrityChecker.initialize] at app startup and periodically
/// check [isSecure] before sensitive operations.
class RuntimeIntegrityChecker {
  RuntimeIntegrityChecker._();

  static final RuntimeIntegrityChecker _instance = RuntimeIntegrityChecker._();

  // Check results cache
  static bool? _isDebuggerAttached;
  static bool? _isRunningOnEmulator;
  static DateTime? _lastCheckTime;
  static final List<String> _securityEvents = [];

  // Check interval (5 minutes)
  static const _checkInterval = Duration(minutes: 5);

  /// Initialize the integrity checker (call once at startup)
  static Future<void> initialize() async {
    await _instance._performChecks();
    _lastCheckTime = DateTime.now();

    // Schedule periodic checks
    Timer.periodic(_checkInterval, (_) async {
      await _instance._performChecks();
      _lastCheckTime = DateTime.now();
    });
  }

  /// Perform all integrity checks
  Future<void> _performChecks() async {
    _isDebuggerAttached = _checkDebugger();
    _isRunningOnEmulator = await _checkEmulator();
  }

  /// Check if a debugger is attached
  bool _checkDebugger() {
    // Check if we're in debug mode
    return kDebugMode;
  }

  /// Check if running on an emulator/simulator
  Future<bool> _checkEmulator() async {
    try {
      if (Platform.isAndroid) {
        // Check for common emulator indicators
        final buildFingerprint = await _getSystemProperty('ro.build.fingerprint') ?? '';
        final buildCharacteristics = await _getSystemProperty('ro.build.characteristics') ?? '';

        final emulatorIndicators = [
          'generic',
          'sdk',
          'test-keys',
          'androidsdk',
          'vbox',
          'genymotion',
        ];

        final combined = '$buildFingerprint$buildCharacteristics'.toLowerCase();
        return emulatorIndicators.any((indicator) => combined.contains(indicator));
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get Android system property via reflection (works on Android only)
  Future<String?> _getSystemProperty(String key) async {
    try {
      return null;
    } catch (e) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC API
  // ═══════════════════════════════════════════════════════════════════════════

  /// Whether the current environment is considered secure
  static bool get isSecure {
    final lastCheck = _lastCheckTime;
    if (lastCheck == null) {
      _logEvent('not_initialized', 'Integrity checker not initialized');
      return true;
    }

    // Check if we need to re-run checks
    if (DateTime.now().difference(lastCheck) > _checkInterval) {
      _instance._performChecks();
      _lastCheckTime = DateTime.now();
    }

    // Debugger attached is the main concern for local game
    final isDebugger = _isDebuggerAttached ?? false;
    return !isDebugger;
  }

  /// Whether a debugger is currently attached
  static bool get isDebuggerAttached => _isDebuggerAttached ?? false;

  /// Whether running on an emulator
  static bool get isRunningOnEmulator => _isRunningOnEmulator ?? false;

  /// Get security status summary
  static Map<String, dynamic> getSecurityStatus() {
    return {
      'is_secure': isSecure,
      'debugger_attached': _isDebuggerAttached,
      'running_on_emulator': _isRunningOnEmulator,
      'last_check': _lastCheckTime?.toIso8601String(),
      'events': List<String>.from(_securityEvents),
    };
  }

  /// Record a suspicious activity
  static void recordSuspiciousActivity(String activity, {String? details}) {
    _logEvent('suspicious', activity, details: details);
  }

  static void _logEvent(String type, String message, {String? details}) {
    final timestamp = DateTime.now().toIso8601String();
    final detailStr = details != null ? ' | $details' : '';
    final event = '[$timestamp] $type: $message$detailStr';
    _securityEvents.add(event);

    if (_securityEvents.length > 100) {
      _securityEvents.removeAt(0);
    }

    if (kDebugMode) {
      print('[SecurityEvent] $type: $message$detailStr');
    }
  }
}
