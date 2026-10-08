import 'package:ar_rayaan/app/app.dart';
import 'package:ar_rayaan/app/core/env_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Future<void> reachHome(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(child: ArRayaanApp(env: EnvConfig.fromDefines())),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 4)); // splash hold
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('welcome-continue')));
  await tester.pumpAndSettle();
  expect(find.text('Prayer Times'), findsOneWidget);
}

void go(WidgetTester tester, String location) {
  final BuildContext ctx = tester.element(find.text('Prayer Times'));
  GoRouter.of(ctx).go(location);
}

Future<void> pumpLatency(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800)); // fake repo latency
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('login: validation, then success routes home', (tester) async {
    await reachHome(tester);
    go(tester, '/auth/login');
    await tester.pumpAndSettle();
    expect(find.text('Welcome Back'), findsOneWidget);

    // Empty submit → inline validation
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);

    // Valid credentials → Home
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'ahmed@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.byKey(const Key('login-submit')));
    await pumpLatency(tester);
    expect(find.text('Prayer Times'), findsOneWidget);
  });

  testWidgets('signup: creates account and shows verify screen', (
    tester,
  ) async {
    await reachHome(tester);
    go(tester, '/auth/signup');
    await tester.pumpAndSettle();
    expect(find.text('Begin your journey with Ar-Rayaan'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Ahmed Khan');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'ahmed@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'password123');
    await tester.tap(find.byKey(const Key('signup-submit')));
    await pumpLatency(tester);

    expect(find.text('Verify Your Email'), findsOneWidget);
    await tester.tap(find.byKey(const Key('verify-continue')));
    await tester.pumpAndSettle();
    expect(find.text('Prayer Times'), findsOneWidget);
  });

  testWidgets('reset: sends link and returns to login', (tester) async {
    await reachHome(tester);
    go(tester, '/auth/reset');
    await tester.pumpAndSettle();
    expect(find.text('Reset Password'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).first,
      'ahmed@example.com',
    );
    await tester.tap(find.byKey(const Key('reset-submit')));
    await pumpLatency(tester);

    expect(find.text('Check Your Inbox'), findsOneWidget);
    await tester.tap(find.byKey(const Key('reset-back-login')));
    await tester.pumpAndSettle();
    expect(find.text('Welcome Back'), findsOneWidget);
  });

  testWidgets('menu: Log Out signs out and routes to login', (tester) async {
    await reachHome(tester);
    go(tester, '/menu');
    await tester.pumpAndSettle();

    // Log Out sits below the locked grouped sections — bring it into view.
    await tester.scrollUntilVisible(
      find.text('Log Out'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log Out'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400)); // sign-out latency
    await tester.pumpAndSettle();
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
