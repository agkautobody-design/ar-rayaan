import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/prayer/application/location_providers.dart';
import 'package:ar_rayaan/features/prayer/application/prayer_providers.dart';
import 'package:ar_rayaan/features/prayer/application/prayer_repository.dart';
import 'package:ar_rayaan/features/prayer/data/city_directory.dart';
import 'package:ar_rayaan/features/qibla/presentation/qibla_screen.dart';
import 'package:ar_rayaan/features/sakina/application/sakina_providers.dart';
import 'package:ar_rayaan/features/sakina/presentation/widgets/need_help_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_harness.dart';

/// Crawl audit F-01: no place is ever assumed. Until the person sets a
/// location, Home, Prayer Times and Qibla ask for one instead of showing
/// times or a bearing for a stand-in city.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  PrayerLocation karachi() => CityDirectory.cities.firstWhere(
    (PrayerLocation c) => c.city == 'Karachi',
  );

  group('the stand-in location', () {
    test('is flagged, unset and labelled honestly', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c.dispose);
      final PrayerLocation loc = c.read(prayerLocationProvider);
      expect(loc.isPlaceholder, isTrue);
      expect(loc.isSet, isFalse);
      expect(loc.label, 'No location set');
      expect(loc.label, isNot(contains('Toronto')));
    });

    test('a saved or chosen location is set', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'ar.location.lat': 24.86,
        'ar.location.lng': 67.0,
        'ar.location.city': 'Karachi',
        'ar.location.country': 'Pakistan',
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c.dispose);
      expect(c.read(prayerLocationProvider).isSet, isTrue);

      final ProviderContainer fresh = ProviderContainer(
        overrides: <Override>[sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(fresh.dispose);
      await fresh
          .read(prayerLocationControllerProvider.notifier)
          .setLocation(karachi());
      expect(fresh.read(prayerLocationProvider).isSet, isTrue);
      expect(fresh.read(prayerLocationProvider).label, 'Karachi, Pakistan');
    });

    test('a device fix is a set location', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c.dispose);
      final GpsStatus status = await c
          .read(prayerLocationControllerProvider.notifier)
          .useGps(fetch: () async => (lat: 48.85, lng: 2.35));
      expect(status, GpsStatus.success);
      expect(c.read(prayerLocationProvider).isSet, isTrue);
    });
  });

  testWidgets('Home asks for a location instead of showing times', (
    tester,
  ) async {
    await AppHarness.boot(tester);
    expect(find.text('Set your location'), findsOneWidget);
    // No prayer name with a clock time anywhere on the tile.
    expect(find.textContaining(RegExp(r'^(Fajr|Dhuhr|Asr|Maghrib|Isha) \u00b7 ')),
        findsNothing);
  });

  testWidgets('Home shows the next prayer once a location is saved', (
    tester,
  ) async {
    await AppHarness.boot(
      tester,
      prefsValues: <String, Object>{
        'ar.location.lat': 24.86,
        'ar.location.lng': 67.0,
        'ar.location.city': 'Karachi',
        'ar.location.country': 'Pakistan',
      },
    );
    expect(find.text('Set your location'), findsNothing);
    expect(
      find.textContaining(RegExp(r'^(Fajr|Dhuhr|Asr|Maghrib|Isha) \u00b7 ')),
      findsOneWidget,
    );
  });

  testWidgets('Prayer Times asks the person to set a location', (
    tester,
  ) async {
    await AppHarness.boot(tester);
    await AppHarness.go(tester, find.text('Faith'), '/prayer');
    expect(find.text('SET YOUR LOCATION'), findsOneWidget);
    expect(find.text('No location set'), findsOneWidget);
    expect(find.text('My location'), findsOneWidget);
    expect(find.text('City'), findsOneWidget);
    // No schedule rows, no stand-in city.
    expect(find.text('Fajr'), findsNothing);
    expect(find.textContaining('Toronto'), findsNothing);
  });

  testWidgets('Qibla asks for a location and shows no bearing', (
    tester,
  ) async {
    await AppHarness.boot(tester);
    await AppHarness.go(tester, find.text('Faith'), '/qibla');
    expect(find.byType(QiblaScreen), findsOneWidget);
    expect(find.text('SET YOUR LOCATION'), findsOneWidget);
    expect(find.text('Use my location'), findsOneWidget);
    expect(find.text('Choose my city'), findsOneWidget);
    expect(find.textContaining('Toronto'), findsNothing);
    expect(find.textContaining('clockwise from true North'), findsNothing);
  });

  testWidgets('Qibla shows the bearing for a chosen city', (tester) async {
    await AppHarness.boot(
      tester,
      prefsValues: <String, Object>{
        'ar.location.lat': 24.86,
        'ar.location.lng': 67.0,
        'ar.location.city': 'Karachi',
        'ar.location.country': 'Pakistan',
      },
    );
    await AppHarness.go(tester, find.text('Faith'), '/qibla');
    expect(find.text('SET YOUR LOCATION'), findsNothing);
    expect(find.textContaining('clockwise from true North'), findsWidgets);
    expect(find.textContaining('Karachi'), findsWidgets);
  });

  Future<void> openHelpSheet(WidgetTester tester, String? country) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    AppHarness.useSurface(tester, height: 1600);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          deviceCountryProvider.overrideWithValue(country),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (BuildContext context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showNeedHelpSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('the help sheet says its order comes from the device language', (
    tester,
  ) async {
    await openHelpSheet(tester, 'US');
    expect(find.textContaining('Lines for the region US come first'),
        findsOneWidget);
    expect(find.textContaining('not your location'), findsOneWidget);
  });

  testWidgets('the help sheet is honest when the country is unknown', (
    tester,
  ) async {
    await openHelpSheet(tester, null);
    expect(find.textContaining('could not tell which country'),
        findsOneWidget);
    expect(find.textContaining('come first'), findsNothing);
  });
}
