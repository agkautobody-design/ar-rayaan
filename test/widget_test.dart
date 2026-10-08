import 'package:ar_rayaan/app/app.dart';
import 'package:ar_rayaan/app/core/env_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('onboarding flow: splash → welcome → sequence → home', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(child: ArRayaanApp(env: EnvConfig.fromDefines())),
    );
    await tester.pump();

    // Screen 1 · Splash (locked artwork, holds 4s)
    expect(find.byType(Image), findsWidgets);

    // Auto-advance after 4s → Screen 2 · Welcome Reflection
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('welcome-continue')), findsOneWidget);

    // Continue → Screen 3 · Home
    await tester.tap(find.byKey(const Key('welcome-continue')));
    await tester.pumpAndSettle();
    expect(find.text('Prayer Times'), findsOneWidget);
    expect(find.text('Today for You'), findsOneWidget);
    expect(find.text('Today’s NOOR'), findsOneWidget);
  });
}
