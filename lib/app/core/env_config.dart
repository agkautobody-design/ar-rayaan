/// Environment configuration (dev / prod flavors).
///
/// Values are injected at build time:
///   flutter build web --release --dart-define=FLAVOR=prod
///
/// Firebase activation is fully define-driven via FirebaseBootstrap (O-4).
///
/// Dead config, kept on purpose: nothing in the app reads [EnvConfig.isProd]
/// or [EnvConfig.firebaseEnabled] to gate behaviour. The real switches are
/// `kReleaseMode`, the `FOUNDER_TOOLS` define (router) and the `FIREBASE_*`
/// defines read by FirebaseBootstrap. Do not rely on [AppFlavor] to hide
/// anything from users.
///
/// The Quran Foundation "vault" (`services/vault`) is likewise NOT wired in:
/// there is no `AR_VAULT_URL` define and no client code calls it. Screens
/// that say "coming with the vault" are placeholders.
library;

import 'firebase/firebase_bootstrap.dart';

enum AppFlavor { dev, prod }

class EnvConfig {
  const EnvConfig._({required this.flavor});

  final AppFlavor flavor;

  bool get isProd => flavor == AppFlavor.prod;

  /// True when the build carries Firebase options (O-4).
  bool get firebaseEnabled => FirebaseBootstrap.configured;

  static const String _flavorDefine = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'dev',
  );

  factory EnvConfig.fromDefines() {
    return EnvConfig._(
      flavor: _flavorDefine == 'prod' ? AppFlavor.prod : AppFlavor.dev,
    );
  }
}
