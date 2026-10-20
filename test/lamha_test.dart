import 'package:ar_rayaan/features/lamha/domain/lamha.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LamhaEngine constitution', () {
    test('never more than 2 default moments per week (+ seasonal specials)', () {
      // Sweep 8 weeks across a year boundary.
      DateTime d = DateTime(2026, 1, 5);
      for (int w = 0; w < 8; w++) {
        final List<LamhaMoment> week = LamhaEngine.defaultWeek(
          d.add(Duration(days: w * 7)),
        );
        final int nonSeasonal = week
            .where(
              (LamhaMoment m) =>
                  m.id == 'friday' ||
                  LamhaEngine.optInAnchors.every((a) => a.id != m.id) &&
                      !m.id.contains('eid') &&
                      !m.id.contains('ashura') &&
                      !m.id.contains('arafah') &&
                      !m.id.contains('ramadan') &&
                      !m.id.contains('white'),
            )
            .length;
        expect(
          nonSeasonal,
          lessThanOrEqualTo(2),
          reason: 'week starting ${d.add(Duration(days: w * 7))}',
        );
      }
    });

    test('Friday always carries the Jumu’ah message', () {
      // 2026-10-02 is a Friday.
      final LamhaMoment? m = LamhaEngine.forDate(DateTime(2026, 10, 2));
      expect(m, isNotNull);
      expect(m!.id, 'friday');
      expect(m.source, isNotEmpty);
    });

    test('Tuesdays and Saturdays are quiet by default', () {
      // 2026-10-06 is a Tuesday, 2026-10-03 is a Saturday.
      expect(LamhaEngine.forDate(DateTime(2026, 10, 6)), isNull);
      expect(LamhaEngine.forDate(DateTime(2026, 10, 3)), isNull);
    });

    test('Wednesday rotation is deterministic and cycles the library', () {
      final DateTime wed1 = DateTime(2026, 10, 7);
      final DateTime wed2 = wed1.add(const Duration(days: 7));
      final LamhaMoment? a = LamhaEngine.forDate(wed1);
      final LamhaMoment? b = LamhaEngine.forDate(wed2);
      expect(a, isNotNull);
      expect(b, isNotNull);
      expect(a!.id, LamhaEngine.forDate(wed1)!.id); // deterministic
      expect(a.id, isNot(b!.id)); // cycles
      // After a full library cycle it repeats.
      final LamhaMoment c = LamhaEngine.forDate(
        wed1.add(Duration(days: 7 * 8)),
      )!;
      expect(c.id, a.id);
    });

    test('seasonal specials override the rotation', () {
      // Find the Gregorian date of 12 Rajab 1447 (white-days eve) — walk and
      // verify any seasonal takes precedence and is sourced.
      DateTime d = DateTime(2026, 12, 15);
      bool found = false;
      for (int i = 0; i < 40; i++) {
        final LamhaMoment? m = LamhaEngine.forDate(d.add(Duration(days: i)));
        if (m != null && m.id == 'white-days-eve') {
          found = true;
          expect(m.source, contains('Nasa'));
        }
      }
      expect(found, isTrue, reason: 'a 12th-of-month eve should occur');
    });

    test('every moment in a full year is sourced', () {
      DateTime d = DateTime(2026, 1, 1);
      int moments = 0;
      for (int i = 0; i < 366; i++) {
        final LamhaMoment? m = LamhaEngine.forDate(d.add(Duration(days: i)));
        if (m != null) {
          moments++;
          expect(m.source, isNotEmpty, reason: m.id);
          expect(m.title, isNotEmpty);
          expect(m.body.length, greaterThan(40));
        }
      }
      expect(moments, greaterThan(80)); // ~2/wk + seasonals
      expect(moments, lessThan(140)); // ceiling sanity
    });
  });

  group('Lamha honesty', () {
    test('the Sunday moment promises what its body delivers', () {
      final LamhaMoment sunday = LamhaEngine.optInAnchors
          .firstWhere((LamhaMoment m) => m.id == 'sunday-evening');
      // Title and body used to disagree ("two rak'ah" vs reciting Al-Mulk).
      expect(sunday.title, isNot(contains('rak')));
      expect(sunday.title, contains('Al-Mulk'));
      expect(sunday.body.toLowerCase(), contains('al-mulk'));
      expect(sunday.source, contains('3404'));
    });

    test('no moment labels the weak home-entry dua as sahih', () {
      DateTime d = DateTime(2026, 1, 1);
      for (int i = 0; i < 366; i++) {
        final LamhaMoment? m = LamhaEngine.forDate(d.add(Duration(days: i)));
        if (m != null && m.source.contains('5096')) {
          expect(m.source.toLowerCase(), contains('daʿif'));
          expect(m.source.toLowerCase(), isNot(contains('sahih')));
        }
      }
    });

    test('every Wednesday has a moment and the rotation really rotates', () {
      final Set<String> ids = <String>{};
      // 2026 spans both daylight-saving changes in the northern hemisphere.
      for (DateTime d = DateTime(2026, 1, 7);
          d.year == 2026;
          d = d.add(const Duration(days: 7))) {
        expect(d.weekday, DateTime.wednesday);
        final LamhaMoment? m = LamhaEngine.forDate(d);
        expect(m, isNotNull, reason: '$d');
        ids.add(m!.id);
      }
      expect(ids.length, greaterThan(8));
    });
  });
}
