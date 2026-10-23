import 'package:ar_rayaan/features/quran/domain/quran_models.dart';
import 'package:ar_rayaan/features/search/domain/app_destinations.dart';
import 'package:ar_rayaan/features/search/domain/did_you_mean.dart';
import 'package:ar_rayaan/features/search/domain/quran_search.dart';
import 'package:ar_rayaan/features/search/domain/search_text.dart';
import 'package:flutter_test/flutter_test.dart';

/// Round 5: a very long query froze Find Anything (120 characters took
/// 19 s, 2,400 characters never came back). The query is now cut to a short
/// bound and every matcher is linear, so any input answers at once.
void main() {
  List<Surah> corpus() => <Surah>[
        for (int s = 1; s <= 114; s++)
          Surah(
            meta: SurahMeta(
              number: s,
              arabicName: 'سورة',
              transliteration: 'Al-Name$s',
              englishMeaning: 'Meaning $s',
              revelationType: 'meccan',
              ayahCount: 55,
            ),
            ayahs: <Ayah>[
              for (int a = 1; a <= 55; a++)
                Ayah(
                  number: a,
                  arabic: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ $a',
                  english: 'In the name of Allah, the Most Merciful $s $a '
                      'and the believers who establish prayer',
                ),
            ],
          ),
      ];

  group('normalizeSearchQuery', () {
    test('trims, collapses spaces and keeps short queries as they are', () {
      expect(normalizeSearchQuery('  qibla   finder '), 'qibla finder');
      expect(normalizeSearchQuery(''), '');
      expect(normalizeSearchQuery('   '), '');
    });

    test('cuts a long paste to the character and word caps', () {
      final String huge = List<String>.filled(1000, 'patience').join(' ');
      final String out = normalizeSearchQuery(huge);
      expect(out.length, lessThanOrEqualTo(kMaxSearchQueryChars));
      expect(out.split(' ').length, lessThanOrEqualTo(kMaxSearchQueryWords));
      expect(out.startsWith('patience'), isTrue);
    });

    test('one endless word is cut, not kept', () {
      final String out = normalizeSearchQuery('a' * 5000);
      expect(out.length, kMaxSearchQueryChars);
    });
  });

  group('a 5000-character query answers at once', () {
    final String wall = List<String>.generate(
      900,
      (int i) => <String>['mercy', 'the', 'prayer', 'abcdefgh', 'patience'][i % 5],
    ).join(' ');
    final String arabicWall = List<String>.filled(900, 'بسم الله').join(' ');

    test('the Qur\'an search (English and Arabic) is bounded', () {
      final List<Surah> surahs = corpus();
      final Stopwatch w = Stopwatch()..start();
      searchQuran(surahs, wall, limit: 200);
      searchQuran(surahs, arabicWall, limit: 200);
      searchQuran(surahs, 'x' * 5000, limit: 200);
      w.stop();
      expect(w.elapsedMilliseconds, lessThan(5000),
          reason: 'three 5000-character queries took ${w.elapsed}');
    });

    test('word, destination, surah-name and suggestion matching are bounded',
        () {
      final List<SurahMeta> metas =
          corpus().map((Surah s) => s.meta).toList();
      final Stopwatch w = Stopwatch()..start();
      for (int i = 0; i < 20; i++) {
        matchesQuery('Actions are judged by motives ' * 40, wall);
        matchDestinations(wall);
        matchSurahNames(metas, wall);
        didYouMean(metas, wall);
      }
      w.stop();
      expect(w.elapsedMilliseconds, lessThan(5000),
          reason: 'took ${w.elapsed}');
    });
  });

  group('ranking and natural phrases', () {
    test('filler words are ignored', () {
      expect(
        matchesQuery('The prayer is a light', 'what is the prayer'),
        isTrue,
      );
      expect(
        searchTokens('how do I find the qibla', dropStopwords: true),
        <String>['qibla'],
      );
    });

    test('"difference of opinion" finds the schools-of-law room', () {
      final List<String> ids = <String>[
        for (final AppDestination d in matchDestinations('difference of opinion'))
          d.id,
      ];
      expect(ids.first, 'madhhab');
      expect(
        matchesQuery('What a madhhab is, with one example', 'difference of opinion'),
        isTrue,
      );
    });

    test('"privacy" finds the Privacy Policy', () {
      expect(matchDestinations('privacy').first.id, 'privacy');
      expect(matchDestinations('privacy').first.route, '/legal/privacy');
    });

    test('a one-letter-off surah is not offered when a room answers', () {
      final List<SurahMeta> metas = <SurahMeta>[
        const SurahMeta(
          number: 15,
          arabicName: 'الحجر',
          transliteration: 'Al-Hijr',
          englishMeaning: 'The Rocky Tract',
          revelationType: 'meccan',
          ayahCount: 99,
        ),
      ];
      expect(matchSurahNames(metas, 'hijri'), isNotEmpty);
      expect(matchSurahNames(metas, 'hijri', allowNear: false), isEmpty);
    });

    test('the phrase aliases all point at words a shelf really uses', () {
      expect(queryAliases('differences of opinions'), contains('madhhab'));
      expect(queryAliases('qibla'), isEmpty);
    });
  });
}
