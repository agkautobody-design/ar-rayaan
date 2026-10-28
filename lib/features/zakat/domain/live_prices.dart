import 'dart:convert';

import 'zakat_currencies.dart';

/// Live gold and silver spot prices (gold-api.com) are quoted in US dollars
/// per troy ounce. The calculator's price fields hold a price per gram in
/// the SAME currency as the person's balances, so the dollar price is changed
/// into the person's currency first (see [LivePriceService]). This keeps the
/// ounce-to-gram constant and the "is this currency one we can fetch" rule in
/// one tested place.
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

  /// Why live prices cannot be fetched for [currencyLabel], or null when
  /// they can (the box holds one of the listed currencies). An empty box is
  /// never assumed to be anything.
  static String? blockedReason(String currencyLabel) {
    if (ZakatCurrencies.codeFromLabel(currencyLabel) != null) return null;
    final String c = currencyLabel.trim();
    if (c.isEmpty) {
      return 'Pick your currency from the list first, so the live prices '
          'come in the same currency as your balances. If yours is not '
          'listed, type the gold and silver prices yourself.';
    }
    return 'Live prices are not offered in ${c.toUpperCase()}. Pick a '
        'currency from the list, or type the gold and silver prices '
        'yourself, in ${c.toUpperCase()}, so the nisab is worked out in the '
        'same currency as your balances.';
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
