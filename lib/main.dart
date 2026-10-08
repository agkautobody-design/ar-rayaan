import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/core/env_config.dart';
import 'app/core/firebase/firebase_bootstrap.dart';
import 'app/core/providers.dart';
import 'features/auth/application/auth_providers.dart';
import 'features/doctor/application/feature_probes.dart';
import 'features/auth/application/auth_repository.dart';
import 'features/auth/data/fake_auth_repository.dart';
import 'features/auth/data/firebase_auth_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final EnvConfig env = EnvConfig.fromDefines();

  final SharedPreferences prefs = await SharedPreferences.getInstance();

  // Doctor Tier 1: every feature registers its vitals at boot.
  FeatureProbes.registerAll();

  // O-4: Firebase when the build carries the Founder's project config
  // (dart-defines), local mode otherwise. The override below is the only
  // place that chooses — screens never know the difference.
  final bool firebaseLive = await FirebaseBootstrap.maybeInit();
  final AuthRepository authRepo;
  if (firebaseLive) {
    authRepo = FirebaseAuthRepository();
  } else {
    final FakeAuthRepository local = FakeAuthRepository(prefs);
    await local.init(); // restore persisted session
    authRepo = local;
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(authRepo),
      ],
      child: ArRayaanApp(env: env),
    ),
  );
}
