import 'package:ar_rayaan/features/zakat/domain/nisab.dart';
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
  StockIntent intent = StockIntent.longTerm,
  bool tola = false,
  double silverGrams = 0,
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
      useTolaNisab: tola,
      stockIntent: intent,
      silverGrams: silverGrams,
      goldPricePerGram: goldPrice,
      silverPricePerGram: silverPrice,
    );

void main() {
  group('nisab', () {
    test('silver standard = 595 g × price (the default)', () {
      final r = ZakatEngine.compute(base(cash: 1000, silverPrice: 2));
      expect(r.nisabValue, closeTo(595 * 2, 0.01));
    });
    test('gold standard = 85 g × price', () {
      final r =
          ZakatEngine.compute(base(cash: 1000, silver: false, goldPrice: 100));
      expect(r.nisabValue, closeTo(8500, 0.01));
    });
    test('tola figures are an explicit switch', () {
      final s = ZakatEngine.compute(base(cash: 1000, silverPrice: 2, tola: true));
      expect(s.nisabValue, closeTo(612.36 * 2, 0.01));
      final g = ZakatEngine.compute(
          base(cash: 1000, silver: false, goldPrice: 100, tola: true));
      expect(g.nisabValue, closeTo(8748, 0.01));
    });
    test('engine and simple calculator share one nisab', () {
      expect(ZakatEngine.silverNisabGrams, Nisab.silverGrams);
      expect(ZakatEngine.goldNisabGrams, Nisab.goldGrams);
    });
    test('boundary: exactly at nisab is eligible', () {
      final double nisab = 595 * 1.5;
      final r = ZakatEngine.compute(base(cash: nisab));
      expect(r.isEligible, isTrue);
      expect(r.zakatDue, closeTo(nisab * 0.025, 0.001));
    });
    test('just below nisab is not eligible', () {
      final r = ZakatEngine.compute(base(cash: 595 * 1.5 - 1));
      expect(r.isEligible, isFalse);
      expect(r.zakatDue, 0);
    });
    test('unknown metal price → nisab unknown, no verdict', () {
      final r = ZakatEngine.compute(base(cash: 99999, silverPrice: 0));
      expect(r.nisabKnown, isFalse);
      expect(r.isEligible, isFalse);
    });
  });

  group('weights without a price are reported, not dropped silently', () {
    test('gold grams with no gold price warn and add nothing', () {
      final r = ZakatEngine.compute(base(goldGrams: 50, goldPrice: 0));
      expect(r.totalAssets, 0);
      expect(r.warnings.any((w) => w.contains('Gold weight')), isTrue);
    });
    test('silver grams with no silver price warn', () {
      final r = ZakatEngine.compute(
          base(silverGrams: 700, silverPrice: 0, cash: 10));
      expect(r.warnings.any((w) => w.contains('Silver weight')), isTrue);
    });
    test('silver grams with a price are valued', () {
      final r = ZakatEngine.compute(base(silverGrams: 700, silverPrice: 2));
      expect(r.totalAssets, closeTo(1400, 0.01));
      expect(r.warnings, isEmpty);
    });
    test('worn jewelry without a gold price warns', () {
      final r = ZakatEngine.compute(base(jewelryGrams: 50, goldPrice: 0));
      expect(r.warnings.any((w) => w.contains('Worn jewelry')), isTrue);
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
      final r = ZakatEngine.compute(
          base(stocksTrader: 20000, intent: StockIntent.trader));
      expect(r.totalAssets, closeTo(20000, 0.01));
    });
    test('only the chosen holding style counts, never both', () {
      final trader = ZakatEngine.compute(base(
          stocksTrader: 20000, stocksLong: 20000, intent: StockIntent.trader));
      expect(trader.totalAssets, closeTo(20000, 0.01));
      expect(trader.warnings, isNotEmpty);
      final long = ZakatEngine.compute(
          base(stocksTrader: 20000, stocksLong: 20000));
      expect(long.totalAssets, closeTo(6000, 0.01));
      expect(long.warnings, isNotEmpty);
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
    test('shafi\'i does not deduct debts, and says so', () {
      final r = ZakatEngine.compute(base(
          madhab: Madhab.shafii, cash: 50000, debts: 1000, mortgageYear: 500));
      expect(r.netZakatable, closeTo(50000, 0.01));
      expect(r.totalDebts, 0);
      expect(r.debtLines, isEmpty);
      expect(r.notes.any((n) => n.contains('Shafi') && n.contains('NOT subtracted')),
          isTrue);
    });
    test('hanafi, hanbali and maliki deduct, each with its own note', () {
      for (final Madhab m in <Madhab>[Madhab.hanafi, Madhab.hanbali, Madhab.maliki]) {
        final r = ZakatEngine.compute(base(madhab: m, cash: 50000, debts: 1000));
        expect(r.netZakatable, closeTo(49000, 0.01), reason: '$m');
        expect(r.notes.where((n) => n.startsWith('Debts (')).length, 1, reason: '$m');
      }
    });
    test('no debts entered means no debt note in any school', () {
      for (final Madhab m in Madhab.values) {
        final r = ZakatEngine.compute(base(madhab: m, cash: 50000));
        expect(r.notes.any((n) => n.startsWith('Debts (')), isFalse, reason: '$m');
      }
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
