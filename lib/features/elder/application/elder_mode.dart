import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';

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

  /// The same decision, read from preferences that are already loaded, so the
  /// router can use it for `initialLocation` without waiting. `app.dart`
  /// should build the router with
  /// `ElderMode.launchLocation(prefs, fallback: AppRoutes.splash)`.
  static String launchLocation(
    SharedPreferences prefs, {
    required String fallback,
  }) {
    try {
      return (prefs.getBool(pref) ?? false) ? homeRoute : fallback;
    } catch (_) {
      return fallback;
    }
  }
}

/// Elder Mode as live app state, so the whole app (text size, tap size) can
/// follow the switch the moment it flips. Persisted under [ElderMode.pref].
class ElderModeController extends Notifier<bool> {
  @override
  bool build() {
    try {
      return ref.read(sharedPreferencesProvider).getBool(ElderMode.pref) ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<void> set(bool on) async {
    state = on;
    try {
      await ref.read(sharedPreferencesProvider).setBool(ElderMode.pref, on);
    } catch (_) {
      await ElderMode.set(on);
    }
  }
}

final NotifierProvider<ElderModeController, bool> elderModeProvider =
    NotifierProvider<ElderModeController, bool>(ElderModeController.new);
