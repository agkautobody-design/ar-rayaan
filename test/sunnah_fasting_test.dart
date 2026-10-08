import 'package:ar_rayaan/features/calendar/domain/hijri_date.dart';
import 'package:ar_rayaan/features/calendar/domain/sunnah_fasting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SunnahFasting markers', () {
    test('White Days 13–15 of every month are recommended', () {
      for (int month = 1; month <= 12; month++) {
        for (final int day in <int>[13, 14, 15]) {
          final List<FastingMarker> markers = SunnahFasting.forDate(
            HijriDate(1447, month, day),
          );
          expect(
            markers.any((FastingMarker m) => m.titleEn.contains('White Days')),
            isTrue,
            reason: 'month $month day $day should carry White Days',
          );
        }
      }
      expect(
        SunnahFasting.forDate(const HijriDate(1447, 5, 12))
            .any((FastingMarker m) => m.titleEn.contains('White Days')),
        isFalse,
      );
    });

    test('Mondays and Thursdays are recommended, other weekdays are not', () {
      // Find a Monday and Thursday by walking Gregorian dates.
      int mondayFound = 0, thursdayFound = 0, fridayFound = 0;
      DateTime d = DateTime(2026, 10, 1);
      for (int i = 0; i < 14; i++) {
        final DateTime g = d.add(Duration(days: i));
        final HijriDate h = HijriDate.fromGregorian(g);
        final List<FastingMarker> m = SunnahFasting.forDate(h);
        if (g.weekday == DateTime.monday) {
          mondayFound++;
          expect(
            m.any((FastingMarker x) => x.titleEn == 'Monday Fast'),
            isTrue,
          );
        }
        if (g.weekday == DateTime.thursday) {
          thursdayFound++;
          expect(
            m.any((FastingMarker x) => x.titleEn == 'Thursday Fast'),
            isTrue,
          );
        }
        if (g.weekday == DateTime.friday) {
          fridayFound++;
          expect(
            m.any((FastingMarker x) => x.titleEn == 'Monday Fast'),
            isFalse,
          );
          expect(
            m.any((FastingMarker x) => x.titleEn == 'Thursday Fast'),
            isFalse,
          );
        }
      }
      expect(mondayFound, greaterThan(0));
      expect(thursdayFound, greaterThan(0));
      expect(fridayFound, greaterThan(0));
    });

    test('Ashura (10 Muharram) and Tasu’a (9 Muharram) are recommended', () {
      expect(
        SunnahFasting.forDate(const HijriDate(1447, 1, 10))
            .any((FastingMarker m) => m.titleEn == 'Day of Ashura'),
        isTrue,
      );
      expect(
        SunnahFasting.forDate(const HijriDate(1447, 1, 9))
            .any((FastingMarker m) => m.titleEn.contains('Tasu')),
        isTrue,
      );
    });

    test('Day of Arafah (9 Dhul-Hijjah) is recommended for non-pilgrims', () {
      final List<FastingMarker> markers = SunnahFasting.forDate(
        const HijriDate(1447, 12, 9),
      );
      expect(
        markers.any((FastingMarker m) => m.titleEn.contains('Arafah')),
        isTrue,
      );
      expect(
        markers.firstWhere((FastingMarker m) => m.titleEn.contains('Arafah')).why,
        contains('expiates'),
      );
    });

    test('Eids and Tashreeq are forbidden', () {
      expect(SunnahFasting.isForbidden(const HijriDate(1447, 10, 1)), isTrue);
      expect(SunnahFasting.isForbidden(const HijriDate(1447, 12, 10)), isTrue);
      for (final int d in <int>[11, 12, 13]) {
        expect(
          SunnahFasting.isForbidden(HijriDate(1447, 12, d)),
          isTrue,
          reason: 'Tashreeq day $d forbidden',
        );
      }
      expect(SunnahFasting.isForbidden(const HijriDate(1447, 12, 14)), isFalse);
    });

    test('Six of Shawwal reminder present in Shawwal only', () {
      expect(
        SunnahFasting.forDate(const HijriDate(1447, 10, 20))
            .any((FastingMarker m) => m.titleEn == 'Six of Shawwal'),
        isTrue,
      );
      expect(
        SunnahFasting.forDate(const HijriDate(1447, 11, 20))
            .any((FastingMarker m) => m.titleEn == 'Six of Shawwal'),
        isFalse,
      );
    });

    test('every marker carries a source and non-empty knowledge card', () {
      // Audit every day of a full Hijri year — the authenticity gate.
      for (int month = 1; month <= 12; month++) {
        final int days = HijriDate.monthLength(1447, month);
        for (int d = 1; d <= days; d++) {
          for (final FastingMarker m
              in SunnahFasting.forDate(HijriDate(1447, month, d))) {
            expect(m.source, contains(RegExp(r'Bukhari|Muslim|Tirmidhi|Nasa')));
            expect(m.why.length, greaterThan(40));
            expect(m.titleEn, isNotEmpty);
            expect(m.titleAr, isNotEmpty);
          }
        }
      }
    });

    test('monthly planner excludes forbidden days and is sorted', () {
      final List<(HijriDate, List<FastingMarker>)> days =
          SunnahFasting.recommendedInMonth(1447, 12);
      expect(
        days.any(
          ((HijriDate, List<FastingMarker>) e) =>
              e.$1.day == 10 ||
              e.$1.day == 11 ||
              e.$1.day == 12 ||
              e.$1.day == 13,
        ),
        isFalse,
        reason: 'Eid/Tashreeq must not appear in the fasting planner',
      );
      expect(
        days.any(((HijriDate, List<FastingMarker>) e) => e.$1.day == 9),
        isTrue,
        reason: 'Arafah must appear',
      );
      for (int i = 1; i < days.length; i++) {
        expect(days[i].$1.day, greaterThan(days[i - 1].$1.day));
      }
    });

    test('Shawwal planner shows the six-day reminder once, not daily', () {
      final List<(HijriDate, List<FastingMarker>)> days =
          SunnahFasting.recommendedInMonth(1447, 10);
      final int shawwalNotes = days
          .where(
            ((HijriDate, List<FastingMarker>) e) => e.$2.any(
              (FastingMarker m) => m.titleEn == 'Six of Shawwal',
            ),
          )
          .length;
      expect(shawwalNotes, lessThanOrEqualTo(4)); // 2nd + White Days only
    });
  });
}
