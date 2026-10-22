import 'package:flutter/foundation.dart' show kIsWeb;

/// Honest wording about offline use.
///
/// The Android and iPhone apps carry their libraries on the device. The web
/// app does NOT: its service worker is deliberately a self-removing stub (a
/// caching worker can keep serving an old copy after a new deploy), so every
/// content file is fetched when it is opened and needs an internet
/// connection. Copy that talks about offline use goes through here so a web
/// visitor is never told something that is false.
abstract final class WebOffline {
  /// True when running in a browser (override in tests).
  static bool get isWeb => kIsWeb;

  /// Eyebrow over the list of libraries that ship with the app.
  static String libraryHeader({bool? web}) => (web ?? isWeb)
      ? 'INCLUDED IN THE APP — LOADS WHEN YOU OPEN IT'
      : 'ALREADY ABOARD — WORKS OFFLINE';

  /// Explanation shown under [libraryHeader] on the web only (null on the
  /// native apps, where the libraries really are on the device).
  static String? libraryNote({bool? web}) => (web ?? isWeb)
      ? 'On the web these libraries are fetched from the site each time you '
          'open them, so they need an internet connection. The Android and '
          'iPhone apps keep them on the device and work offline.'
      : null;

  /// Message for a screen whose content could not be fetched.
  static String needsInternet(String what, {bool? web}) => (web ?? isWeb)
      ? '$what needs an internet connection on the web. Check your '
          'connection and try again.'
      : '$what could not be loaded. Try again.';
}
