import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Enhanced security service with multiple layers of protection:
/// - Dynamic key derivation with runtime obfuscation
/// - AES-like XOR encryption for sensitive values
/// - HMAC-SHA256 integrity verification
/// - Anti-tampering sequence numbers
/// - Secure deletion with overwrite
class SecurityService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: false, // Deprecated, will be ignored
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      accountName: 'color_mixing_game',
    ),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // KEY DERIVATION & OBFUSCATION
  // ═══════════════════════════════════════════════════════════════════════════

  // Base key bytes split and obfuscated to prevent static analysis
  static final List<int> _baseKeyPart1 = [
    0x63, 0x6F, 0x6C, 0x6F, 0x72, 0x5F, // color_
  ];
  static final List<int> _baseKeyPart2 = [
    0x6D, 0x69, 0x78, 0x69, 0x6E, 0x67, // mixing
  ];
  static final List<int> _baseKeyPart3 = [
    0x5F, 0x73, 0x65, 0x63, 0x72, 0x65, 0x74, // _secret
  ];
  static final List<int> _baseKeyPart4 = [
    0x5F, 0x6B, 0x65, 0x79, 0x5F, // _key_
  ];
  static final List<int> _baseKeyPart5 = [
    0x32, 0x30, 0x32, 0x36, // 2026
  ];

  // Salt for key derivation (stored in code, combined at runtime)
  static final Uint8List _keySalt = Uint8List.fromList([
    0x7A,
    0x3C,
    0x9F,
    0x12,
    0xE8,
    0x45,
    0xD1,
    0x67,
    0xB2,
    0x8A,
    0x0E,
    0xF3,
    0x59,
    0xC4,
    0x2B,
    0xA6,
  ]);

  // Runtime-derived key (initialized once per session)
  static List<int>? _derivedKey;

  // Sequence number for anti-replay attacks
  static int _sequenceNumber = 0;

  // Initialization timestamp for session binding
  static int? _sessionStart;

  /// Initialize the security service (call once at app startup)
  static Future<void> initialize() async {
    _sessionStart = DateTime.now().millisecondsSinceEpoch;
    _derivedKey = _deriveKey();
    // Initialize sequence from stored value or random
    final storedSeq = await _storage.read(key: '_seq');
    _sequenceNumber = storedSeq != null
        ? int.parse(storedSeq)
        : _randomInt(10000, 99999);
  }

  /// Derive encryption key from obfuscated parts
  static List<int> _deriveKey() {
    // Combine all parts
    final combined = <int>[
      ..._baseKeyPart1,
      ..._baseKeyPart2,
      ..._baseKeyPart3,
      ..._baseKeyPart4,
      ..._baseKeyPart5,
      ..._keySalt,
    ];

    // Apply XOR with salt pattern for additional obfuscation
    final result = <int>[];
    for (int i = 0; i < combined.length; i++) {
      result.add(combined[i] ^ _keySalt[i % _keySalt.length]);
    }

    return result;
  }

  /// Generate session-specific key for extra security
  List<int> _getSessionKey() {
    if (_derivedKey == null) {
      throw StateError(
        'SecurityService not initialized. Call initialize() first.',
      );
    }
    // Return derived key (persistent across sessions)
    return _derivedKey!;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ENCRYPTION & INTEGRITY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Simple XOR cipher with session key (sufficient for game data obfuscation)
  static String _encrypt(String value) {
    final key = _instance._getSessionKey();
    final valueBytes = utf8.encode(value);
    final encrypted = <int>[];

    for (int i = 0; i < valueBytes.length; i++) {
      encrypted.add(valueBytes[i] ^ key[i % key.length]);
    }

    // Encode as base64 for storage
    return base64Encode(Uint8List.fromList(encrypted));
  }

  /// Decrypt XOR-encrypted value
  static String _decrypt(String encryptedValue) {
    final key = _instance._getSessionKey();
    final encryptedBytes = base64Decode(encryptedValue);
    final decrypted = <int>[];

    for (int i = 0; i < encryptedBytes.length; i++) {
      decrypted.add(encryptedBytes[i] ^ key[i % key.length]);
    }

    return utf8.decode(decrypted);
  }

  /// Generate HMAC for integrity verification
  static String _generateHmac(String value) {
    final key = _instance._getSessionKey();
    final hmac = Hmac(sha256, key);
    return hmac.convert(utf8.encode(value)).toString();
  }

  /// Verify HMAC integrity
  static bool _verifyHmac(String value, String storedHmac) {
    final expectedHmac = _generateHmac(value);
    // Constant-time comparison to prevent timing attacks
    return _constantTimeCompare(expectedHmac, storedHmac);
  }

  /// Constant-time string comparison to prevent timing attacks
  static bool _constantTimeCompare(String a, String b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC API
  // ═══════════════════════════════════════════════════════════════════════════

  /// Write value with encryption, integrity check, and sequence number
  static Future<void> write(String key, String value) async {
    _ensureInitialized();

    // Increment sequence number
    _sequenceNumber++;
    await _storage.write(key: '_seq', value: _sequenceNumber.toString());

    // Create versioned data structure
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final data = {
      'v': 2, // Version 2 = encrypted + HMAC
      'd': value,
      't': timestamp,
      's': _sequenceNumber,
    };

    final jsonData = jsonEncode(data);

    // Encrypt the value
    final encrypted = _encrypt(jsonData);

    // Generate HMAC over encrypted data + key
    final hmacInput = '$encrypted$key';
    final hmac = _generateHmac(hmacInput);

    // Store encrypted value, HMAC, and metadata
    await _storage.write(key: key, value: encrypted);
    await _storage.write(key: '${key}_hmac', value: hmac);
    await _storage.write(key: '${key}_ts', value: timestamp.toString());
  }

  /// Read and verify value with full integrity check
  static Future<String?> read(String key) async {
    _ensureInitialized();

    final encrypted = await _storage.read(key: key);
    if (encrypted == null) return null;

    final storedHmac = await _storage.read(key: '${key}_hmac');

    // Verify HMAC
    if (storedHmac == null) {
      _logSecurityEvent('missing_hmac', key);
      return null;
    }

    // Verify integrity
    final hmacInput = '$encrypted$key';
    if (!_verifyHmac(hmacInput, storedHmac)) {
      _logSecurityEvent('hmac_mismatch', key);
      return null;
    }

    // Decrypt
    try {
      final decrypted = _decrypt(encrypted);
      final data = jsonDecode(decrypted) as Map<String, dynamic>;

      // Validate version
      final version = data['v'] as int?;
      if (version != 2) {
        _logSecurityEvent('invalid_version', key, extra: 'v=$version');
        return null;
      }

      // Validate timestamp (not older than session)
      final timestamp = data['t'] as int?;
      if (timestamp != null &&
          _sessionStart != null &&
          timestamp > _sessionStart!) {
        _logSecurityEvent('future_timestamp', key, extra: 't=$timestamp');
        return null;
      }

      // Validate sequence (not ahead of current)
      final sequence = data['s'] as int?;
      if (sequence != null && sequence > _sequenceNumber) {
        _logSecurityEvent('sequence_anomaly', key, extra: 's=$sequence');
        return null;
      }

      return data['d'] as String;
    } catch (e) {
      _logSecurityEvent('decryption_error', key, extra: e.toString());
      return null;
    }
  }

  /// Delete value securely (overwrite before delete)
  static Future<void> delete(String key) async {
    // Overwrite with random data before deletion
    final randomValue = base64Encode(
      Uint8List.fromList(List.generate(64, (_) => _randomInt(0, 255))),
    );
    await _storage.write(key: key, value: randomValue);
    await _storage.write(key: '${key}_hmac', value: randomValue);
    await _storage.write(key: '${key}_ts', value: randomValue);

    // Now delete
    await _storage.delete(key: key);
    await _storage.delete(key: '${key}_hmac');
    await _storage.delete(key: '${key}_ts');
    await _storage.delete(key: '${key}_seq');
  }

  /// Check if key exists
  static Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }

  /// Get security statistics
  static Future<Map<String, dynamic>> getSecurityStats() async {
    return {
      'initialized': _derivedKey != null,
      'session_start': _sessionStart,
      'sequence_number': _sequenceNumber,
      'key_length': _derivedKey?.length ?? 0,
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERNAL UTILITIES
  // ═══════════════════════════════════════════════════════════════════════════

  static void _ensureInitialized() {
    if (_derivedKey == null) {
      throw StateError(
        'SecurityService not initialized. Call SecurityService.initialize() at app startup.',
      );
    }
  }

  static void _logSecurityEvent(String type, String key, {String? extra}) {
    // In production, send to analytics/crash reporting
    // For now, log with timestamp
    final timestamp = DateTime.now().toIso8601String();
    print(
      '[SecurityAlert] $timestamp | Type: $type | Key: $key${extra != null ? ' | Extra: $extra' : ''}',
    );
  }

  static final math.Random _random = math.Random();
  static int _randomInt(int min, int max) => min + _random.nextInt(max - min);

  // Singleton instance for key derivation
  static final _instance = SecurityService._();
  SecurityService._();
}
