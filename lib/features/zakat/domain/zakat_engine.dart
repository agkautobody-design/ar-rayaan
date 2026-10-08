/// The Guided Zakat Engine — every asset a Muslim household actually holds,
/// computed with madhab awareness and scholarly positions labeled, never
/// ruled on. Pure on-device math; works fully offline once a metal price
/// is known (live fetch is a convenience, never a requirement).
///
/// Sources behind the rules (full detail: "Ar-Rayaan Zakat — Deep Research
/// & Calculator Design.md"):
/// - Rate 1/40 (2.5%), hawl = one lunar year.
/// - Nisab: 87.48 g gold (7.5 tola) / 612.36 g silver (52.5 tola). Most
///   scholars recommend the silver standard today (lower threshold → more
///   reaches the poor); both are shown, the user chooses.
/// - Worn jewelry: Hanafi — zakatable (Abu Dawud 1563, 1565);
///   Maliki/Shafi'i/Hanbali — exempt if genuinely worn (stored jewelry is
///   zakatable in ALL schools).
/// - Stocks held long-term: zakatable base = proportional share of the
///   company's zakatable assets; practical proxies 25% (IFG) / 30% (NZF) of
///   market value, or a custom ratio from the fund's report (AAOIFI method).
/// - Retirement: two respectable positions — FCNA: annually on the net
///   accessible value (balance − taxes − early-withdrawal penalties);
///   Position 2: on penalty-free access. Both presented; the user chooses
///   and stays consistent.
/// - Debts: deduct what is due within the current lunar year (Hanafi: this
///   year's installments of long-term debt such as a mortgage — NOT the
///   whole principal). Shafi'i generally does not deduct debts; surfaced
///   as a note, not a forced rule.
library;

/// The four Sunni schools — drives the worn-jewelry rule and debt notes.
enum Madhab { hanafi, maliki, shafii, hanbali }

/// How held shares are treated.
enum StockIntent { trader, longTerm }

/// Practical proxies for the zakatable share of long-term holdings.
enum LongTermMethod { ifg25, nzf30, custom }

/// The two labeled positions on locked retirement funds.
enum RetirementPosition { annualNetAccessible, onAccess }

/// One computed line of the breakdown (for the result screen).
class ZakatLine {
  const ZakatLine(this.label, this.amount, {this.note});
  final String label;
  final double amount;
  final String? note;
}

/// Every input the guided wizard collects, in the user's own currency.
class GuidedZakatInput {
  const GuidedZakatInput({
    this.madhab = Madhab.hanafi,
    // Cash & bank
    this.cashAndBank = 0,
    this.savings = 0,
    this.moneyOwedToYou = 0,
    this.expectedReceivables = 0,
    // Gold & silver by value
    this.goldValue = 0,
    this.silverValue = 0,
    // Gold & silver by weight (converted via metal price)
    this.goldGrams = 0,
    this.goldKarat = 24,
    this.silverGrams = 0,
    // Jewelry
    this.wornJewelryGoldGrams = 0,
    this.wornJewelryKarat = 22,
    // Investments
    this.stockIntent = StockIntent.longTerm,
    this.stockTraderValue = 0,
    this.stockLongTermValue = 0,
    this.longTermMethod = LongTermMethod.nzf30,
    this.customRatio = 0.25,
    this.cryptoValue = 0,
    // Retirement
    this.retirementBalance = 0,
    this.retirementPenaltyPct = 0.30,
    this.retirementPosition = RetirementPosition.annualNetAccessible,
    // Business & property
    this.businessCash = 0,
    this.businessInventory = 0,
    this.businessReceivables = 0,
    this.rentalIncomeSaved = 0,
    this.propertyForResaleValue = 0,
    // Debts
    this.debtsDueThisYear = 0,
    this.mortgageYearInstallments = 0,
    this.billsDue = 0,
    // Nisab
    this.useSilverNisab = true,
    this.goldPricePerGram = 0,
    this.silverPricePerGram = 0,
  });

  final Madhab madhab;
  final double cashAndBank;
  final double savings;
  final double moneyOwedToYou;
  final double expectedReceivables;
  final double goldValue;
  final double silverValue;
  final double goldGrams;
  final int goldKarat;
  final double silverGrams;
  final double wornJewelryGoldGrams;
  final int wornJewelryKarat;
  final StockIntent stockIntent;
  final double stockTraderValue;
  final double stockLongTermValue;
  final LongTermMethod longTermMethod;
  final double customRatio;
  final double cryptoValue;
  final double retirementBalance;
  final double retirementPenaltyPct;
  final RetirementPosition retirementPosition;
  final double businessCash;
  final double businessInventory;
  final double businessReceivables;
  final double rentalIncomeSaved;
  final double propertyForResaleValue;
  final double debtsDueThisYear;
  final double mortgageYearInstallments;
  final double billsDue;
  final bool useSilverNisab;
  final double goldPricePerGram;
  final double silverPricePerGram;
}

/// The computed outcome with a full, displayable breakdown.
class GuidedZakatResult {
  const GuidedZakatResult({
    required this.assetLines,
    required this.debtLines,
    required this.totalAssets,
    required this.totalDebts,
    required this.netZakatable,
    required this.nisabValue,
    required this.nisabKnown,
    required this.isEligible,
    required this.zakatDue,
    required this.notes,
  });

  final List<ZakatLine> assetLines;
  final List<ZakatLine> debtLines;
  final double totalAssets;
  final double totalDebts;
  final double netZakatable;
  final double nisabValue;
  final bool nisabKnown;
  final bool isEligible;
  final double zakatDue;

  /// Scholarly position notes to surface on the result screen.
  final List<String> notes;
}

abstract final class ZakatEngine {
  static const double goldNisabGrams = 87.48; // 7.5 tola
  static const double silverNisabGrams = 612.36; // 52.5 tola
  static const double rate = 0.025;

  /// Gold purity by karat.
  static double karatPurity(int karat) => switch (karat) {
    24 => 1.0,
    22 => 0.916,
    21 => 0.875,
    18 => 0.750,
    14 => 0.585,
    10 => 0.417,
    9 => 0.375,
    _ => karat / 24.0,
  };

  static double nisabValue(GuidedZakatInput i) {
    if (i.useSilverNisab) {
      return i.silverPricePerGram > 0
          ? silverNisabGrams * i.silverPricePerGram
          : 0;
    }
    return i.goldPricePerGram > 0 ? goldNisabGrams * i.goldPricePerGram : 0;
  }

  static GuidedZakatResult compute(GuidedZakatInput i) {
    final List<ZakatLine> assets = [];
    final List<ZakatLine> debts = [];
    final List<String> notes = [];
    void add(String label, double amount, [String? note]) {
      if (amount > 0) assets.add(ZakatLine(label, amount, note: note));
    }

    // Cash & bank — always zakatable.
    add('Cash & bank balances', i.cashAndBank);
    add('Savings & deposits', i.savings);
    add('Money owed to you', i.moneyOwedToYou, 'if repayment is expected');
    add('Expected receivables', i.expectedReceivables,
        'tax refunds, salary due, refundable deposits');

    // Gold & silver — by value or by weight × purity × live price.
    add('Gold (by value)', i.goldValue);
    add('Silver (by value)', i.silverValue);
    if (i.goldGrams > 0 && i.goldPricePerGram > 0) {
      final double pure = i.goldGrams * karatPurity(i.goldKarat);
      add('Gold ${i.goldGrams.toStringAsFixed(1)} g · ${i.goldKarat}k',
          pure * i.goldPricePerGram,
          '${pure.toStringAsFixed(1)} g pure × price');
    }
    if (i.silverGrams > 0 && i.silverPricePerGram > 0) {
      add('Silver ${i.silverGrams.toStringAsFixed(1)} g',
          i.silverGrams * i.silverPricePerGram);
    }

    // Worn jewelry — THE madhab split. Stored jewelry is zakatable in all
    // schools and belongs in the gold/silver fields above.
    if (i.wornJewelryGoldGrams > 0 && i.goldPricePerGram > 0) {
      final double pure =
          i.wornJewelryGoldGrams * karatPurity(i.wornJewelryKarat);
      if (i.madhab == Madhab.hanafi) {
        add('Worn gold jewelry (Hanafi)', pure * i.goldPricePerGram,
            '${pure.toStringAsFixed(1)} g pure · Abu Dawud 1563');
      } else {
        notes.add(
            'Worn jewelry: exempt in the Maliki, Shafi\'i and Hanbali schools '
            'when genuinely worn (Hanafi: zakatable). Stored jewelry is '
            'zakatable in every school — enter it under Gold.');
      }
    }

    // Investments.
    add('Stocks — trading', i.stockTraderValue, 'full market value');
    if (i.stockLongTermValue > 0) {
      final double ratio = switch (i.longTermMethod) {
        LongTermMethod.ifg25 => 0.25,
        LongTermMethod.nzf30 => 0.30,
        LongTermMethod.custom => i.customRatio.clamp(0.0, 1.0),
      };
      final String methodName = switch (i.longTermMethod) {
        LongTermMethod.ifg25 => 'IFG 25% proxy',
        LongTermMethod.nzf30 => 'NZF 30% proxy',
        LongTermMethod.custom => 'custom ratio',
      };
      add('Stocks — long-term', i.stockLongTermValue * ratio,
          '$methodName of market value (AAOIFI underlying-assets method)');
    }
    add('Crypto', i.cryptoValue, 'market value on your zakat date');

    // Retirement — two labeled positions.
    if (i.retirementBalance > 0) {
      if (i.retirementPosition == RetirementPosition.annualNetAccessible) {
        final double accessible =
            i.retirementBalance * (1 - i.retirementPenaltyPct.clamp(0, 1));
        add('Retirement (401k / RRSP / pension)', accessible,
            'FCNA position: net accessible value after taxes & penalties');
      } else {
        notes.add(
            'Retirement: the "on access" position defers zakat on locked '
            'funds until penalty-free withdrawal. Both positions are '
            'respectable — pick one and stay consistent year to year.');
      }
    }

    // Business & property.
    add('Business cash', i.businessCash);
    add('Business inventory', i.businessInventory, 'goods held for sale');
    add('Business receivables', i.businessReceivables);
    add('Saved rental income', i.rentalIncomeSaved,
        'the property itself is not zakatable');
    add('Property held for resale', i.propertyForResaleValue,
        'trade goods — market value');

    // Debts — what is due within this lunar year.
    void deduct(String label, double amount, [String? note]) {
      if (amount > 0) debts.add(ZakatLine(label, amount, note: note));
    }

    deduct('Debts due this year', i.debtsDueThisYear);
    deduct('Mortgage — this year\'s installments', i.mortgageYearInstallments,
        'not the full remaining principal');
    deduct('Bills due now', i.billsDue);
    if ((i.debtsDueThisYear > 0 || i.mortgageYearInstallments > 0) &&
        i.madhab == Madhab.shafii) {
      notes.add(
          'Note: the Shafi\'i school generally does not deduct debts from '
          'zakatable wealth. Shown here for transparency — consult your '
          'scholar on which practice you follow.');
    }

    final double totalAssets =
        assets.fold(0.0, (sum, l) => sum + l.amount);
    final double totalDebts = debts.fold(0.0, (sum, l) => sum + l.amount);
    final double net = (totalAssets - totalDebts).clamp(0.0, double.infinity);
    final double nisab = nisabValue(i);
    final bool nisabKnown = nisab > 0;
    final bool eligible = nisabKnown && net >= nisab;

    return GuidedZakatResult(
      assetLines: assets,
      debtLines: debts,
      totalAssets: totalAssets,
      totalDebts: totalDebts,
      netZakatable: net,
      nisabValue: nisab,
      nisabKnown: nisabKnown,
      isEligible: eligible,
      zakatDue: eligible ? net * rate : 0,
      notes: notes,
    );
  }
}
