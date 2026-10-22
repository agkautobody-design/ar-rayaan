import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/calendar/domain/hijri_date.dart';
import 'package:ar_rayaan/features/calendar/domain/sunnah_fasting.dart';
import 'package:ar_rayaan/features/calendar/presentation/calendar_screen.dart';
import 'package:ar_rayaan/features/qibla/domain/compass_math.dart';
import 'package:ar_rayaan/features/qibla/domain/qibla_direction.dart';
import 'package:ar_rayaan/features/ramadan/domain/ramadan_season.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('qibla direction', () {
    test('bearing from Toronto points north-east to the Kaaba', () {
      final double b = QiblaDirection.bearingToKaaba(
        QiblaDirection.sampleToronto,
      );
      expect(b, greaterThan(54));
      expect(b, lessThan(56));
      expect(QiblaDirection.compassPoint(b), 'NE');
    });

    test('bearing is sane from other cities', () {
      expect(
        QiblaDirection.bearingToKaaba((lat: 51.5074, lng: -0.1278)),
        inInclusiveRange(118, 120),
      ); // London ~ ESE
      final double jakarta = QiblaDirection.bearingToKaaba((
        lat: -6.2088,
        lng: 106.8456,
      ));
      expect(jakarta, inInclusiveRange(294, 296)); // Jakarta ~ WNW
      expect(QiblaDirection.compassPoint(jakarta), 'WNW');
    });

    test('compass points wrap correctly', () {
      expect(QiblaDirection.compassPoint(0), 'N');
      expect(QiblaDirection.compassPoint(359), 'N');
      expect(QiblaDirection.compassPoint(90), 'E');
      expect(QiblaDirection.compassPoint(180), 'S');
      expect(QiblaDirection.compassPoint(270), 'W');
    });

    test('distance to the Kaaba is near zero at Makkah and sane elsewhere', () {
      expect(
        QiblaDirection.distanceToKaabaKm(QiblaDirection.kaaba),
        lessThan(0.1),
      );
      expect(
        QiblaDirection.distanceToKaabaKm((lat: 24.4672, lng: 39.6111)),
        inInclusiveRange(334, 344), // Madinah ~339 km
      );
      expect(
        QiblaDirection.distanceToKaabaKm(QiblaDirection.sampleToronto),
        inInclusiveRange(10450, 10550), // Toronto ~10,496 km
      );
    });
  });

  group('compass maths', () {
    test('normalize folds into 0..360', () {
      expect(CompassMath.normalize(0), 0);
      expect(CompassMath.normalize(360), 0);
      expect(CompassMath.normalize(-90), 270);
      expect(CompassMath.normalize(725), 5);
    });

    test('shortestDelta takes the short way round', () {
      expect(CompassMath.shortestDelta(350, 10), 20);
      expect(CompassMath.shortestDelta(10, 350), -20);
      expect(CompassMath.shortestDelta(0, 180), 180);
      expect(CompassMath.shortestDelta(90, 90), 0);
    });

    test('smoothing is correct across the 359 to 0 wrap', () {
      final double s = CompassMath.smooth(350, 10, factor: 0.5);
      expect(s, closeTo(0, 0.001));
      expect(CompassMath.smooth(100, 100), closeTo(100, 0.001));
      expect(CompassMath.smooth(100, 140, factor: 1), closeTo(140, 0.001));
    });

    test('true heading adds declination (east positive)', () {
      expect(CompassMath.trueHeading(10, -15), 355);
      expect(CompassMath.trueHeading(350, 15), 5);
      expect(CompassMath.trueHeading(90, 0), 90);
    });

    test('offset to the Qibla is zero when facing it', () {
      expect(
        CompassMath.offsetToQibla(qiblaBearing: 55, trueHeading: 55),
        0,
      );
      expect(
        CompassMath.offsetToQibla(qiblaBearing: 10, trueHeading: 350),
        20,
      );
      expect(
        CompassMath.offsetToQibla(qiblaBearing: 350, trueHeading: 10),
        -20,
      );
    });

    test('heading from orientation, phone held flat', () {
      double h(double alpha) => CompassMath.headingFromOrientation(
        alpha: alpha,
        beta: 0,
        gamma: 0,
      );
      expect(h(0), closeTo(0, 0.001));
      expect(h(90), closeTo(270, 0.001)); // turned left of north = west
      expect(h(180), closeTo(180, 0.001));
      expect(h(270), closeTo(90, 0.001));
    });

    test('tilt and roll do not change a flat heading', () {
      final double a = CompassMath.headingFromOrientation(
        alpha: 40,
        beta: 0,
        gamma: 0,
      );
      final double b = CompassMath.headingFromOrientation(
        alpha: 40,
        beta: 25,
        gamma: 15,
      );
      expect(b, closeTo(a, 0.001));
    });

    test('heading from orientation, phone held upright', () {
      double h(double alpha) => CompassMath.headingFromOrientation(
        alpha: alpha,
        beta: 90,
        gamma: 0,
      );
      expect(h(0), closeTo(0, 0.001));
      expect(h(90), closeTo(270, 0.001));
      expect(h(270), closeTo(90, 0.001));
    });
  });

  group('hijri calendar', () {
    test('gregorian to hijri anchors (official Umm al-Qura data)', () {
      expect(
        HijriDate.fromGregorian(DateTime(2026, 2, 18)),
        const HijriDate(1447, 9, 1),
      ); // Ramadan 1447
      expect(
        HijriDate.fromGregorian(DateTime(2026, 3, 20)),
        const HijriDate(1447, 10, 1),
      ); // Eid al-Fitr 1447
      expect(
        HijriDate.fromGregorian(DateTime(2026, 6, 16)),
        const HijriDate(1448, 1, 1),
      ); // New Year 1448
      expect(
        HijriDate.fromGregorian(DateTime(2025, 3, 1)),
        const HijriDate(1446, 9, 1),
      ); // Ramadan 1446
      expect(
        HijriDate.fromGregorian(DateTime(2024, 7, 7)),
        const HijriDate(1446, 1, 1),
      ); // New Year 1446
    });

    test('hijri to gregorian anchors', () {
      expect(
        const HijriDate(1447, 12, 10).toGregorian(),
        DateTime(2026, 5, 27),
      ); // Eid al-Adha 1447
      expect(
        const HijriDate(1448, 9, 1).toGregorian(),
        DateTime(2027, 2, 8),
      ); // Ramadan 1448
    });

    test('month lengths follow Umm al-Qura data in range', () {
      expect(HijriDate.monthLength(1447, 9), 30); // Ramadan 1447: 30 days
      expect(HijriDate.monthLength(1447, 12), 29);
      expect(HijriDate.monthLength(1448, 12), 30);
      expect(HijriDate.isLeapYear(1447), isTrue);
    });

    test('tabular fallback covers dates outside the Umm al-Qura range', () {
      final DateTime g = const HijriDate(1600, 1, 1).toGregorian();
      expect(HijriDate.fromGregorian(g), const HijriDate(1600, 1, 1));
    });

    test('round-trips across a full year', () {
      DateTime g = DateTime(2026, 1, 1);
      for (int i = 0; i < 366; i++) {
        final HijriDate h = HijriDate.fromGregorian(g);
        expect(h.toGregorian(), g);
        g = g.add(const Duration(days: 1));
      }
    });
  });

  group('observances', () {
    test('soonest-first within the next lunar year, none in the past', () {
      final DateTime today = DateTime(2026, 7, 19);
      final List<(Observance, HijriDate)> up = Observances.upcoming(today);
      expect(up.length, Observances.all.length);
      expect(up.first.$1.nameEn, contains('Mawlid'));
      expect(up.first.$2, const HijriDate(1448, 3, 12));
      expect(up.any(((Observance, HijriDate) e) => e.$1.nameEn == 'Ramadan Begins'),
          isTrue);
      for (int i = 0; i < up.length; i++) {
        expect(up[i].$2.toGregorian().isBefore(today), isFalse);
        if (i > 0) {
          expect(
            up[i].$2.toGregorian().isBefore(up[i - 1].$2.toGregorian()),
            isFalse,
          );
        }
      }
    });

    test('every observance explains itself; sourced unless contested', () {
      for (final Observance o in Observances.all) {
        expect(o.about.length, greaterThan(40), reason: o.nameEn);
        if (o.basis != ObservanceBasis.contested) {
          expect(o.source, isNotEmpty, reason: o.nameEn);
        }
        expect(o.nameAr, isNotEmpty, reason: o.nameEn);
        expect(o.basis.label, isNotEmpty);
      }
    });

    test('disputed days are not presented as settled', () {
      Observance named(String part) =>
          Observances.all.firstWhere((Observance o) => o.nameEn.contains(part));
      expect(named('Mawlid').basis, isNot(ObservanceBasis.established));
      expect(named('Bara').basis, isNot(ObservanceBasis.established));
      expect(named('Mi').basis, isNot(ObservanceBasis.established));
      expect(named('Eid al-Fitr').basis, ObservanceBasis.established);
      expect(named('Arafah').basis, ObservanceBasis.established);
    });
  });

  group('fasting markers', () {
    test('a forbidden day returns only the prohibition', () {
      // Eid al-Fitr 1447 (20 March 2026) fell on a Friday; also test a
      // Thursday-or-Monday Eid by walking the Shawwal 1 of several years.
      for (int y = 1440; y <= 1460; y++) {
        final List<FastingMarker> m = SunnahFasting.forDate(
          HijriDate(y, 10, 1),
        );
        expect(m.length, 1, reason: 'Eid al-Fitr $y');
        expect(m.single.kind, FastingKind.forbidden);
        final List<FastingMarker> adha = SunnahFasting.forDate(
          HijriDate(y, 12, 10),
        );
        expect(adha.length, 1, reason: 'Eid al-Adha $y');
        expect(adha.single.kind, FastingKind.forbidden);
      }
    });

    test('the Eid citation is the Bukhari / Muslim pair', () {
      final FastingMarker fitr = SunnahFasting.forDate(
        const HijriDate(1447, 10, 1),
      ).single;
      expect(fitr.source, contains('Bukhari 1991'));
      expect(fitr.source, contains('Muslim 1137'));
    });
  });

  group('RamadanSeason', () {
    test('before Ramadan it is the coming one; during it, the current one', () {
      final RamadanSeason before = RamadanSeason.forDate(DateTime(2026, 1, 10));
      expect(before.hijriYear, 1447);
      expect(before.start, DateTime(2026, 2, 18));
      expect(before.end, DateTime(2026, 3, 20));
      expect(before.length, 30);
      expect(before.contains(DateTime(2026, 1, 10)), isFalse);
      expect(before.daysUntilStart(DateTime(2026, 1, 10)), 39);

      final RamadanSeason during = RamadanSeason.forDate(DateTime(2026, 3, 1));
      expect(during.hijriYear, 1447);
      expect(during.contains(DateTime(2026, 3, 1)), isTrue);
      expect(during.dayOf(DateTime(2026, 2, 18)), 1);
      expect(during.dayOf(DateTime(2026, 3, 1)), 12);
      expect(during.contains(DateTime(2026, 3, 20)), isFalse);
    });

    test('after Eid the next year starts a clean season', () {
      final RamadanSeason next = RamadanSeason.forDate(DateTime(2026, 10, 20));
      expect(next.hijriYear, 1448);
      expect(next.start, DateTime(2027, 2, 8));
      expect(next.key('juz'), 'ar.ramadan.1448.juz');
      expect(
        RamadanSeason.forDate(DateTime(2026, 2, 20)).key('juz'),
        isNot(next.key('juz')),
      );
    });
  });

  group('calendar screen', () {
    testWidgets('observance rows open an explanation sheet', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      tester.view.physicalSize = const Size(430, 3600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(home: CalendarScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('UPCOMING OBSERVANCES'), findsOneWidget);
      final Observance first = Observances.upcoming(DateTime.now()).first.$1;
      final Finder row = find.byKey(Key('observance-${first.nameEn}'));
      expect(row, findsOneWidget);

      await tester.tap(row);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(first.about), findsOneWidget);
      expect(find.text(first.basis.label.toUpperCase()), findsOneWidget);
    });
  });
}
