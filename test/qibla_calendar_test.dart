import 'package:ar_rayaan/app/app.dart';
import 'package:ar_rayaan/app/core/env_config.dart';
import 'package:ar_rayaan/features/calendar/domain/hijri_date.dart';
import 'package:ar_rayaan/features/qibla/domain/qibla_direction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('qibla direction', () {
    test('bearing from Toronto points north-east to the Kaaba', () {
      final double b = QiblaDirection.bearingToKaaba(
        QiblaDirection.defaultLocation,
      );
      expect(b, greaterThan(54));
      expect(b, lessThan(56));
      expect(QiblaDirection.compassPoint(b), 'NE');
    });

    test('bearing is sane from other cities', () {
      expect(
        QiblaDirection.bearingToKaaba((lat: -6.2088, lng: 106.8456)),
        inInclusiveRange(294, 296),
      ); // Jakarta ~ NW
      expect(
        QiblaDirection.bearingToKaaba((lat: 51.5074, lng: -0.1278)),
        inInclusiveRange(118, 120),
      ); // London ~ ESE
      final double jakarta = QiblaDirection.bearingToKaaba((
        lat: -6.2088,
        lng: 106.8456,
      ));
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
        QiblaDirection.distanceToKaabaKm(QiblaDirection.defaultLocation),
        inInclusiveRange(10450, 10550), // Toronto ~10,496 km
      );
    });
  });

  group('hijri calendar', () {
    test('gregorian → hijri anchors (official Umm al-Qura data)', () {
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

    test('hijri → gregorian anchors', () {
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
      // Tabular leap-year math still available for out-of-range years.
      expect(HijriDate.isLeapYear(1447), isTrue);
    });

    test('tabular fallback covers dates outside the Umm al-Qura range', () {
      // 1600 AH is beyond the official data table — must still convert.
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

    test('observances come out soonest-first within 12 months', () {
      final List<(Observance, HijriDate)> up = Observances.upcoming(
        DateTime(2026, 7, 19),
      );
      expect(up.length, Observances.all.length);
      expect(up.first.$1.nameEn, contains('Mawlid'));
      expect(up.first.$2, const HijriDate(1448, 3, 12));
      expect(up.any((e) => e.$1.nameEn == 'Ramadan Begins'), isTrue);
      // Every observance lands in the future.
      final DateTime today = DateTime(2026, 7, 19);
      for (final (_, HijriDate d) in up) {
        expect(
          d.toGregorian().isBefore(today),
          isFalse,
          reason: d.format(),
        );
      }
    });
  });

  testWidgets('calendar tile and qibla screen work end-to-end', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(child: ArRayaanApp(env: EnvConfig.fromDefines())),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('welcome-continue')));
    await tester.pumpAndSettle();

    // Home tile → Islamic Calendar
    await tester.tap(find.text('Islamic Calendar'));
    await tester.pumpAndSettle();
    expect(find.text('Islamic Calendar'), findsWidgets); // title + tile
    expect(find.text('UPCOMING OBSERVANCES'), findsOneWidget);
    expect(find.text('Ramadan Begins'), findsOneWidget);
    expect(find.text('Eid al-Fitr'), findsOneWidget);
    // The fasting planner card pushed the honesty footer below the fold —
    // scroll it into view before asserting.
    await tester.dragUntilVisible(
      find.text(
        'DATES FOLLOW THE OFFICIAL UMM AL-QURA CALENDAR · CONFIRM BY LOCAL MOON SIGHTING',
      ),
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    expect(
      find.text(
        'DATES FOLLOW THE OFFICIAL UMM AL-QURA CALENDAR · CONFIRM BY LOCAL MOON SIGHTING',
      ),
      findsOneWidget,
    );

    // Qibla via router (Menu/Explore row destination)
    final BuildContext ctx = tester.element(find.text('UPCOMING OBSERVANCES'));
    // ignore: use_build_context_synchronously
    GoRouter.of(ctx).go('/qibla');
    await tester.pumpAndSettle();
    expect(find.text('DIRECTION TO THE KAABA · MAKKAH'), findsOneWidget);
    expect(find.textContaining('° NE'), findsOneWidget);
    expect(find.text('clockwise from true North'), findsOneWidget);
  });
}
