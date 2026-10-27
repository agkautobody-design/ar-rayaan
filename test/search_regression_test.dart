// A regression set of realistic search queries, run against the REAL bundled
// data (the whole Qur'an, the Forty Hadith, every story pack, the Q&A bank).
// Each row says what a person typing that query must be shown. Pure Dart: no
// widgets, so it runs fast and cannot be fooled by a stubbed shelf.
import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/features/hadith/domain/hadith_models.dart';
import 'package:ar_rayaan/features/quran/domain/quran_models.dart';
import 'package:ar_rayaan/features/search/domain/quran_find.dart';
import 'package:ar_rayaan/features/search/domain/search_docs.dart';
import 'package:ar_rayaan/features/search/domain/search_engine.dart';
import 'package:ar_rayaan/features/stories/domain/story.dart';
import 'package:flutter_test/flutter_test.dart';

class _Qa {
  const _Qa(this.q, this.a);
  final String q;
  final String a;
}

class _Corpus {
  _Corpus._(this.surahs, this.translit, this.hadith, this.stories, this.qa);

  final List<Surah> surahs;
  final Map<String, String> translit;
  final List<Hadith> hadith;
  final List<Story> stories;
  final List<_Qa> qa;

  static _Corpus load() {
    final List<dynamic> q =
        jsonDecode(File('assets/quran/quran.json').readAsStringSync())
            as List<dynamic>;
    final List<Surah> surahs = <Surah>[
      for (final Map<String, dynamic> s in q.cast<Map<String, dynamic>>())
        Surah(
          meta: SurahMeta(
            number: s['n'] as int,
            arabicName: s['ar'] as String,
            transliteration: s['tl'] as String,
            englishMeaning: s['en'] as String,
            revelationType: s['ty'] as String,
            ayahCount: s['c'] as int,
          ),
          ayahs: <Ayah>[
            for (final List<dynamic> v
                in (s['v'] as List<dynamic>).cast<List<dynamic>>())
              Ayah(
                number: v[0] as int,
                arabic: v[1] as String,
                english: v[2] as String,
              ),
          ],
        ),
    ];
    final Map<String, String> tl = ((jsonDecode(
      File('assets/quran/transliteration.json').readAsStringSync(),
    ) as Map<String, dynamic>)['map'] as Map<String, dynamic>)
        .cast<String, String>();
    final List<dynamic> hs = jsonDecode(
      File('assets/hadith/nawawi40.json').readAsStringSync(),
    ) as List<dynamic>;
    final List<Hadith> hadith = <Hadith>[
      for (final Map<String, dynamic> e in hs.cast<Map<String, dynamic>>())
        Hadith(
          number: e['n'] as int,
          arabic: e['ar'] as String,
          english: e['en'] as String,
          source: e['src'] as String?,
          grade: HadithGrade.fromJson(e),
        ),
    ];
    final List<Story> stories = <Story>[];
    final List<File> files = Directory('assets/stories')
        .listSync()
        .whereType<File>()
        .where((File f) => f.path.endsWith('.json'))
        .toList()
      ..sort((File a, File b) => a.path.compareTo(b.path));
    for (final File f in files) {
      final Object? d = jsonDecode(f.readAsStringSync());
      if (d is List<dynamic>) {
        for (final Object? e in d) {
          stories.add(Story.fromJson(Map<String, dynamic>.from(e! as Map)));
        }
      }
    }
    final List<dynamic> qs = (jsonDecode(
      File('assets/qa/qa_bank.json').readAsStringSync(),
    ) as Map<String, dynamic>)['questions'] as List<dynamic>;
    final List<_Qa> qa = <_Qa>[
      for (final Map<String, dynamic> e in qs.cast<Map<String, dynamic>>())
        _Qa(e['q'] as String, e['a'] as String),
    ];
    return _Corpus._(surahs, tl, hadith, stories, qa);
  }
}

final _Corpus corpus = _Corpus.load();

/// Qur'an hit keys for [q], best first.
List<String> quran(String q) => <String>[
      for (final h in findQuran(corpus.surahs, q, translit: corpus.translit))
        h.key,
    ];

/// The other shelves for [q], best first, as `H<n>`, `S:<id>`, `QA:<question>`
/// — the same order the screen uses (score, then shelf order).
List<String> others(String q) {
  final QuerySpec spec = QuerySpec.parse(q);
  final List<(int, String)> found = <(int, String)>[];
  for (final Hadith h in corpus.hadith) {
    final int s = scoreDoc(docFor(h, () => hadithDoc(h)), spec);
    if (s > 0) found.add((s, 'H${h.number}'));
  }
  for (final Story st in corpus.stories) {
    final int s = scoreDoc(docFor(st, () => storyDoc(st)), spec);
    if (s > 0) found.add((s, 'S:${st.id}'));
  }
  for (final _Qa e in corpus.qa) {
    final int s = scoreDoc(docFor(e, () => qaDoc(e.q, e.a)), spec);
    if (s > 0) found.add((s, 'QA:${e.q}'));
  }
  final List<(int, (int, String))> idx = <(int, (int, String))>[
    for (int i = 0; i < found.length; i++) (i, found[i]),
  ]..sort(((int, (int, String)) a, (int, (int, String)) b) {
      final int c = b.$2.$1.compareTo(a.$2.$1);
      return c != 0 ? c : a.$1.compareTo(b.$1);
    });
  return <String>[for (final (int, (int, String)) e in idx) e.$2.$2];
}

/// One realistic query and what must be shown for it.
class _Case {
  const _Case(
    this.query, {
    this.quranFirst,
    this.quranAmong = const <String>[],
    this.quranAny = false,
    this.otherTop,
    this.otherIn = const <String>[],
    this.otherWithin = 5,
  });

  final String query;

  /// The first Qur'an hit must be this verse.
  final String? quranFirst;

  /// These verses must all be among the Qur'an hits.
  final List<String> quranAmong;

  /// There must be at least one Qur'an hit.
  final bool quranAny;

  /// The first non-Qur'an result must be this.
  final String? otherTop;

  /// These must all be within the first [otherWithin] non-Qur'an results.
  final List<String> otherIn;
  final int otherWithin;
}

const List<_Case> _cases = <_Case>[
  // The audit's named failures.
  _Case('ayat al kursi', quranFirst: '2:255'),
  _Case('ayatul kursi', quranFirst: '2:255'),
  _Case('ayat-ul-kursi', quranFirst: '2:255'),
  _Case('aayat al kursi', quranFirst: '2:255'),
  _Case('Ayat al-Kursi meaning', quranFirst: '2:255'),
  _Case('throne verse', quranFirst: '2:255'),
  _Case('verse of the throne', quranFirst: '2:255'),
  _Case('kursi', quranFirst: '2:255'),
  _Case('آية الكرسي', quranFirst: '2:255'),
  _Case('الحي القيوم', quranAmong: <String>['2:255', '3:2']),
  _Case('salah', quranAny: true, quranAmong: <String>['2:43']),
  _Case('salat', quranAny: true, quranAmong: <String>['2:43']),
  _Case('how to pray', quranAny: true),
  _Case('prophet yusuf', otherTop: 'S:prophet-yusuf'),
  _Case('yusuf', otherTop: 'S:prophet-yusuf'),
  _Case('joseph', otherTop: 'S:prophet-yusuf'),
  _Case('yousuf', otherTop: 'S:prophet-yusuf'),
  _Case('dua before sleep', otherTop: 'S:dua-sleep'),
  // Verse keys.
  _Case('2:255', quranFirst: '2:255'),
  _Case('2.255', quranFirst: '2:255'),
  _Case('٢:٢٥٥', quranFirst: '2:255'),
  _Case('112:1', quranFirst: '112:1'),
  // Named verses.
  _Case('last two verses of baqarah', quranAmong: <String>['2:285', '2:286']),
  _Case('light verse', quranFirst: '24:35'),
  _Case('verse of debt', quranFirst: '2:282'),
  // Words people type that the English does not use.
  _Case('sabr', quranAmong: <String>['2:153']),
  _Case('patience', quranAmong: <String>['2:153'], otherTop: 'S:kh-yaqub'),
  _Case('riba', quranAmong: <String>['2:275', '2:276']),
  _Case('usury', quranAny: true),
  _Case('iblis', quranAmong: <String>['15:31'], otherTop: 'S:ghayb-iblis-refuses'),
  _Case('shaytan', quranAny: true),
  _Case('backbiting', quranAmong: <String>['49:12']),
  _Case('shahadah', quranAny: true, otherTop: 'S:newmuslim-01'),
  _Case('tasbih', quranAny: true),
  _Case('sirat', quranAmong: <String>['1:6']),
  _Case('straight path', quranAmong: <String>['1:6']),
  _Case('jannah', quranAny: true),
  _Case('paradise', quranAny: true),
  _Case('hellfire', quranAny: true),
  _Case('tawbah', quranAny: true, otherTop: 'QA:What are the conditions of Tawbah?'),
  _Case('repentance', quranAny: true),
  _Case('dhikr', quranAny: true),
  _Case('music', otherTop: 'QA:What is the ruling on music?'),
  _Case('mortgage', otherTop: 'QA:Is a mortgage haram?'),
  _Case('menstruation prayer',
      otherTop: 'QA:How should a woman pray during menstruation?'),
  // Transliteration.
  _Case('bismillahir rahmanir raheem', quranFirst: '1:1'),
  _Case('ihdinas siraatal mustaqeem', quranFirst: '1:6'),
  // Arabic.
  _Case('بسم الله الرحمن الرحيم', quranAmong: <String>['1:1']),
  _Case('الصلاة', quranAny: true),
  _Case('الصراط المستقيم', quranAmong: <String>['1:6']),
  // English phrases.
  _Case('created me guides me', quranAmong: <String>['26:78']),
  _Case('mercy', quranAny: true),
  _Case('forgive', quranAny: true),
  // Names with variant spellings: the story must come first.
  _Case('moses', otherTop: 'S:prophet-musa'),
  _Case('moosa', otherTop: 'S:prophet-musa'),
  _Case('abraham', otherTop: 'S:prophet-ibrahim'),
  _Case('ebrahim', otherTop: 'S:prophet-ibrahim'),
  _Case('jesus', otherTop: 'S:prophet-isa'),
  _Case('eesa', otherTop: 'S:prophet-isa'),
  _Case('noah', otherTop: 'S:prophet-nuh'),
  _Case('nuh', otherTop: 'S:prophet-nuh'),
  _Case('adam', otherTop: 'S:prophet-adam'),
  _Case('mary', otherTop: 'S:woman-maryam'),
  _Case('khadijah', otherTop: 'S:woman-khadijah'),
  _Case('aisha', otherTop: 'S:woman-aisha'),
  _Case('umar', otherTop: 'S:comp-umar'),
  _Case('bilal', otherIn: <String>['S:comp-bilal']),
  _Case('hijrah', otherIn: <String>['S:seerah-09']),
  _Case('badr', otherIn: <String>['S:seerah-17']),
  _Case('uhud', otherIn: <String>['S:seerah-19']),
  _Case('dajjal', otherIn: <String>['S:sign-08']),
  // Hadith: by meaning, by number, by grade.
  _Case('intentions', otherIn: <String>['H1'], otherWithin: 10),
  _Case('actions are judged by intentions', otherTop: 'H1'),
  _Case('sincere advice', otherTop: 'H7'),
  _Case('hadith 30', otherTop: 'H30'),
  _Case('hadith 19', otherTop: 'H19'),
  _Case('sahih', otherIn: <String>['H1'], otherWithin: 60),
  _Case('hasan', otherIn: <String>['H41'], otherWithin: 60),
  // Worship words and their spellings.
  _Case('wudu', otherIn: <String>['S:newmuslim-04']),
  _Case('wudhu', otherIn: <String>['S:newmuslim-04']),
  _Case('ablution', otherIn: <String>['S:newmuslim-04']),
  _Case('fasting', quranAmong: <String>['2:183']),
  _Case('sawm', quranAmong: <String>['2:183']),
  _Case('roza', quranAmong: <String>['2:183']),
  _Case('ramadan', quranAmong: <String>['2:185']),
  _Case('ramzan', quranAmong: <String>['2:185']),
  _Case('zakat', quranAny: true),
  _Case('zakah', quranAny: true),
  _Case('hajj', quranAmong: <String>['22:27']),
  _Case('haj', quranAmong: <String>['22:27']),
  _Case('charity', quranAny: true),
  _Case('sadaqah', quranAny: true),
  _Case('marriage', quranAny: true),
  _Case('nikah', quranAny: true),
  _Case('divorce', quranAmong: <String>['2:227']),
  _Case('angels', quranAny: true),
  _Case('judgement day', quranAny: true),
  _Case('day of judgment', quranAny: true),
];

void main() {
  test('the set has at least 60 realistic queries', () {
    expect(_cases.length, greaterThanOrEqualTo(60));
  });

  test('the whole Qur\'an and every shelf loaded', () {
    expect(corpus.surahs.length, 114);
    expect(
      corpus.surahs.fold<int>(0, (int n, Surah s) => n + s.ayahs.length),
      6236,
    );
    expect(corpus.hadith.length, 42);
    expect(corpus.stories.length, greaterThan(250));
    expect(corpus.qa.length, greaterThan(5));
  });

  group('each query shows what the person is after', () {
    for (final _Case c in _cases) {
      test('"${c.query}"', () {
        final List<String> q = quran(c.query);
        final List<String> o = others(c.query);
        if (c.quranFirst != null) {
          expect(q, isNotEmpty, reason: 'no Qur\'an hit');
          expect(q.first, c.quranFirst, reason: 'first Qur\'an hit');
        }
        for (final String k in c.quranAmong) {
          expect(q, contains(k), reason: 'Qur\'an hits $q');
        }
        if (c.quranAny) expect(q, isNotEmpty, reason: 'no Qur\'an hit');
        if (c.otherTop != null) {
          expect(o, isNotEmpty, reason: 'no other hit');
          expect(o.first, c.otherTop, reason: 'top of ${o.take(5).toList()}');
        }
        for (final String k in c.otherIn) {
          expect(
            o.take(c.otherWithin).toList(),
            contains(k),
            reason: 'top ${c.otherWithin}: ${o.take(c.otherWithin).toList()}',
          );
        }
      });
    }
  });

  group('ranking and paging', () {
    test('a named verse is the whole answer, not one hit among many', () {
      expect(quran('ayat al kursi'), <String>['2:255']);
    });

    test('more than 30 hits are all returned, so "show more" has a target',
        () {
      final List<String> q = quran('mercy');
      expect(q.length, greaterThan(30));
      expect(q.toSet().length, q.length, reason: 'no verse twice');
    });

    test('a phrase beats loose words; the shorter verse comes first', () {
      final List<String> q = quran('created me guides me');
      expect(q.first, '26:78');
    });

    test('a story named for the word comes before one that mentions it', () {
      final List<String> o = others('yusuf');
      expect(o.first, 'S:prophet-yusuf');
    });

    test('a word inside another word is not a match ("isa" in "disagree")',
        () {
      for (final String k in quran('isa').take(20)) {
        final Ayah a = corpus.surahs[int.parse(k.split(':')[0]) - 1]
            .ayahs[int.parse(k.split(':')[1]) - 1];
        final String en = ' ${a.english.toLowerCase()}';
        expect(
          en.contains(' isa') ||
              en.contains('jesus') ||
              en.contains('isaac'),
          isTrue,
          reason: '$k: ${a.english}',
        );
      }
    });

    test('nonsense finds nothing and does not throw', () {
      expect(quran('zzzqqxxnotaword'), isEmpty);
      expect(others('zzzqqxxnotaword'), isEmpty);
      expect(quran(''), isEmpty);
      expect(others('   '), isEmpty);
    });
  });
}
