import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/prayer/application/location_providers.dart';
import 'package:ar_rayaan/features/prayer/application/prayer_repository.dart';
import 'package:ar_rayaan/features/prayer/data/city_directory.dart';
import 'package:ar_rayaan/features/prayer/presentation/prayer_times_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A city that is not in the directory can be named, saved with its country,
/// and kept across restarts and fresh GPS fixes.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<({ProviderContainer c, SharedPreferences prefs})> make(
      [Map<String, Object> seed = const <String, Object>{}]) async {
    SharedPreferences.setMockInitialValues(seed);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(c.dispose);
    return (c: c, prefs: prefs);
  }

  Future<({double lat, double lng})> milton() async =>
      (lat: 43.52, lng: -79.86);

  test('naming a place saves city and country and keeps the device zone',
      () async {
    final t = await make();
    final PrayerLocationController ctl =
        t.c.read(prayerLocationControllerProvider.notifier);
    final GpsStatus got =
        await ctl.saveNamedPlace('  Milton ', 'Canada', fetch: milton);
    expect(got == GpsStatus.success, isTrue);
    final PrayerLocation loc = t.c.read(prayerLocationControllerProvider);
    expect(loc.city == 'Milton', isTrue);
    expect(loc.country == 'Canada', isTrue);
    expect(loc.label == 'Milton, Canada', isTrue);
    expect(loc.isGps, isFalse);
    expect(loc.zone == null, isTrue, reason: 'device zone, not a guess');
    expect(t.prefs.getString('ar.location.city') == 'Milton', isTrue);
    expect(t.prefs.getString('ar.location.country') == 'Canada', isTrue);
  });

  test('the saved name survives a restart', () async {
    final t = await make();
    await t.c
        .read(prayerLocationControllerProvider.notifier)
        .saveNamedPlace('Milton', 'Canada', fetch: milton);
    final ProviderContainer again = ProviderContainer(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(t.prefs),
      ],
    );
    addTearDown(again.dispose);
    final PrayerLocation loc = again.read(prayerLocationControllerProvider);
    expect(loc.label == 'Milton, Canada', isTrue);
    expect(loc.isSet, isTrue);
  });

  test('a fresh fix in the same place keeps the name', () async {
    final t = await make();
    final PrayerLocationController ctl =
        t.c.read(prayerLocationControllerProvider.notifier);
    await ctl.saveNamedPlace('Milton', 'Canada', fetch: milton);
    await ctl.useGps(fetch: () async => (lat: 43.53, lng: -79.85));
    expect(t.c.read(prayerLocationControllerProvider).label == 'Milton, Canada',
        isTrue);
  });

  test('a fix far away drops the name', () async {
    final t = await make();
    final PrayerLocationController ctl =
        t.c.read(prayerLocationControllerProvider.notifier);
    await ctl.saveNamedPlace('Milton', 'Canada', fetch: milton);
    await ctl.useGps(fetch: () async => (lat: 21.42, lng: 39.82));
    expect(t.c.read(prayerLocationControllerProvider).isGps, isTrue);
  });

  test('a blank name saves nothing', () async {
    final t = await make();
    final PrayerLocationController ctl =
        t.c.read(prayerLocationControllerProvider.notifier);
    final GpsStatus got = await ctl.saveNamedPlace('   ', 'Canada',
        fetch: milton);
    expect(got == GpsStatus.success, isFalse);
    expect(t.c.read(prayerLocationControllerProvider).isSet, isFalse);
  });

  test('without a location fix nothing is saved and the old place stays',
      () async {
    final t = await make();
    final PrayerLocationController ctl =
        t.c.read(prayerLocationControllerProvider.notifier);
    final PrayerLocation karachi = CityDirectory.cities
        .firstWhere((PrayerLocation c) => c.city == 'Karachi');
    await ctl.setLocation(karachi);
    final GpsStatus got = await ctl.saveNamedPlace('Milton', 'Canada',
        fetch: () async => throw const GpsException(GpsStatus.denied));
    expect(got == GpsStatus.denied, isTrue);
    expect(t.c.read(prayerLocationControllerProvider).city == 'Karachi',
        isTrue);
  });

  test('names are cleaned and capped', () {
    expect(PrayerLocationController.cleanName('a\u0000b\n  c') == 'a b c',
        isTrue);
    expect(
        PrayerLocationController.cleanName('x' * 200).length ==
            PrayerLocationController.maxNameLength,
        isTrue);
  });

  testWidgets('the city sheet offers a way to name a place not listed',
      (WidgetTester tester) async {
    Object? result;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () async {
              result = await showModalBottomSheet<Object>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const CitySheet(),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('city-search')), 'Milton');
    await tester.pump();
    expect(find.textContaining('No city in the list matches'), findsOneWidget);
    await tester.tap(find.byKey(const Key('city-not-listed')));
    await tester.pump();
    // The typed search is carried into the name field.
    expect(
        (tester.widget(find.byKey(const Key('named-city'))) as TextField)
                .controller!
                .text ==
            'Milton',
        isTrue);
    await tester.enterText(find.byKey(const Key('named-country')), 'Canada');
    await tester.tap(find.byKey(const Key('named-save')));
    await tester.pumpAndSettle();
    expect(result is NamedPlace, isTrue);
    expect((result! as NamedPlace).city == 'Milton', isTrue);
    expect((result! as NamedPlace).country == 'Canada', isTrue);
  });
}
