import 'package:flutter/foundation.dart' show kIsWeb;

/// Honest wording about offline use.
///
/// The Android and iPhone apps carry their libraries on the device. The web
/// app does NOT: every content file is fetched when it is first opened and
/// needs an internet connection then; `ContentLoader` keeps a copy in the
/// browser's cache afterwards. Since `web/ar_sw.js` (a network-first offline
/// shell) the app itself also reopens with no internet once it has been
/// opened online in that browser, unless the browser blocks site storage
/// (private windows) or the person clears this site's data. Copy that talks
/// about offline use goes through here so a web visitor is never told
/// something that is false.
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
      ? 'On the web these libraries are fetched from the site the first '
          'time you open them, so they need an internet connection then; '
          'after that your browser keeps a copy and the app reopens without '
          'internet (not in a private window, and not after you clear this '
          'site\u2019s data). The Android and iPhone apps keep them on the '
          'device and work offline.'
      : null;

  /// Message for a screen whose content could not be fetched.
  static String needsInternet(String what, {bool? web}) => (web ?? isWeb)
      ? '$what needs an internet connection on the web. Check your '
          'connection and try again.'
      : '$what could not be loaded. Try again.';
}
