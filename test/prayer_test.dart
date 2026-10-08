import 'package:ar_rayaan/app/app.dart';
import 'package:ar_rayaan/app/core/env_config.dart';
import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/prayer/application/location_providers.dart';
import 'package:ar_rayaan/features/prayer/application/prayer_alerts.dart';
import 'package:ar_rayaan/features/prayer/application/prayer_providers.dart';
import 'package:ar_rayaan/features/prayer/application/prayer_repository.dart';
import 'package:ar_rayaan/features/prayer/data/adhan_calc_prayer_repository.dart';
import 'package:ar_rayaan/features/prayer/data/aladhan_prayer_repository.dart';
import 'package:ar_rayaan/features/prayer/data/cached_prayer_repository.dart';
import 'package:ar_rayaan/features/prayer/data/city_directory.dart';
import 'package:ar_rayaan/features/prayer/data/fake_prayer_repository.dart';
import 'package:ar_rayaan/features/prayer/domain/prayer_times.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

PrayerTimes sample() {
  DateTime at(int h, [int m = 0]) {
    final DateTime n = DateTime.now();
    return DateTime(n.year, n.month, n.day, h, m);
  }

  return PrayerTimes(
    fajr: at(5, 12),
    sunrise: at(6, 41),
    dhuhr: at(12, 47),
    asr: at(16, 5),
    maghrib: at(19, 28),
    isha: at(21, 2),
    locationLabel: 'Toronto, Canada',
    methodLabel: 'Muslim World League',
  );
}

class _ThrowingPrayerRepository implements PrayerRepository {
  @override
  Future<PrayerTimes> timingsForToday(PrayerLocation location) {
    throw const PrayerTimesException('offline');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('next-prayer logic', () {
    test('midday points to the next upcoming prayer', () {
      final PrayerTimes t = sample();
      final DateTime now = DateTime(
        t.dhuhr.year,
        t.dhuhr.month,
        t.dhuhr.day,
        13,
        0,
      );
      expect(t.nextPrayer(now).$1, 'Asr');
      expect(t.nextPrayer(now).$2, t.asr);
    });

    test('before Fajr points to Fajr; after Isha wraps to tomorrow', () {
      final PrayerTimes t = sample();
      final DateTime early = DateTime(
        t.fajr.year,
        t.fajr.month,
        t.fajr.day,
        3,
        0,
      );
      expect(t.nextPrayer(early).$1, 'Fajr');
      expect(t.nextPrayer(early).$2, t.fajr);

      final DateTime late = DateTime(
        t.isha.year,
        t.isha.month,
        t.isha.day,
        23,
        30,
      );
      final (String name, DateTime time) = t.nextPrayer(late);
      expect(name, 'Fajr');
      expect(time.day, t.fajr.add(const Duration(days: 1)).day);
    });
  });

  group('Aladhan parsing', () {
    test('parses timings payload, strips timezone suffixes', () async {
      final http_testing.MockClient client = http_testing.MockClient((
        request,
      ) async {
        expect(request.url.host, 'api.aladhan.com');
        expect(request.url.queryParameters['city'], 'Toronto');
        return http.Response(
          '{"code":200,"data":{"timings":{'
          '"Fajr":"05:12 (EDT)","Sunrise":"06:41 (EDT)",'
          '"Dhuhr":"12:47 (EDT)","Asr":"16:05 (EDT)",'
          '"Maghrib":"19:28 (EDT)","Isha":"21:02 (EDT)"}}}',
          200,
        );
      });
      final AladhanPrayerRepository repo = AladhanPrayerRepository(
        client: client,
      );
      final PrayerTimes t = await repo.timingsForToday(
        const PrayerLocation(
          city: 'Toronto',
          country: 'Canada',
          latitude: 43.6532,
          longitude: -79.3832,
        ),
      );
      expect(t.fajr.hour, 5);
      expect(t.fajr.minute, 12);
      expect(t.isha.hour, 21);
      expect(t.methodLabel, 'Muslim World League');
      expect(t.locationLabel, 'Toronto, Canada');
    });

    test('non-200 response raises PrayerTimesException', () async {
      final http_testing.MockClient client = http_testing.MockClient(
        (request) async => http.Response('err', 503),
      );
      final AladhanPrayerRepository repo = AladhanPrayerRepository(
        client: client,
      );
      expect(
        () => repo.timingsForToday(
          const PrayerLocation(
            city: 'Toronto',
            country: 'Canada',
            latitude: 43.6532,
            longitude: -79.3832,
          ),
        ),
        throwsA(isA<PrayerTimesException>()),
      );
    });
  });

  group('offline cache', () {
    const PrayerLocation loc = PrayerLocation(
      city: 'Toronto',
      country: 'Canada',
      latitude: 43.6532,
      longitude: -79.3832,
    );

    test('success is cached; failure falls back to today\'s cache', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Online: inner succeeds → schedule returned and cached.
      final CachedPrayerRepository online = CachedPrayerRepository(
        FakePrayerRepository(),
        prefs,
      );
      final PrayerTimes live = await online.timingsForToday(loc);
      expect(live.dhuhr.hour, 12);

      // Offline: inner throws → same-day cache served instead of an error.
      final CachedPrayerRepository offline = CachedPrayerRepository(
        _ThrowingPrayerRepository(),
        prefs,
      );
      final PrayerTimes cached = await offline.timingsForToday(loc);
      expect(cached.dhuhr.hour, 12);
      expect(cached.locationLabel, 'Toronto, Canada');
    });

    test('failure with no cache rethrows', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final CachedPrayerRepository repo = CachedPrayerRepository(
        _ThrowingPrayerRepository(),
        prefs,
      );
      expect(() => repo.timingsForToday(loc), throwsA(anything));
    });
  });

  testWidgets('prayer times screen shows schedule with NEXT highlight', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prayerRepositoryProvider.overrideWithValue(FakePrayerRepository()),
        ],
        child: ArRayaanApp(env: EnvConfig.fromDefines()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('welcome-continue')));
    await tester.pumpAndSettle();

    // Home tile navigates to the prayer times screen.
    await tester.tap(find.text('Prayer Times'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('NEXT PRAYER'), findsOneWidget);
    expect(find.text('Fajr'), findsWidgets);
    expect(find.textContaining('5:12'), findsWidgets);
    expect(find.text('Dhuhr'), findsWidgets); // hero + row
    expect(find.textContaining('12:47'), findsWidgets); // hero + row
    expect(find.text('Isha'), findsWidgets); // row (+ hero if next)
    expect(find.text('NEXT'), findsOneWidget);
    // The Tahajjud card pushed the location footer below the fold.
    await tester.dragUntilVisible(
      find.text('Toronto, Canada · Muslim World League'),
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    expect(find.text('Toronto, Canada · Muslim World League'), findsOneWidget);
  });

  group('offline calculation (O-11)', () {
    test('computes a sane ordered day for Makkah without network', () async {
      final AdhanCalcPrayerRepository repo = AdhanCalcPrayerRepository();
      const PrayerLocation makkah = PrayerLocation(
        city: 'Makkah',
        country: 'Saudi Arabia',
        latitude: 21.4225,
        longitude: 39.8262,
      );
      final PrayerTimes t = await repo.timingsForToday(makkah);
      expect(t.fajr.isBefore(t.sunrise), isTrue);
      expect(t.sunrise.isBefore(t.dhuhr), isTrue);
      expect(t.dhuhr.isBefore(t.asr), isTrue);
      expect(t.asr.isBefore(t.maghrib), isTrue);
      expect(t.maghrib.isBefore(t.isha), isTrue);
      // Astronomical sanity: the Fajr→Sunrise and Maghrib→Isha windows at
      // Makkah are always within twilight-scale durations.
      expect(
        t.sunrise.difference(t.fajr).inMinutes,
        inInclusiveRange(50, 140),
      );
      expect(
        t.isha.difference(t.maghrib).inMinutes,
        inInclusiveRange(50, 140),
      );
      expect(t.methodLabel, contains('calculated on-device'));
    });

    test('city directory entries are valid coordinates', () {
      expect(CityDirectory.cities.length, greaterThanOrEqualTo(20));
      for (final PrayerLocation c in CityDirectory.cities) {
        expect(c.latitude, inInclusiveRange(-90, 90), reason: c.city);
        expect(c.longitude, inInclusiveRange(-180, 180), reason: c.city);
        expect(c.city, isNotEmpty);
      }
      // Makkah must be present — the Umm al-Qibla default for Muslims.
      expect(
        CityDirectory.cities.any((c) => c.city == 'Makkah'),
        isTrue,
      );
    });
  });

  group('location controller (O-11)', () {
    test('GPS success persists the fix', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer c = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c.dispose);
      final GpsStatus status = await c
          .read(prayerLocationControllerProvider.notifier)
          .useGps(fetch: () async => (lat: 51.5074, lng: -0.1278));
      expect(status, GpsStatus.success);
      final PrayerLocation loc = c.read(prayerLocationControllerProvider);
      expect(loc.latitude, 51.5074);
      expect(prefs.getDouble('ar.location.lat'), 51.5074);
    });

    test('GPS failure keeps the previous location and reports status', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer c = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c.dispose);
      final GpsStatus status = await c
          .read(prayerLocationControllerProvider.notifier)
          .useGps(
            fetch: () async => throw const GpsException(GpsStatus.denied),
          );
      expect(status, GpsStatus.denied);
      expect(c.read(prayerLocationControllerProvider).city, 'Toronto');
    });

    test('saved location is restored on rebuild', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'ar.location.lat': 21.4225,
        'ar.location.lng': 39.8262,
        'ar.location.city': 'Makkah',
        'ar.location.country': 'Saudi Arabia',
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer c = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c.dispose);
      final PrayerLocation loc = c.read(prayerLocationControllerProvider);
      expect(loc.city, 'Makkah');
      expect(loc.latitude, 21.4225);
    });
  });

  group('prayer alerts (O-11)', () {
    test('toggles persist and only cover the five prayers', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer c = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c.dispose);
      final PrayerAlertController ctrl = c.read(
        prayerAlertsProvider.notifier,
      );
      await ctrl.toggle('Fajr');
      await ctrl.toggle('Sunrise'); // not alertable — ignored
      expect(c.read(prayerAlertsProvider), <String>{'Fajr'});
      expect(prefs.getStringList('ar.prayer.alerts'), <String>['Fajr']);
      await ctrl.toggle('Fajr');
      expect(c.read(prayerAlertsProvider), isEmpty);
    });

    test('activeAlert fires once when an enabled prayer time arrives',
        () async {
      final DateTime now = DateTime.now();
      final PrayerTimes t = PrayerTimes(
        fajr: DateTime(now.year, now.month, now.day, now.hour, now.minute),
        sunrise: now.add(const Duration(hours: 1)),
        dhuhr: now.add(const Duration(hours: 2)),
        asr: now.add(const Duration(hours: 3)),
        maghrib: now.add(const Duration(hours: 4)),
        isha: now.add(const Duration(hours: 5)),
        locationLabel: 'X',
        methodLabel: 'Y',
      );
      final ProviderContainer c = ProviderContainer(
        overrides: [
          prayerRepositoryProvider.overrideWithValue(_FixedRepository(t)),
          prayerAlertsProvider.overrideWith(
            () => _PresetAlerts(<String>{'Fajr'}),
          ),
        ],
      );
      addTearDown(c.dispose);
      await c.read(prayerTimesProvider.future);
      expect(c.read(activeAlertProvider), 'Fajr');
      // Once marked fired, it stays quiet.
      c
          .read(firedAlertsProvider.notifier)
          .markFired('${now.year}-${now.month}-${now.day}:Fajr');
      expect(c.read(activeAlertProvider), isNull);
    });
  });
}

class _FixedRepository implements PrayerRepository {
  _FixedRepository(this.t);
  final PrayerTimes t;
  @override
  Future<PrayerTimes> timingsForToday(PrayerLocation location) async => t;
}

class _PresetAlerts extends PrayerAlertController {
  _PresetAlerts(this.preset);
  final Set<String> preset;
  @override
  Set<String> build() => preset;
}
