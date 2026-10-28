import 'dart:convert';

import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/features/prayer/application/prayer_providers.dart';
import 'package:ar_rayaan/features/prayer/application/prayer_repository.dart';
import 'package:ar_rayaan/features/zakat/domain/live_price_service.dart';
import 'package:ar_rayaan/features/zakat/presentation/zakat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Zakat calculator follows the person's region: it guesses the currency
/// (and says where the guess came from), fetches prices in that currency,
/// shows the rate used, and refuses to mix currencies silently.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String goldApi(double p) => json.encode(
      {'price': p, 'symbol': 'X', 'updatedAt': '2026-10-27T12:30:00Z'});
  final String usdJson = json.encode({
    'date': '2026-10-27',
    'usd': {'cad': 1.4, 'pkr': 280, 'eur': 0.9},
  });

  MockClient fake({bool gold = true, bool feed = true}) {
    return MockClient((http.Request r) async {
      if (r.url.host == 'api.gold-api.com') {
        if (!gold) return http.Response('', 503);
        return http.Response(
            r.url.path.endsWith('XAU') ? goldApi(3110.35) : goldApi(31.1035),
            200);
      }
      if (feed && r.url.pathSegments.last == 'usd.json') {
        return http.Response(usdJson, 200);
      }
      return http.Response('', 503);
    });
  }

  const PrayerLocation toronto = PrayerLocation(
    city: 'Toronto',
    country: 'Canada',
    latitude: 43.6532,
    longitude: -79.3832,
  );

  Future<void> open(
    WidgetTester tester, {
    MockClient? client,
    String device = '',
    PrayerLocation? place,
    Map<String, Object> prefs = const <String, Object>{},
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final SharedPreferences sp = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(430, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(sp),
        if (place != null) prayerLocationProvider.overrideWithValue(place),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: ZakatScreen(
          livePriceService: LivePriceService(client: client ?? fake()),
          deviceCountryCode: device,
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  String currencyBox(WidgetTester tester) =>
      tester.widget<TextField>(find.byKey(const Key('currency-label'))).controller!.text;
  String note(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('currency-note'))).data!;
  Finder status() => find.byKey(const Key('live-price-status'));

  Future<void> tapLive(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('live-prices-button')));
    await tester.tap(find.byKey(const Key('live-prices-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('currency follows the region', () {
    testWidgets('device region fills the box and the button names it',
        (tester) async {
      await open(tester, device: 'PK');
      expect(currencyBox(tester), 'PKR');
      expect(note(tester), contains('PKR'));
      expect(note(tester), contains('device region (PK)'));
      expect(find.text('Use live prices (PKR)'), findsOneWidget);
    });

    testWidgets('the saved prayer-times city wins over the device region',
        (tester) async {
      await open(tester, device: 'PK', place: toronto);
      expect(currencyBox(tester), 'CAD');
      expect(note(tester), contains('prayer-times location (Canada)'));
      expect(find.text('Use live prices (CAD)'), findsOneWidget);
    });

    testWidgets('a currency the person chose before wins over both',
        (tester) async {
      await open(tester,
          device: 'PK',
          place: toronto,
          prefs: <String, Object>{'zakat.currency.v1': 'EUR'});
      expect(currencyBox(tester), 'EUR');
      expect(note(tester), contains('Your choice'));
    });

    testWidgets('picking from the list fills the box and is remembered',
        (tester) async {
      await open(tester, device: 'PK');
      await tester.ensureVisible(find.byKey(const Key('currency-picker')));
      await tester.tap(find.byKey(const Key('currency-picker')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('EUR · Euro').last);
      await tester.pumpAndSettle();
      expect(currencyBox(tester), 'EUR');
      expect(find.text('Use live prices (EUR)'), findsOneWidget);
      final SharedPreferences sp = await SharedPreferences.getInstance();
      expect(sp.getString('zakat.currency.v1'), 'EUR');
    });
  });

  group('live prices in the local currency', () {
    testWidgets('CAD: prices, source, time, and the rate used; nisab follows',
        (tester) async {
      await open(tester, place: toronto);
      await tapLive(tester);
      final String text = tester.widget<Text>(status()).data!;
      expect(text, contains('Live prices in CAD per gram'));
      expect(text, contains('gold CAD 140.00'));
      expect(text, contains('silver CAD 1.400'));
      expect(text, contains('Source: gold-api.com'));
      expect(text, contains('as of'));
      expect(text, contains('Converted from USD at 1 USD = 1.4000 CAD'));
      expect(text, contains('27 Oct 2026'));
      expect(
          find.byWidgetPredicate(
              (w) => w is EditableText && w.controller.text == '140.00'),
          findsOneWidget);
      // 595 g of silver at 1.4 CAD a gram.
      expect(find.text('833.00'), findsWidgets);
    });

    testWidgets('USD: no conversion line', (tester) async {
      await open(tester, device: 'US');
      await tapLive(tester);
      final String text = tester.widget<Text>(status()).data!;
      expect(text, contains('Live prices in USD per gram'));
      expect(text, contains('gold USD 100.00'));
      expect(text, isNot(contains('Converted from USD')));
    });

    testWidgets('changing the currency after a fetch blocks the figure',
        (tester) async {
      await open(tester, place: toronto);
      await tapLive(tester);
      await tester.enterText(find.byKey(const Key('currency-label')), 'PKR');
      await tester.pump();
      expect(find.textContaining('are in CAD, but your currency is now PKR'),
          findsOneWidget);
      expect(find.text('—'), findsWidgets);
    });

    testWidgets('exchange rate missing: says so, names the currency, and '
        'typing prices still works', (tester) async {
      await open(tester, place: toronto, client: fake(feed: false));
      await tapLive(tester);
      final String text = tester.widget<Text>(status()).data!;
      expect(text, contains('Could not get live prices'));
      expect(text, contains('exchange rate into CAD'));
      expect(text, contains('type the gold and silver prices yourself'));
      await tester.enterText(find.byType(TextField).at(0), '5');
      expect(tester.takeException(), isNull);
    });

    testWidgets('offline: specific message', (tester) async {
      await open(tester,
          place: toronto,
          client: MockClient((_) async => throw http.ClientException('x')));
      await tapLive(tester);
      final String text = tester.widget<Text>(status()).data!;
      expect(text, contains('No internet connection'));
      expect(text, contains('type the gold and silver prices yourself'));
    });

    testWidgets('failure after a good fetch offers the saved prices in the '
        'same currency only', (tester) async {
      final String saved = json.encode({
        'CAD': {
          'gold': 120.5,
          'silver': 1.4,
          'currency': 'CAD',
          'source': 'gold-api.com',
          'asOf': '2026-10-20T08:00:00Z',
          'daily': false,
          'rate': 1.35,
          'rateAsOf': '2026-10-20T00:00:00Z',
          'rateSource': 'currency-api daily reference rate, via jsDelivr',
        },
      });
      await open(tester,
          place: toronto,
          client: fake(gold: false, feed: false),
          prefs: <String, Object>{LivePriceService.prefsKey: saved});
      await tapLive(tester);
      expect(tester.widget<Text>(status()).data!,
          contains('Could not get live prices'));
      await tester.ensureVisible(find.byKey(const Key('use-saved-prices')));
      await tester.tap(find.byKey(const Key('use-saved-prices')));
      await tester.pump();
      final String text = tester.widget<Text>(status()).data!;
      expect(text, contains('Saved prices in CAD per gram'));
      expect(text, contains('gold CAD 120.50'));
      expect(text, contains('1 USD = 1.3500 CAD'));
      expect(text, contains('not live'));

      // Another currency has no saved copy.
      await tester.enterText(find.byKey(const Key('currency-label')), 'PKR');
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(const Key('use-saved-prices')), findsNothing);
    });
  });

  group('nisab and tola are unchanged', () {
    testWidgets('85 g gold, 595 g silver and the tola figures are on screen',
        (tester) async {
      await open(tester, device: 'CA');
      expect(find.textContaining('595 g'), findsWidgets);
      expect(find.textContaining('85 g'), findsWidgets);
      expect(find.textContaining('Default is 85 g gold / 595 g silver'),
          findsOneWidget);
      expect(find.text('Use South Asian tola figures'), findsOneWidget);
      await tester.ensureVisible(find.text('Use South Asian tola figures'));
      await tester.tap(find.text('Use South Asian tola figures'));
      await tester.pump();
      expect(find.textContaining('612.36 g'), findsWidgets);
      expect(find.textContaining('87.48 g'), findsWidgets);
    });

    testWidgets('the Scholar review needed label is still on the screen',
        (tester) async {
      await open(tester, device: 'CA');
      expect(find.textContaining('Scholar review needed'), findsWidgets);
    });
  });
}
