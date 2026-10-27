import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The parent's PIN: 4 to 6 digits, chosen by the parent on this device.
///
/// It is what stops a child. A multiplication a ten-year-old can answer is not
/// a gate, so the Family Wing, Kids Corner's exit and every other grown-up
/// door ask for this instead.
///
/// Only a salted SHA-256 of the PIN is kept, in this device's storage, and it
/// never leaves the device. It is a barrier for a child, not a vault: someone
/// with the device and developer tools could still clear it, which is the
/// same as clearing the app's data.
class ParentPin {
  ParentPin(this._prefs);

  final SharedPreferences _prefs;

  static const String _key = 'ar.parent.pin.v1';
  static const String _failsKey = 'ar.parent.pin.fails';
  static const String _lockKey = 'ar.parent.pin.lockUntil';

  /// Wrong tries before the PIN is locked for a while.
  static const int maxTries = 5;

  /// How long the PIN stays locked after [maxTries] wrong tries.
  static const Duration lockFor = Duration(minutes: 5);

  bool get isSet => _prefs.getString(_key) != null;

  /// 4 to 6 digits, and not an obvious one.
  static String? problemWith(String pin) {
    if (!RegExp(r'^\d{4,6}$').hasMatch(pin)) {
      return 'Use 4 to 6 digits.';
    }
    if (RegExp(r'^(\d)\1+$').hasMatch(pin)) {
      return 'Choose a PIN that is not the same digit repeated.';
    }
    const String up = '0123456789012345678901234567890';
    const String down = '9876543210987654321098765432109';
    if (up.contains(pin) || down.contains(pin)) {
      return 'Choose a PIN that is not a run of numbers.';
    }
    return null;
  }

  static String _hash(String salt, String pin) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  /// Saves [pin] (already checked with [problemWith]).
  Future<void> set(String pin, {Random? rng}) async {
    final Random r = rng ?? Random.secure();
    final String salt = List<String>.generate(
      16,
      (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    await _prefs.setString(_key, '$salt:${_hash(salt, pin)}');
    await _prefs.remove(_failsKey);
    await _prefs.remove(_lockKey);
  }

  /// How much longer the PIN is locked, or null when it is not.
  Duration? lockedFor([DateTime? now]) {
    final int? until = _prefs.getInt(_lockKey);
    if (until == null) return null;
    final Duration left = DateTime.fromMillisecondsSinceEpoch(until)
        .difference(now ?? DateTime.now());
    return left.isNegative || left == Duration.zero ? null : left;
  }

  /// True when [pin] is right. A wrong try counts; after [maxTries] the PIN
  /// locks for [lockFor]. While locked nothing is accepted, not even the
  /// right PIN.
  Future<bool> verify(String pin, [DateTime? now]) async {
    final String? stored = _prefs.getString(_key);
    if (stored == null) return false;
    if (lockedFor(now) != null) return false;
    final int split = stored.indexOf(':');
    final bool ok = split > 0 &&
        _hash(stored.substring(0, split), pin) == stored.substring(split + 1);
    if (ok) {
      await _prefs.remove(_failsKey);
      await _prefs.remove(_lockKey);
      return true;
    }
    final int fails = (_prefs.getInt(_failsKey) ?? 0) + 1;
    if (fails >= maxTries) {
      await _prefs.setInt(
        _lockKey,
        (now ?? DateTime.now()).add(lockFor).millisecondsSinceEpoch,
      );
      await _prefs.remove(_failsKey);
    } else {
      await _prefs.setInt(_failsKey, fails);
    }
    return false;
  }

  /// Tries left before the lock.
  int get triesLeft => maxTries - (_prefs.getInt(_failsKey) ?? 0);
}
