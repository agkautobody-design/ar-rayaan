import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/community/presentation/community_screen.dart';
import 'package:ar_rayaan/features/games/presentation/ludo_screen.dart';
import 'package:ar_rayaan/features/prayer/application/prayer_providers.dart';
import 'package:ar_rayaan/features/prayer/application/prayer_repository.dart';
import 'package:ar_rayaan/features/prayer/domain/prayer_times.dart';
import 'package:ar_rayaan/features/prayer/presentation/prayer_times_screen.dart';
import 'package:ar_rayaan/features/ramadan/presentation/ramadan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_harness.dart';

final PrayerTimes _times = PrayerTimes(
  fajr: DateTime(2026, 10, 22, 5, 41),
  sunrise: DateTime(2026, 10, 22, 7, 5),
  dhuhr: DateTime(2026, 10, 22, 12, 47),
  asr: DateTime(2026, 10, 22, 15, 52),
  maghrib: DateTime(2026, 10, 22, 18, 21),
  isha: DateTime(2026, 10, 22, 19, 45),
  locationLabel: 'Toronto, Canada',
  methodLabel: 'Muslim World League',
);

/// Round 4, area D: goal landing and findability.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GPS location label', () {
    test('a GPS fix is named as such, with rounded coordinates', () {
      const PrayerLocation gps = PrayerLocation(
        city: PrayerLocation.gpsCity,
        country: '',
        latitude: 43.6532,
        longitude: -79.3832,
      );
      expect(gps.isGps, isTrue);
      expect(gps.label, 'Your location (GPS) · 43.65°N 79.38°W');
      expect(gps.label, isNot(contains('My Location')));
      expect(gps.placeName, 'your location');
    });

    test('a chosen city keeps its name', () {
      const PrayerLocation city = PrayerLocation(
        city: 'Karachi',
        country: 'Pakistan',
        latitude: 24.86,
        longitude: 67.0,
      );
      expect(city.isGps, isFalse);
      expect(city.label, 'Karachi, Pakistan');
      expect(city.placeName, 'Karachi');
    });

    test('southern and western hemispheres are labelled', () {
      const PrayerLocation s = PrayerLocation(
        city: PrayerLocation.gpsCity,
        country: '',
        latitude: -33.87,
        longitude: 151.21,
      );
      expect(s.coordinates, '33.87°S 151.21°E');
    });
  });

  testWidgets('Community: working tiles come before "Coming soon" ones', (
    WidgetTester tester,
  ) async {
    String? opened;
    final GoRouter router = GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (BuildContext c, GoRouterState s) =>
              const CommunityScreen(),
        ),
        GoRoute(
          path: '/masajid',
          builder: (BuildContext c, GoRouterState s) {
            opened = s.uri.toString();
            return const Scaffold(body: Text('masajid page'));
          },
        ),
      ],
    );
    AppHarness.useSurface(tester);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump(const Duration(milliseconds: 300));

    final Finder masjid = find.text('Find a masjid near you');
    expect(masjid, findsOneWidget);
    expect(find.text('Jumu’ah and prayer times'), findsOneWidget);
    final double workingY = tester.getTopLeft(masjid).dy;
    final double soonY = tester.getTopLeft(find.text('Events')).dy;
    expect(workingY, lessThan(soonY));
    expect(
      tester.getTopLeft(find.text('Jumu’ah and prayer times')).dy,
      lessThan(soonY),
    );

    await tester.tap(masjid);
    await tester.pump(const Duration(milliseconds: 400));
    expect(opened, '/masajid');
  });

  testWidgets('Sakina offers the du’a for worry and peace', (
    WidgetTester tester,
  ) async {
    await AppHarness.boot(tester);
    await AppHarness.go(tester, find.byType(Scaffold).first, '/sakina');
    final Finder chip = find.byKey(const Key('sakina-duas'));
    expect(chip, findsOneWidget);
    expect(find.text('Duas for worry & peace'), findsOneWidget);
    await tester.tap(chip);
    await AppHarness.settle(tester);
    expect(
      AppHarness.location(tester, find.byType(Scaffold).first),
      '/stories/read',
    );
  });

  testWidgets('Prayer Times: an unset Jumu\u2019ah row links to the masjid finder',
      (WidgetTester tester) async {
    String? opened;
    final GoRouter router = GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (BuildContext c, GoRouterState s) =>
              const PrayerTimesScreen(),
        ),
        GoRoute(
          path: '/masajid',
          builder: (BuildContext c, GoRouterState s) {
            opened = s.uri.toString();
            return const Scaffold(body: Text('masajid page'));
          },
        ),
      ],
    );
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    AppHarness.useSurface(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          prayerLocationProvider.overrideWithValue(
            const PrayerLocation(
              city: 'Toronto',
              country: 'Canada',
              latitude: 43.65,
              longitude: -79.38,
            ),
          ),
          prayerTimesProvider.overrideWith((ref) async => _times),
          nowTickerProvider.overrideWith(
            (ref) => Stream<DateTime>.value(DateTime(2026, 10, 22, 10)),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final Finder link = find.byKey(const Key('jumuah-find-masjid'));
    expect(link, findsOneWidget);
    expect(find.text('Find a masjid for the Friday time'), findsOneWidget);
    await tester.tap(link);
    await tester.pump(const Duration(milliseconds: 400));
    expect(opened, '/masajid');
  });

  testWidgets('Ramadan Mode names the date it is counting to', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    AppHarness.useSurface(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(home: RamadanScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    if (find.text('Ramadan Mubarak').evaluate().isEmpty) {
      final Finder date = find.byKey(const Key('ramadan-expected-date'));
      expect(date, findsOneWidget);
      expect(tester.widget<Text>(date).data, contains('Expected around'));
      expect(find.textContaining('crescent-willing'), findsNothing);
    }
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('Ludo tells a new player that a 6 brings a token out', (
    WidgetTester tester,
  ) async {
    AppHarness.useSurface(tester);
    await tester.pumpWidget(const MaterialApp(home: LudoScreen()));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('ludo-six-hint')), findsNothing);
    await tester.tap(find.text('Play Hadi'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('ludo-six-hint')), findsOneWidget);
    expect(find.textContaining('need a 6'), findsOneWidget);
  });
}
