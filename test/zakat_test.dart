import 'package:ar_rayaan/app/app.dart';
import 'package:ar_rayaan/app/core/env_config.dart';
import 'package:ar_rayaan/features/zakat/domain/zakat_calculation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('zakat calculation', () {
    test('nisab values follow the 85g / 595g standard', () {
      expect(ZakatCalculation.nisabValue(NisabStandard.gold, 100), 8500);
      expect(ZakatCalculation.nisabValue(NisabStandard.silver, 10), 5950);
      expect(ZakatCalculation.nisabValue(NisabStandard.gold, 0), 0);
    });

    test('above nisab pays exactly one-fortieth of net wealth', () {
      final ZakatResult r = ZakatCalculation.compute(
        const ZakatInput(
          cashAndSavings: 100000,
          standard: NisabStandard.gold,
          metalPricePerGram: 100, // nisab 8,500
        ),
      );
      expect(r.totalAssets, 100000);
      expect(r.netZakatable, 100000);
      expect(r.isEligible, isTrue);
      expect(r.zakatDue, 2500);
    });

    test('debts reduce zakatable wealth', () {
      final ZakatResult r = ZakatCalculation.compute(
        const ZakatInput(
          cashAndSavings: 50000,
          investmentsAndBusiness: 20000,
          debtsDueNow: 10000,
          standard: NisabStandard.gold,
          metalPricePerGram: 100,
        ),
      );
      expect(r.netZakatable, 60000);
      expect(r.zakatDue, 1500);
    });

    test('below nisab pays nothing; debts never go negative', () {
      final ZakatResult below = ZakatCalculation.compute(
        const ZakatInput(
          cashAndSavings: 5000,
          standard: NisabStandard.gold,
          metalPricePerGram: 100, // nisab 8,500
        ),
      );
      expect(below.isEligible, isFalse);
      expect(below.zakatDue, 0);

      final ZakatResult overdrawn = ZakatCalculation.compute(
        const ZakatInput(
          cashAndSavings: 3000,
          debtsDueNow: 9000,
          standard: NisabStandard.gold,
          metalPricePerGram: 100,
        ),
      );
      expect(overdrawn.netZakatable, 0);
      expect(overdrawn.zakatDue, 0);
    });

    test('without a metal price nothing is due (nisab unknown)', () {
      final ZakatResult r = ZakatCalculation.compute(
        const ZakatInput(cashAndSavings: 1000000),
      );
      expect(r.nisabValue, 0);
      expect(r.isEligible, isFalse);
      expect(r.zakatDue, 0);
    });

    test('amount parsing tolerates symbols, commas and blanks', () {
      expect(ZakatCalculation.parseAmount(''), 0);
      expect(ZakatCalculation.parseAmount('  '), 0);
      expect(ZakatCalculation.parseAmount('12,500.75'), 12500.75);
      expect(ZakatCalculation.parseAmount('\$3,000'), 3000);
      expect(ZakatCalculation.parseAmount('abc'), 0);
    });

    test('amount formatting adds thousands separators', () {
      expect(ZakatCalculation.formatAmount(2500), '2,500.00');
      expect(ZakatCalculation.formatAmount(1000000), '1,000,000.00');
      expect(ZakatCalculation.formatAmount(500), '500.00');
    });
  });

  testWidgets('zakat screen computes live end-to-end', (tester) async {
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

    final BuildContext ctx = tester.element(find.text('Prayer Times'));
    // ignore: use_build_context_synchronously
    GoRouter.of(ctx).go('/zakat');
    await tester.pumpAndSettle();

    expect(find.text('PURIFY YOUR WEALTH · 2.5% ABOVE NISAB'), findsOneWidget);
    expect(
      find.text('Enter metal prices to set your nisab'),
      findsOneWidget,
    );

    // Silver standard is the default: price 2/g → nisab 612.36 × 2 = 1,224.72.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Silver price per gram'),
      '2',
    );
    await tester.pump();
    expect(find.text('1,224.72'), findsOneWidget); // nisab stat
    expect(
      find.text('Below nisab — no zakat due, and your sadaqah is still loved'),
      findsOneWidget,
    );

    // Open the Cash & Bank section and add 100,000 cash → due 2,500.
    await tester.tap(find.text('CASH & BANK'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Cash & bank balances'),
      '100,000',
    );
    await tester.pump();
    expect(find.text('2,500.00'), findsOneWidget); // zakat due
    expect(
      find.text('Your wealth is above nisab — may Allah accept it'),
      findsOneWidget,
    );

    // Switch to gold standard with price 100/g → nisab 8,748.00.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Gold price per gram'),
      '100',
    );
    await tester.pump();
    await tester.tap(find.text('Gold · 87.5 g'));
    await tester.pump();
    expect(find.text('8,748.00'), findsOneWidget);
    expect(
      find.text('Your wealth is above nisab — may Allah accept it'),
      findsOneWidget,
    );
  });
}
