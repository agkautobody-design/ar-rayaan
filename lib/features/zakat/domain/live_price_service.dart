import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'live_prices.dart';

/// Gold and silver prices per gram in one currency, with where and when they
/// came from, so the screen can always say "source + time" and, when the
/// price was changed from US dollars, "at what rate, from which day".
class MetalPrices {
  const MetalPrices({
    required this.goldPerGram,
    required this.silverPerGram,
    required this.source,
    required this.asOf,
    this.currency = 'USD',
    this.usdRate,
    this.rateAsOf,
    this.rateSource,
    this.dailyOnly = false,
    this.fromSavedCopy = false,
  });

  final double goldPerGram;
  final double silverPerGram;

  /// ISO 4217 code the two prices are in, upper case.
  final String currency;

  /// Plain name of the provider, e.g. `gold-api.com`.
  final String source;

  /// When the provider says the quote was made (or, for a daily feed, the day
  /// of the rate, at midnight UTC).
  final DateTime asOf;

  /// How many units of [currency] one US dollar bought when the dollar spot
  /// price was changed into [currency]. Null when the prices are in dollars
  /// or came from the daily feed already in [currency].
  final double? usdRate;

  /// The day of [usdRate] (midnight UTC), when the feed gave one.
  final DateTime? rateAsOf;

  /// Plain name of where [usdRate] came from.
  final String? rateSource;

  /// True for a once-a-day reference rate (no time of day).
  final bool dailyOnly;

  /// True when read back from this device rather than fetched just now.
  final bool fromSavedCopy;

  /// True when the dollar spot price was changed into [currency] here.
  bool get converted => usdRate != null;

  MetalPrices asSavedCopy() => MetalPrices(
        goldPerGram: goldPerGram,
        silverPerGram: silverPerGram,
        source: source,
        asOf: asOf,
        currency: currency,
        usdRate: usdRate,
        rateAsOf: rateAsOf,
        rateSource: rateSource,
        dailyOnly: dailyOnly,
        fromSavedCopy: true,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'gold': goldPerGram,
        'silver': silverPerGram,
        'currency': currency,
        'source': source,
        'asOf': asOf.toUtc().toIso8601String(),
        'daily': dailyOnly,
        if (usdRate != null) 'rate': usdRate,
        if (rateAsOf != null) 'rateAsOf': rateAsOf!.toUtc().toIso8601String(),
        if (rateSource != null) 'rateSource': rateSource,
      };

  static MetalPrices? tryFromJson(Object? doc) {
    if (doc is! Map<String, dynamic>) return null;
    final Object? g = doc['gold'];
    final Object? s = doc['silver'];
    final Object? src = doc['source'];
    final Object? at = doc['asOf'];
    if (g is! num || s is! num || src is! String || at is! String) return null;
    final DateTime? when = DateTime.tryParse(at);
    if (when == null || !g.isFinite || !s.isFinite || g <= 0 || s <= 0) {
      return null;
    }
    // Copies saved before currencies were added were always dollars.
    final Object? cur = doc['currency'];
    final String currency =
        cur is String && cur.trim().isNotEmpty ? cur.trim().toUpperCase() : 'USD';
    final Object? rate = doc['rate'];
    final Object? rateAt = doc['rateAsOf'];
    final Object? rateSrc = doc['rateSource'];
    final double? usdRate =
        (rate is num && rate.isFinite && rate > 0) ? rate.toDouble() : null;
    return MetalPrices(
      goldPerGram: g.toDouble(),
      silverPerGram: s.toDouble(),
      source: src,
      asOf: when,
      currency: currency,
      usdRate: usdRate,
      rateAsOf:
          usdRate != null && rateAt is String ? DateTime.tryParse(rateAt) : null,
      rateSource: usdRate != null && rateSrc is String ? rateSrc : null,
      dailyOnly: doc['daily'] == true,
      fromSavedCopy: true,
    );
  }

  static const List<String> _months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// "27 Oct 2026, 14:05" (device time) or "27 Oct 2026" for a daily rate.
  String whenText() {
    final DateTime d = dailyOnly ? asOf.toUtc() : asOf.toLocal();
    final String day = '${d.day} ${_months[d.month - 1]} ${d.year}';
    return dailyOnly ? day : '$day, ${_two(d.hour)}:${_two(d.minute)}';
  }

  /// "27 Oct 2026", the day of the exchange rate, or null when not known.
  String? rateWhenText() {
    final DateTime? r = rateAsOf?.toUtc();
    if (r == null) return null;
    return '${r.day} ${_months[r.month - 1]} ${r.year}';
  }

  /// A price per gram as shown in the price box and in the status line:
  /// two decimals from 100 up, three below (so a dinar price of 0.5 per gram
  /// of silver keeps its third digit).
  static String formatPrice(double v) =>
      v >= 100 ? v.toStringAsFixed(2) : v.toStringAsFixed(3);

  /// An exchange rate: two decimals from 100 up, four below.
  static String formatRate(double v) =>
      v >= 100 ? v.toStringAsFixed(2) : v.toStringAsFixed(4);

  /// "gold CAD 132.451, silver CAD 1.612"
  String priceLine() => 'gold $currency ${formatPrice(goldPerGram)}, '
      'silver $currency ${formatPrice(silverPerGram)}';

  /// Where the numbers came from, when, and (if changed from dollars) at
  /// what rate from which day. One honest paragraph for the status line.
  String sourceLine() {
    final StringBuffer b = StringBuffer(
      'Source: $source, ${dailyOnly ? 'rate for' : 'as of'} ${whenText()}.',
    );
    final double? r = usdRate;
    if (r != null) {
      final String? day = rateWhenText();
      b.write(' Converted from USD at 1 USD = ${formatRate(r)} $currency'
          ' (${rateSource ?? 'daily reference rate'}'
          '${day == null ? '' : ', rate for $day'}).');
    }
    if (dailyOnly) b.write(' This source updates once a day.');
    return b.toString();
  }
}

enum LivePriceFailure {
  offline,
  timeout,
  unavailable,
  unreadable,

  /// The price services answered, but have no exchange rate or metal price
  /// for the chosen currency.
  noRate,

  /// The dollar price of gold and silver arrived, but the exchange rate into
  /// the chosen currency did not.
  rateUnavailable,
}

/// A price fetch that failed, in words a person can act on.
class LivePriceException implements Exception {
  const LivePriceException(this.kind, {this.currency});
  final LivePriceFailure kind;

  /// The currency the person asked for, for the messages that name it.
  final String? currency;

  String get message {
    final String cur = currency ?? 'that currency';
    switch (kind) {
      case LivePriceFailure.offline:
        return 'No internet connection. Check your connection and try again.';
      case LivePriceFailure.timeout:
        return 'The price service took too long to answer. Try again in a '
            'moment.';
      case LivePriceFailure.unavailable:
        return 'The price services are not answering right now. Try again '
            'later.';
      case LivePriceFailure.unreadable:
        return 'The price service sent something the app could not read. '
            'Try again later.';
      case LivePriceFailure.noRate:
        return 'The price services have no exchange rate for $cur.';
      case LivePriceFailure.rateUnavailable:
        return 'The gold and silver prices in US dollars arrived, but the '
            'exchange rate into $cur did not, so they cannot be shown in '
            '$cur. Try again later, or choose USD.';
    }
  }

  @override
  String toString() => 'LivePriceException(${kind.name})';
}

/// Fetches gold and silver prices per gram in the person's currency with no
/// key and no secret.
///
/// Sources, tried in order; the first that answers with sane numbers wins:
///  1. gold-api.com `GET /price/XAU` and `/price/XAG`: the keyless spot quote
///     in US dollars per troy ounce, with a timestamp. Changed into the
///     person's currency with the day's `usd.json` rate from source 2.
///  2. The open currency-api dataset (`@fawazahmed0/currency-api`, published
///     as CC0 in its repository listing), a once-a-day reference rate that
///     also lists gold (`xau`) and silver (`xag`) in every currency. Served
///     from jsDelivr, with Cloudflare Pages as the second address. Used for
///     the exchange rate in step 1, and on its own (prices straight in the
///     person's currency) when gold-api.com fails.
/// The terms of both are summarised in docs/DATA_SOURCES.md. The last good
/// result for each currency is kept on this device so a failure can still
/// show "last saved ... from <date>".
class LivePriceService {
  LivePriceService({
    http.Client? client,
    this.timeout = const Duration(seconds: 8),
    this.goldApiBase = 'https://api.gold-api.com',
    this.dailyFeedBases = const <String>[
      'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/'
          'currencies',
      'https://latest.currency-api.pages.dev/v1/currencies',
    ],
  }) : _client = client ?? http.Client();

  /// Saved copies, one per currency, as one JSON object keyed by code.
  static const String prefsKey = 'zakat.live_prices.v2';

  /// The earlier single (US dollar) copy; still read for USD.
  static const String legacyPrefsKey = 'zakat.live_prices.v1';

  final http.Client _client;
  final Duration timeout;
  final String goldApiBase;
  final List<String> dailyFeedBases;

  // Wide, on purpose: only to refuse nonsense (0, a typo'd unit, a swapped
  // pair), never to second-guess the market. Checked on the US dollar figure.
  static const double _minGoldOz = 200;
  static const double _maxGoldOz = 100000;
  static const double _minSilverOz = 2;
  static const double _maxSilverOz = 5000;

  // Exchange rates: one US dollar buys at least this many and at most this
  // many units of any listed currency (Iraqi dinar and Indonesian rupiah are
  // in the thousands; nothing listed is anywhere near a dollar a thousand).
  static const double _minRate = 0.001;
  static const double _maxRate = 1e7;

  static final RegExp _codeShape = RegExp(r'^[A-Z]{3}$');

  /// Gold and silver per gram in [currency] (an ISO 4217 code), from the
  /// first source that works. Throws [LivePriceException] otherwise.
  Future<MetalPrices> fetch({String currency = 'USD'}) async {
    final String cur = currency.trim().toUpperCase();
    if (!_codeShape.hasMatch(cur)) {
      throw LivePriceException(LivePriceFailure.noRate, currency: cur);
    }
    final List<LivePriceFailure> failures = <LivePriceFailure>[];
    final List<Future<MetalPrices> Function()> sources =
        <Future<MetalPrices> Function()>[
      () => _fromGoldApi(cur),
      () => _fromDailyFeed(cur),
    ];
    for (final Future<MetalPrices> Function() source in sources) {
      try {
        final MetalPrices p = await source();
        await _save(p);
        return p;
      } catch (e) {
        failures.add(_classify(e));
      }
    }
    throw _combine(failures, cur);
  }

  /// The last good prices in [currency] kept on this device, or null.
  Future<MetalPrices?> lastSaved({String currency = 'USD'}) async {
    final String cur = currency.trim().toUpperCase();
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(prefsKey);
      if (raw != null) {
        final Object? doc = json.decode(raw);
        if (doc is Map<String, dynamic>) {
          final MetalPrices? p = MetalPrices.tryFromJson(doc[cur]);
          if (p != null && p.currency == cur) return p;
        }
      }
      if (cur == 'USD') {
        final String? old = prefs.getString(legacyPrefsKey);
        if (old != null) {
          final MetalPrices? p = MetalPrices.tryFromJson(json.decode(old));
          if (p != null && p.currency == 'USD') return p;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _save(MetalPrices p) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      Map<String, Object?> all = <String, Object?>{};
      final String? raw = prefs.getString(prefsKey);
      if (raw != null) {
        try {
          final Object? doc = json.decode(raw);
          if (doc is Map<String, dynamic>) all = Map<String, Object?>.from(doc);
        } catch (_) {
          // An unreadable old copy is replaced, not kept.
        }
      }
      all[p.currency] = p.toJson();
      await prefs.setString(prefsKey, json.encode(all));
    } catch (_) {
      // Saving is a convenience; a failure must not hide fresh prices.
    }
  }

  static LivePriceFailure _classify(Object e) {
    if (e is LivePriceException) return e.kind;
    if (e is TimeoutException) return LivePriceFailure.timeout;
    if (e is FormatException) return LivePriceFailure.unreadable;
    // SocketException, ClientException, TLS errors: no usable network.
    return LivePriceFailure.offline;
  }

  /// One exception for a list of failures from several attempts.
  static LivePriceException _combine(
    List<LivePriceFailure> failures,
    String cur,
  ) {
    if (failures.contains(LivePriceFailure.noRate)) {
      return LivePriceException(LivePriceFailure.noRate, currency: cur);
    }
    if (failures.contains(LivePriceFailure.rateUnavailable)) {
      return LivePriceException(LivePriceFailure.rateUnavailable,
          currency: cur);
    }
    if (failures.every((LivePriceFailure f) => f == LivePriceFailure.offline)) {
      return const LivePriceException(LivePriceFailure.offline);
    }
    if (failures.every((LivePriceFailure f) =>
        f == LivePriceFailure.offline || f == LivePriceFailure.timeout)) {
      return const LivePriceException(LivePriceFailure.timeout);
    }
    if (failures.contains(LivePriceFailure.unreadable) &&
        !failures.contains(LivePriceFailure.unavailable)) {
      return const LivePriceException(LivePriceFailure.unreadable);
    }
    return const LivePriceException(LivePriceFailure.unavailable);
  }

  Future<http.Response> _get(String url) async {
    final http.Response r = await _client
        .get(Uri.parse(url), headers: const <String, String>{
      'Accept': 'application/json',
    }).timeout(timeout);
    if (r.statusCode != 200) {
      throw const LivePriceException(LivePriceFailure.unavailable);
    }
    return r;
  }

  /// `<base>/<file>` from the first daily-feed address that answers.
  Future<({String body, String via})> _getDaily(String file) async {
    final List<LivePriceFailure> failures = <LivePriceFailure>[];
    for (final String base in dailyFeedBases) {
      try {
        final http.Response r = await _get('$base/$file');
        return (body: utf8.decode(r.bodyBytes), via: _viaName(base));
      } catch (e) {
        failures.add(_classify(e));
      }
    }
    throw _combine(failures, '');
  }

  static String _viaName(String base) {
    final String host = Uri.parse(base).host;
    if (host.contains('jsdelivr')) return 'jsDelivr';
    if (host.contains('pages.dev')) return 'Cloudflare Pages';
    return host;
  }

  // ---- source 1: gold-api.com spot in dollars, changed into [cur] --------

  Future<MetalPrices> _fromGoldApi(String cur) async {
    final List<http.Response> r = await Future.wait(<Future<http.Response>>[
      _get('$goldApiBase/price/XAU'),
      _get('$goldApiBase/price/XAG'),
    ]);
    final ({double ounce, DateTime? at}) gold =
        _readGoldApi(utf8.decode(r[0].bodyBytes));
    final ({double ounce, DateTime? at}) silver =
        _readGoldApi(utf8.decode(r[1].bodyBytes));
    _checkRange(gold.ounce, silver.ounce);

    double rate = 1;
    DateTime? rateAt;
    String? rateVia;
    if (cur != 'USD') {
      try {
        final ({double rate, DateTime? at, String via}) fx = await _usdRate(cur);
        rate = fx.rate;
        rateAt = fx.at;
        rateVia = 'currency-api daily reference rate, via ${fx.via}';
      } catch (e) {
        final LivePriceFailure k = _classify(e);
        throw LivePriceException(
          k == LivePriceFailure.noRate
              ? LivePriceFailure.noRate
              : LivePriceFailure.rateUnavailable,
          currency: cur,
        );
      }
    }
    return MetalPrices(
      goldPerGram: gold.ounce * rate / LivePrices.gramsPerTroyOunce,
      silverPerGram: silver.ounce * rate / LivePrices.gramsPerTroyOunce,
      currency: cur,
      source: 'gold-api.com',
      asOf: gold.at ?? DateTime.now().toUtc(),
      usdRate: cur == 'USD' ? null : rate,
      rateAsOf: rateAt,
      rateSource: rateVia,
    );
  }

  static ({double ounce, DateTime? at}) _readGoldApi(String body) {
    final Object? doc = json.decode(body);
    if (doc is! Map<String, dynamic>) {
      throw const FormatException('not an object');
    }
    final Object? price = doc['price'];
    if (price is! num || !price.isFinite || price <= 0) {
      throw const FormatException('price missing or not positive');
    }
    final Object? at = doc['updatedAt'];
    return (
      ounce: price.toDouble(),
      at: at is String ? DateTime.tryParse(at) : null,
    );
  }

  /// How many [cur] one US dollar buys, from the daily feed's `usd.json`.
  Future<({double rate, DateTime? at, String via})> _usdRate(String cur) async {
    final ({String body, String via}) f = await _getDaily('usd.json');
    final Object? doc = json.decode(f.body);
    if (doc is! Map<String, dynamic>) {
      throw const FormatException('not an object');
    }
    final Object? rates = doc['usd'];
    if (rates is! Map<String, dynamic>) {
      throw const FormatException('usd rates missing');
    }
    final Object? v = rates[cur.toLowerCase()];
    if (v == null) {
      throw LivePriceException(LivePriceFailure.noRate, currency: cur);
    }
    if (v is! num || !v.isFinite || v < _minRate || v > _maxRate) {
      throw const FormatException('exchange rate is not plausible');
    }
    final Object? date = doc['date'];
    return (
      rate: v.toDouble(),
      at: date is String ? DateTime.tryParse(date) : null,
      via: f.via,
    );
  }

  // ---- source 2: the daily feed's own gold and silver in [cur] ----------

  Future<MetalPrices> _fromDailyFeed(String cur) async {
    final List<({String body, String via})> r =
        await Future.wait(<Future<({String body, String via})>>[
      _getDaily('xau.json'),
      _getDaily('xag.json'),
    ]);
    final ({double usd, double local, DateTime? at}) gold =
        _readDaily(r[0].body, 'xau', cur);
    final ({double usd, double local, DateTime? at}) silver =
        _readDaily(r[1].body, 'xag', cur);
    _checkRange(gold.usd, silver.usd);
    return MetalPrices(
      goldPerGram: gold.local / LivePrices.gramsPerTroyOunce,
      silverPerGram: silver.local / LivePrices.gramsPerTroyOunce,
      currency: cur,
      source: 'currency-api (daily reference rate, via ${r[0].via})',
      asOf: gold.at ?? DateTime.now().toUtc(),
      dailyOnly: true,
    );
  }

  /// Price of one troy ounce of [code] (`xau` or `xag`) in US dollars and in
  /// [cur], from a feed body like `{"date": "...", "xau": {"usd": 2650, ...}}`.
  static ({double usd, double local, DateTime? at}) _readDaily(
    String body,
    String code,
    String cur,
  ) {
    final Object? doc = json.decode(body);
    if (doc is! Map<String, dynamic>) {
      throw const FormatException('not an object');
    }
    final Object? rates = doc[code];
    if (rates is! Map<String, dynamic>) {
      throw const FormatException('metal prices missing');
    }
    final Object? usd = rates['usd'];
    if (usd is! num || !usd.isFinite || usd <= 0) {
      throw const FormatException('usd price missing or not positive');
    }
    final Object? local = rates[cur.toLowerCase()];
    if (local == null) {
      throw LivePriceException(LivePriceFailure.noRate, currency: cur);
    }
    if (local is! num || !local.isFinite || local <= 0) {
      throw const FormatException('price missing or not positive');
    }
    final double rate = local.toDouble() / usd.toDouble();
    if (rate < _minRate || rate > _maxRate) {
      throw const FormatException('exchange rate is not plausible');
    }
    final Object? date = doc['date'];
    return (
      usd: usd.toDouble(),
      local: local.toDouble(),
      at: date is String ? DateTime.tryParse(date) : null,
    );
  }

  static void _checkRange(double goldOz, double silverOz) {
    if (goldOz < _minGoldOz ||
        goldOz > _maxGoldOz ||
        silverOz < _minSilverOz ||
        silverOz > _maxSilverOz ||
        silverOz >= goldOz) {
      throw const FormatException('price outside any plausible range');
    }
  }

  void close() => _client.close();
}
