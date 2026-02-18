import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecurityService {
  static const _storage = FlutterSecureStorage();

  // In a real production app, this key should be derived or fetched securely.
  // For this local-only game, we use a hardcoded obfuscated key to prevent simple edits.
  // This is not "unbreakable" but raises the bar significantly.
  static const List<int> _keyBytes = [
    0x63,
    0x6F,
    0x6C,
    0x6F,
    0x72,
    0x5F,
    0x6D,
    0x69,
    0x78,
    0x69,
    0x6E,
    0x67, // color_mixing
    0x5F,
    0x73,
    0x65,
    0x63,
    0x72,
    0x65,
    0x74,
    0x5F,
    0x6B,
    0x65,
    0x79, // _secret_key
    0x5F, 0x32, 0x30, 0x32, 0x36, // _2026
  ];

  static Future<void> write(String key, String value) async {
    // Generate hash for integrity check
    final hmac = Hmac(sha256, _keyBytes);
    final digest = hmac.convert(utf8.encode(value)).toString();

    // Store value
    await _storage.write(key: key, value: value);
    // Store hash
    await _storage.write(key: '${key}_hash', value: digest);
  }

  static Future<String?> read(String key) async {
    final value = await _storage.read(key: key);
    if (value == null) return null;

    final storedHash = await _storage.read(key: '${key}_hash');
    if (storedHash == null) {
      // Missing hash means potential tampering or old data format (though we are migrating)
      // For now, valid data with missing hash is treated as suspicious but we return it
      // In strict mode, we might return null.
      print('SecurityWarning: Missing integrity hash for $key');
      return value;
    }

    // Verify hash
    final hmac = Hmac(sha256, _keyBytes);
    final calculatedHash = hmac.convert(utf8.encode(value)).toString();

    if (calculatedHash != storedHash) {
      print('SecurityAlert: Data tampering detected for $key!');
      // TODO: Handle tampering (e.g., reset data, show error).
      // For now, return null to force fallback/reset, preventing use of hacked data.
      return null;
    }

    return value;
  }

  static Future<void> delete(String key) async {
    await _storage.delete(key: key);
    await _storage.delete(key: '${key}_hash');
  }

  static Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }
}
