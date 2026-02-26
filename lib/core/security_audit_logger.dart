import 'dart:async';
import 'dart:convert';
import 'package:color_mixing_deductive/core/security_service.dart';
import 'package:flutter/foundation.dart';

/// Severity levels for security events
enum SecurityEventSeverity {
  /// Informational event (normal operation)
  info,

  /// Potentially suspicious activity
  warning,

  /// Definitely suspicious activity
  error,

  /// Critical security threat
  critical,
}

/// Represents a security event
class SecurityEvent {
  final DateTime timestamp;
  final String type;
  final String message;
  final SecurityEventSeverity severity;
  final Map<String, dynamic> metadata;
  final String? stackTrace;

  SecurityEvent({
    required this.timestamp,
    required this.type,
    required this.message,
    this.severity = SecurityEventSeverity.info,
    this.metadata = const {},
    this.stackTrace,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'type': type,
        'message': message,
        'severity': severity.name,
        'metadata': metadata,
        'stack_trace': stackTrace,
      };

  static SecurityEvent fromJson(Map<String, dynamic> json) => SecurityEvent(
        timestamp: DateTime.parse(json['timestamp'] as String),
        type: json['type'] as String,
        message: json['message'] as String,
        severity: SecurityEventSeverity.values.firstWhere(
          (e) => e.name == json['severity'],
          orElse: () => SecurityEventSeverity.info,
        ),
        metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
        stackTrace: json['stack_trace'] as String?,
      );
}

/// Security audit logger for tracking and analyzing security events.
///
/// Features:
/// - In-memory event buffer with configurable size
/// - Persistent storage for critical events
/// - Event filtering and aggregation
/// - Export functionality for analysis
class SecurityAuditLogger {
  // Configuration
  static const int _maxInMemoryEvents = 100;
  static const int _maxPersistedEvents = 500;
  static const String _persistKey = 'security_audit_log';

  // In-memory event buffer
  static final List<SecurityEvent> _events = [];

  // Stream controller for real-time monitoring
  static final StreamController<SecurityEvent> _eventController =
      StreamController<SecurityEvent>.broadcast();

  // Event counters for aggregation
  static final Map<String, int> _eventCounts = {};
  static DateTime? _lastReset;

  // Throttle to prevent log flooding
  static DateTime? _lastLogTime;
  static const _logThrottleMs = 100;
  static int _droppedEvents = 0;

  /// Stream of security events (for real-time monitoring)
  static Stream<SecurityEvent> get eventStream => _eventController.stream;

  /// Initialize the audit logger (call once at startup)
  static Future<void> initialize() async {
    await _loadPersistedEvents();
    _lastReset = DateTime.now();
  }

  /// Load persisted events from storage
  static Future<void> _loadPersistedEvents() async {
    try {
      final data = await SecurityService.read(_persistKey);
      if (data != null) {
        final List<dynamic> decoded = jsonDecode(data);
        _events.clear();
        _events.addAll(
          decoded
              .cast<Map<String, dynamic>>()
              .map((json) => SecurityEvent.fromJson(json))
              .toList(),
        );
      }
    } catch (e) {
      debugPrint('Failed to load security audit log: $e');
    }
  }

  /// Persist events to storage
  static Future<void> _persistEvents() async {
    try {
      final eventsToPersist = _events.take(_maxPersistedEvents).toList();
      final encoded = jsonEncode(eventsToPersist.map((e) => e.toJson()).toList());
      await SecurityService.write(_persistKey, encoded);
    } catch (e) {
      debugPrint('Failed to persist security audit log: $e');
    }
  }

  /// Log a security event
  static void log(
    String type,
    String message, {
    SecurityEventSeverity severity = SecurityEventSeverity.info,
    Map<String, dynamic>? metadata,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final now = DateTime.now();

    // Throttle check
    final lastLog = _lastLogTime;
    if (lastLog != null &&
        now.difference(lastLog).inMilliseconds < _logThrottleMs) {
      _droppedEvents++;
      return;
    }
    _lastLogTime = now;

    // Create event
    final event = SecurityEvent(
      timestamp: now,
      type: type,
      message: message,
      severity: severity,
      metadata: {
        ...?metadata,
        if (error != null) 'error': error.toString(),
        if (_droppedEvents > 0) ...{
          'dropped_events': _droppedEvents,
        },
      },
      stackTrace: stackTrace?.toString(),
    );

    // Add to in-memory buffer
    _events.add(event);
    if (_events.length > _maxInMemoryEvents) {
      _events.removeAt(0);
    }

    // Update counts
    _eventCounts[type] = (_eventCounts[type] ?? 0) + 1;

    // Persist critical events immediately
    if (severity >= SecurityEventSeverity.error) {
      _persistEvents();
    }

    // Emit to stream
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }

    // Log to console in debug mode
    if (kDebugMode) {
      final severityStr = severity.name.toUpperCase().padRight(8);
      debugPrint('[SecurityAudit] $severityStr $type: $message');
    }
  }

  /// Get all events in memory
  static List<SecurityEvent> getEvents() => List.unmodifiable(_events);

  /// Get events filtered by severity
  static List<SecurityEvent> getEventsBySeverity(
    SecurityEventSeverity minSeverity,
  ) {
    return _events
        .where((e) => e.severity.index >= minSeverity.index)
        .toList();
  }

  /// Get events filtered by type
  static List<SecurityEvent> getEventsByType(String type) {
    return _events.where((e) => e.type == type).toList();
  }

  /// Get event counts since last reset
  static Map<String, int> getEventCounts() => Map.unmodifiable(_eventCounts);

  /// Get summary statistics
  static Map<String, dynamic> getSummary() {
    final now = DateTime.now();
    final criticalCount = _events
        .where((e) => e.severity == SecurityEventSeverity.critical)
        .length;
    final errorCount = _events
        .where((e) => e.severity == SecurityEventSeverity.error)
        .length;
    final warningCount = _events
        .where((e) => e.severity == SecurityEventSeverity.warning)
        .length;

    return {
      'total_events': _events.length,
      'critical_count': criticalCount,
      'error_count': errorCount,
      'warning_count': warningCount,
      'info_count': _events.length - criticalCount - errorCount - warningCount,
      'event_counts': _eventCounts,
      'dropped_events': _droppedEvents,
      'last_reset': _lastReset?.toIso8601String(),
      'uptime_seconds': _lastReset != null
          ? now.difference(_lastReset!).inSeconds
          : null,
    };
  }

  /// Export events for analysis (JSON format)
  static String exportEvents({
    DateTime? startTime,
    DateTime? endTime,
    SecurityEventSeverity? minSeverity,
  }) {
    var filtered = _events;

    if (startTime != null) {
      filtered = filtered.where((e) => e.timestamp.isAfter(startTime)).toList();
    }
    if (endTime != null) {
      filtered = filtered.where((e) => e.timestamp.isBefore(endTime)).toList();
    }
    if (minSeverity != null) {
      filtered = filtered
          .where((e) => e.severity.index >= minSeverity.index)
          .toList();
    }

    return jsonEncode({
      'exported_at': DateTime.now().toIso8601String(),
      'event_count': filtered.length,
      'events': filtered.map((e) => e.toJson()).toList(),
    });
  }

  /// Clear all events (use with caution)
  static Future<void> clear() async {
    _events.clear();
    _eventCounts.clear();
    _droppedEvents = 0;
    _lastReset = DateTime.now();
    await SecurityService.delete(_persistKey);
  }

  /// Reset event counts
  static void resetCounts() {
    _eventCounts.clear();
    _lastReset = DateTime.now();
  }

  /// Dispose resources
  static void dispose() {
    _persistEvents();
    _eventController.close();
  }
}

/// Convenience methods for logging specific security events
extension SecurityAuditShortcuts on SecurityAuditLogger {
  static void logInfo(String message, {Map<String, dynamic>? metadata}) {
    SecurityAuditLogger.log(
      'info',
      message,
      severity: SecurityEventSeverity.info,
      metadata: metadata,
    );
  }

  static void logWarning(String message, {Map<String, dynamic>? metadata}) {
    SecurityAuditLogger.log(
      'warning',
      message,
      severity: SecurityEventSeverity.warning,
      metadata: metadata,
    );
  }

  static void logError(
    String message, {
    Map<String, dynamic>? metadata,
    Object? error,
    StackTrace? stackTrace,
  }) {
    SecurityAuditLogger.log(
      'error',
      message,
      severity: SecurityEventSeverity.error,
      metadata: metadata,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void logCritical(
    String message, {
    Map<String, dynamic>? metadata,
    Object? error,
    StackTrace? stackTrace,
  }) {
    SecurityAuditLogger.log(
      'critical',
      message,
      severity: SecurityEventSeverity.critical,
      metadata: metadata,
      error: error,
      stackTrace: stackTrace,
    );
  }
}

/// Compare severity levels
extension SecurityEventSeverityCompare on SecurityEventSeverity {
  bool operator >=(SecurityEventSeverity other) => index >= other.index;
}
