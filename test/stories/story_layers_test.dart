import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/features/stories/domain/story_layers.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards for the layered prophet / unseen content
/// (assets/stories/layers and assets/stories/earlier). They read the files
/// straight from disk, so they cannot be neutered by a UI change.
///
/// The religious-content standard they enforce:
///  * Qur'an is only a reference into the bundled text, never copied;
///  * hadith are from the six books, each with grade AND grader, a verdict
///    of "ok" on file, and our own summary (no Arabic, no long text);
///  * every scholarly item names a work we actually read;
///  * "Not yet scholar-reviewed" is the only review wording allowed;
///  * earlier accounts carry the three-class rule and a stated basis.
void main() {
  Map<String, dynamic> readMap(String path) =>
      json.decode(File(path).readAsStringSync()) as Map<String, dynamic>;

  List<Map<String, dynamic>> readList(String path) =>
      (json.decode(File(path).readAsStringSync()) as List<dynamic>)
          .cast<Map<String, dynamic>>();

  // Arabic block U+0600..U+06FF (the salawat sign U+FDFA is outside it).
  bool hasArabic(String s) =>
      s.runes.any((int r) => r >= 0x600 && r <= 0x6ff);

  const List<String> packs = <String>[
    'prophets', 'women', 'seerah', 'companions', 'ghayb', 'signs', 'tales',
    'khutbahs', 'modernhadith', 'dailyduas', 'newmuslim',
  ];

  // Works whose text a researcher actually read; extend only with works that
  // were really read and are named with their edition.
  const List<String> knownWorks = <String>[
    'Tafsir Ibn Kathir',
    'Ma’ariful Qur’an',
  ];

  late Map<String, dynamic> index;
  late List<Map<String, dynamic>> subjects;
  late List<int> ayahCounts;
  late Map<String, dynamic> verdicts;

  setUpAll(() {
    index = readMap('assets/stories/layers/index.json');
    subjects = (index['subjects'] as List<dynamic>).cast<Map<String, dynamic>>();
    ayahCounts = <int>[
      for (final dynamic s in json.decode(
        File('assets/quran/quran.json').readAsStringSync(),
      ) as List<dynamic>)
        (s as Map<String, dynamic>)['c'] as int,
    ];
    verdicts = <String, dynamic>{};
    for (final FileSystemEntity f in Directory('tool/hadith_verdicts').listSync()) {
      if (f is File && f.path.endsWith('.json')) {
        final dynamic j = json.decode(f.readAsStringSync());
        if (j is Map<String, dynamic>) {
          // Same ranking as tool/hadith_check.py: ok > wrong > unverifiable.
          j.forEach((String k, dynamic v) {
            int rank(dynamic x) => (x is Map<String, dynamic>)
                ? (x['verdict'] == 'ok' ? 3 : (x['verdict'] == 'wrong' ? 2 : 1))
                : 0;
            if (rank(v) > rank(verdicts[k])) verdicts[k] = v;
          });
        }
      }
    }
  });

  StoryLayers load(Map<String, dynamic> subject) {
    final String id = subject['id'] as String;
    final Map<String, dynamic> layers = readMap('assets/stories/layers/$id.json');
    final File earlierFile = File('assets/stories/earlier/$id.json');
    return StoryLayers.fromJson(
      layers,
      earlierFile.existsSync() ? readMap(earlierFile.path) : null,
    );
  }

  test('the fixed badge and banner wording never drift', () {
    expect(kEarlierBadge, 'Not from the Qur’an');
    expect(kReviewBanner, 'Not yet scholar-reviewed');
    expect(kDisputedLabel, 'Disputed in the sources');
    expect(kHadithBooks.keys.toSet(), <String>{
      'bukhari', 'muslim', 'abudawud', 'tirmidhi', 'nasai', 'ibnmajah',
    });
  });

  test('pilot subjects are present', () {
    final Set<String> ids = <String>{
      for (final Map<String, dynamic> s in subjects) s['id'] as String,
    };
    for (final String id in <String>[
      'sulayman', 'dawud', 'jinn', 'gog-magog', 'angels',
    ]) {
      expect(ids.contains(id), isTrue, reason: 'pilot subject $id missing');
    }
  });

  test('index: files exist, stories exist, no story in two subjects', () {
    final Set<String> storyIds = <String>{};
    for (final String p in packs) {
      for (final Map<String, dynamic> s in readList('assets/stories/$p.json')) {
        storyIds.add(s['id'] as String);
      }
    }
    final Set<String> seen = <String>{};
    final Set<String> subjectIds = <String>{};
    for (final Map<String, dynamic> s in subjects) {
      final String id = s['id'] as String;
      expect(subjectIds.add(id), isTrue, reason: 'duplicate subject $id');
      expect(File('assets/stories/layers/$id.json').existsSync(), isTrue,
          reason: 'layers file missing for $id');
      expect(File('assets/stories/earlier/$id.json').existsSync(),
          s['earlier'] == true,
          reason: '$id: index "earlier" flag must match the file');
      final List<String> stories = (s['stories'] as List<dynamic>).cast<String>();
      expect(stories, isNotEmpty);
      for (final String st in stories) {
        expect(storyIds.contains(st), isTrue,
            reason: '$id points at missing story $st');
        expect(seen.add(st), isTrue, reason: 'story $st is in two subjects');
      }
    }
    // Every layers file on disk is indexed (a file nobody can reach is dead).
    for (final FileSystemEntity f in Directory('assets/stories/layers').listSync()) {
      final String name = f.uri.pathSegments.last;
      if (name == 'index.json' || !name.endsWith('.json')) continue;
      expect(subjectIds.contains(name.replaceAll('.json', '')), isTrue,
          reason: '$name is not in index.json');
    }
  });

  test('every subject parses and says it is not yet scholar-reviewed', () {
    for (final Map<String, dynamic> s in subjects) {
      final StoryLayers l = load(s);
      expect(l.isEmpty, isFalse);
      expect(l.kind == 'prophet' || l.kind == 'unseen', isTrue);
      final Map<String, dynamic> raw =
          readMap('assets/stories/layers/${s['id']}.json');
      expect(raw['reviewStatus'], 'Not yet scholar-reviewed');
    }
  });

  test('Qur’an layer: real ayat, short passages, references only', () {
    for (final Map<String, dynamic> s in subjects) {
      final StoryLayers l = load(s);
      for (final LayerQuranRef r in l.quran) {
        expect(r.surah >= 1 && r.surah <= 114, isTrue, reason: r.label);
        expect(r.from >= 1 && r.to >= r.from, isTrue, reason: r.label);
        expect(r.to <= ayahCounts[r.surah - 1], isTrue,
            reason: '${s['id']}: ${r.label} is past the end of the surah');
        expect(r.to - r.from, lessThan(12),
            reason: '${r.label}: keep passages short');
      }
      // The pack must hold references only: no ayah text of its own.
      final String raw =
          File('assets/stories/layers/${s['id']}.json').readAsStringSync();
      expect(hasArabic(raw), isFalse,
          reason: '${s['id']}: Arabic text must come from the bundled Qur’an');
    }
  });

  test('hadith layer: six books, grade + grader, verdict on file, no copied text',
      () {
    int total = 0;
    final RegExp date = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    for (final Map<String, dynamic> s in subjects) {
      final StoryLayers l = load(s);
      for (final LayerHadith h in l.hadith) {
        total++;
        final String key = '${h.book}:${h.number}';
        expect(kHadithBooks.containsKey(h.book), isTrue, reason: key);
        expect(RegExp(r'^\d{1,5}$').hasMatch(h.number), isTrue, reason: key);
        expect(h.narrator.trim(), isNotEmpty, reason: key);
        expect(h.grade.trim(), isNotEmpty, reason: '$key has no grade');
        expect(h.grader.trim(), isNotEmpty, reason: '$key has no grader');
        expect(date.hasMatch(h.verified), isTrue, reason: key);
        expect(h.summary.length, lessThan(760),
            reason: '$key: a summary, not the hadith text');
        expect(hasArabic(h.summary), isFalse,
            reason: '$key: no Arabic hadith text');
        final dynamic v = verdicts[key];
        expect(v, isNotNull, reason: '$key has no verdict on file');
        expect((v as Map<String, dynamic>)['verdict'], 'ok',
            reason: '$key verdict is not ok');
        expect(h.reference, '${kHadithBooks[h.book]} ${h.number}');
        expect(h.sunnahUrl, 'https://sunnah.com/${h.book}:${h.number}');
        if (!h.isTopTier) {
          // The four Sunan: the grader must be a named person or body, not
          // the collection itself.
          expect(h.grader.toLowerCase().contains('bukhari'), isFalse, reason: key);
        }
      }
    }
    expect(total, greaterThanOrEqualTo(25));
  });

  test('scholarly layer: every item names a work that was read', () {
    int total = 0;
    for (final Map<String, dynamic> s in subjects) {
      final StoryLayers l = load(s);
      for (final LayerScholarly item in l.scholarly) {
        total++;
        expect(knownWorks.any(item.work.startsWith), isTrue,
            reason: '${s['id']}: unattributed work "${item.work}"');
        expect(item.author.trim(), isNotEmpty);
        expect(item.locator.trim(), isNotEmpty);
        expect(item.summary.trim().length, greaterThan(40));
      }
      for (final LayerDifference d in l.differences) {
        expect(d.views.length, greaterThanOrEqualTo(2),
            reason: '${s['id']}: "${d.question}" needs at least two views');
        for (final LayerView v in d.views) {
          expect(v.who.trim(), isNotEmpty);
          expect(v.work.trim(), isNotEmpty,
              reason: '${s['id']}: a view without a named work');
          expect(v.view.trim(), isNotEmpty);
        }
      }
    }
    expect(total, greaterThanOrEqualTo(10));
  });

  test('earlier accounts: three classes, a stated basis, contradicted not told',
      () {
    int total = 0;
    for (final Map<String, dynamic> s in subjects) {
      final StoryLayers l = load(s);
      final Set<String> ids = <String>{};
      for (final EarlierAccount e in l.earlier) {
        total++;
        expect(ids.add(e.id), isTrue, reason: 'duplicate earlier id ${e.id}');
        expect(e.origin.trim(), isNotEmpty);
        expect(e.claim.trim(), isNotEmpty);
        expect(e.ruling.trim().length, greaterThan(30));
        expect(e.basis.trim(), isNotEmpty, reason: '${e.id}: no basis');
        if (e.cls == EarlierClass.contradicted) {
          expect(e.ruling.startsWith('Not told here'), isTrue,
              reason: '${e.id}: a contradicted account must say it is not told');
        }
      }
    }
    expect(total, greaterThanOrEqualTo(2));
    final List<String> raw = <String>[
      for (final FileSystemEntity f in Directory('assets/stories/earlier').listSync())
        if (f is File && f.path.endsWith('.json')) f.readAsStringSync(),
    ];
    for (final String r in raw) {
      expect(r.contains('"badge": "Not from the Qur’an"'), isTrue);
    }
  });

  test('EarlierClass: parse and labels', () {
    expect(EarlierClass.parse('confirmed'), EarlierClass.confirmed);
    expect(EarlierClass.parse('contradicted'), EarlierClass.contradicted);
    expect(EarlierClass.parse('silent'), EarlierClass.silent);
    expect(EarlierClass.parse('anything else'), EarlierClass.silent);
    expect(EarlierClass.silent.label.contains('neither believe nor disbelieve'),
        isTrue);
    expect(EarlierClass.contradicted.label.contains('not told'), isTrue);
  });

  test('"scholar-reviewed" appears only as "Not yet scholar-reviewed"', () {
    final RegExp bad = RegExp(r'(?<!not yet )scholar[- ]reviewed',
        caseSensitive: false);
    final List<String> hits = <String>[];
    for (final String dir in <String>[
      'assets/stories/layers',
      'assets/stories/earlier',
      'lib/features/stories',
      'lib/features/family',
    ]) {
      for (final FileSystemEntity f in Directory(dir).listSync(recursive: true)) {
        if (f is! File) continue;
        if (!(f.path.endsWith('.json') || f.path.endsWith('.dart'))) continue;
        if (bad.hasMatch(f.readAsStringSync())) hits.add(f.path);
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });

  test('no images anywhere in the stories, layers or family assets', () {
    const List<String> ext = <String>[
      '.png', '.jpg', '.jpeg', '.gif', '.webp', '.svg', '.bmp',
    ];
    final List<String> hits = <String>[];
    for (final String dir in <String>['assets/stories', 'assets/family']) {
      for (final FileSystemEntity f in Directory(dir).listSync(recursive: true)) {
        if (f is File && ext.any(f.path.toLowerCase().endsWith)) hits.add(f.path);
      }
    }
    expect(hits, isEmpty, reason: 'no prophet imagery: ${hits.join(', ')}');
  });

  test('priority prophets are present with the caveats that must stay', () {
    final List<String> ids = (readMap('assets/stories/layers/index.json')['subjects']
            as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map((Map<String, dynamic> m) => m['id'] as String)
        .toList();
    for (final String id in <String>[
      'musa', 'ibrahim', 'yusuf', 'isa', 'nuh', 'adam', 'muhammad', 'maryam',
    ]) {
      expect(ids, contains(id), reason: 'subject $id must be indexed');
      final Map<String, dynamic> l = readMap('assets/stories/layers/$id.json');
      expect((l['quran'] as List<dynamic>).length, greaterThanOrEqualTo(3),
          reason: '$id needs Qur\'an references');
    }
    final String ibrahim = File('assets/stories/layers/ibrahim.json').readAsStringSync();
    expect(ibrahim.contains('3207') && ibrahim.contains('349'), isTrue,
        reason: 'the two heavens for Ibrahim must both be reported');
    final String nuh = File('assets/stories/layers/nuh.json').readAsStringSync();
    expect(nuh.contains('not a saying of the Prophet'), isTrue,
        reason: 'Ibn Abbas on the idols is a Companion saying');
  });

  test('model: a layers file with nothing in it is empty', () {
    final StoryLayers l = StoryLayers.fromJson(
      <String, dynamic>{'subject': 'x', 'title': 'X', 'kind': 'unseen'},
      null,
    );
    expect(l.isEmpty, isTrue);
  });
}
