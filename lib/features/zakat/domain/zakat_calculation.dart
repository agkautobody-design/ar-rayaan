/// Zakat calculation helpers — the simple nisab/2.5% model plus the money
/// parsing and formatting the guided calculator uses.
///
/// Pure math, works fully offline. Nisab thresholds come from `Nisab` (the
/// single source of truth: 85 g gold / 595 g silver). The user enters the
/// metal price per gram in their own currency, so no market feed is needed.
/// Scholarly rulings differ by madhhab and asset type — the screen carries a
/// "consult your scholar" note (content pending Founder/scholar review).
library;

import 'nisab.dart';

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
  /// Nisab in grams, from the single source of truth.
  static const double goldNisabGrams = Nisab.goldGrams;
  static const double silverNisabGrams = Nisab.silverGrams;

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

  /// Parses a money or weight field typed on any keyboard.
  ///
  /// Handles `12,500.75`, `12.500,75`, `1 234,5`, `1'234.50`, `$3,000`,
  /// `1,5` (= 1.5), Arabic-Indic digits and the Arabic decimal/thousands
  /// marks. Rules:
  /// - when both `.` and `,` appear, the LAST one is the decimal mark and
  ///   the other is a thousands mark;
  /// - a mark that appears more than once is a thousands mark;
  /// - a lone `.` is a decimal point (`1.5`, `87.480`);
  /// - a lone `,` is a thousands mark only when exactly three digits follow
  ///   and one to three non-zero-led digits precede (`3,000` = 3000);
  ///   otherwise it is a decimal comma (`1,5` = 1.5, `0,500` = 0.5).
  /// Empty or invalid input gives 0.
  static double parseAmount(String raw) {
    final StringBuffer norm = StringBuffer();
    for (final int c in raw.runes) {
      if (c >= 0x0660 && c <= 0x0669) {
        norm.writeCharCode(0x30 + (c - 0x0660)); // Arabic-Indic digits
      } else if (c >= 0x06F0 && c <= 0x06F9) {
        norm.writeCharCode(0x30 + (c - 0x06F0)); // Eastern Arabic digits
      } else if (c == 0x066B) {
        norm.write('.'); // Arabic decimal separator
      } else if (c == 0x066C) {
        norm.write(','); // Arabic thousands separator
      } else {
        norm.writeCharCode(c);
      }
    }
    final String typed = norm.toString().trim();
    // Scientific notation ("1e12"): its letters used to be stripped, turning
    // 1e12 into 112. Read it as the number it says (then cap it).
    final RegExp sci = RegExp(r'^[+-]?\d+(?:\.\d+)?[eE][+-]?\d+$');
    if (sci.hasMatch(typed)) {
      final double? e = double.tryParse(typed);
      if (e == null || e.isNaN || e.isInfinite) return 0;
      return e > maxAmount ? maxAmount : (e < -maxAmount ? -maxAmount : e);
    }
    // Digit groups split by spaces ("1000 5000") are only a number when they
    // are real thousands groups ("1 234 567,5"); otherwise they used to be
    // glued into one huge figure. Unclear input counts as 0, and
    // [amountProblem] tells the person.
    if (_hasUnclearGrouping(typed)) return 0;
    String t = typed.replaceAll(RegExp(r'[^\d.,-]'), '');
    if (t.isEmpty) return 0;
    final bool negative = t.startsWith('-');
    t = t.replaceAll('-', '');
    if (t.isEmpty) return 0;

    final int lastDot = t.lastIndexOf('.');
    final int lastComma = t.lastIndexOf(',');
    final int dots = '.'.allMatches(t).length;
    final int commas = ','.allMatches(t).length;
    String intPart = t;
    String frac = '';
    if (lastDot >= 0 && lastComma >= 0) {
      final int dec = lastDot > lastComma ? lastDot : lastComma;
      intPart = t.substring(0, dec);
      frac = t.substring(dec + 1);
    } else if (lastDot >= 0) {
      if (dots == 1) {
        intPart = t.substring(0, lastDot);
        frac = t.substring(lastDot + 1);
      }
    } else if (lastComma >= 0) {
      if (commas == 1) {
        final String before = t.substring(0, lastComma);
        final String after = t.substring(lastComma + 1);
        final bool thousands =
            after.length == 3 &&
            before.isNotEmpty &&
            before.length <= 3 &&
            !before.startsWith('0');
        if (!thousands) {
          intPart = before;
          frac = after;
        }
      }
    }
    intPart = intPart.replaceAll(RegExp(r'[.,]'), '');
    frac = frac.replaceAll(RegExp(r'[.,]'), '');
    if (intPart.isEmpty && frac.isEmpty) return 0;
    final double? v = double.tryParse(
      '${intPart.isEmpty ? '0' : intPart}${frac.isEmpty ? '' : '.$frac'}',
    );
    if (v == null) return 0;
    final double capped = v > maxAmount ? maxAmount : v;
    return negative ? -capped : capped;
  }

  /// The largest amount a field accepts (one quadrillion). Anything bigger
  /// is capped, so a typo can never print as "2.5e+21".
  static const double maxAmount = 1e15;

  static final RegExp _digitSpace = RegExp(r"\d[\s'\u00A0\u202F]+\d");
  static final RegExp _wellGrouped = RegExp(
    r"^[^\d-]*-?\d{1,3}(?:[\s'\u00A0\u202F]\d{3})+(?:[.,]\d+)?[^\d]*$",
  );

  /// True for digits separated by spaces that are not thousands groups.
  static bool _hasUnclearGrouping(String typed) {
    if (!_digitSpace.hasMatch(typed)) return false;
    return !_wellGrouped.hasMatch(typed);
  }

  /// A short message when [raw] is not a usable amount, else null. Empty
  /// input is fine (it counts as zero).
  static String? amountProblem(String raw) {
    final String t = raw.trim();
    if (t.isEmpty) return null;
    final double v = parseAmount(t);
    if (v < 0) return 'Enter zero or more, not a negative amount';
    if (!RegExp(r'[\d\u0660-\u0669\u06F0-\u06F9]').hasMatch(t)) {
      return 'Enter the amount as a number';
    }
    if (_hasUnclearGrouping(t)) {
      return 'Not sure how to read this. Use one number, like 12500.50';
    }
    if (v >= maxAmount) return 'That number is too large';
    return null;
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
