import 'dart:async';
import 'dart:convert';

import 'package:ar_rayaan/features/zakat/domain/live_price_service.dart';
import 'package:ar_rayaan/features/zakat/presentation/zakat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

/// The Zakat "Use live prices (USD)" button: every outcome (success, timeout,
/// bad JSON, offline, one provider down) is tested with a fake HTTP client.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String goldApi(double p) =>
      json.encode({'price': p, 'symbol': 'X', 'updatedAt': '2026-10-27T12:30:00Z'});
  String daily(String code, double p) =>
      json.encode({'date': '2026-10-27', code: {'usd': p}});

  // Routes the two sources. A handler returns a body, or null to fail with
  // the given status/exception.
  MockClient fake({
    http.Response Function(Uri)? primary,
    http.Response Function(Uri)? fallback,
  }) {
    return MockClient((http.Request r) async {
      if (r.url.host == 'api.gold-api.com') {
        return (primary ?? (_) => http.Response('', 503))(r.url);
      }
      return (fallback ?? (_) => http.Response('', 503))(r.url);
    });
  }

  http.Response okGoldApi(Uri u) => http.Response(
      u.path.endsWith('XAU') ? goldApi(3110.35) : goldApi(31.1035), 200);

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('LivePriceService', () {
    test('success: per-gram dollars, source and timestamp, saved copy',
        () async {
      final s = LivePriceService(client: fake(primary: okGoldApi));
      final p = await s.fetch();
      expect((p.goldPerGram - 100).abs() < 1e-9, isTrue);
      expect((p.silverPerGram - 1).abs() < 1e-9, isTrue);
      expect(p.source, 'gold-api.com');
      expect(p.asOf.toUtc(), DateTime.utc(2026, 10, 27, 12, 30));
      expect(p.dailyOnly, isFalse);
      final saved = await s.lastSaved();
      expect(saved, isNotNull);
      expect(saved!.fromSavedCopy, isTrue);
      expect((saved.goldPerGram - 100).abs() < 1e-9, isTrue);
    });

    test('primary down: falls back to the daily feed and says so', () async {
      final s = LivePriceService(
        client: fake(
          fallback: (u) => http.Response(
              u.path.endsWith('xau.json')
                  ? daily('xau', 3110.35)
                  : daily('xag', 31.1035),
              200),
        ),
      );
      final p = await s.fetch();
      expect(p.dailyOnly, isTrue);
      expect(p.source, contains('daily'));
      expect(p.whenText(), '27 Oct 2026');
      expect((p.goldPerGram - 100).abs() < 1e-9, isTrue);
    });

    test('bad JSON from every source: unreadable, nothing saved', () async {
      final s = LivePriceService(
        client: fake(
          primary: (_) => http.Response('<html>oops</html>', 200),
          fallback: (_) => http.Response('{"xau": {}}', 200),
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
          primary: (u) => http.Response(goldApi(5), 200),
          fallback: (u) => http.Response(daily('xau', 5), 200),
        ),
      );
      await expectLater(s.fetch(), throwsA(isA<LivePriceException>()));
    });

    test('offline: a network error from every source', () async {
      final s = LivePriceService(
        client: MockClient((_) async => throw http.ClientException('no route')),
      );
      await expectLater(
          s.fetch(),
          throwsA(isA<LivePriceException>().having(
              (e) => e.kind, 'kind', LivePriceFailure.offline)));
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
          .map((k) => LivePriceException(k).message)
          .toSet();
      expect(msgs.length, LivePriceFailure.values.length);
    });
  });

  group('Zakat screen button', () {
    Future<void> open(WidgetTester tester, LivePriceService svc) async {
      tester.view.physicalSize = const Size(430, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester
          .pumpWidget(await wrapWithProviders(ZakatScreen(livePriceService: svc)));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('currency-label')), 'USD');
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('live-prices-button')));
    }

    Finder status() => find.byKey(const Key('live-price-status'));

    testWidgets('success fills the boxes and shows source + time',
        (tester) async {
      await open(tester, LivePriceService(client: fake(primary: okGoldApi)));
      await tester.tap(find.byKey(const Key('live-prices-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final text = tester.widget<Text>(status()).data!;
      expect(text, contains('gold-api.com'));
      expect(text, contains('2026'));
      expect(text, contains(r'$100.00'));
      expect(
          find.byWidgetPredicate(
              (w) => w is EditableText && w.controller.text == '100.00'),
          findsOneWidget);
    });

    testWidgets('offline: specific message, manual entry still possible',
        (tester) async {
      await open(
          tester,
          LivePriceService(
              client: MockClient((_) async => throw http.ClientException('x'))));
      await tester.tap(find.byKey(const Key('live-prices-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final text = tester.widget<Text>(status()).data!;
      expect(text, contains('No internet connection'));
      expect(text, contains('type the gold and silver prices yourself'));
      await tester.enterText(find.byType(TextField).at(0), '5');
      expect(tester.takeException(), isNull);
    });

    testWidgets('failure after a good fetch offers the saved prices',
        (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        LivePriceService.prefsKey: json.encode({
          'gold': 120.5,
          'silver': 1.4,
          'source': 'gold-api.com',
          'asOf': '2026-10-20T08:00:00Z',
          'daily': false,
        }),
      });
      await open(
          tester,
          LivePriceService(
              client: MockClient((_) async => http.Response('nope', 500))));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byKey(const Key('live-prices-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.widget<Text>(status()).data!,
          contains('Could not get live prices'));
      await tester.ensureVisible(find.byKey(const Key('use-saved-prices')));
      await tester.tap(find.byKey(const Key('use-saved-prices')));
      await tester.pump();
      final text = tester.widget<Text>(status()).data!;
      expect(text, contains(r'$120.50'));
      expect(text, contains('not live'));
    });
  });
}
