import 'dart:async';
import 'dart:convert';

import 'package:ar_rayaan/features/zakat/domain/live_price_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The live-price service: dollar spot from gold-api.com, changed into the
/// person's currency with the daily feed, and every way that can fail. Fake
/// HTTP only; nothing here touches the network.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 3110.35 USD an ounce is exactly 100 USD a gram; silver 31.1035 is 1.
  String goldApi(double p) => json.encode(
      {'price': p, 'symbol': 'X', 'updatedAt': '2026-10-27T12:30:00Z'});
  String usdRates(Map<String, num> rates) =>
      json.encode({'date': '2026-10-27', 'usd': rates});
  String metal(String code, Map<String, num> prices) =>
      json.encode({'date': '2026-10-27', code: prices});

  final String usdJson = usdRates(<String, num>{
    'cad': 1.4,
    'pkr': 280,
    'kwd': 0.3,
    'idr': 16000,
  });
  final String xauJson = metal('xau', <String, num>{
    'usd': 3110.35,
    'cad': 4354.49,
    'pkr': 870898,
  });
  final String xagJson = metal('xag', <String, num>{
    'usd': 31.1035,
    'cad': 43.5449,
    'pkr': 8708.98,
  });

  /// Routes by host. A handler returns a response; a missing handler answers
  /// 503. [log] records every URL asked for.
  MockClient fake({
    http.Response Function(Uri)? gold,
    http.Response Function(Uri)? jsd,
    http.Response Function(Uri)? pages,
    List<Uri>? log,
  }) {
    return MockClient((http.Request r) async {
      log?.add(r.url);
      final http.Response Function(Uri)? h = switch (r.url.host) {
        'api.gold-api.com' => gold,
        'cdn.jsdelivr.net' => jsd,
        'latest.currency-api.pages.dev' => pages,
        _ => null,
      };
      return (h ?? (_) => http.Response('', 503))(r.url);
    });
  }

  http.Response okGold(Uri u) => http.Response(
      u.path.endsWith('XAU') ? goldApi(3110.35) : goldApi(31.1035), 200);
  http.Response okFeed(Uri u) {
    final String f = u.pathSegments.last;
    if (f == 'usd.json') return http.Response(usdJson, 200);
    if (f == 'xau.json') return http.Response(xauJson, 200);
    if (f == 'xag.json') return http.Response(xagJson, 200);
    return http.Response('{}', 404);
  }

  bool near(double a, double b) => (a - b).abs() < 1e-6;

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('LivePriceService, US dollars', () {
    test('success: per-gram dollars, source and timestamp, saved copy; the '
        'exchange-rate feed is not asked', () async {
      final List<Uri> log = <Uri>[];
      final s = LivePriceService(client: fake(gold: okGold, jsd: okFeed, log: log));
      final p = await s.fetch();
      expect(near(p.goldPerGram, 100), isTrue);
      expect(near(p.silverPerGram, 1), isTrue);
      expect(p.currency, 'USD');
      expect(p.source, 'gold-api.com');
      expect(p.asOf.toUtc(), DateTime.utc(2026, 10, 27, 12, 30));
      expect(p.dailyOnly, isFalse);
      expect(p.converted, isFalse);
      expect(log.where((u) => u.host != 'api.gold-api.com'), isEmpty);
      final saved = await s.lastSaved();
      expect(saved, isNotNull);
      expect(saved!.fromSavedCopy, isTrue);
      expect(near(saved.goldPerGram, 100), isTrue);
    });

    test('an older (v1) saved copy is still offered for USD', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        LivePriceService.legacyPrefsKey: json.encode({
          'gold': 120.5,
          'silver': 1.4,
          'source': 'gold-api.com',
          'asOf': '2026-10-20T08:00:00Z',
          'daily': false,
        }),
      });
      final s = LivePriceService(client: fake());
      final saved = await s.lastSaved();
      expect(saved, isNotNull);
      expect(saved!.currency, 'USD');
      expect(near(saved.goldPerGram, 120.5), isTrue);
      expect(await s.lastSaved(currency: 'CAD'), isNull);
    });
  });

  group('LivePriceService, other currencies', () {
    test('CAD: dollar spot times the day\'s rate, with the rate and its day',
        () async {
      final s = LivePriceService(client: fake(gold: okGold, jsd: okFeed));
      final p = await s.fetch(currency: 'cad');
      expect(p.currency, 'CAD');
      expect(near(p.goldPerGram, 140), isTrue);
      expect(near(p.silverPerGram, 1.4), isTrue);
      expect(p.converted, isTrue);
      expect(near(p.usdRate!, 1.4), isTrue);
      expect(p.rateAsOf!.toUtc(), DateTime.utc(2026, 10, 27));
      expect(p.source, 'gold-api.com');
      expect(p.rateSource, contains('jsDelivr'));
      final String line = p.sourceLine();
      expect(line, contains('Source: gold-api.com'));
      expect(line, contains('Converted from USD at 1 USD = 1.4000 CAD'));
      expect(line, contains('27 Oct 2026'));
      expect(p.priceLine(), 'gold CAD 140.00, silver CAD 1.400');
    });

    test('PKR and IDR: large rates convert without losing digits', () async {
      final s = LivePriceService(client: fake(gold: okGold, jsd: okFeed));
      final p = await s.fetch(currency: 'PKR');
      expect(near(p.goldPerGram, 28000), isTrue);
      expect(near(p.silverPerGram, 280), isTrue);
      final i = await s.fetch(currency: 'IDR');
      expect(near(i.goldPerGram, 1600000), isTrue);
      expect(i.sourceLine(), contains('1 USD = 16000.00 IDR'));
    });

    test('KWD: a price under 100 keeps three decimals', () async {
      final s = LivePriceService(client: fake(gold: okGold, jsd: okFeed));
      final p = await s.fetch(currency: 'KWD');
      expect(near(p.goldPerGram, 30), isTrue);
      expect(near(p.silverPerGram, 0.3), isTrue);
      expect(MetalPrices.formatPrice(0.3), '0.300');
      expect(MetalPrices.formatPrice(30), '30.000');
      expect(MetalPrices.formatPrice(28000), '28000.00');
      expect(MetalPrices.formatRate(1.4), '1.4000');
    });

    test('saved copies are kept per currency', () async {
      final s = LivePriceService(client: fake(gold: okGold, jsd: okFeed));
      await s.fetch(currency: 'CAD');
      await s.fetch(currency: 'PKR');
      final cad = await s.lastSaved(currency: 'CAD');
      final pkr = await s.lastSaved(currency: 'PKR');
      expect(near(cad!.goldPerGram, 140), isTrue);
      expect(cad.usdRate, isNotNull);
      expect(near(pkr!.goldPerGram, 28000), isTrue);
      expect(await s.lastSaved(currency: 'USD'), isNull);
      expect(await s.lastSaved(currency: 'EUR'), isNull);
    });

    test('the rate comes from the second address when the first is down',
        () async {
      final s = LivePriceService(
          client: fake(gold: okGold, pages: okFeed)); // jsDelivr answers 503
      final p = await s.fetch(currency: 'CAD');
      expect(near(p.goldPerGram, 140), isTrue);
      expect(p.rateSource, contains('Cloudflare Pages'));
    });

    test('gold-api.com down: the daily feed gives prices straight in the '
        'currency and says it is a daily rate', () async {
      final s = LivePriceService(client: fake(jsd: okFeed));
      final p = await s.fetch(currency: 'CAD');
      expect(p.dailyOnly, isTrue);
      expect(p.currency, 'CAD');
      expect(p.source, contains('daily'));
      expect(p.whenText(), '27 Oct 2026');
      expect(p.converted, isFalse);
      expect(near(p.goldPerGram, 4354.49 / 31.1035), isTrue);
      expect(p.sourceLine(), contains('updates once a day'));
    });

    test('gold-api.com down, USD: the daily feed gives dollars', () async {
      final s = LivePriceService(client: fake(jsd: okFeed));
      final p = await s.fetch();
      expect(p.dailyOnly, isTrue);
      expect(near(p.goldPerGram, 100), isTrue);
      expect(near(p.silverPerGram, 1), isTrue);
    });

    test('a currency the feed does not list: noRate, naming the currency',
        () async {
      final s = LivePriceService(client: fake(gold: okGold, jsd: okFeed));
      await expectLater(
          s.fetch(currency: 'XYZ'),
          throwsA(isA<LivePriceException>()
              .having((e) => e.kind, 'kind', LivePriceFailure.noRate)
              .having((e) => e.message, 'message', contains('XYZ'))));
      expect(await s.lastSaved(currency: 'XYZ'), isNull);
    });

    test('a currency code that is not three letters is refused', () async {
      final s = LivePriceService(client: fake(gold: okGold, jsd: okFeed));
      for (final String bad in <String>['', '12', 'DOLLAR', 'C\$']) {
        await expectLater(
            s.fetch(currency: bad),
            throwsA(isA<LivePriceException>()
                .having((e) => e.kind, 'kind', LivePriceFailure.noRate)),
            reason: bad);
      }
    });

    test('dollars arrive but the exchange rate does not: rateUnavailable, '
        'nothing saved, never a dollar price passed off as local', () async {
      final s = LivePriceService(client: fake(gold: okGold)); // feeds 503
      await expectLater(
          s.fetch(currency: 'CAD'),
          throwsA(isA<LivePriceException>()
              .having((e) => e.kind, 'kind', LivePriceFailure.rateUnavailable)
              .having((e) => e.message, 'message', contains('CAD'))
              .having((e) => e.message, 'message', contains('USD'))));
      expect(await s.lastSaved(currency: 'CAD'), isNull);
      expect(await s.lastSaved(), isNull);
    });

    test('an unreadable or absurd exchange rate is refused', () async {
      for (final String body in <String>[
        '<html>oops</html>',
        usdRates(<String, num>{'cad': 0}),
        usdRates(<String, num>{'cad': -3}),
        usdRates(<String, num>{'cad': 1e12}),
        '{"date": "2026-10-27"}',
      ]) {
        final s = LivePriceService(
            client: fake(gold: okGold, jsd: (_) => http.Response(body, 200)));
        await expectLater(
            s.fetch(currency: 'CAD'),
            throwsA(isA<LivePriceException>().having(
                (e) => e.kind, 'kind', LivePriceFailure.rateUnavailable)),
            reason: body);
      }
    });
  });

  group('LivePriceService, failure modes', () {
    test('bad JSON from every source: unreadable, nothing saved', () async {
      final s = LivePriceService(
        client: fake(
          gold: (_) => http.Response('<html>oops</html>', 200),
          jsd: (_) => http.Response('{"xau": {}}', 200),
          pages: (_) => http.Response('{"xau": {}}', 200),
        ),
      );
      await expectLater(
          s.fetch(),
          throwsA(isA<LivePriceException>().having(
              (e) => e.kind, 'kind', LivePriceFailure.unreadable)));
      expect(await s.lastSaved(), isNull);
    });

    test('implausible numbers are refused', () async {
      final s = LivePriceService(
        client: fake(
          gold: (u) => http.Response(goldApi(5), 200),
          jsd: (u) => http.Response(
              metal('xau', <String, num>{'usd': 5, 'cad': 7}), 200),
        ),
      );
      await expectLater(s.fetch(), throwsA(isA<LivePriceException>()));
    });

    test('offline: a network error from every source', () async {
      final s = LivePriceService(
        client: MockClient((_) async => throw http.ClientException('no route')),
      );
      for (final String cur in <String>['USD', 'CAD']) {
        await expectLater(
            s.fetch(currency: cur),
            throwsA(isA<LivePriceException>().having(
                (e) => e.kind, 'kind', LivePriceFailure.offline)),
            reason: cur);
      }
    });

    test('timeout: a source that never answers', () async {
      final never = Completer<http.Response>();
      final s = LivePriceService(
        client: MockClient((_) => never.future),
        timeout: const Duration(milliseconds: 40),
      );
      await expectLater(
          s.fetch(),
          throwsA(isA<LivePriceException>().having(
              (e) => e.kind, 'kind', LivePriceFailure.timeout)));
    });

    test('all sources answer with an error status: unavailable', () async {
      final s = LivePriceService(client: fake());
      await expectLater(
          s.fetch(),
          throwsA(isA<LivePriceException>().having(
              (e) => e.kind, 'kind', LivePriceFailure.unavailable)));
    });

    test('every failure has a specific human message', () {
      final msgs = LivePriceFailure.values
          .map((k) => LivePriceException(k, currency: 'CAD').message)
          .toSet();
      expect(msgs.length, LivePriceFailure.values.length);
    });
  });
}
