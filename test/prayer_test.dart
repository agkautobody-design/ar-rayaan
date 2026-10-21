import 'dart:async';

import 'package:ar_rayaan/app/core/notifications/prayer_notification_scheduler.dart';
import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/prayer/application/location_providers.dart';
import 'package:ar_rayaan/features/prayer/application/prayer_alerts.dart';
import 'package:ar_rayaan/features/prayer/application/prayer_notification_plan.dart';
import 'package:ar_rayaan/features/prayer/application/prayer_providers.dart';
import 'package:ar_rayaan/features/prayer/application/prayer_repository.dart';
import 'package:ar_rayaan/features/prayer/application/prayer_settings.dart';
import 'package:ar_rayaan/features/prayer/data/adhan_calc_prayer_repository.dart';
import 'package:ar_rayaan/features/prayer/data/city_directory.dart';
import 'package:ar_rayaan/features/prayer/domain/prayer_times.dart';
import 'package:ar_rayaan/features/prayer/domain/prayer_zone.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

PrayerLocation city(String name) => CityDirectory.cities.firstWhere(
  (PrayerLocation c) => c.city == name,
);

PrayerTimes sampleTimes({PrayerZone? zone}) => PrayerTimes(
  fajr: DateTime(2026, 10, 20, 5, 30),
  sunrise: DateTime(2026, 10, 20, 6, 50),
  dhuhr: DateTime(2026, 10, 20, 12, 40),
  asr: DateTime(2026, 10, 20, 15, 40),
  maghrib: DateTime(2026, 10, 20, 18, 20),
  isha: DateTime(2026, 10, 20, 19, 40),
  locationLabel: 'Test',
  methodLabel: 'Test',
  zone: zone,
);

class CountingRepo implements PrayerRepository {
  int calls = 0;

  @override
  Future<PrayerTimes> timingsForToday(PrayerLocation location) async {
    calls++;
    return sampleTimes(zone: location.zone);
  }
}

class RecordingScheduler implements PrayerNotificationScheduler {
  final List<List<PlannedPrayerNotification>> plans =
      <List<PlannedPrayerNotification>>[];

  @override
  bool get supported => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<ExactAlarmStatus> exactAlarmStatus() async =>
      ExactAlarmStatus.notNeeded;

  @override
  Future<void> openExactAlarmSettings() async {}

  @override
  Future<void> replaceAll(List<PlannedPrayerNotification> plan) async {
    plans.add(plan);
  }

  final List<List<PlannedReminder>> reminders = <List<PlannedReminder>>[];

  @override
  Future<void> replaceReminders(List<PlannedReminder> r) async {
    reminders.add(r);
  }

  final List<List<PlannedReminder>> academyReminders =
      <List<PlannedReminder>>[];

  @override
  Future<void> replaceAcademyReminders(List<PlannedReminder> r) async {
    academyReminders.add(r);
  }
}

Future<void> settle() async {
  for (int i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PrayerZone', () {
    test('fixed offsets', () {
      const PrayerZone makkah = PrayerZone(180);
      expect(
        makkah.offsetAtUtc(DateTime.utc(2026, 7, 1)),
        const Duration(hours: 3),
      );
      expect(
        makkah.offsetAtUtc(DateTime.utc(2026, 1, 1)),
        const Duration(hours: 3),
      );
    });

    test('US daylight saving 2026: 8 March to 1 November', () {
      const PrayerZone ny = PrayerZone(-300, DstRule.us);
      expect(ny.offsetOnDate(2026, 3, 7), const Duration(hours: -5));
      expect(ny.offsetOnDate(2026, 3, 8), const Duration(hours: -4));
      expect(ny.offsetOnDate(2026, 10, 31), const Duration(hours: -4));
      expect(ny.offsetOnDate(2026, 11, 1), const Duration(hours: -5));
    });

    test('EU daylight saving 2026: 29 March to 25 October', () {
      const PrayerZone london = PrayerZone(0, DstRule.eu);
      expect(london.offsetOnDate(2026, 3, 28), Duration.zero);
      expect(london.offsetOnDate(2026, 3, 29), const Duration(hours: 1));
      expect(london.offsetOnDate(2026, 10, 24), const Duration(hours: 1));
      expect(london.offsetOnDate(2026, 10, 25), Duration.zero);
    });

    test('Australian daylight saving spans the new year', () {
      const PrayerZone sydney = PrayerZone(600, DstRule.au);
      expect(sydney.offsetOnDate(2026, 1, 15), const Duration(hours: 11));
      expect(sydney.offsetOnDate(2026, 4, 4), const Duration(hours: 11));
      expect(sydney.offsetOnDate(2026, 4, 5), const Duration(hours: 10));
      expect(sydney.offsetOnDate(2026, 10, 3), const Duration(hours: 10));
      expect(sydney.offsetOnDate(2026, 10, 4), const Duration(hours: 11));
      expect(sydney.offsetOnDate(2026, 12, 25), const Duration(hours: 11));
    });

    test('Egypt daylight saving 2026: 24 April to 29 October', () {
      const PrayerZone cairo = PrayerZone(120, DstRule.egypt);
      expect(cairo.offsetOnDate(2026, 4, 23), const Duration(hours: 2));
      expect(cairo.offsetOnDate(2026, 4, 24), const Duration(hours: 3));
      expect(cairo.offsetOnDate(2026, 10, 29), const Duration(hours: 3));
      expect(cairo.offsetOnDate(2026, 10, 30), const Duration(hours: 2));
    });

    test('id and parse round trip', () {
      const PrayerZone z = PrayerZone(-300, DstRule.us);
      expect(z.id, 'us|-300');
      expect(PrayerZone.parse(z.id), z);
      expect(PrayerZone.parse('none|180'), const PrayerZone(180));
      expect(PrayerZone.parse(null), isNull);
      expect(PrayerZone.parse('garbage'), isNull);
      expect(PrayerZone.parse('nope|180'), isNull);
      expect(PrayerZone.parse('us|x'), isNull);
    });

    test('wallClock and instantOf are inverses', () {
      const PrayerZone ny = PrayerZone(-300, DstRule.us);
      final DateTime instant = DateTime.utc(2026, 10, 20, 16, 30);
      final DateTime wall = PrayerZone.wallClock(ny, instant);
      expect(wall, DateTime(2026, 10, 20, 12, 30));
      expect(PrayerZone.instantOf(ny, wall), instant);
    });

    test('wallClock crosses midnight in the city zone, not the device zone', () {
      const PrayerZone makkah = PrayerZone(180);
      final DateTime wall = PrayerZone.wallClock(
        makkah,
        DateTime.utc(2026, 10, 19, 22, 0),
      );
      expect(wall, DateTime(2026, 10, 20, 1, 0));
    });
  });

  group('Automatic method by region', () {
    test('Doha gets Qatar, not Dubai', () {
      expect(autoMethodFor(city('Doha')), 'qatar');
    });

    test('Dubai gets Dubai', () {
      expect(autoMethodFor(city('Dubai')), 'dubai');
    });

    test('Makkah, Riyadh get Umm al-Qura', () {
      expect(autoMethodFor(city('Makkah')), 'umm_al_qura');
      expect(autoMethodFor(city('Riyadh')), 'umm_al_qura');
    });

    test('other regions', () {
      expect(autoMethodFor(city('Kuwait City')), 'kuwait');
      expect(autoMethodFor(city('Toronto')), 'north_america');
      expect(autoMethodFor(city('London')), 'moon_sighting_committee');
      expect(autoMethodFor(city('Cairo')), 'egyptian');
      expect(autoMethodFor(city('Karachi')), 'karachi');
      expect(autoMethodFor(city('Istanbul')), 'turkey');
    });

    test('every directory city carries a zone', () {
      for (final PrayerLocation c in CityDirectory.cities) {
        expect(c.zone, isNotNull, reason: c.city);
      }
    });
  });

  group('AdhanCalcPrayerRepository', () {
    test('Makkah on a fixed clock gives plausible wall times for that day', () {
      final AdhanCalcPrayerRepository repo = AdhanCalcPrayerRepository(
        clock: () => DateTime.utc(2026, 10, 20, 9),
      );
      final PrayerLocation makkah = city('Makkah');
      return repo.timingsForToday(makkah).then((PrayerTimes t) {
        for (final (String, DateTime) p in t.ordered) {
          expect(p.$2.year, 2026, reason: p.$1);
          expect(p.$2.month, 10, reason: p.$1);
          expect(p.$2.day, 20, reason: p.$1);
        }
        expect(t.fajr.isBefore(t.sunrise), isTrue);
        expect(t.sunrise.isBefore(t.dhuhr), isTrue);
        expect(t.dhuhr.isBefore(t.asr), isTrue);
        expect(t.asr.isBefore(t.maghrib), isTrue);
        expect(t.maghrib.isBefore(t.isha), isTrue);
        final int dhuhrMinutes = t.dhuhr.hour * 60 + t.dhuhr.minute;
        expect(dhuhrMinutes, inInclusiveRange(11 * 60 + 50, 12 * 60 + 20));
        expect(t.zone, makkah.zone);
        expect(t.methodLabel, contains('Umm al-Qura'));
      });
    });

    test('the city clock decides the day, not the device zone', () {
      // 22:00 UTC on 19 Oct is already 20 Oct, 01:00 in Makkah.
      final AdhanCalcPrayerRepository repo = AdhanCalcPrayerRepository();
      final PrayerTimes t = repo.timingsAt(
        city('Makkah'),
        DateTime.utc(2026, 10, 19, 22),
      );
      expect(t.fajr.day, 20);
      expect(t.isha.day, 20);
    });

    test('Umm al-Qura: Isha is 90 min after Maghrib, 120 in Ramadan', () {
      final AdhanCalcPrayerRepository repo = AdhanCalcPrayerRepository();
      final PrayerLocation makkah = city('Makkah');
      final PrayerTimes normal = repo.timingsAt(
        makkah,
        DateTime.utc(2026, 10, 20, 9),
      );
      final PrayerTimes ramadan = repo.timingsAt(
        makkah,
        DateTime.utc(2027, 2, 20, 9),
      );
      final int normalGap = normal.isha.difference(normal.maghrib).inMinutes;
      final int ramadanGap = ramadan.isha.difference(ramadan.maghrib).inMinutes;
      expect(normalGap, inInclusiveRange(89, 91));
      expect(ramadanGap, inInclusiveRange(119, 121));
      expect(ramadan.methodLabel, contains('Isha +30 min'));
      expect(normal.methodLabel, isNot(contains('Isha +30 min')));
    });

    test('Hanafi Asr is later than standard Asr', () {
      final PrayerLocation toronto = city('Toronto');
      final DateTime at = DateTime.utc(2026, 10, 20, 16);
      final PrayerTimes standard = AdhanCalcPrayerRepository().timingsAt(
        toronto,
        at,
      );
      final PrayerTimes hanafi = AdhanCalcPrayerRepository(
        settings: const PrayerSettings(hanafiAsr: true),
      ).timingsAt(toronto, at);
      expect(hanafi.asr.isAfter(standard.asr), isTrue);
      expect(hanafi.dhuhr, standard.dhuhr);
    });

    test('Toronto times follow Toronto daylight time', () {
      final PrayerTimes t = AdhanCalcPrayerRepository().timingsAt(
        city('Toronto'),
        DateTime.utc(2026, 10, 20, 16),
      );
      final int dhuhrMinutes = t.dhuhr.hour * 60 + t.dhuhr.minute;
      // Solar noon in Toronto in late October on EDT is about 12:50.
      expect(dhuhrMinutes, inInclusiveRange(12 * 60 + 25, 13 * 60 + 15));
    });
  });

  group('PrayerTimes', () {
    test('nextPrayer skips Sunrise', () {
      final PrayerTimes t = sampleTimes();
      // 06:00 is between Fajr and Sunrise... next is Dhuhr, never Sunrise.
      expect(t.nextPrayer(DateTime(2026, 10, 20, 6, 0)).$1, 'Dhuhr');
      expect(t.nextPrayer(DateTime(2026, 10, 20, 4, 0)).$1, 'Fajr');
      expect(t.nextPrayer(DateTime(2026, 10, 20, 13, 0)).$1, 'Asr');
      expect(t.nextPrayer(DateTime(2026, 10, 20, 18, 30)).$1, 'Isha');
    });

    test('nextPrayer wraps to tomorrow Fajr after Isha', () {
      final PrayerTimes t = sampleTimes();
      final (String, DateTime) next = t.nextPrayer(DateTime(2026, 10, 20, 23));
      expect(next.$1, 'Fajr');
      expect(next.$2, DateTime(2026, 10, 21, 5, 30));
    });

    test('nextPrayer converts the instant through the zone', () {
      final PrayerTimes t = sampleTimes(zone: const PrayerZone(180));
      // 08:00 UTC is 11:00 in Makkah: next is Dhuhr at 12:40.
      expect(t.nextPrayer(DateTime.utc(2026, 10, 20, 8)).$1, 'Dhuhr');
      // 17:30 UTC is 20:30 in Makkah: after Isha.
      expect(
        t.nextPrayer(DateTime.utc(2026, 10, 20, 17, 30)).$2,
        DateTime(2026, 10, 21, 5, 30),
      );
    });

    test('prayers has five entries without Sunrise', () {
      final List<String> names = sampleTimes().prayers
          .map(((String, DateTime) e) => e.$1)
          .toList();
      expect(names, <String>['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']);
    });

    test('lastThirdStartFor uses the night in progress before Fajr', () {
      final PrayerTimes t = sampleTimes();
      final DateTime evening = t.lastThirdStartFor(DateTime(2026, 10, 20, 12));
      final DateTime preDawn = t.lastThirdStartFor(DateTime(2026, 10, 20, 3));
      expect(evening.isAfter(t.maghrib), isTrue);
      expect(preDawn.isBefore(t.fajr), isTrue);
      expect(preDawn.isAfter(DateTime(2026, 10, 20, 0, 0)), isTrue);
    });
  });

  group('dueAlert', () {
    final PrayerTimes t = sampleTimes();
    const Set<String> enabled = <String>{'Dhuhr', 'Asr'};

    test('nothing before the time', () {
      expect(
        dueAlert(
          times: t,
          now: DateTime(2026, 10, 20, 12, 39),
          enabled: enabled,
          fired: <String>{},
        ),
        isNull,
      );
    });

    test('fires inside the two-minute window', () {
      expect(
        dueAlert(
          times: t,
          now: DateTime(2026, 10, 20, 12, 41),
          enabled: enabled,
          fired: <String>{},
        ),
        'Dhuhr',
      );
    });

    test('not after the window and not when disabled', () {
      expect(
        dueAlert(
          times: t,
          now: DateTime(2026, 10, 20, 12, 43),
          enabled: enabled,
          fired: <String>{},
        ),
        isNull,
      );
      expect(
        dueAlert(
          times: t,
          now: DateTime(2026, 10, 20, 18, 21),
          enabled: enabled,
          fired: <String>{},
        ),
        isNull,
      );
    });

    test('not twice once marked fired', () {
      final Set<String> fired = <String>{
        alertKey(DateTime(2026, 10, 20, 12, 41), 'Dhuhr'),
      };
      expect(
        dueAlert(
          times: t,
          now: DateTime(2026, 10, 20, 12, 41),
          enabled: enabled,
          fired: fired,
        ),
        isNull,
      );
    });

    test('empty toggle set never fires', () {
      expect(
        dueAlert(
          times: t,
          now: DateTime(2026, 10, 20, 12, 41),
          enabled: <String>{},
          fired: <String>{},
        ),
        isNull,
      );
    });
  });

  group('providers', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
    });

    ProviderContainer makeContainer(
      Stream<DateTime> ticker, {
      List<Override> extra = const <Override>[],
    }) {
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          nowTickerProvider.overrideWith((ref) => ticker),
          ...extra,
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('prayer times are recomputed when the day changes, alerts re-arm', () async {
      final StreamController<DateTime> ticker =
          StreamController<DateTime>.broadcast();
      addTearDown(ticker.close);
      final CountingRepo repo = CountingRepo();
      final ProviderContainer c = makeContainer(
        ticker.stream,
        extra: <Override>[prayerRepositoryProvider.overrideWithValue(repo)],
      );
      c.listen<AsyncValue<PrayerTimes>>(
        prayerTimesProvider,
        (AsyncValue<PrayerTimes>? a, AsyncValue<PrayerTimes> b) {},
      );
      c.listen<Set<String>>(
        firedAlertsProvider,
        (Set<String>? a, Set<String> b) {},
      );

      await settle();

      // Fallback location is Toronto (UTC-4 in October).
      ticker.add(DateTime.utc(2026, 10, 20, 3, 59)); // 23:59 on the 19th
      await settle();
      c.read(firedAlertsProvider.notifier).markFired('2026-10-19:Isha');
      expect(c.read(firedAlertsProvider), contains('2026-10-19:Isha'));
      final int before = repo.calls;

      // Same civil day: another tick must not refetch.
      ticker.add(DateTime.utc(2026, 10, 20, 3, 59, 30));
      await settle();
      expect(repo.calls, before);
      expect(c.read(firedAlertsProvider), isNotEmpty);

      // Past the city's midnight: refetch and re-arm.
      ticker.add(DateTime.utc(2026, 10, 20, 4, 1)); // 00:01 on the 20th
      await settle();
      expect(repo.calls, greaterThan(before));
      expect(c.read(firedAlertsProvider), isEmpty);
      expect(c.read(prayerDayKeyProvider), '2026-10-20');
    });

    test('alert toggles persist', () async {
      final ProviderContainer c = makeContainer(
        Stream<DateTime>.value(DateTime.utc(2026, 10, 20, 12)),
      );
      expect(c.read(prayerAlertsProvider), isEmpty);
      await c.read(prayerAlertsProvider.notifier).toggle('Fajr');
      await c.read(prayerAlertsProvider.notifier).toggle('Isha');
      await c.read(prayerAlertsProvider.notifier).toggle('Sunrise'); // ignored
      await c.read(prayerAlertsProvider.notifier).toggle('Isha'); // off again
      expect(c.read(prayerAlertsProvider), <String>{'Fajr'});

      final ProviderContainer again = makeContainer(
        Stream<DateTime>.value(DateTime.utc(2026, 10, 20, 12)),
      );
      expect(again.read(prayerAlertsProvider), <String>{'Fajr'});
    });

    test('manual city zone is persisted and restored', () async {
      final ProviderContainer c = makeContainer(
        Stream<DateTime>.value(DateTime.utc(2026, 10, 20, 12)),
      );
      final PrayerLocation london = city('London');
      await c
          .read(prayerLocationControllerProvider.notifier)
          .setLocation(london);
      expect(prefs.getString('ar.location.zone'), 'eu|0');

      final ProviderContainer again = makeContainer(
        Stream<DateTime>.value(DateTime.utc(2026, 10, 20, 12)),
      );
      final PrayerLocation restored = again.read(
        prayerLocationControllerProvider,
      );
      expect(restored.city, 'London');
      expect(restored.zone, const PrayerZone(0, DstRule.eu));
    });

    test('a city saved before zones existed gets its zone from the directory',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'ar.location.lat': 25.2048,
        'ar.location.lng': 55.2708,
        'ar.location.city': 'Dubai',
        'ar.location.country': 'UAE',
      });
      prefs = await SharedPreferences.getInstance();
      final ProviderContainer c = makeContainer(
        Stream<DateTime>.value(DateTime.utc(2026, 10, 20, 12)),
      );
      expect(
        c.read(prayerLocationControllerProvider).zone,
        const PrayerZone(240),
      );
    });

    test('GPS fix clears the stored zone', () async {
      final ProviderContainer c = makeContainer(
        Stream<DateTime>.value(DateTime.utc(2026, 10, 20, 12)),
      );
      final PrayerLocationController ctl = c.read(
        prayerLocationControllerProvider.notifier,
      );
      await ctl.setLocation(city('Sydney'));
      expect(prefs.getString('ar.location.zone'), isNotNull);
      final GpsStatus status = await ctl.useGps(
        fetch: () async => (lat: 43.7, lng: -79.4),
      );
      expect(status, GpsStatus.success);
      expect(c.read(prayerLocationControllerProvider).zone, isNull);
      expect(prefs.getString('ar.location.zone'), isNull);
    });
  });

  group('notification plan', () {
    test('plans only enabled prayers still in the future, in order', () {
      final List<PlannedPrayerNotification> plan = planPrayerNotifications(
        location: city('Makkah'),
        settings: const PrayerSettings(),
        enabled: <String>{'Fajr', 'Isha'},
        now: DateTime.utc(2026, 10, 20, 0), // 03:00 in Makkah
        days: 3,
      );
      expect(plan.length, 6);
      for (final PlannedPrayerNotification n in plan) {
        expect(n.prayer == 'Fajr' || n.prayer == 'Isha', isTrue);
        expect(n.at.isAfter(DateTime.utc(2026, 10, 20, 0)), isTrue);
      }
      for (int i = 1; i < plan.length; i++) {
        expect(plan[i].at.isAfter(plan[i - 1].at), isTrue);
      }
      expect(plan.first.prayer, 'Fajr');
      expect(plan.first.id, 202610200);
      expect(plan[1].prayer, 'Isha');
      expect(plan[1].id, 202610204);
      final Set<int> ids = plan.map((PlannedPrayerNotification n) => n.id).toSet();
      expect(ids.length, plan.length);
    });

    test('a prayer already past today is left out', () {
      final List<PlannedPrayerNotification> plan = planPrayerNotifications(
        location: city('Makkah'),
        settings: const PrayerSettings(),
        enabled: <String>{'Fajr'},
        now: DateTime.utc(2026, 10, 20, 12), // 15:00 in Makkah
        days: 2,
      );
      expect(plan.length, 1);
      expect(plan.first.id, 202610210);
    });

    test('nothing enabled means an empty plan', () {
      expect(
        planPrayerNotifications(
          location: city('Makkah'),
          settings: const PrayerSettings(),
          enabled: <String>{},
          now: DateTime.utc(2026, 10, 20),
        ),
        isEmpty,
      );
    });

    test('the sync provider hands the plan to the scheduler', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final RecordingScheduler scheduler = RecordingScheduler();
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          nowTickerProvider.overrideWith(
            (ref) => Stream<DateTime>.value(DateTime.now()),
          ),
          prayerNotificationSchedulerProvider.overrideWithValue(scheduler),
        ],
      );
      addTearDown(c.dispose);
      c.listen(prayerNotificationSyncProvider, (previous, next) {});
      await settle();
      expect(scheduler.plans, isNotEmpty);
      expect(scheduler.plans.last, isEmpty);

      await c.read(prayerAlertsProvider.notifier).toggle('Fajr');
      await settle();
      expect(scheduler.plans.last, isNotEmpty);
      expect(
        scheduler.plans.last.every(
          (PlannedPrayerNotification n) => n.prayer == 'Fajr',
        ),
        isTrue,
      );
    });

    test('the default scheduler is an unsupported no-op', () async {
      const NoopPrayerNotificationScheduler s =
          NoopPrayerNotificationScheduler();
      expect(s.supported, isFalse);
      expect(await s.requestPermission(), isFalse);
      await s.replaceAll(<PlannedPrayerNotification>[]);
    });
  });
}
