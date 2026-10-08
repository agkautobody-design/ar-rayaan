import 'package:ar_rayaan/app/app.dart';
import 'package:ar_rayaan/app/core/env_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('welcome reflection carries the corrected attribution', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(child: ArRayaanApp(env: EnvConfig.fromDefines())),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.text('— A beloved transmitted supplication'), findsOneWidget);
    expect(find.textContaining('Sahih Muslim'), findsNothing);
  });

  testWidgets('menu follows the locked grouped spec and routes modules', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(430, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(child: ArRayaanApp(env: EnvConfig.fromDefines())),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('welcome-continue')));
    await tester.pumpAndSettle();

    final BuildContext home = tester.element(find.text('Prayer Times'));
    // ignore: use_build_context_synchronously
    GoRouter.of(home).go('/menu');
    await tester.pumpAndSettle();

    // Locked groups, in order.
    expect(find.text('FAITH & WORSHIP'), findsOneWidget);
    expect(find.text('FAMILY & COMMUNITY'), findsOneWidget);
    expect(find.text('TOOLS & RESOURCES'), findsOneWidget);

    // Marriage row present per locked design, destination-less.
    expect(find.text('Marriage'), findsOneWidget);

    // Settings · Help & Support row, My Profile card, Log Out kept.
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Help & Support'), findsOneWidget);
    expect(find.text('My Profile'), findsOneWidget);
    expect(find.text('Your Journey, Your Progress'), findsOneWidget);
    expect(find.text('Log Out'), findsOneWidget);

    // A shipped module row routes.
    await tester.tap(find.text('Qibla Finder'));
    await tester.pumpAndSettle();
    expect(find.text('DIRECTION TO THE KAABA · MAKKAH'), findsOneWidget);
  });
}
