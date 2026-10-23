import 'package:ar_rayaan/features/quran/domain/quran_models.dart';
import 'package:ar_rayaan/features/search/domain/app_destinations.dart';
import 'package:ar_rayaan/features/search/domain/did_you_mean.dart';
import 'package:ar_rayaan/features/search/domain/search_text.dart';
import 'package:flutter_test/flutter_test.dart';

/// The common ways people spell Islamic words, and that they all find the
/// same thing. Pure Dart: the folding table, the sound-alike surah key and
/// the one-letter tolerance.
SurahMeta _m(int n, String tl, String en) => SurahMeta(
      number: n,
      arabicName: tl,
      transliteration: tl,
      englishMeaning: en,
      revelationType: 'meccan',
      ayahCount: 5,
    );

final List<SurahMeta> _metas = <SurahMeta>[
  _m(1, 'Al-Fatihah', 'The Opener'),
  _m(2, 'Al-Baqarah', 'The Cow'),
  _m(3, "Ali 'Imran", 'Family of Imran'),
  _m(12, 'Yusuf', 'Joseph'),
  _m(14, 'Ibrahim', 'Abraham'),
  _m(18, 'Al-Kahf', 'The Cave'),
  _m(19, 'Maryam', 'Mary'),
  _m(32, 'As-Sajdah', 'The Prostration'),
  _m(36, 'Ya-Sin', 'Ya Sin'),
  _m(47, 'Muhammad', 'Muhammad'),
  _m(55, 'Ar-Rahman', 'The Beneficent'),
  _m(56, "Al-Waqi'ah", 'The Inevitable'),
  _m(67, 'Al-Mulk', 'The Sovereignty'),
  _m(110, 'An-Nasr', 'The Help'),
  _m(112, 'Al-Ikhlas', 'The Sincerity'),
];

List<int> _surahs(String q) =>
    <int>[for (final SurahMeta m in matchSurahNames(_metas, q)) m.number];

List<String> _rooms(String q) =>
    <String>[for (final AppDestination d in matchDestinations(q)) d.id];

void main() {
  group('every spelling of a word reads as the same word', () {
    const List<List<String>> groups = <List<String>>[
      <String>['Quran', 'Koran', 'Qur\'an', 'Quraan'],
      <String>['Dua', 'Du\'a', 'Dhua', 'Duaa'],
      <String>['Eid', 'Id'],
      <String>['Hajj', 'Haj'],
      <String>['Jumuah', 'Jumu\'ah', 'Jummah', 'Friday'],
      <String>['Isa', 'Eesa', 'Jesus'],
      <String>['Musa', 'Moses'],
      <String>['Wudu', 'Wudhu', 'Ablution'],
      <String>['Salah', 'Salat', 'Namaz', 'Prayer'],
      <String>['Sawm', 'Siyam', 'Roza', 'Fasting'],
      <String>['Zakat', 'Zakah'],
      <String>['Dhikr', 'Zikr', 'Zikir'],
      <String>['Tasbih', 'Tasbeeh'],
      <String>['Ramadan', 'Ramazan', 'Ramzan'],
      <String>['Nikah', 'Nikkah', 'Marriage'],
      <String>['Madhab', 'Mazhab', 'Madhhab', 'Madhahib'],
      <String>['Qibla', 'Qiblah', 'Kibla'],
      <String>['Masjid', 'Mosque'],
      <String>['Yusuf', 'Yousuf', 'Yosef'],
      <String>['Muhammad', 'Mohammed', 'Mohamed'],
      <String>['Ibrahim', 'Ebrahim', 'Abraham'],
      <String>['Maryam', 'Mary'],
      <String>['Yasin', 'Yaseen'],
      <String>['Kahf', 'Kahaf'],
      <String>['Rahman', 'Rehman'],
      <String>['Fatiha', 'Fatihah', 'Fateha'],
      <String>['Ikhlas', 'Ikhlaas'],
      <String>['Mulk', 'Mulq'],
      <String>['Baqara', 'Baqarah'],
      <String>['Imran', 'Imraan'],
      <String>['Sajda', 'Sajdah'],
      <String>['Waqia', 'Waqiah', 'Waqi\'ah'],
    ];
    for (final List<String> g in groups) {
      test(g.join(' = '), () {
        final Set<String> stems = <String>{
          for (final String w in g) searchTokens(w).join(' '),
        };
        expect(stems.length, 1, reason: '$g -> $stems');
        // Folding is symmetrical: text in one spelling answers a query in
        // another.
        for (final String a in g) {
          for (final String b in g) {
            expect(matchesQuery('A page about $a today', b), isTrue,
                reason: '"$b" should find "$a"');
          }
        }
      });
    }

    test('the folds do not merge unrelated words', () {
      expect(matchesQuery('The prayer is a light', 'fasting'), isFalse);
      expect(matchesQuery('Patience is a light', 'mary'), isFalse);
      expect(stemWord('moses'), isNot(stemWord('isa')));
    });
  });

  group('surah names by spelling', () {
    const Map<String, int> cases = <String, int>{
      'Yaseen': 36,
      'Yasin': 36,
      'Ya-Sin': 36,
      'Kahf': 18,
      'Kahaf': 18,
      'Al Kahaf': 18,
      'Rahman': 55,
      'Rehman': 55,
      'Ar-Rehman': 55,
      'Fatiha': 1,
      'Fatihah': 1,
      'Fateha': 1,
      'Ikhlas': 112,
      'Ikhlaas': 112,
      'Mulk': 67,
      'Mulq': 67,
      'Baqara': 2,
      'Baqarah': 2,
      'Imran': 3,
      'Imraan': 3,
      'Sajda': 32,
      'Sajdah': 32,
      'Waqia': 56,
      'Waqiah': 56,
      "Waqi'ah": 56,
      'Yusuf': 12,
      'Yousuf': 12,
      'Yosef': 12,
      'Muhammad': 47,
      'Mohammed': 47,
      'Mohamed': 47,
      'Ibrahim': 14,
      'Ebrahim': 14,
      'Abraham': 14,
      'Maryam': 19,
      'Mary': 19,
      'surah yaseen': 36,
    };
    cases.forEach((String q, int n) {
      test('"$q" finds surah $n first', () {
        final List<int> r = _surahs(q);
        expect(r, isNotEmpty, reason: q);
        expect(r.first, n, reason: '$q -> $r');
      });
    });

    test('one wrong letter is forgiven from 5 letters up', () {
      expect(_surahs('baqrah'), <int>[2]);
      expect(_surahs('fatihaa'), <int>[1]);
      expect(_surahs('ikhlaz'), <int>[112]);
    });

    test('a short word gets no tolerance, and exact matches are not diluted',
        () {
      expect(_surahs('mulp'), isEmpty);
      expect(_surahs('nasx'), isEmpty);
      expect(_surahs('rahman'), <int>[55]);
    });
  });

  group('rooms by spelling', () {
    test('worship words land on the right room', () {
      expect(_rooms('Hijri').first, 'calendar');
      expect(_rooms('Islamic date').first, 'calendar');
      expect(_rooms('Qiblah').first, 'qibla');
      expect(_rooms('Kibla').first, 'qibla');
      expect(_rooms('Mosque').first, 'masajid');
      expect(_rooms('Masjid').first, 'masajid');
      expect(_rooms('Roza').first, 'ramadan');
      expect(_rooms('Ramzan').first, 'ramadan');
      expect(_rooms('Ramazan').first, 'ramadan');
      expect(_rooms('Zikr'), contains('adhkar'));
      expect(_rooms('Tasbeeh').first, 'tasbih');
      expect(_rooms('Zakah').first, 'zakat');
      expect(_rooms('Haj').first, 'hajj');
      expect(_rooms('Nikkah'), contains('marriage'));
      expect(_rooms('Madhahib').first, 'madhhab');
      expect(_rooms('Koran'), contains('quran'));
      expect(_rooms('Namaz').first, 'huda');
    });
  });

  group('did you mean', () {
    test('suggests the surah or room one letter away', () {
      expect(didYouMean(_metas, 'baqrah'), 'Al-Baqarah');
      expect(didYouMean(_metas, 'masjd'), 'masjid');
      expect(didYouMean(_metas, 'surah ikhlaz'), 'Al-Ikhlas');
    });

    test('says nothing for a word that is already right or far off', () {
      expect(didYouMean(_metas, 'baqarah'), isNull);
      expect(didYouMean(_metas, 'Yaseen'), isNull);
      expect(didYouMean(_metas, 'Rehman'), isNull);
      expect(didYouMean(_metas, 'mulq'), isNull);
      expect(didYouMean(_metas, 'prayers'), isNull);
      expect(didYouMean(_metas, 'guides'), isNull);
      expect(didYouMean(_metas, 'mercy'), isNull);
      expect(didYouMean(_metas, 'patience'), isNull);
      expect(didYouMean(_metas, 'ab'), isNull);
      expect(didYouMean(_metas, ''), isNull);
    });
  });

  test('withinOneEdit', () {
    expect(withinOneEdit('rahman', 'rahman'), isTrue);
    expect(withinOneEdit('rahman', 'rehman'), isTrue);
    expect(withinOneEdit('rahman', 'rahmn'), isTrue);
    expect(withinOneEdit('rahman', 'rahmaan'), isTrue);
    expect(withinOneEdit('rahman', 'rehmaan'), isFalse);
    expect(withinOneEdit('rahman', 'ra'), isFalse);
  });
}
