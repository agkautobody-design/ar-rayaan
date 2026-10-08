import 'package:ar_rayaan/app/app.dart';
import 'package:ar_rayaan/app/core/env_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home tiles show live data, not stale placeholders', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(430, 1600);
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

    // Stale placeholders are gone.
    expect(find.text('Riyad as-Salihin · Chapter 1'), findsNothing);
    expect(find.text('Dhuhr 12:47 PM'), findsNothing);
    expect(find.text('Morning Adhkar · 28 remaining'), findsNothing);
    expect(find.text('Continue Reading · Surah Al-Kahf'), findsNothing);

    // Live content in their place.
    expect(find.text('The Forty Hadith · An-Nawawi'), findsOneWidget);
    expect(find.text('Begin Reading · Al-Fatihah'), findsOneWidget);
    expect(find.textContaining('Morning Adhkar'), findsWidgets);
  });
}
