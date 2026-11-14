import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' hide Text;
import 'app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/core/child_mode.dart';
import 'app/core/env_config.dart';
import 'app/core/error_handling.dart';
import 'app/core/restart_app.dart';
import 'app/crashlytics_initializer.dart';
import 'app/push_notification_service.dart';
import 'features/prayer/data/adhan_notification_service.dart';
import 'app/core/notifications/adhan_notification_bridge.dart';
import 'app/core/firebase/firebase_bootstrap.dart';
import 'app/core/providers.dart';
import 'app/core/storage/safe_prefs.dart';
import 'features/auth/application/auth_providers.dart';
import 'features/doctor/application/drift_guard.dart';
import 'features/hadi/data/api_key_vault.dart';
import 'features/support/data/helplines_loader.dart';
import 'features/support/data/pack_repository.dart';
import 'features/support/data/secret_store.dart';
import 'features/support/application/support_settings.dart';
import 'features/hadi/data/hadi_report_service.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/prayer/presentation/worship_boot.dart';
import 'features/doctor/application/feature_probes.dart';
import 'features/auth/application/auth_repository.dart';
import 'features/auth/data/fake_auth_repository.dart';
import 'features/auth/data/firebase_auth_repository.dart';

/// Everything runs inside one guarded zone: an error that escapes any
/// future, timer or callback is recorded (see [AppErrorHandling]) instead of
/// ending as an uncaught exception, and a screen that throws while building
/// shows the friendly fallback rather than a bare grey rectangle.
void main() {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    AppErrorHandling.install();
    try {
      await _start();
    } catch (error, stack) {
      // Startup itself failed (before any screen exists): say so, plainly.
      AppErrorHandling.record(error, stack, where: 'startup');
      runApp(_StartupFailedApp(error));
    }
  }, AppErrorHandling.onZoneError);
}

/// Runs an optional start-up step: if it fails, the failure is recorded and
/// start-up continues. Only the steps that decide what the app IS (storage,
/// content packs, Firebase itself, the auth override) may stop the boot — a
/// notification or crash-reporting extra must never keep the app closed.
Future<void> _tryBoot(String name, Future<void> Function() step) async {
  try {
    await step();
  } catch (error, stack) {
    AppErrorHandling.record(error, stack, where: 'startup:$name');
  }
}

Future<void> _start() async {
  final EnvConfig env = EnvConfig.fromDefines();

  // Blocked browser storage must not stop the app from starting: SafePrefs
  // falls back to memory for the session.
  final SharedPreferences prefs = await SafePrefs.open();
  // A device handed to a child stays in child mode across reloads.
  loadChildMode(prefs);
  // The person's own AI key: moved out of plain text into the secure store.
  await ApiKeyVault.load(prefs);
  // Help lines and support packs are independent: fetched side by side.
  await Future.wait<void>(<Future<void>>[
    HelplinesLoader.load(),
    SupportPackRepository.load(),
  ]);
  await SecretStore.preload(<String>[
    SupportKeys.safeWordSecret,
    SupportKeys.memorySecret,
  ]);

  // Doctor Tier 1: every feature registers its vitals at boot.
  FeatureProbes.registerAll();

  // O-4: Firebase when the build carries the Founder's project config
  // (dart-defines), local mode otherwise. The override below is the only
  // place that chooses — screens never know the difference.
  final bool firebaseLive = await FirebaseBootstrap.maybeInit();
  if (firebaseLive) {
    await _tryBoot('crashlytics', () async => CrashlyticsInitializer.initialize());
    await _tryBoot('push', PushNotificationService.initialize);
    await _tryBoot('adhan-notifications', AdhanNotificationService.initialize);
    await _tryBoot('adhan-bridge', () async => AdhanNotificationBridge.register());
  }
  unawaited(DriftGuard().scan());
  // Reports saved on the device while offline go out now that Firebase is up.
  if (firebaseLive) unawaited(HadiReportService(prefs).flush());

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


/// Shown only if the app could not start at all. The real error is printed
/// in small type at the bottom: a screenshot of this screen tells support
/// exactly what broke.
class _StartupFailedApp extends StatelessWidget {
  const _StartupFailedApp(this.error);

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: const Color(0xFF05090F),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ar-Rayaan could not start. Close it and open it again, or '
                  'reload the page. Nothing you saved was lost.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFE8DCC0),
                    fontSize: 17,
                    height: 1.5,
                    decoration: TextDecoration.none,
                  ),
                ),
                if (kIsWeb) ...<Widget>[
                  const SizedBox(height: 24),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: const Color(0xFF05090F),
                      minimumSize: const Size(140, 44),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 10),
                    ),
                    onPressed: restartApp,
                    child: const Text(
                      'Try again',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0x80E8DCC0),
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.normal,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
