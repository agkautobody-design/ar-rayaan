/// Nisab — the ONE place the thresholds live. The calculator, its result
/// screen and every line of copy in the zakat and finance features read
/// from here, so they can never disagree.
///
/// Default: 85 g of gold (20 mithqal) and 595 g of silver (200 dirham), the
/// figures used by most contemporary fatwa and standards bodies. South Asian
/// Hanafi practice often uses the tola figures (7.5 tola gold = 87.48 g,
/// 52.5 tola silver = 612.36 g); the calculator offers them as a switch.
library;

abstract final class Nisab {
  /// Gold: 20 mithqal.
  static const double goldGrams = 85;

  /// Silver: 200 dirham.
  static const double silverGrams = 595;

  /// Gold: 7.5 tola (South Asian convention).
  static const double tolaGoldGrams = 87.48;

  /// Silver: 52.5 tola (South Asian convention).
  static const double tolaSilverGrams = 612.36;

  static double gold({bool tola = false}) => tola ? tolaGoldGrams : goldGrams;

  static double silver({bool tola = false}) =>
      tola ? tolaSilverGrams : silverGrams;

  /// '85' / '87.48' — grams without a trailing '.0'.
  static String fmt(double grams) {
    final String s = grams.toStringAsFixed(2);
    return s.endsWith('.00') ? s.substring(0, s.length - 3) : s;
  }
}
