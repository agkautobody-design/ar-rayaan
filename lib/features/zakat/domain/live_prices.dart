import 'dart:convert';

/// Live gold and silver spot prices (gold-api.com) are quoted in US dollars
/// per troy ounce. The calculator's price fields hold a price per gram in
/// the SAME currency as the person's balances, so a dollar price may only be
/// used when the balances are in dollars. This keeps that rule in one tested
/// place.
class LivePrices {
  const LivePrices._();

  static const double gramsPerTroyOunce = 31.1035;

  /// True when [label] (the optional currency box) says US dollars.
  static bool isUsd(String label) {
    final String t = label.trim().toUpperCase().replaceAll('.', '');
    return t == 'USD' ||
        t == r'$' ||
        t == r'US$' ||
        t == 'US DOLLAR' ||
        t == 'US DOLLARS' ||
        t == 'DOLLAR' ||
        t == 'DOLLARS';
  }

  /// Why live prices must not be used for [currencyLabel], or null when they
  /// may be. An empty label is not assumed to be dollars.
  static String? blockedReason(String currencyLabel) {
    if (isUsd(currencyLabel)) return null;
    final String c = currencyLabel.trim();
    if (c.isEmpty) {
      return 'Live prices are in US dollars. If your balances are in US '
          'dollars, type USD in the currency box below. If they are in '
          'another currency, type the gold and silver prices yourself, in '
          'that currency.';
    }
    return 'Live prices are in US dollars, but your currency is set to '
        '${c.toUpperCase()}. Type the gold and silver prices yourself, in '
        '${c.toUpperCase()}, so the nisab is worked out in the same '
        'currency as your balances.';
  }

  /// Dollars per gram from the two API bodies, e.g. `{"price": 2650.5}`.
  /// Throws [FormatException] when either body is not a plausible price.
  static ({double gold, double silver}) perGram(
    String goldBody,
    String silverBody,
  ) {
    return (
      gold: _ounceToGram(goldBody),
      silver: _ounceToGram(silverBody),
    );
  }

  static double _ounceToGram(String body) {
    final Object? doc = json.decode(body);
    if (doc is! Map<String, dynamic>) {
      throw const FormatException('price response is not an object');
    }
    final Object? price = doc['price'];
    if (price is! num || !price.isFinite || price <= 0) {
      throw const FormatException('price is missing or not positive');
    }
    return price.toDouble() / gramsPerTroyOunce;
  }
}
