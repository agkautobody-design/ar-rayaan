import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/core/env_config.dart';
import 'app/core/firebase/firebase_bootstrap.dart';
import 'app/core/providers.dart';
import 'app/core/storage/safe_prefs.dart';
import 'features/auth/application/auth_providers.dart';
import 'features/doctor/application/drift_guard.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/prayer/presentation/worship_boot.dart';
import 'features/doctor/application/feature_probes.dart';
import 'features/auth/application/auth_repository.dart';
import 'features/auth/data/fake_auth_repository.dart';
import 'features/auth/data/firebase_auth_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final EnvConfig env = EnvConfig.fromDefines();

  // Blocked browser storage must not stop the app from starting: SafePrefs
  // falls back to memory for the session.
  final SharedPreferences prefs = await SafePrefs.open();

  // Doctor Tier 1: every feature registers its vitals at boot.
  FeatureProbes.registerAll();

  // O-4: Firebase when the build carries the Founder's project config
  // (dart-defines), local mode otherwise. The override below is the only
  // place that chooses — screens never know the difference.
  final bool firebaseLive = await FirebaseBootstrap.maybeInit();
  unawaited(DriftGuard().scan());

  final AuthRepository authRepo;
  if (firebaseLive) {
    authRepo = FirebaseAuthRepository();
  } else {
    final FakeAuthRepository local = FakeAuthRepository(prefs);
    await local.init(); // restore persisted session
    authRepo = local;
  }

  // First-run gate: fresh installs walk the onboarding flow once.
  final bool showOnboarding = await OnboardingScreen.shouldShow();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(authRepo),
      ],
      child: WorshipBoot(
        child: ArRayaanApp(env: env, showOnboarding: showOnboarding),
      ),
    ),
  );
}
