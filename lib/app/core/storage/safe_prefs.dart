import 'package:shared_preferences/shared_preferences.dart';

/// Opens SharedPreferences without ever blocking the app from starting.
///
/// In a browser with site data blocked (cookies off, a sandboxed frame) the
/// plugin can throw when it touches localStorage. Before this guard that
/// happened before `runApp`, so the person saw the boot splash forever. Now
/// the app falls back to an in-memory store for the session: everything
/// works, nothing is remembered after a reload, and [fellBack] tells the UI
/// so it can say so.
class SafePrefs {
  const SafePrefs._();

  /// True when storage could not be opened and this session is in memory.
  static bool fellBack = false;

  static Future<SharedPreferences> open({
    Future<SharedPreferences> Function()? loader,
  }) async {
    try {
      return await (loader ?? SharedPreferences.getInstance)();
    } catch (_) {
      fellBack = true;
      // The in-memory store is the plugin's own test double; it is the
      // supported way to get a working SharedPreferences without storage.
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues(<String, Object>{});
      return SharedPreferences.getInstance();
    }
  }
}
