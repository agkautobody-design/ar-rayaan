import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/zakat/domain/hawl_tracker.dart';
import 'package:ar_rayaan/features/zakat/domain/nisab.dart';
import 'package:ar_rayaan/features/zakat/domain/zakat_al_fitr.dart';
import 'package:ar_rayaan/features/zakat/domain/zakat_calculation.dart';
import 'package:ar_rayaan/features/zakat/presentation/zakat_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Nisab: one source of truth', () {
    test('defaults are 85 g gold and 595 g silver', () {
      expect(Nisab.goldGrams, 85);
      expect(Nisab.silverGrams, 595);
      expect(Nisab.gold(), 85);
      expect(Nisab.silver(), 595);
    });

    test('tola figures are only used when asked for', () {
      expect(Nisab.gold(tola: true), 87.48);
      expect(Nisab.silver(tola: true), 612.36);
    });

    test('the calculator reads the same constants', () {
      expect(ZakatCalculation.goldNisabGrams, Nisab.goldGrams);
      expect(ZakatCalculation.silverNisabGrams, Nisab.silverGrams);
    });

    test('fmt drops a trailing .00 only', () {
      expect(Nisab.fmt(85), '85');
      expect(Nisab.fmt(595), '595');
      expect(Nisab.fmt(87.48), '87.48');
      expect(Nisab.fmt(612.36), '612.36');
    });
  });

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
          cashAndSavings: 8000,
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

    test('exactly at nisab is eligible', () {
      final ZakatResult r = ZakatCalculation.compute(
        const ZakatInput(
          cashAndSavings: 8500,
          standard: NisabStandard.gold,
          metalPricePerGram: 100,
        ),
      );
      expect(r.isEligible, isTrue);
      expect(r.zakatDue, 212.5);
    });

    test('without a metal price nothing is due (nisab unknown)', () {
      final ZakatResult r = ZakatCalculation.compute(
        const ZakatInput(cashAndSavings: 1000000),
      );
      expect(r.nisabValue, 0);
      expect(r.isEligible, isFalse);
      expect(r.zakatDue, 0);
    });
  });

  group('parseAmount', () {
    double p(String s) => ZakatCalculation.parseAmount(s);

    test('blank and garbage are zero', () {
      expect(p(''), 0);
      expect(p('  '), 0);
      expect(p('abc'), 0);
      expect(p(','), 0);
      expect(p('.'), 0);
    });

    test('a decimal comma is a decimal, not a thousands mark', () {
      expect(p('1,5'), 1.5);
      expect(p('12,50'), 12.5);
      expect(p('0,500'), 0.5);
      expect(p('1234,5'), 1234.5);
    });

    test('a comma followed by exactly three digits is thousands', () {
      expect(p('3,000'), 3000);
      expect(p('\$3,000'), 3000);
      expect(p('12,500'), 12500);
      expect(p('1,234,567'), 1234567);
    });

    test('both marks: the last one is the decimal', () {
      expect(p('12,500.75'), 12500.75);
      expect(p('1.234,56'), 1234.56);
      expect(p('1,234,567.89'), 1234567.89);
      expect(p('1.234.567,89'), 1234567.89);
    });

    test('a lone dot is a decimal point', () {
      expect(p('1.5'), 1.5);
      expect(p('87.480'), 87.48);
      expect(p('.5'), 0.5);
    });

    test('spaces, apostrophes and currency symbols are ignored', () {
      expect(p('1 234,5'), 1234.5);
      expect(p("1'234.50"), 1234.5);
      expect(p('USD 2,500'), 2500);
    });

    test('Arabic-Indic digits and separators', () {
      expect(p('١٢٣'), 123);
      expect(p('١٫٥'), 1.5);
      expect(p('١٬٢٣٤'), 1234);
    });

    test('plain integers and negatives', () {
      expect(p('0'), 0);
      expect(p('100000'), 100000);
      expect(p('-5'), -5);
    });
  });

  group('formatAmount', () {
    test('adds thousands separators', () {
      expect(ZakatCalculation.formatAmount(2500), '2,500.00');
      expect(ZakatCalculation.formatAmount(1000000), '1,000,000.00');
      expect(ZakatCalculation.formatAmount(500), '500.00');
      expect(ZakatCalculation.formatAmount(0), '0.00');
    });
  });

  group('HawlTracker', () {
    test('the year completes on the same Hijri day one year later', () {
      // 1 Ramadan 1447 = 18 Feb 2026; 1 Ramadan 1448 = 8 Feb 2027.
      final HawlStatus s = HawlTracker.status(
        DateTime(2026, 2, 18),
        DateTime(2026, 10, 20),
      );
      expect(s.startHijri.year, 1447);
      expect(s.startHijri.month, 9);
      expect(s.startHijri.day, 1);
      expect(s.dueHijri.year, 1448);
      expect(s.dueHijri.month, 9);
      expect(s.dueHijri.day, 1);
      expect(s.dueDate, DateTime(2027, 2, 8));
      expect(s.daysLeft, 111);
      expect(s.isComplete, isFalse);
    });

    test('complete on the due day and after', () {
      final DateTime start = DateTime(2026, 2, 18);
      expect(
        HawlTracker.status(start, DateTime(2027, 2, 8)).isComplete,
        isTrue,
      );
      expect(
        HawlTracker.status(start, DateTime(2027, 2, 8)).daysLeft,
        0,
      );
      expect(
        HawlTracker.status(start, DateTime(2027, 3, 1)).daysLeft,
        isNegative,
      );
      expect(
        HawlTracker.status(start, DateTime(2027, 2, 7)).isComplete,
        isFalse,
      );
    });

    test('time of day never matters', () {
      final HawlStatus a = HawlTracker.status(
        DateTime(2026, 2, 18, 23, 59),
        DateTime(2026, 10, 20, 0, 1),
      );
      final HawlStatus b = HawlTracker.status(
        DateTime(2026, 2, 18, 0, 1),
        DateTime(2026, 10, 20, 23, 59),
      );
      expect(a.daysLeft, b.daysLeft);
    });
  });

  group('ZakatAlFitr', () {
    test('household total is people times the user figure', () {
      expect(ZakatAlFitr.total(people: 4, perPerson: 12.5), 50);
      expect(ZakatAlFitr.total(people: 1, perPerson: 10), 10);
    });

    test('no figure means no total (the app supplies none)', () {
      expect(ZakatAlFitr.total(people: 4, perPerson: 0), 0);
      expect(ZakatAlFitr.total(people: 4, perPerson: -3), 0);
    });

    test('people are clamped to 1..99', () {
      expect(ZakatAlFitr.clampPeople(0), 1);
      expect(ZakatAlFitr.clampPeople(-4), 1);
      expect(ZakatAlFitr.clampPeople(7), 7);
      expect(ZakatAlFitr.clampPeople(500), 99);
    });

    test('carries a primary source', () {
      expect(ZakatAlFitr.source, contains('Bukhari'));
    });
  });

  group('ZakatAlFitrCard', () {
    testWidgets('multiplies, and remembers the household', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      tester.view.physicalSize = const Size(430, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SingleChildScrollView(child: ZakatAlFitrCard())),
          ),
        ),
      );
      await tester.pump();
      expect(
        find.text('Enter the per-person amount to see the household total.'),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('One more'));
      await tester.tap(find.byTooltip('One more'));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('fitr-amount')), '10,5');
      await tester.pump();
      // 3 people at 10.50.
      expect(find.text('Total for 3: 31.50'), findsOneWidget);
      expect(prefs.getInt('ar.zakat.fitr.people'), 3);
      expect(prefs.getString('ar.zakat.fitr.amount'), '10,5');
    });
  });
}
