import 'package:ar_rayaan/features/hadith/domain/daily_hadith.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DailyHadiths', () {
    test('exactly 60 hadiths, all sourced, all short', () {
      expect(DailyHadiths.all.length, 60);
      for (final DailyHadith h in DailyHadiths.all) {
        expect(
          h.source,
          contains(RegExp(r'Bukhari|Muslim|Tirmidhi|Dawud|Majah|Nasa|Ahmad|Hakim|Quran|Mu.jam')),
          reason: 'unsourced: ${h.text}',
        );
        expect(h.narrator, isNotEmpty);
        // One-sentence rule: short enough for a lock-screen notification.
        expect(h.text.length, lessThan(320), reason: h.text);
      }
    });

    test('selection is deterministic by date and wraps the year', () {
      final DateTime a = DateTime(2026, 3, 15);
      expect(DailyHadiths.forDate(a).text, DailyHadiths.forDate(a).text);
      // Day 1 of year → index 0; day 61 → index 0 again (60-entry cycle).
      expect(
        DailyHadiths.forDate(DateTime(2026, 1, 1)).text,
        DailyHadiths.all[0].text,
      );
      expect(
        DailyHadiths.forDate(DateTime(2026, 3, 2)).text, // day 61 (non-leap)
        DailyHadiths.all[0].text,
      );
    });

    test('the Gate hadith (Bukhari 1896) is in the rotation', () {
      expect(
        DailyHadiths.all.any((DailyHadith h) => h.source.contains('1896')),
        isTrue,
      );
    });
  });

  group('MoodMap', () {
    test('all 10 feelings present with sourced responses', () {
      expect(MoodMap.feelings.length, 10);
      const Set<String> expected = <String>{
        'peace', 'grateful', 'anxious', 'sad', 'angry',
        'lonely', 'overwhelmed', 'hopeful', 'grieving', 'sin',
      };
      expect(MoodMap.feelings.map((Feeling f) => f.id).toSet(), expected);
      for (final Feeling f in MoodMap.feelings) {
        expect(f.responses, isNotEmpty, reason: f.id);
        for (final FeelingResponse r in f.responses) {
          expect(r.source, isNotEmpty, reason: '${f.id}: ${r.text}');
          expect(r.text, isNotEmpty);
        }
      }
    });

    test('struggling-with-sin leads with 39:53 and never lectures', () {
      final Feeling sin = MoodMap.byId('sin');
      expect(sin.responses.first.text, contains('do not despair'));
      expect(sin.responses.first.source, contains('39:53'));
    });

    test('responseFor is deterministic and cycles', () {
      final DateTime d = DateTime(2026, 6, 10);
      expect(
        MoodMap.responseFor('sad', d).text,
        MoodMap.responseFor('sad', d).text,
      );
      final Feeling sad = MoodMap.byId('sad');
      // Advance by the number of responses → same response again.
      expect(
        MoodMap.responseFor(
          'sad',
          d.add(Duration(days: sad.responses.length)),
        ).text,
        MoodMap.responseFor('sad', d).text,
      );
    });

    test('byId falls back gracefully for unknown feelings', () {
      expect(MoodMap.byId('nonexistent').id, MoodMap.feelings.first.id);
    });
  });
}
