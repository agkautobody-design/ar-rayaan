import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/share/application/share_text.dart';
import 'env_config.dart';

/// Active build flavor, read from --dart-define values.
final Provider<EnvConfig> envProvider = Provider<EnvConfig>(
  (ref) => EnvConfig.fromDefines(),
);

/// Overridden at bootstrap with the real SharedPreferences instance.
final Provider<SharedPreferences> sharedPreferencesProvider =
    Provider<SharedPreferences>(
      (ref) => throw UnimplementedError('SharedPreferences not initialized'),
    );

/// Public URL of the app, used for the share/beta-invite QR.
///
/// Priority: `--dart-define=APP_URL=...` (e.g. the Founder's future domain)
/// → otherwise the one fixed address every share uses ([kInviteUrl]), so the
/// QR code and the shared text can never point to different places. (The old
/// default, the page's own origin, threw on Android and iOS.)
final Provider<String> appUrlProvider = Provider<String>((ref) {
  const String defined = String.fromEnvironment('APP_URL');
  if (defined.isNotEmpty) return defined;
  return kInviteUrl;
});
