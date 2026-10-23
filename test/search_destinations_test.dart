import 'dart:io';

import 'package:ar_rayaan/app/core/route_titles.dart';
import 'package:ar_rayaan/features/quran/domain/quran_models.dart';
import 'package:ar_rayaan/features/search/domain/app_destinations.dart';
import 'package:ar_rayaan/features/search/domain/search_text.dart';
import 'package:flutter_test/flutter_test.dart';

import 'audit/router_source.dart';

/// Pure-Dart tests of the global search's matching: the app's own rooms,
/// surah names, and the light synonym / stemming fold.
void main() {
  List<String> ids(String q, {bool academyOn = true}) => <String>[
        for (final AppDestination d in matchDestinations(q, academyOn: academyOn))
          d.id,
      ];

  group('app destinations', () {
    test('every destination is a real route with a page title', () {
      final RouterSource router = RouterSource.read();
      final Set<String> seen = <String>{};
      for (final AppDestination d in kAppDestinations) {
        expect(seen.add(d.id), isTrue, reason: 'duplicate id ${d.id}');
        expect(router.resolves(d.route), isTrue,
            reason: '${d.id} -> ${d.route} is not in router.dart');
        expect(RouteTitles.forPath(d.route.split('?').first), isNot(RouteTitles.appName),
            reason: '${d.route} has no title in route_titles.dart');
        expect(d.keywords, isNotEmpty);
        expect(d.title.trim(), isNotEmpty);
        expect(d.subtitle.trim(), isNotEmpty);
      }
    });

    test('the study queries land on the right room', () {
      expect(ids('qibla').first, 'qibla');
      expect(ids('tasbih').first, 'tasbih');
      expect(ids('Tasbeeh counter').first, 'tasbih');
      expect(ids('99 names').first, 'names99');
      expect(ids('asma ul husna').first, 'names99');
      expect(ids('asmaul husna').first, 'names99');
      expect(ids('names of allah').first, 'names99');
      expect(ids('how to pray').first, 'huda');
      expect(ids('salah').first, 'huda');
      expect(ids('hifz').first, 'hifz');
      expect(ids('memorizing'), contains('hifz'));
      expect(ids('tajweed').first, 'tajweed');
      expect(ids('calendar').first, 'calendar');
      expect(ids('hijri').first, 'calendar');
      expect(ids('masjid').first, 'masajid');
      expect(ids('halal food').first, 'masajid');
      expect(ids('masjid near me').first, 'masajid');
      expect(ids('family tree').first, 'family-tree');
      expect(ids('letters').first, 'letters');
      expect(ids('alphabet').first, 'letters');
      expect(ids('trivia').first, 'trivia');
      expect(ids('charity'), contains('zakat'));
      expect(ids('zakat').first, 'zakat');
      expect(ids('dua for sleeping'), contains('adhkar'));
      expect(ids('madhab').first, 'madhhab');
      expect(ids('schools of thought').first, 'madhhab');
    });

    test('words with no room return nothing', () {
      expect(ids('mercy'), isEmpty);
      expect(ids('zzzz'), isEmpty);
      expect(ids('ab'), isEmpty);
      expect(ids(''), isEmpty);
    });

    test('round 3: findability queries land on an existing guide or room', () {
      expect(ids('tahajjud').first, 'night-prayer');
      expect(ids('tahajud').first, 'night-prayer');
      expect(ids('night prayer'), contains('night-prayer'));
      expect(ids('patience').first, 'patience');
      expect(ids('sabr').first, 'patience');
      expect(ids('nikah').first, 'nikah-guide');
      expect(ids('marriage').first, 'nikah-guide');
      expect(ids('marriage'), contains('marriage'));
      expect(ids('madhab').first, 'madhhab');
      expect(ids('jumuah').first, 'jumuah');
      expect(ids('Jumu\'ah time').first, 'jumuah');
      expect(ids('hijri converter').first, 'calendar');
      expect(ids('new to islam').first, 'new-muslim');
    });

    test('round 4: the tahajjud, witr, what-is-Islam and schools guides', () {
      expect(ids('tahajjud').first, 'night-prayer');
      expect(ids('witr').first, 'witr-guide');
      expect(ids('qunut').first, 'witr-guide');
      expect(ids('what is islam').first, 'what-is-islam');
      expect(ids('meaning of islam').first, 'what-is-islam');
      expect(ids('madhhab').first, 'madhhab');
      expect(ids('hands in prayer').first, 'madhhab');
      const Map<String, String> routes = <String, String>{
        'night-prayer': '/huda/guide?id=huda-tahajjud',
        'witr-guide': '/huda/guide?id=huda-witr',
        'what-is-islam': '/huda/guide?id=huda-what-is-islam',
        'madhhab': '/huda/guide?id=huda-madhhab-overview',
      };
      for (final MapEntry<String, String> e in routes.entries) {
        final AppDestination d =
            kAppDestinations.firstWhere((AppDestination x) => x.id == e.key);
        expect(d.route, e.value);
      }
    });

    test('guide destinations point at a real guide id in the pack', () {
      final String pack = File('assets/guides/guides.json').readAsStringSync();
      for (final AppDestination d in kAppDestinations) {
        if (!d.route.startsWith('/huda/guide?id=')) continue;
        final String id = d.route.split('=').last;
        expect(pack, contains('"id": "$id"'), reason: '${d.id} -> $id');
      }
    });

    test('Academy rooms vanish with the Academy switch', () {
      expect(ids('tasbih'), contains('tasbih'));
      expect(ids('tasbih', academyOn: false), isNot(contains('tasbih')));
      expect(ids('hifz', academyOn: false), isEmpty);
      expect(ids('qibla', academyOn: false).first, 'qibla');
    });

    test('an exact keyword outranks a partial one', () {
      // "prayer" is the whole keyword of the Huda entry, and only part of
      // "prayer times".
      final List<String> r = ids('prayer');
      expect(r.indexOf('huda') < r.indexOf('prayer-times'), isTrue);
    });
  });

  group('synonym and stem folding', () {
    const String hadith1 =
        'Actions are (judged) by motives (niyyah), so each man will have '
        'what he intended.';

    test('"intentions" finds the hadith that says "motives"', () {
      expect(matchesQuery(hadith1, 'actions are judged by intentions'), isTrue);
      expect(matchesQuery(hadith1, 'intentions'), isTrue);
      expect(matchesQuery(hadith1, 'intention'), isTrue);
      expect(matchesQuery(hadith1, 'judged'), isTrue);
      expect(matchesQuery(hadith1, 'banana'), isFalse);
      expect(matchesQuery(hadith1, 'actions are judged by banana'), isFalse);
    });

    test('plain phrases and short words still match as before', () {
      expect(matchesQuery('Patience is a light', 'patience'), isTrue);
      expect(matchesQuery('Patience is a light', 'light'), isTrue);
      expect(matchesQuery('Patience is a light', 'pat'), isTrue);
      expect(matchesQuery('Patience is a light', 'zzz'), isFalse);
      expect(matchesQuery('', 'light'), isFalse);
      expect(matchesQuery('light', ''), isFalse);
    });

    test('guide titles are found by the wording people use', () {
      expect(matchesQuery('How to Pray — The Essentials', 'salah'), isTrue);
      expect(matchesQuery('Marriage — The Nikah', 'nikah'), isTrue);
      expect(matchesQuery('Marriage — The Nikah', 'marriage'), isTrue);
      expect(matchesQuery('Marriage — The Nikah', 'wedding'), isTrue);
      expect(matchesQuery('Wudu — The Purifying Wash', 'ablution'), isTrue);
      expect(matchesQuery('Sleeping Manners', 'sleep'), isTrue);
      expect(matchesQuery('Giving. Sadaqah: the voluntary charity', 'charity'),
          isTrue);
    });

    test('stemming is stable', () {
      expect(stemWord('motives'), stemWord('motive'));
      expect(stemWord('judged'), stemWord('judge'));
      expect(stemWord('intentions'), stemWord('motives'));
      expect(searchTokens('Qur’an'), <String>['quran']);
    });
  });

  group('surah names', () {
    const List<SurahMeta> metas = <SurahMeta>[
      SurahMeta(
        number: 2,
        arabicName: 'البقرة',
        transliteration: 'Al-Baqarah',
        englishMeaning: 'The Cow',
        revelationType: 'medinan',
        ayahCount: 286,
      ),
      SurahMeta(
        number: 36,
        arabicName: 'يس',
        transliteration: 'Ya-Sin',
        englishMeaning: 'Ya Sin',
        revelationType: 'meccan',
        ayahCount: 83,
      ),
      SurahMeta(
        number: 55,
        arabicName: 'الرحمن',
        transliteration: 'Ar-Rahman',
        englishMeaning: 'The Beneficent',
        revelationType: 'medinan',
        ayahCount: 78,
      ),
      SurahMeta(
        number: 67,
        arabicName: 'الملك',
        transliteration: 'Al-Mulk',
        englishMeaning: 'The Sovereignty',
        revelationType: 'meccan',
        ayahCount: 30,
      ),
    ];

    List<int> nums(String q) =>
        <int>[for (final SurahMeta m in matchSurahNames(metas, q)) m.number];

    test('finds a surah by its name, with or without the article', () {
      expect(nums('mulk'), <int>[67]);
      expect(nums('Al-Mulk'), <int>[67]);
      expect(nums('al mulk'), <int>[67]);
      expect(nums('surah mulk'), <int>[67]);
      expect(nums('rahman'), <int>[55]);
      expect(nums('yasin'), <int>[36]);
      expect(nums('ya-sin'), <int>[36]);
      expect(nums('baqarah'), <int>[2]);
    });

    test('finds by number only with "surah", and by English meaning', () {
      expect(nums('surah 36'), <int>[36]);
      expect(nums('chapter 67'), <int>[67]);
      expect(nums('36'), isEmpty);
      expect(nums('cow'), <int>[2]);
      expect(nums('sovereign'), <int>[67]);
    });

    test('finds by Arabic name and ignores noise', () {
      expect(nums('الملك'), <int>[67]);
      expect(nums('zz'), isEmpty);
      expect(nums('xyzq'), isEmpty);
      expect(nums(''), isEmpty);
    });
  });
}
