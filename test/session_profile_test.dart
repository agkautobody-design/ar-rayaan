import 'dart:convert';

import 'package:ar_rayaan/features/auth/application/auth_repository.dart';
import 'package:ar_rayaan/features/auth/data/fake_auth_repository.dart';
import 'package:ar_rayaan/features/profile/data/local_profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_harness.dart';

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

  group('profile tab', () {
    testWidgets('guest sees the Guest card with a sign-in prompt', (
      tester,
    ) async {
      await AppHarness.boot(tester);
      await tester.tap(find.text('You'));
      await AppHarness.settle(tester);

      expect(find.text('Guest'), findsOneWidget);
      expect(find.text('Sign in if you wish. Your progress stays on this device.'), findsOneWidget);
    });

    testWidgets('a restored session shows the name on the profile card', (
      tester,
    ) async {
      await AppHarness.boot(
        tester,
        prefsValues: <String, Object>{
          'ar.auth.session': jsonEncode(<String, String>{
            'uid': 'u1',
            'email': 'ahmed@example.com',
            'name': 'Ahmed',
          }),
        },
      );
      await tester.tap(find.text('You'));
      await AppHarness.settle(tester);

      final String onScreen = tester
          .widgetList<Text>(find.byType(Text))
          .map((Text t) => t.data ?? '')
          .join(' | ');
      expect(find.text('Ahmed'), findsWidgets, reason: onScreen);
      expect(find.text('Sign in if you wish. Your progress stays on this device.'), findsNothing,
          reason: onScreen);
      expect(find.text('Guest'), findsNothing, reason: onScreen);
    });
  });
}
