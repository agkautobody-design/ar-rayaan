import 'package:ar_rayaan/app/app.dart';
import 'package:ar_rayaan/app/core/env_config.dart';
import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/auth/application/auth_providers.dart';
import 'package:ar_rayaan/features/auth/application/auth_repository.dart';
import 'package:ar_rayaan/features/auth/data/fake_auth_repository.dart';
import 'package:ar_rayaan/features/profile/data/local_profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('session persistence', () {
    test('sign-in persists and init restores the session', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      final FakeAuthRepository repo = FakeAuthRepository(prefs);
      await repo.init();
      expect(await repo.currentUser(), isNull);

      await repo.signInWithEmail(
        email: 'ahmed@example.com',
        password: 'password123',
      );
      expect(prefs.getString('ar.auth.session'), isNotNull);

      final FakeAuthRepository restored = FakeAuthRepository(prefs);
      await restored.init();
      final AuthUser? user = await restored.currentUser();
      expect(user?.email, 'ahmed@example.com');
      expect(user?.name, 'Ahmed');
      // Stream yields the restored session first.
      expect(
        (await restored.authStateChanges().first)?.email,
        'ahmed@example.com',
      );
    });

    test('sign-out clears the persisted session', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final FakeAuthRepository repo = FakeAuthRepository(prefs);
      await repo.signInWithEmail(
        email: 'ahmed@example.com',
        password: 'password123',
      );
      await repo.signOut();
      expect(prefs.getString('ar.auth.session'), isNull);
      expect(await repo.currentUser(), isNull);
    });
  });

  group('profile persistence', () {
    test('ensureProfile creates once, save updates, record survives', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final LocalProfileRepository repo = LocalProfileRepository(prefs);

      const AuthUser user = AuthUser(
        uid: 'u1',
        email: 'ahmed@example.com',
        name: 'Ahmed',
      );
      final p1 = await repo.ensureProfile(user);
      expect(p1.displayName, 'Ahmed');
      expect(p1.email, 'ahmed@example.com');

      await repo.save(p1.copyWith(displayName: 'A. Khan'));
      final p2 = await repo.ensureProfile(user);
      expect(p2.displayName, 'A. Khan');
      expect(p2.createdAt, p1.createdAt); // original record preserved
    });
  });

  group('profile screen data', () {
    Future<void> pumpApp(
      WidgetTester tester,
      SharedPreferences prefs,
      FakeAuthRepository authRepo,
    ) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            authRepositoryProvider.overrideWithValue(authRepo),
          ],
          child: ArRayaanApp(env: EnvConfig.fromDefines()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 4)); // splash
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('welcome-continue')));
      await tester.pumpAndSettle();
    }

    testWidgets('guest sees Guest card with sign-in prompt', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await pumpApp(tester, prefs, FakeAuthRepository(prefs));

      final BuildContext ctx = tester.element(find.text('Prayer Times'));
      GoRouter.of(ctx).go('/profile');
      await tester.pumpAndSettle();

      expect(find.text('Guest'), findsOneWidget);
      expect(find.text('Sign in to save your journey'), findsOneWidget);
    });

    testWidgets('signed-in user sees their name on the profile card', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await pumpApp(tester, prefs, FakeAuthRepository(prefs));

      // Sign in through the real UI.
      GoRouter.of(tester.element(find.text('Prayer Times'))).go('/auth/login');
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'ahmed@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();

      // Fresh context — the pre-login one was deactivated by navigation.
      GoRouter.of(tester.element(find.text('Prayer Times'))).go('/profile');
      await tester.pumpAndSettle();
      expect(find.text('Ahmed'), findsWidgets); // profile card name
      expect(find.text('View your profile'), findsOneWidget);
    });
  });
}
