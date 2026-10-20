import 'package:shared_preferences/shared_preferences.dart';

/// The Elder Mode switch. One key, one owner: Home's Elder tile and the Elder
/// home screen WRITE it ([set]); the app launch READS it ([isEnabled]) to
/// decide whether to open on the Elder home (see [ElderMode.homeRoute]).
/// Before this helper the flag was written in three places and read in none,
/// so "the app opens here every time" was never true.
abstract final class ElderMode {
  static const String pref = 'ar.elder.mode';

  /// The route Elder Mode opens on.
  static const String homeRoute = '/home/elder';

  static Future<bool> isEnabled() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      return p.getBool(pref) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> set(bool on) async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setBool(pref, on);
    } catch (_) {}
  }

  /// Where a cold start should land: the Elder home when the mode is on,
  /// otherwise [fallback].
  static Future<String> launchRoute({required String fallback}) async =>
      await isEnabled() ? homeRoute : fallback;
}
