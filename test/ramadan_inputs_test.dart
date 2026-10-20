import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/ramadan/presentation/ramadan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('typed household text survives the 30 second refresh', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(430, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(home: RamadanScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final Finder fields = find.byType(TextField);
    expect(fields, findsWidgets);
    await tester.enterText(fields.last, 'Iftar for six on Friday');
    await tester.pump(const Duration(seconds: 31));
    await tester.pump(const Duration(seconds: 31));

    expect(find.text('Iftar for six on Friday'), findsOneWidget);
    // Let any debounce timers finish so the test ends cleanly.
    await tester.pump(const Duration(seconds: 2));
  });
}
