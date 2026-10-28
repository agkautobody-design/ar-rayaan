import 'package:firebase_core/firebase_core.dart';

import '../online_status.dart';

/// O-4 Firebase bootstrap — activated purely by build-time defines, so the
/// same binary runs in local mode (beta, no config) or Firebase mode
/// (Founder's project) with zero code changes:
///
///   flutter build web --release \
///     --dart-define=FIREBASE_API_KEY=… \
///     --dart-define=FIREBASE_APP_ID=… \
///     --dart-define=FIREBASE_PROJECT_ID=… \
///     --dart-define=FIREBASE_MESSAGING_SENDER_ID=… \
///     --dart-define=FIREBASE_AUTH_DOMAIN=… \
///     --dart-define=FIREBASE_STORAGE_BUCKET=…
///
/// Setup steps for the Founder live in FIREBASE_SETUP.md.
abstract final class FirebaseBootstrap {
  static const String _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String _projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );
  static const String _senderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const String _authDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
  );
  static const String _storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );

  /// True when the build carries a complete-enough config to initialize.
  static bool get configured =>
      _apiKey.isNotEmpty && _appId.isNotEmpty && _projectId.isNotEmpty;

  static FirebaseOptions? get _options => configured
      ? const FirebaseOptions(
          apiKey: _apiKey,
          appId: _appId,
          projectId: _projectId,
          messagingSenderId: _senderId,
          authDomain: _authDomain,
          storageBucket: _storageBucket,
        )
      : null;

  static const Duration initTimeout = Duration(seconds: 8);

  /// Initializes Firebase when configured; returns whether Firebase is
  /// live. Never throws — any misconfiguration falls back to local mode.
  ///
  /// On the web the Firebase SDK is a script fetched from Google's servers at
  /// start-up. When that fetch cannot complete (offline, a blocked domain, a
  /// captive portal) the SDK's future never finishes, and the app sat on its
  /// splash forever. Waiting longer than [initTimeout] means "not available":
  /// the app starts in local mode, as it does for any other Firebase failure.
  static Future<bool> maybeInit() async {
    final FirebaseOptions? options = _options;
    if (options == null) return false;
    // The browser says there is no connection: do not wait for a script that
    // cannot arrive. The app starts at once in local mode (everything that
    // works offline works; sign-in and cloud reports wait for a connection).
    if (deviceReportsOnline == false) return false;
    try {
      await Firebase.initializeApp(options: options).timeout(initTimeout);
      return true;
    } catch (_) {
      return false;
    }
  }
}
