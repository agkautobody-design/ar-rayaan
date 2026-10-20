import 'package:ar_rayaan/app/core/notifications/notification_ids.dart';
import 'package:ar_rayaan/app/core/notifications/prayer_notification_scheduler.dart';
import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/calendar/application/hijri_settings.dart';
import 'package:ar_rayaan/features/calendar/domain/hijri_date.dart';
import 'package:ar_rayaan/features/habits/application/habits_providers.dart';
import 'package:ar_rayaan/features/prayer/application/iqamah_settings.dart';
import 'package:ar_rayaan/features/prayer/application/prayer_log.dart';
import 'package:ar_rayaan/features/prayer/application/prayer_settings.dart';
import 'package:ar_rayaan/features/qibla/domain/compass_math.dart';
import 'package:ar_rayaan/features/qibla/domain/magnetic_declination.dart';
import 'package:ar_rayaan/features/zakat/domain/zakat_al_fitr.dart';
import 'package:ar_rayaan/features/zakat/domain/zakat_history.dart';
import 'package:ar_rayaan/features/zakat/domain/zakat_reminders.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> container([Map<String, Object>? initial]) async {
  SharedPreferences.setMockInitialValues(initial ?? <String, Object>{});
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final ProviderContainer c = ProviderContainer(
    overrides: <Override>[sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(c.dispose);
  return c;
}

ZakatRecord record(DateTime d, {double due = 100}) => ZakatRecord(
  date: d,
  madhab: 'hanafi',
  nisabBasis: 'silver',
  tolaFigures: false,
  netZakatable: due * 40,
  nisabValue: 1000,
  zakatDue: due,
  eligible: true,
  goldPricePerGram: 70,
  silverPricePerGram: 1,
);

void main() {
  tearDown(() => HijriDate.config = const HijriConfig());

  group('WMM2025 declination (NOAA published test values)', () {
    // year, height km, lat, lon, expected declination (degrees).
    const List<(double, double, double, double, double)> rows =
        <(double, double, double, double, double)>[
          (2025.0, 0, 80, 0, 1.28),
          (2025.0, 0, 0, 120, -0.16),
          (2025.0, 0, -80, 240, 68.78),
          (2025.0, 100, 80, 0, 0.85),
          (2025.0, 100, 0, 120, -0.15),
          (2025.0, 100, -80, 240, 68.21),
          (2027.5, 0, 80, 0, 2.59),
          (2027.5, 0, 0, 120, -0.24),
          (2027.5, 0, -80, 240, 68.49),
          (2027.5, 100, 80, 0, 2.16),
          (2027.5, 100, 0, 120, -0.23),
          (2027.5, 100, -80, 240, 67.93),
        ];
    test('matches all twelve rows within 0.02 degrees', () {
      for (final (double, double, double, double, double) r in rows) {
        final (double x, double y, double _) = MagneticModel.fieldComponents(
          latitude: r.$3,
          longitude: r.$4,
          decimalYear: r.$1,
          heightKm: r.$2,
        );
        final double d = _atan2Deg(y, x);
        expect(d, closeTo(r.$5, 0.02), reason: 'row $r');
      }
    });

    test('validity window is flagged', () {
      final MagneticDeclination ok = MagneticModel.declination(
        latitude: 21.4,
        longitude: 39.8,
        date: DateTime.utc(2026, 7, 1),
      );
      expect(ok.withinValidity, isTrue);
      final MagneticDeclination old = MagneticModel.declination(
        latitude: 21.4,
        longitude: 39.8,
        date: DateTime.utc(2020, 7, 1),
      );
      expect(old.withinValidity, isFalse);
    });

    test('decimal year is about half way through July 1', () {
      expect(
        MagneticModel.decimalYear(DateTime.utc(2026, 7, 2)),
        closeTo(2026.5, 0.01),
      );
    });
  });

  group('compass erratic detection', () {
    test('a steady heading is not erratic', () {
      expect(
        CompassMath.isErratic(<double>[10, 10.5, 11, 10.8, 11.2, 11, 10.9, 11]),
        isFalse,
      );
    });
    test('large alternating swings are erratic', () {
      expect(
        CompassMath.isErratic(<double>[
          10, 60, 10, 70, 5, 80, 0, 75, 10, 65, 5, 70,
        ]),
        isTrue,
      );
    });
    test('a steady turn in one direction is not erratic', () {
      expect(
        CompassMath.isErratic(<double>[
          0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110,
        ]),
        isFalse,
      );
    });
  });

  group('notification ids', () {
    test('only stale ids in range are cancelled', () {
      final List<int> stale = staleIds(
        pending: <int>[1, 2, 3, kReminderIdBase + 1],
        wanted: <int>{2},
        inRange: isPrayerId,
      );
      expect(stale, <int>[1, 3]);
    });
    test('ranges are disjoint', () {
      expect(isPrayerId(kReminderIdBase), isFalse);
      expect(isReminderId(kReminderIdBase), isTrue);
      expect(isPrayerId(202610204 + kLeadIdOffset), isTrue);
    });
    test('window stays under the iOS 64 limit', () {
      expect(kMaxPrayerNotifications, lessThan(64));
    });
  });

  group('prayer settings', () {
    test('cleanOffsets clamps, drops zeros and unknown names', () {
      final Map<String, int> m = PrayerSettings.cleanOffsets(<String, int>{
        'Fajr': 99,
        'Asr': -99,
        'Isha': 0,
        'Bogus': 5,
      });
      expect(m, <String, int>{
        'Fajr': kMaxOffsetMinutes,
        'Asr': -kMaxOffsetMinutes,
      });
    });

    test('offsets and high-latitude choice persist', () async {
      ProviderContainer c = await container();
      final PrayerSettingsController ctl = c.read(
        prayerSettingsProvider.notifier,
      );
      await ctl.setOffset('Fajr', 4);
      await ctl.setHighLatitude('seventh_of_the_night');
      expect(c.read(prayerSettingsProvider).offsetFor('Fajr'), 4);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      c.dispose();
      c = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(c.dispose);
      final PrayerSettings s = c.read(prayerSettingsProvider);
      expect(s.offsetFor('Fajr'), 4);
      expect(s.highLatitude, 'seventh_of_the_night');
      await c.read(prayerSettingsProvider.notifier).clearOffsets();
      expect(c.read(prayerSettingsProvider).hasOffsets, isFalse);
    });

    test('an unknown high-latitude key is ignored', () async {
      final ProviderContainer c = await container();
      await c.read(prayerSettingsProvider.notifier).setHighLatitude('nope');
      expect(c.read(prayerSettingsProvider).highLatitude, 'auto');
    });
  });

  group('hijri settings', () {
    test('basis and shift change the date and persist', () async {
      final DateTime day = DateTime(2026, 10, 20);
      HijriDate.config = const HijriConfig();
      final HijriDate tomorrow = HijriDate.fromGregorian(
        DateTime(2026, 10, 21),
      );
      final ProviderContainer c = await container();
      await c.read(hijriSettingsProvider.notifier).setAdjustDays(1);
      expect(HijriDate.fromGregorian(day), tomorrow);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('ar.hijri.adjust'), 1);
    });

    test('adjustment is clamped to two days', () async {
      final ProviderContainer c = await container();
      await c.read(hijriSettingsProvider.notifier).setAdjustDays(9);
      expect(c.read(hijriSettingsProvider).adjustDays, HijriConfig.maxAdjust);
    });

    test('tabular basis round-trips through Gregorian', () {
      HijriDate.config = const HijriConfig(basis: HijriBasis.tabular);
      final DateTime day = DateTime(2026, 3, 1);
      final HijriDate h = HijriDate.fromGregorian(day);
      final DateTime back = h.toGregorian();
      expect(DateTime(back.year, back.month, back.day), day);
    });
  });

  group('zakat reminders', () {
    test('nothing is planned until the user opts in', () {
      expect(
        planZakatReminders(
          now: DateTime.utc(2026, 1, 1),
          hawlOn: false,
          fitrOn: false,
          hawlStart: DateTime(2025, 6, 1),
        ),
        isEmpty,
      );
    });

    test('hawl reminders use the reminder id range and lie in the future', () {
      final DateTime now = DateTime.utc(2026, 1, 1);
      final List<PlannedReminder> r = planZakatReminders(
        now: now,
        hawlOn: true,
        fitrOn: false,
        hawlStart: DateTime(2025, 6, 1),
      );
      expect(r, isNotEmpty);
      for (final PlannedReminder p in r) {
        expect(p.id, greaterThanOrEqualTo(kReminderIdBase));
        expect(p.at.isAfter(now), isTrue);
      }
    });

    test('Zakat al-Fitr reminders cite their source', () {
      final List<PlannedReminder> r = planZakatReminders(
        now: DateTime.utc(2026, 1, 1),
        hawlOn: false,
        fitrOn: true,
      );
      expect(r, isNotEmpty);
      expect(r.first.body, contains(ZakatAlFitr.source));
    });
  });

  group('zakat history', () {
    test('encode/decode round trip, newest first, bad rows skipped', () {
      final List<ZakatRecord> list = ZakatHistory.add(
        ZakatHistory.add(<ZakatRecord>[], record(DateTime(2025, 3, 1))),
        record(DateTime(2026, 3, 1), due: 150),
      );
      final List<ZakatRecord> back = ZakatHistory.decode(
        ZakatHistory.encode(list),
      );
      expect(back.map((ZakatRecord r) => r.zakatDue), <double>[150, 100]);
      expect(ZakatHistory.decode('not json'), isEmpty);
      expect(ZakatHistory.decode(null), isEmpty);
    });

    test('same-day save replaces and the list is capped', () {
      List<ZakatRecord> list = <ZakatRecord>[];
      list = ZakatHistory.add(list, record(DateTime(2026, 3, 1), due: 1));
      list = ZakatHistory.add(list, record(DateTime(2026, 3, 1), due: 2));
      expect(list.length, 1);
      expect(list.single.zakatDue, 2);
      for (int i = 0; i < kMaxZakatRecords + 5; i++) {
        list = ZakatHistory.add(list, record(DateTime(2020, 1, 1 + i)));
      }
      expect(list.length, kMaxZakatRecords);
    });

    test('comparison prefers the record about a year earlier', () {
      final ZakatRecord now = record(DateTime(2026, 3, 1));
      final ZakatRecord lastYear = record(DateTime(2025, 3, 3), due: 80);
      final ZakatRecord recent = record(DateTime(2026, 1, 1), due: 90);
      expect(
        ZakatHistory.comparisonFor(now, <ZakatRecord>[recent, lastYear]),
        lastYear,
      );
      expect(ZakatHistory.comparisonFor(now, <ZakatRecord>[]), isNull);
    });
  });

  group('Zakat al-Fitr from a staple', () {
    test('is plain multiplication of the user figures', () {
      expect(
        ZakatAlFitr.totalFromStaple(
          people: 4,
          kgPerPerson: 2,
          pricePerKg: 1.5,
        ),
        12,
      );
      expect(
        ZakatAlFitr.totalFromStaple(
          people: 4,
          kgPerPerson: 0,
          pricePerKg: 1.5,
        ),
        0,
      );
    });
  });

  group('prayer log', () {
    test('missed adds one make-up prayer once; changing removes it', () async {
      final ProviderContainer c = await container();
      final PrayerLogController log = c.read(prayerLogProvider.notifier);
      await log.mark('2026-10-20', 'Fajr', PrayerMark.missed);
      expect(c.read(qadaProvider)['Fajr'], 1);
      await log.mark('2026-10-20', 'Fajr', PrayerMark.excused);
      expect(c.read(qadaProvider)['Fajr'] ?? 0, 0);
      expect(
        c.read(prayerLogProvider).markFor('2026-10-20', 'Fajr'),
        PrayerMark.excused,
      );
    });

    test('choosing the same mark again clears it; excused never counts', () async {
      final ProviderContainer c = await container();
      final PrayerLogController log = c.read(prayerLogProvider.notifier);
      await log.mark('2026-10-20', 'Asr', PrayerMark.excused);
      expect(c.read(qadaProvider)['Asr'] ?? 0, 0);
      await log.mark('2026-10-20', 'Asr', PrayerMark.excused);
      expect(c.read(prayerLogProvider).markFor('2026-10-20', 'Asr'), isNull);
    });

    test('marks survive a restart', () async {
      ProviderContainer c = await container();
      await c
          .read(prayerLogProvider.notifier)
          .mark(
            PrayerLogController.dayKey(DateTime.now()),
            'Dhuhr',
            PrayerMark.prayed,
          );
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      c.dispose();
      c = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(c.dispose);
      expect(
        c
            .read(prayerLogProvider)
            .markFor(PrayerLogController.dayKey(DateTime.now()), 'Dhuhr'),
        PrayerMark.prayed,
      );
    });
  });

  group('iqamah', () {
    test('time parsing is strict', () {
      expect(IqamahSettings.parseTime('13:05'), (13, 5));
      expect(IqamahSettings.parseTime('25:00'), isNull);
      expect(IqamahSettings.parseTime('1305'), isNull);
      expect(IqamahSettings.parseTime(null), isNull);
    });

    test('minutes clamp and zero clears; Jumuah validates', () async {
      final ProviderContainer c = await container();
      final IqamahController ctl = c.read(iqamahProvider.notifier);
      await ctl.setMinutes('Fajr', 500);
      expect(c.read(iqamahProvider).minutesFor('Fajr'), IqamahSettings.maxMinutes);
      await ctl.setMinutes('Fajr', 0);
      expect(c.read(iqamahProvider).isEmpty, isTrue);
      await ctl.setJumuah('13:15');
      expect(c.read(iqamahProvider).jumuahTime, '13:15');
      await ctl.setJumuah('soon');
      expect(c.read(iqamahProvider).jumuahTime, isNull);
    });

    test('iqamah is the adhan plus the minutes', () {
      const IqamahSettings s = IqamahSettings(
        minutesAfter: <String, int>{'Fajr': 20},
      );
      final DateTime adhan = DateTime(2026, 10, 20, 5, 30);
      expect(s.iqamahFor('Fajr', adhan), DateTime(2026, 10, 20, 5, 50));
      expect(s.iqamahFor('Asr', adhan), isNull);
    });
  });

  group('dhikr ledger', () {
    test('record adds to today and ignores non-positive counts', () async {
      final ProviderContainer c = await container();
      final DhikrLedgerController ctl = c.read(dhikrLedgerProvider.notifier);
      await ctl.record(33);
      await ctl.record(0);
      await ctl.record(-5);
      expect(c.read(dhikrLedgerProvider).values.fold<int>(0, (a, b) => a + b), 33);
    });
  });
}

double _atan2Deg(double y, double x) =>
    MagneticModel.declinationFromComponents(x, y);
