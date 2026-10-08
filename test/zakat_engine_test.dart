import 'package:ar_rayaan/features/zakat/domain/zakat_engine.dart';
import 'package:flutter_test/flutter_test.dart';

GuidedZakatInput base({
  Madhab madhab = Madhab.hanafi,
  double cash = 0,
  double goldGrams = 0,
  int karat = 24,
  double jewelryGrams = 0,
  int jewelryKarat = 22,
  double stocksTrader = 0,
  double stocksLong = 0,
  LongTermMethod method = LongTermMethod.nzf30,
  double retirement = 0,
  RetirementPosition retPos = RetirementPosition.annualNetAccessible,
  double debts = 0,
  double mortgageYear = 0,
  bool silver = true,
  double goldPrice = 100,
  double silverPrice = 1.5,
}) =>
    GuidedZakatInput(
      madhab: madhab,
      cashAndBank: cash,
      goldGrams: goldGrams,
      goldKarat: karat,
      wornJewelryGoldGrams: jewelryGrams,
      wornJewelryKarat: jewelryKarat,
      stockTraderValue: stocksTrader,
      stockLongTermValue: stocksLong,
      longTermMethod: method,
      retirementBalance: retirement,
      retirementPosition: retPos,
      debtsDueThisYear: debts,
      mortgageYearInstallments: mortgageYear,
      useSilverNisab: silver,
      goldPricePerGram: goldPrice,
      silverPricePerGram: silverPrice,
    );

void main() {
  group('nisab', () {
    test('silver standard = 612.36 g × price', () {
      final r = ZakatEngine.compute(base(cash: 1000, silverPrice: 2));
      expect(r.nisabValue, closeTo(612.36 * 2, 0.01));
    });
    test('gold standard = 87.48 g × price', () {
      final r =
          ZakatEngine.compute(base(cash: 1000, silver: false, goldPrice: 100));
      expect(r.nisabValue, closeTo(8748, 0.01));
    });
    test('boundary: exactly at nisab is eligible', () {
      final double nisab = 612.36 * 1.5;
      final r = ZakatEngine.compute(base(cash: nisab));
      expect(r.isEligible, isTrue);
      expect(r.zakatDue, closeTo(nisab * 0.025, 0.001));
    });
    test('just below nisab is not eligible', () {
      final r = ZakatEngine.compute(base(cash: 612.36 * 1.5 - 1));
      expect(r.isEligible, isFalse);
      expect(r.zakatDue, 0);
    });
    test('unknown metal price → nisab unknown, no verdict', () {
      final r = ZakatEngine.compute(base(cash: 99999, silverPrice: 0));
      expect(r.nisabKnown, isFalse);
      expect(r.isEligible, isFalse);
    });
  });

  group('gold & karat math', () {
    test('24k grams × price', () {
      final r = ZakatEngine.compute(base(goldGrams: 50));
      expect(r.totalAssets, closeTo(5000, 0.01));
    });
    test('22k jewelry purity 0.916 (Hanafi counts worn jewelry)', () {
      final r = ZakatEngine.compute(base(jewelryGrams: 100, jewelryKarat: 22));
      expect(r.totalAssets, closeTo(100 * 0.916 * 100, 0.5));
    });
    test('18k purity 0.75', () {
      final r = ZakatEngine.compute(base(goldGrams: 40, karat: 18));
      expect(r.totalAssets, closeTo(40 * 0.75 * 100, 0.01));
    });
  });

  group('madhab jewelry split', () {
    for (final m in Madhab.values) {
      test('$m', () {
        final r = ZakatEngine.compute(
            base(madhab: m, jewelryGrams: 100, jewelryKarat: 24));
        if (m == Madhab.hanafi) {
          expect(r.totalAssets, closeTo(10000, 0.01));
          expect(r.notes, isEmpty);
        } else {
          expect(r.totalAssets, 0);
          expect(r.notes.any((n) => n.contains('Worn jewelry')), isTrue);
        }
      });
    }
  });

  group('stocks', () {
    test('trader: full market value', () {
      final r = ZakatEngine.compute(base(stocksTrader: 20000));
      expect(r.totalAssets, closeTo(20000, 0.01));
    });
    test('long-term NZF 30% proxy', () {
      final r = ZakatEngine.compute(base(stocksLong: 20000));
      expect(r.totalAssets, closeTo(6000, 0.01));
    });
    test('long-term IFG 25% proxy', () {
      final r = ZakatEngine.compute(
          base(stocksLong: 20000, method: LongTermMethod.ifg25));
      expect(r.totalAssets, closeTo(5000, 0.01));
    });
  });

  group('retirement positions', () {
    test('FCNA annual: net accessible after 30% penalty', () {
      final r = ZakatEngine.compute(base(retirement: 100000));
      expect(r.totalAssets, closeTo(70000, 0.01));
    });
    test('on-access: excluded now, note surfaced', () {
      final r = ZakatEngine.compute(
          base(retirement: 100000, retPos: RetirementPosition.onAccess));
      expect(r.totalAssets, 0);
      expect(r.notes.any((n) => n.contains('on access')), isTrue);
    });
  });

  group('debts', () {
    test('mortgage: only this year\'s installments deducted', () {
      final r = ZakatEngine.compute(base(cash: 50000, mortgageYear: 12000));
      expect(r.netZakatable, closeTo(38000, 0.01));
    });
    test('debts floor net at zero, never negative', () {
      final r = ZakatEngine.compute(base(cash: 1000, debts: 5000));
      expect(r.netZakatable, 0);
      expect(r.zakatDue, 0);
    });
    test('shafi\'i debt note appears', () {
      final r = ZakatEngine.compute(
          base(madhab: Madhab.shafii, cash: 50000, debts: 1000));
      expect(r.notes.any((n) => n.contains('Shafi')), isTrue);
    });
  });

  group('end-to-end household', () {
    test('cash + gold + stocks + retirement − mortgage year', () {
      final r = ZakatEngine.compute(base(
        cash: 15000,
        goldGrams: 60, // 24k × $100 = 6000
        stocksLong: 40000, // 30% = 12000
        retirement: 80000, // 70% = 56000
        mortgageYear: 18000,
      ));
      // assets: 15000 + 6000 + 12000 + 56000 = 89000; net 71000
      expect(r.totalAssets, closeTo(89000, 0.5));
      expect(r.netZakatable, closeTo(71000, 0.5));
      expect(r.isEligible, isTrue);
      expect(r.zakatDue, closeTo(1775, 0.5));
      expect(r.assetLines.length, greaterThanOrEqualTo(4));
      expect(r.debtLines.length, 1);
    });
  });
}
