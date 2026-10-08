/// Environment configuration (dev / prod flavors).
///
/// Values are injected at build time:
///   flutter build web --release --dart-define=FLAVOR=prod
///
/// Firebase activation is fully define-driven via FirebaseBootstrap (O-4).
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
