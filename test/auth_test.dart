import 'package:ar_rayaan/app/router.dart';
import 'package:ar_rayaan/features/auth/application/auth_providers.dart';
import 'package:ar_rayaan/features/auth/application/auth_repository.dart';
import 'package:ar_rayaan/features/auth/data/fake_auth_repository.dart';
import 'package:ar_rayaan/features/auth/data/firebase_auth_repository.dart';
import 'package:ar_rayaan/features/auth/presentation/login_screen.dart';
import 'package:ar_rayaan/features/auth/presentation/reset_screen.dart';
import 'package:ar_rayaan/features/auth/presentation/signup_screen.dart';
import 'package:ar_rayaan/features/auth/presentation/verify_screen.dart';
import 'package:ar_rayaan/features/legal/legal_routes.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Real auth screens on a small router, backed by the in-memory repository.
/// (The old version drove the whole app and was switched off; this one runs.)
GoRouter _router(String initial) => GoRouter(
  initialLocation: initial,
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.signup,
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: AppRoutes.reset,
      builder: (context, state) => const ResetScreen(),
    ),
    GoRoute(
      path: AppRoutes.verify,
      builder: (context, state) => const VerifyScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text('HOME-SCREEN'))),
    ),
    ...legalRoutes,
  ],
);

Future<FakeAuthRepository> _pump(
  WidgetTester tester,
  String initial, {
  bool signedIn = false,
}) async {
  tester.view.physicalSize = const Size(430, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final FakeAuthRepository repo = FakeAuthRepository();
  if (signedIn) {
    await tester.runAsync(() async {
      await repo.signUpWithEmail(
        name: 'Ahmed Khan',
        email: 'ahmed@example.com',
        password: 'password123',
      );
    });
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(routerConfig: _router(initial)),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

Future<void> _latency(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('login: validation, then success routes home', (tester) async {
    await _pump(tester, AppRoutes.login);
    expect(find.text('Welcome Back'), findsOneWidget);

    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'ahmed@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.byKey(const Key('login-submit')));
    await _latency(tester);
    expect(find.text('HOME-SCREEN'), findsOneWidget);
  });

  testWidgets('signup: creates account and shows verify screen', (
    tester,
  ) async {
    await _pump(tester, AppRoutes.signup);
    expect(find.text('Begin your journey with Ar-Rayaan'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Ahmed Khan');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'ahmed@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'password123');
    await tester.tap(find.byKey(const Key('signup-submit')));
    await _latency(tester);

    expect(find.text('Verify Your Email'), findsOneWidget);
    await tester.tap(find.byKey(const Key('verify-continue')));
    await tester.pumpAndSettle();
    expect(find.text('HOME-SCREEN'), findsOneWidget);
  });

  testWidgets('signup links to the Terms and the Privacy Policy', (
    tester,
  ) async {
    await _pump(tester, AppRoutes.signup);

    await tester.tap(find.byKey(const Key('signup-terms')));
    await tester.pumpAndSettle();
    expect(find.text('Terms of Service'), findsWidgets);
    expect(find.byKey(const Key('legal-draft-notice')), findsOneWidget);
    expect(find.textContaining('Not a source of fatwa'), findsOneWidget);

    // Back to sign-up, then the privacy link.
    await tester.tap(find.byIcon(Icons.arrow_back).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('signup-privacy')));
    await tester.pumpAndSettle();
    expect(find.text('Privacy Policy'), findsWidgets);
    expect(find.byKey(const Key('legal-draft-notice')), findsOneWidget);
    expect(find.textContaining('your key and the messages'), findsOneWidget);
  });

  testWidgets('verify: resend works and says so', (tester) async {
    await _pump(tester, AppRoutes.verify, signedIn: true);
    expect(find.text('Verify Your Email'), findsOneWidget);
    await tester.tap(find.byKey(const Key('verify-resend')));
    await _latency(tester);
    expect(find.byKey(const Key('verify-status')), findsOneWidget);
    expect(find.textContaining('Sent again'), findsOneWidget);
  });

  testWidgets('verify: resend while signed out reports a problem', (
    tester,
  ) async {
    await _pump(tester, AppRoutes.verify);
    await tester.tap(find.byKey(const Key('verify-resend')));
    await _latency(tester);
    expect(find.textContaining('sign in'), findsOneWidget);
  });

  testWidgets('reset: sends link and returns to login', (tester) async {
    await _pump(tester, AppRoutes.reset);
    expect(find.text('Reset Password'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).first,
      'ahmed@example.com',
    );
    await tester.tap(find.byKey(const Key('reset-submit')));
    await _latency(tester);

    expect(find.text('Check Your Inbox'), findsOneWidget);
    await tester.tap(find.byKey(const Key('reset-back-login')));
    await tester.pumpAndSettle();
    expect(find.text('Welcome Back'), findsOneWidget);
  });

  group('delete account', () {
    testWidgets('signed out: nothing to delete', (tester) async {
      await _pump(tester, LegalRoutes.deleteAccount);
      expect(find.byKey(const Key('delete-signed-out')), findsOneWidget);
      expect(find.byKey(const Key('delete-submit')), findsNothing);
    });

    testWidgets('needs the checkbox and the password, then signs out', (
      tester,
    ) async {
      final FakeAuthRepository repo = await _pump(
        tester,
        LegalRoutes.deleteAccount,
        signedIn: true,
      );
      expect(find.byKey(const Key('delete-submit')), findsOneWidget);

      // Disabled until the person confirms.
      final Finder button = find.byKey(const Key('delete-submit'));
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(await repo.currentUser(), isNotNull);

      await tester.tap(find.byKey(const Key('delete-confirm')));
      await tester.pumpAndSettle();

      // A wrong password is refused and the account survives.
      await tester.enterText(find.byKey(const Key('delete-password')), 'abc');
      await tester.tap(button);
      await _latency(tester);
      expect(find.byKey(const Key('delete-error')), findsOneWidget);
      expect(await repo.currentUser(), isNotNull);

      // The right password deletes it.
      await tester.enterText(
        find.byKey(const Key('delete-password')),
        'password123',
      );
      await tester.tap(button);
      await _latency(tester);
      expect(await repo.currentUser(), isNull);
    });
  });

  group('firebase repository', () {
    test('requires-recent-login has a human message', () {
      expect(
        FirebaseAuthRepository.mapError(
          fb.FirebaseAuthException(code: 'requires-recent-login'),
        ).message,
        contains('password'),
      );
    });

    test('social sign-in off the web explains itself', () {
      const AuthException e = FirebaseAuthRepository.socialUnavailable;
      expect(e.message, contains('web'));
      expect(e.message, contains('email'));
    });
  });
}
