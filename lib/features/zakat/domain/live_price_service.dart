import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'live_prices.dart';

/// Gold and silver prices in US dollars per gram, with where and when they
/// came from, so the screen can always say "source + time".
class MetalPrices {
  const MetalPrices({
    required this.goldPerGram,
    required this.silverPerGram,
    required this.source,
    required this.asOf,
    this.dailyOnly = false,
    this.fromSavedCopy = false,
  });

  final double goldPerGram;
  final double silverPerGram;

  /// Plain name of the provider, e.g. `gold-api.com`.
  final String source;

  /// When the provider says the quote was made (or, for a daily feed, the day
  /// of the rate, at midnight UTC).
  final DateTime asOf;

  /// True for a once-a-day reference rate (no time of day).
  final bool dailyOnly;

  /// True when read back from this device rather than fetched just now.
  final bool fromSavedCopy;

  MetalPrices asSavedCopy() => MetalPrices(
        goldPerGram: goldPerGram,
        silverPerGram: silverPerGram,
        source: source,
        asOf: asOf,
        dailyOnly: dailyOnly,
        fromSavedCopy: true,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'gold': goldPerGram,
        'silver': silverPerGram,
        'source': source,
        'asOf': asOf.toUtc().toIso8601String(),
        'daily': dailyOnly,
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
    return MetalPrices(
      goldPerGram: g.toDouble(),
      silverPerGram: s.toDouble(),
      source: src,
      asOf: when,
      dailyOnly: doc['daily'] == true,
      fromSavedCopy: true,
    );
  }

  /// "27 Oct 2026, 14:05" (device time) or "27 Oct 2026" for a daily rate.
  String whenText() {
    const List<String> m = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final DateTime d = dailyOnly ? asOf.toUtc() : asOf.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    final String day = '${d.day} ${m[d.month - 1]} ${d.year}';
    return dailyOnly ? day : '$day, ${two(d.hour)}:${two(d.minute)}';
  }
}

enum LivePriceFailure { offline, timeout, unavailable, unreadable }

/// A price fetch that failed, in words a person can act on.
class LivePriceException implements Exception {
  const LivePriceException(this.kind);
  final LivePriceFailure kind;

  String get message {
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
    }
  }

  @override
  String toString() => 'LivePriceException(${kind.name})';
}

/// Fetches gold and silver spot prices with no key and no secret.
///
/// Sources, tried in order; the first that answers with sane numbers wins:
///  1. gold-api.com `GET /price/XAU` and `/price/XAG` — keyless spot quote
///     with a timestamp. (CORS and terms could not be checked from the build
///     environment; if it ever stops answering, step 2 takes over.)
///  2. The open-licence currency-api dataset on jsDelivr
///     (`@fawazahmed0/currency-api`, CC0), a once-a-day reference rate, which
///     is also readable from the web build.
/// The last good result is kept on this device so a failure can still show
/// "last saved ... from <date>".
class LivePriceService {
  LivePriceService({
    http.Client? client,
    this.timeout = const Duration(seconds: 8),
    this.goldApiBase = 'https://api.gold-api.com',
    this.dailyFeedBase =
        'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/'
            'currencies',
  }) : _client = client ?? http.Client();

  static const String prefsKey = 'zakat.live_prices.v1';

  final http.Client _client;
  final Duration timeout;
  final String goldApiBase;
  final String dailyFeedBase;

  // Wide, on purpose: only to refuse nonsense (0, a typo'd unit, a swapped
  // pair), never to second-guess the market.
  static const double _minGoldOz = 200;
  static const double _maxGoldOz = 100000;
  static const double _minSilverOz = 2;
  static const double _maxSilverOz = 5000;

  Future<MetalPrices> fetch() async {
    final List<LivePriceFailure> failures = <LivePriceFailure>[];
    for (final Future<MetalPrices> Function() source in <Future<MetalPrices>
        Function()>[_fromGoldApi, _fromDailyFeed]) {
      try {
        final MetalPrices p = await source();
        await _save(p);
        return p;
      } on LivePriceException catch (e) {
        failures.add(e.kind);
      } on TimeoutException {
        failures.add(LivePriceFailure.timeout);
      } on FormatException {
        failures.add(LivePriceFailure.unreadable);
      } catch (_) {
        // SocketException, ClientException, TLS errors: no usable network.
        failures.add(LivePriceFailure.offline);
      }
    }
    if (failures.every((f) => f == LivePriceFailure.offline)) {
      throw const LivePriceException(LivePriceFailure.offline);
    }
    if (failures.every((f) =>
        f == LivePriceFailure.offline || f == LivePriceFailure.timeout)) {
      throw const LivePriceException(LivePriceFailure.timeout);
    }
    if (failures.contains(LivePriceFailure.unreadable) &&
        !failures.contains(LivePriceFailure.unavailable)) {
      throw const LivePriceException(LivePriceFailure.unreadable);
    }
    throw const LivePriceException(LivePriceFailure.unavailable);
  }

  /// The last good prices kept on this device, or null.
  Future<MetalPrices?> lastSaved() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(prefsKey);
      if (raw == null) return null;
      return MetalPrices.tryFromJson(json.decode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> _save(MetalPrices p) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, json.encode(p.toJson()));
    } catch (_) {
      // Saving is a convenience; a failure must not hide fresh prices.
    }
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

  Future<MetalPrices> _fromGoldApi() async {
    final List<http.Response> r = await Future.wait(<Future<http.Response>>[
      _get('$goldApiBase/price/XAU'),
      _get('$goldApiBase/price/XAG'),
    ]);
    final ({double ounce, DateTime? at}) gold =
        _readGoldApi(utf8.decode(r[0].bodyBytes));
    final ({double ounce, DateTime? at}) silver =
        _readGoldApi(utf8.decode(r[1].bodyBytes));
    _checkRange(gold.ounce, silver.ounce);
    return MetalPrices(
      goldPerGram: gold.ounce / LivePrices.gramsPerTroyOunce,
      silverPerGram: silver.ounce / LivePrices.gramsPerTroyOunce,
      source: 'gold-api.com',
      asOf: gold.at ?? DateTime.now().toUtc(),
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

  Future<MetalPrices> _fromDailyFeed() async {
    final List<http.Response> r = await Future.wait(<Future<http.Response>>[
      _get('$dailyFeedBase/xau.json'),
      _get('$dailyFeedBase/xag.json'),
    ]);
    final ({double ounce, DateTime? at}) gold =
        _readDaily(utf8.decode(r[0].bodyBytes), 'xau');
    final ({double ounce, DateTime? at}) silver =
        _readDaily(utf8.decode(r[1].bodyBytes), 'xag');
    _checkRange(gold.ounce, silver.ounce);
    return MetalPrices(
      goldPerGram: gold.ounce / LivePrices.gramsPerTroyOunce,
      silverPerGram: silver.ounce / LivePrices.gramsPerTroyOunce,
      source: 'currency-api (daily reference rate, via jsDelivr)',
      asOf: gold.at ?? DateTime.now().toUtc(),
      dailyOnly: true,
    );
  }

  static ({double ounce, DateTime? at}) _readDaily(String body, String code) {
    final Object? doc = json.decode(body);
    if (doc is! Map<String, dynamic>) {
      throw const FormatException('not an object');
    }
    final Object? rates = doc[code];
    final Object? usd = rates is Map<String, dynamic> ? rates['usd'] : null;
    if (usd is! num || !usd.isFinite || usd <= 0) {
      throw const FormatException('usd rate missing or not positive');
    }
    final Object? date = doc['date'];
    return (
      ounce: usd.toDouble(),
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
