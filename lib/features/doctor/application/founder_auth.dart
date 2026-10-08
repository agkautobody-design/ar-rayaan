/// Founder authentication for the Doctor console.
///
/// NO default PIN (founder decision 2026-10-05): first entry offers a
/// set-PIN flow; recovery uses two security questions the founder
/// answers at setup. PIN is hashed (SHA-256 + per-install salt) and
/// stored on-device only — never the PIN itself.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class FounderAuth {
  static const String _pinHashKey = 'ar.doctor.pin.hash';
  static const String _saltKey = 'ar.doctor.pin.salt';
  static const String _q1Key = 'ar.doctor.recover.q1';
  static const String _a1Key = 'ar.doctor.recover.a1';
  static const String _q2Key = 'ar.doctor.recover.q2';
  static const String _a2Key = 'ar.doctor.recover.a2';

  static bool isConfigured(SharedPreferences prefs) =>
      prefs.getString(_pinHashKey) != null;

  /// Set (or replace, after verification of the old PIN) the PIN and
  /// the two recovery Q&As. [pin] must be 4–8 digits.
  static Future<void> configure({
    required SharedPreferences prefs,
    required String pin,
    required String question1,
    required String answer1,
    required String question2,
    required String answer2,
  }) async {
    _validatePin(pin);
    if (question1.trim().isEmpty ||
        question2.trim().isEmpty ||
        answer1.trim().isEmpty ||
        answer2.trim().isEmpty) {
      throw ArgumentError('Recovery questions and answers are required.');
    }
    final String salt = _salt(prefs);
    await prefs.setString(_pinHashKey, _hash(pin, salt));
    await prefs.setString(_q1Key, question1.trim());
    await prefs.setString(_q2Key, question2.trim());
    await prefs.setString(_a1Key, _hash(answer1.trim().toLowerCase(), salt));
    await prefs.setString(_a2Key, _hash(answer2.trim().toLowerCase(), salt));
  }

  static bool verify(SharedPreferences prefs, String pin) {
    final String? stored = prefs.getString(_pinHashKey);
    if (stored == null) return false;
    return _hash(pin, _salt(prefs)) == stored;
  }

  /// Recovery: both answers must match. On success the founder sets a
  /// new PIN immediately (the caller re-runs configure).
  static bool verifyRecovery(
    SharedPreferences prefs, {
    required String answer1,
    required String answer2,
  }) {
    final String salt = _salt(prefs);
    return prefs.getString(_a1Key) == _hash(answer1.trim().toLowerCase(), salt) &&
        prefs.getString(_a2Key) == _hash(answer2.trim().toLowerCase(), salt);
  }

  static String recoveryQuestion1(SharedPreferences prefs) =>
      prefs.getString(_q1Key) ?? '';
  static String recoveryQuestion2(SharedPreferences prefs) =>
      prefs.getString(_q2Key) ?? '';

  static void _validatePin(String pin) {
    if (!RegExp(r'^\d{4,8}$').hasMatch(pin)) {
      throw ArgumentError('PIN must be 4–8 digits.');
    }
  }

  static String _salt(SharedPreferences prefs) {
    String? s = prefs.getString(_saltKey);
    if (s == null) {
      s = base64Encode(
          sha256.convert(utf8.encode('ar-rayaan-${DateTime.now()}')).bytes);
      prefs.setString(_saltKey, s);
    }
    return s;
  }

  static String _hash(String value, String salt) =>
      sha256.convert(utf8.encode('$salt::$value')).toString();
}
