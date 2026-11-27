import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/support/presentation/support_pathway_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Every support page puts "Talk to Hādi" near the top, for people who are
/// not ready to speak to a person yet.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a pathway page offers Talk to Hādi without scrolling',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(home: SupportPathwayScreen(id: 'drugs')),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('support-talk-to-hadi')), findsOneWidget);
    expect(find.text('Talk to Hādi'), findsOneWidget);
  });
}
