import 'package:ar_rayaan/features/zakat/presentation/zakat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

/// P0-4: live prices are US dollars; they must not be dropped into price
/// boxes whose balances are in another currency.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Finder liveButton() => find.ancestor(
        of: find.text('Use live prices (USD)'),
        matching: find.byWidgetPredicate((Widget w) => w is TextButton),
      );

  Future<void> open(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(430, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(await wrapWithProviders(const ZakatScreen()));
    await tester.pump();
  }

  testWidgets('wrong or empty currency: the button explains, never silent',
      (tester) async {
    await open(tester);
    // Empty currency: not assumed to be dollars. The button stays tappable.
    expect(tester.widget<TextButton>(liveButton()).onPressed, isNotNull);
    expect(find.textContaining('type USD in the currency box'),
        findsWidgets);

    await tester.enterText(find.byKey(const Key('currency-label')), 'PKR');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('live-prices-button')));
    await tester.tap(find.byKey(const Key('live-prices-button')));
    await tester.pump();
    expect(find.byKey(const Key('live-price-status')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('live-price-status'))).data,
        contains('your currency is set to PKR'));
  });
}
