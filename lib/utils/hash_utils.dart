import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Local password hashing utility (SHA-256 + per-user salt).
///
/// NOTE: This is a prototype-grade local authentication helper. It is NOT a substitute
/// for a server-side key-derivation function (bcrypt / Argon2) in production. Use it
/// only for single-device local accounts as described in the README.
class HashUtils {
  const HashUtils._();

  static final Random _random = Random.secure();

  /// Generates a 32-character hex salt.
  static String generateSalt() {
    final values = List<int>.generate(16, (_) => _random.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Hashes [password] with [salt] using SHA-256. Returns hex digest.
  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt::$password');
    return sha256.convert(bytes).toString();
  }

  /// Verifies a password against stored hash and salt.
  static bool verifyPassword(String password, String salt, String storedHash) {
    return hashPassword(password, salt) == storedHash;
  }

  /// Generates a simple random temporary password (used by admins).
  static String generateTempPassword() {
    final values = List<int>.generate(12, (_) => _random.nextInt(36));
    return values.map((v) => v < 10 ? v.toString() : String.fromCharCode(97 + v - 10)).join();
  }
}
