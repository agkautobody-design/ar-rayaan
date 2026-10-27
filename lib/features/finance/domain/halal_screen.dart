/// The AAOIFI-style stock screens as pure functions, so the percentages the
/// screen shows are exact and testable.
///
/// Thresholds (the widely used AAOIFI Shari'ah Standard 21 figures):
///  * haram business income: at most 5% of total revenue;
///  * interest-bearing debt: at most 30% of market capitalisation;
///  * interest-bearing deposits and securities: at most 30% of market cap;
///  * interest income: at most 5% of total revenue.
/// Where the standard allows a tolerated share, that share is purified (given
/// away). Percentages are shown to one decimal place and compared UNROUNDED,
/// so 5.4% is never shown as "5%" next to a 5% ceiling.
library;

/// One screen's outcome.
class ScreenLine {
  const ScreenLine({
    required this.name,
    required this.percent,
    required this.limit,
    required this.passes,
    required this.text,
    this.purify = false,
  });

  final String name;

  /// The measured ratio in percent (unrounded).
  final double percent;

  /// The ceiling in percent.
  final double limit;
  final bool passes;

  /// Whether a passing result still leaves a portion to purify.
  final bool purify;
  final String text;
}

/// The full outcome: each screen that could be run plus one overall verdict.
class ScreenResult {
  const ScreenResult({required this.lines, required this.verdict});
  final List<ScreenLine> lines;

  /// 'pass', 'fail' or 'incomplete'.
  final String verdict;

  List<String> get messages => lines.map((l) => l.text).toList();
}

abstract final class HalalScreen {
  static const double revenueCeiling = 5.0;
  static const double marketCapCeiling = 30.0;

  /// One decimal, never rounding a failing value down to the ceiling:
  /// 5.04 -> "5.0%" would read as passing next to "5%", so a value above the
  /// limit that would round to the limit is shown with two decimals.
  static String pct(double v, [double limit = -1]) {
    final String one = v.toStringAsFixed(1);
    if (limit > 0 && v > limit && double.parse(one) <= limit) {
      return '${v.toStringAsFixed(2)}%';
    }
    return '$one%';
  }

  static ScreenResult run({
    required double haramRevenue,
    required double totalRevenue,
    required double interestBearingDebt,
    required double marketCap,
    required double interestIncome,
    double interestBearingDeposits = 0,
  }) {
    final List<ScreenLine> lines = <ScreenLine>[];

    if (totalRevenue > 0) {
      final double p = haramRevenue / totalRevenue * 100;
      final bool ok = p <= revenueCeiling;
      lines.add(ScreenLine(
        name: 'Business activity',
        percent: p,
        limit: revenueCeiling,
        passes: ok,
        purify: ok && p > 0,
        text: ok
            ? 'Business activity: ${pct(p, revenueCeiling)} of revenue is from '
                'haram sources, within the 5% limit${p > 0 ? ' - purify that portion by giving it away' : ''}'
            : 'Business activity: ${pct(p, revenueCeiling)} of revenue is from '
                'haram sources, above the 5% limit - fails',
      ));
    }
    if (marketCap > 0) {
      final double p = interestBearingDebt / marketCap * 100;
      final bool ok = p <= marketCapCeiling;
      lines.add(ScreenLine(
        name: 'Leverage',
        percent: p,
        limit: marketCapCeiling,
        passes: ok,
        text: ok
            ? 'Leverage: interest-bearing debt is ${pct(p, marketCapCeiling)} of market cap, within the 30% limit'
            : 'Leverage: interest-bearing debt is ${pct(p, marketCapCeiling)} of market cap, above the 30% limit - fails',
      ));
      if (interestBearingDeposits > 0) {
        final double d = interestBearingDeposits / marketCap * 100;
        final bool dok = d <= marketCapCeiling;
        lines.add(ScreenLine(
          name: 'Deposits and securities',
          percent: d,
          limit: marketCapCeiling,
          passes: dok,
          text: dok
              ? 'Interest-bearing deposits and securities: ${pct(d, marketCapCeiling)} of market cap, within the 30% limit'
              : 'Interest-bearing deposits and securities: ${pct(d, marketCapCeiling)} of market cap, above the 30% limit - fails',
        ));
      }
    }
    if (totalRevenue > 0) {
      final double p = interestIncome / totalRevenue * 100;
      final bool ok = p <= revenueCeiling;
      lines.add(ScreenLine(
        name: 'Interest income',
        percent: p,
        limit: revenueCeiling,
        passes: ok,
        purify: ok && p > 0,
        text: ok
            ? 'Interest income: ${pct(p, revenueCeiling)} of revenue, within the 5% limit${p > 0 ? ' - purify it' : ''}'
            : 'Interest income: ${pct(p, revenueCeiling)} of revenue, above the 5% limit - fails',
      ));
    }

    final bool haveRevenue = totalRevenue > 0;
    final bool haveCap = marketCap > 0;
    String verdict;
    if (!haveRevenue && !haveCap) {
      verdict = 'incomplete';
    } else if (lines.any((l) => !l.passes)) {
      verdict = 'fail';
    } else if (haveRevenue && haveCap) {
      verdict = 'pass';
    } else {
      verdict = 'incomplete';
    }
    return ScreenResult(lines: lines, verdict: verdict);
  }

  /// The one-line overall verdict shown under the individual screens.
  static String verdictText(ScreenResult r) {
    switch (r.verdict) {
      case 'pass':
        return 'Overall: passes all the screens you entered. This is a '
            'screening aid, not a fatwa - check the latest filings or a '
            'qualified screening service before you invest.';
      case 'fail':
        return 'Overall: fails at least one screen, so it is not suitable '
            'on these figures.';
      default:
        return 'Overall: not enough figures to give a verdict - enter total '
            'revenue and market cap as well.';
    }
  }
}
