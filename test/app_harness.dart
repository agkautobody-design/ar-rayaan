import 'package:ar_rayaan/app/app.dart';
import 'package:ar_rayaan/app/core/env_config.dart';
import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/auth/application/auth_providers.dart';
import 'package:ar_rayaan/features/auth/data/fake_auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shared harness for tests that run the real [ArRayaanApp] (router, theme,
/// bottom-nav shell) against in-memory preferences.
class AppHarness {
  AppHarness._(this.prefs, this.auth);

  final SharedPreferences prefs;
  final FakeAuthRepository auth;

  /// Phone-sized surface, tall enough that lazy lists build every row.
  static void useSurface(WidgetTester tester, {double height = 3200}) {
    tester.view.physicalSize = Size(430, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  /// Boots the app (already past onboarding) and lets the first frames run.
  /// `prefsValues` seeds SharedPreferences, `overrides` adds provider
  /// overrides on top of the harness's own.
  static Future<AppHarness> boot(
    WidgetTester tester, {
    Map<String, Object> prefsValues = const <String, Object>{},
    List<Override> overrides = const <Override>[],
    double height = 3200,
  }) async {
    SharedPreferences.setMockInitialValues(prefsValues);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final FakeAuthRepository auth = FakeAuthRepository(prefs);
    await auth.init();
    useSurface(tester, height: height);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWithValue(auth),
          ...overrides,
        ],
        child: ArRayaanApp(env: EnvConfig.fromDefines()),
      ),
    );
    await settle(tester);
    return AppHarness._(prefs, auth);
  }

  /// Several short pumps instead of pumpAndSettle: Home hosts looping
  /// animations that never "settle".
  static Future<void> settle(WidgetTester tester) async {
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  /// The router's current location, read from any widget under the app.
  static String location(WidgetTester tester, Finder anchor) =>
      GoRouter.of(tester.element(anchor))
          .routerDelegate
          .currentConfiguration
          .uri
          .path;

  /// Navigate with the real router.
  static Future<void> go(
    WidgetTester tester,
    Finder anchor,
    String path,
  ) async {
    GoRouter.of(tester.element(anchor)).go(path);
    await settle(tester);
  }
}
