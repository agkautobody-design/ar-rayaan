/// Zakat calculation — nisab thresholds and the 2.5% obligation.
///
/// Pure math, works fully offline. Nisab follows the widely-held scholarly
/// standard: 85 grams of gold or 595 grams of silver. The user enters the
/// metal price per gram in their own currency, so no market feed is needed.
/// Scholarly rulings differ by madhhab and asset type — the screen carries a
/// "consult your scholar" note (content pending Founder/scholar review).
library;

/// Which precious metal sets the nisab threshold.
enum NisabStandard { gold, silver }

/// Everything needed to compute zakat, in the user's own currency.
class ZakatInput {
  const ZakatInput({
    this.cashAndSavings = 0,
    this.goldAndSilverValue = 0,
    this.investmentsAndBusiness = 0,
    this.moneyOwedToYou = 0,
    this.debtsDueNow = 0,
    this.standard = NisabStandard.gold,
    this.metalPricePerGram = 0,
  });

  /// Cash on hand and in bank accounts.
  final double cashAndSavings;

  /// Market value of gold & silver held (non-jewellery-use per many scholars).
  final double goldAndSilverValue;

  /// Stocks, funds, business inventory and trade assets.
  final double investmentsAndBusiness;

  /// Loans you expect to be repaid.
  final double moneyOwedToYou;

  /// Debts and bills due immediately (deducted).
  final double debtsDueNow;

  /// Nisab standard (gold 85g / silver 595g).
  final NisabStandard standard;

  /// Local price of one gram of the chosen metal (user-entered).
  final double metalPricePerGram;
}

/// The computed outcome.
class ZakatResult {
  const ZakatResult({
    required this.totalAssets,
    required this.netZakatable,
    required this.nisabValue,
    required this.isEligible,
    required this.zakatDue,
  });

  /// Sum of all zakatable asset categories, before debts.
  final double totalAssets;

  /// totalAssets − debtsDueNow, floored at 0.
  final double netZakatable;

  /// Nisab threshold in currency (grams × price); 0 when price unknown.
  final double nisabValue;

  /// True when the nisab is known and netZakatable meets or exceeds it.
  final bool isEligible;

  /// 2.5% of netZakatable when eligible, else 0.
  final double zakatDue;
}

abstract final class ZakatCalculation {
  /// Nisab in grams: 85g gold / 595g silver (widely-held standard).
  static const double goldNisabGrams = 85;
  static const double silverNisabGrams = 595;

  /// Zakat rate: one-fortieth.
  static const double rate = 0.025;

  static double nisabValue(NisabStandard standard, double pricePerGram) {
    if (pricePerGram <= 0) return 0;
    final double grams = standard == NisabStandard.gold
        ? goldNisabGrams
        : silverNisabGrams;
    return grams * pricePerGram;
  }

  static ZakatResult compute(ZakatInput input) {
    final double total =
        input.cashAndSavings +
        input.goldAndSilverValue +
        input.investmentsAndBusiness +
        input.moneyOwedToYou;
    final double net = (total - input.debtsDueNow).clamp(0.0, double.infinity);
    final double nisab = nisabValue(input.standard, input.metalPricePerGram);
    final bool eligible = nisab > 0 && net >= nisab;
    return ZakatResult(
      totalAssets: total,
      netZakatable: net,
      nisabValue: nisab,
      isEligible: eligible,
      zakatDue: eligible ? net * rate : 0,
    );
  }

  /// Parses a money field: trims, drops currency symbols, commas and spaces.
  /// Empty or invalid → 0.
  static double parseAmount(String raw) {
    final String cleaned = raw
        .replaceAll(RegExp(r'[^\d.,-]'), '')
        .replaceAll(',', '')
        .trim();
    if (cleaned.isEmpty) return 0;
    return double.tryParse(cleaned) ?? 0;
  }

  /// Formats a currency amount with thousands separators, 2 decimals.
  static String formatAmount(double value) {
    final String fixed = value.toStringAsFixed(2);
    final List<String> parts = fixed.split('.');
    final String digits = parts[0];
    final StringBuffer out = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final int fromEnd = digits.length - i;
      out.write(digits[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) out.write(',');
    }
    return '${out.toString()}.${parts[1]}';
  }
}
