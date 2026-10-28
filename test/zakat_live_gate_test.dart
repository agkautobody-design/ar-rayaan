import 'package:ar_rayaan/features/zakat/presentation/zakat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

/// Live prices are only fetched for a currency the app can convert into; for
/// anything else the button explains, in words, what to do instead.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> open(WidgetTester tester, {String device = ''}) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(430, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(await wrapWithProviders(
        ZakatScreen(deviceCountryCode: device)));
    await tester.pump();
  }

  Finder status() => find.byKey(const Key('live-price-status'));

  testWidgets('no currency known: the button explains, never silent',
      (tester) async {
    await open(tester);
    expect(find.text('Use live prices'), findsOneWidget);
    expect(find.byKey(const Key('currency-note')), findsOneWidget);
    expect(find.textContaining('could not tell your currency'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('live-prices-button')));
    await tester.tap(find.byKey(const Key('live-prices-button')));
    await tester.pump();
    expect(status(), findsOneWidget);
    expect(tester.widget<Text>(status()).data, contains('Pick your currency'));
  });

  testWidgets('a currency that is not listed: named, with what to do',
      (tester) async {
    await open(tester);
    await tester.enterText(find.byKey(const Key('currency-label')), 'IRR');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('live-prices-button')));
    await tester.tap(find.byKey(const Key('live-prices-button')));
    await tester.pump();
    final String text = tester.widget<Text>(status()).data!;
    expect(text, contains('not offered in IRR'));
    expect(text, contains('type the gold and silver prices yourself'));
  });
}
