import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Data-integrity guards for religious content. These read the asset and
/// source files straight from disk (flutter test runs from the package
/// root), so they cost nothing and cannot be neutered by a UI change.
void main() {
  late List<int> ayahCounts; // index 0 = surah 1

  setUpAll(() {
    final List<dynamic> quran = jsonDecode(
      File('assets/quran/quran.json').readAsStringSync(),
    ) as List<dynamic>;
    ayahCounts = <int>[
      for (final dynamic s in quran) (s as Map<String, dynamic>)['c'] as int,
    ];
  });

  // "Qur'an 2:255", "Quran 2:255-257", "Surah 2:255" or "(2:255)".
  final RegExp ref = RegExp(
    r"(?:Qur['’]an|Quran|Surah)\s*(\d{1,3}):(\d{1,3})(?:[\-–](\d{1,3}))?"
    r"|\((\d{1,3}):(\d{1,3})(?:[\-–](\d{1,3}))?\)",
  );

  List<String> problems(String label, String text) {
    final List<String> out = <String>[];
    for (final RegExpMatch m in ref.allMatches(text)) {
      final int s = int.parse(m.group(1) ?? m.group(4)!);
      final int a = int.parse(m.group(2) ?? m.group(5)!);
      final String? bRaw = m.group(3) ?? m.group(6);
      final int? b = bRaw == null ? null : int.parse(bRaw);
      final bool ok = s >= 1 &&
          s <= 114 &&
          a >= 1 &&
          a <= ayahCounts[s - 1] &&
          (b == null || (b >= a && b <= ayahCounts[s - 1]));
      if (!ok) out.add('$label: "${m.group(0)}" is not a real ayah reference');
    }
    return out;
  }

  Iterable<File> files(String dir, String ext) => Directory(dir)
      .listSync(recursive: true)
      .whereType<File>()
      .where((File f) => f.path.endsWith(ext));

  test('every Qur’an reference in any asset pack is a real ayah', () {
    final List<String> bad = <String>[];
    int checked = 0;
    for (final File f in files('assets', '.json')) {
      if (f.path.endsWith('quran.json') ||
          f.path.endsWith('transliteration.json')) {
        continue;
      }
      final String text = f.readAsStringSync();
      checked += ref.allMatches(text).length;
      bad.addAll(problems(f.path, text));
    }
    expect(checked, greaterThan(300), reason: 'the scan found the packs');
    expect(bad, isEmpty, reason: bad.join('\n'));
  });

  test('every Qur’an reference in the Dart sources is a real ayah', () {
    final List<String> bad = <String>[];
    for (final File f in files('lib', '.dart')) {
      bad.addAll(problems(f.path, f.readAsStringSync()));
    }
    expect(bad, isEmpty, reason: bad.join('\n'));
  });

  test('known-wrong hadith citations stay fixed', () {
    // Each of these was an audited mis-citation; the right source is in
    // the comment. A regression here puts a wrong number in front of a user.
    const Map<String, String> banned = <String, String>{
      'Muslim 4222': 'ongoing charity hadith is Muslim 1631',
      'Muslim 1808': 'weeping over the dead is Muslim 927',
      'Tirmidhi 3565': 'the debt dua is Tirmidhi 3563',
      'Abu Dawud 5096 — sahih': 'the home dua wording is daʿif',
      'Sunan Abi Dawud 5096 — sahih': 'the home dua wording is daʿif',
      'Bukhari 604).': 'adhan wording is Muslim 379',
      'Muslim 2752 \u2014 the grave': 'Muslim 2752 is about mercy in 100 parts',
      "Muslim 407'": 'one blessing, ten returned is Muslim 408',
    };
    final List<String> hits = <String>[];
    for (final String dir in <String>[
      'assets/stories',
      'assets/guides',
      'assets/share',
      'assets/adhkar',
      'lib/features/hadith',
      'lib/features/lamha',
      'lib/features/huda',
      'lib/features/stories',
    ]) {
      for (final File f in Directory(dir)
          .listSync(recursive: true)
          .whereType<File>()
          .where((File f) =>
              f.path.endsWith('.json') || f.path.endsWith('.dart'))) {
        final String text = f.readAsStringSync();
        banned.forEach((String bad, String why) {
          if (text.contains(bad)) hits.add('${f.path}: "$bad" ($why)');
        });
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });

  test('dailyduas: every dua is filed under a Hisn gate (or marked duplicate)',
      () {
    final List<dynamic> duas = jsonDecode(
      File('assets/stories/dailyduas.json').readAsStringSync(),
    ) as List<dynamic>;
    expect(duas.length, 42);
    const Set<String> gates = <String>{
      'morning-evening', 'waking-sleeping', 'home', 'food', 'travel',
      'hardship', 'prayer', 'fasting', 'family', 'decisions', 'rain',
    };
    int uncategorised = 0;
    for (final dynamic d in duas) {
      final Map<String, dynamic> m = d as Map<String, dynamic>;
      final String? gate = m['hisnCategory'] as String?;
      if (gate == null || !gates.contains(gate)) uncategorised++;
    }
    expect(uncategorised, 0);
  });

  test('family tree: every person is reachable via children or spouses', () {
    final Map<String, dynamic> tree = jsonDecode(
      File('assets/family/tree.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final List<Map<String, dynamic>> nodes =
        (tree['nodes'] as List<dynamic>).cast<Map<String, dynamic>>();
    final Map<String, Map<String, dynamic>> byId = <String, Map<String, dynamic>>{
      for (final Map<String, dynamic> n in nodes) n['id'] as String: n,
    };
    final Set<String> seen = <String>{};
    final List<String> stack = <String>['adam'];
    while (stack.isNotEmpty) {
      final String id = stack.removeLast();
      if (!seen.add(id)) continue;
      final Map<String, dynamic>? n = byId[id];
      if (n == null) continue;
      stack
        ..addAll((n['children'] as List<dynamic>? ?? <dynamic>[]).cast<String>())
        ..addAll((n['spouses'] as List<dynamic>? ?? <dynamic>[]).cast<String>());
    }
    final List<String> lost = <String>[
      for (final String id in byId.keys)
        if (!seen.contains(id)) id,
    ];
    expect(lost, isEmpty, reason: 'unreachable: $lost');
    expect(seen.contains('maryam'), isTrue);
    expect(seen.contains('isa'), isTrue);
  });
}
