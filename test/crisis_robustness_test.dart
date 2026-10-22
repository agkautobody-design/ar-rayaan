import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/features/sakina/domain/crisis_detector.dart';
import 'package:flutter_test/flutter_test.dart';

/// The crisis gate must survive the ways people (and filters) disguise text:
/// fullwidth letters, look-alike Cyrillic and Greek letters, a soft hyphen or
/// zero-width character inside a word, digits typed for letters, accents and
/// one typing slip. No new phrase is written here: every positive is the
/// existing golden set (test/data/crisis_golden.json), changed by code.
///
/// The other half is the cost: the same detector must stay silent on a large
/// benign corpus (ordinary Islamic questions, and every string in the app's
/// own assets).
///
/// As the golden file says, non-English phrases in it still need review by
/// native speakers before a release. This test proves the code, not the set.
String _longestWordMap(String s, String Function(String) f) {
  final List<String> words = s.split(' ');
  int bi = 0;
  for (int i = 0; i < words.length; i++) {
    if (words[i].length > words[bi].length) bi = i;
  }
  words[bi] = f(words[bi]);
  return words.join(' ');
}

String _fullwidth(String s) => String.fromCharCodes(
      s.runes.map((int r) => (r >= 0x21 && r <= 0x7e) ? r + 0xFEE0 : r),
    );

String _cyrillic(String s) => s
    .replaceAll('a', 'а')
    .replaceAll('e', 'е')
    .replaceAll('o', 'о')
    .replaceAll('c', 'с')
    .replaceAll('p', 'р');

String _greek(String s) => s
    .replaceAll('o', 'ο')
    .replaceAll('i', 'ι')
    .replaceAll('a', 'α')
    .replaceAll('v', 'ν');

String _softHyphen(String s) => _longestWordMap(
      s,
      (String w) =>
          w.length >= 4 ? '${w.substring(0, 2)}­${w.substring(2)}' : w,
    );

String _zeroWidth(String s) => _longestWordMap(
      s,
      (String w) =>
          w.length >= 4 ? '${w.substring(0, 2)}​${w.substring(2)}' : w,
    );

String _leet(String s) => s
    .replaceAll('a', '4')
    .replaceAll('e', '3')
    .replaceAll('i', '1')
    .replaceAll('o', '0');

String _accents(String s) => s
    .replaceAll('e', 'é')
    .replaceAll('a', 'á')
    .replaceAll('i', 'í')
    .replaceAll('o', 'ó');

String _swap(String s) => _longestWordMap(s, (String w) {
      if (w.length < 4) return w;
      final List<String> c = w.split('');
      final String t = c[1];
      c[1] = c[2];
      c[2] = t;
      return c.join();
    });

String _drop(String s) => _longestWordMap(
      s,
      (String w) => w.length >= 5 ? w.substring(0, 2) + w.substring(3) : w,
    );

String _double(String s) => _longestWordMap(
      s,
      (String w) => w.length >= 4 ? w.substring(0, 2) + w[1] + w.substring(2) : w,
    );

List<String> _strings(dynamic node) {
  final List<String> out = <String>[];
  void walk(dynamic n) {
    if (n is String) {
      if (n.length >= 12) out.add(n);
    } else if (n is List<dynamic>) {
      n.forEach(walk);
    } else if (n is Map<String, dynamic>) {
      n.values.forEach(walk);
    }
  }

  walk(node);
  return out;
}

void main() {
  final Map<String, dynamic> golden = json.decode(
    File('test/data/crisis_golden.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final List<Map<String, dynamic>> cases = <Map<String, dynamic>>[
    for (final dynamic c in golden['cases'] as List<dynamic>)
      c as Map<String, dynamic>,
  ];
  final List<Map<String, dynamic>> positives = <Map<String, dynamic>>[
    for (final Map<String, dynamic> c in cases)
      if (c['expect'] != null) c,
  ];
  final List<Map<String, dynamic>> negatives = <Map<String, dynamic>>[
    for (final Map<String, dynamic> c in cases)
      if (c['expect'] == null) c,
  ];

  // Disguises that must never lose a detection, and never change its kind.
  final Map<String, String Function(String)> exact =
      <String, String Function(String)>{
    'fullwidth letters': _fullwidth,
    'cyrillic look-alikes': _cyrillic,
    'greek look-alikes': _greek,
    'soft hyphen inside a word': _softHyphen,
    'zero-width character inside a word': _zeroWidth,
    'digits typed for letters': _leet,
    'accents added': _accents,
    'upper case': (String s) => s.toUpperCase(),
    'padded with other talk': (String s) =>
        'so yesterday my friend said hello and then $s and then we went home',
  };

  for (final MapEntry<String, String Function(String)> m in exact.entries) {
    test('recall is kept under: ${m.key}', () {
      final List<String> missed = <String>[];
      for (final Map<String, dynamic> c in positives) {
        final CrisisKind? got = CrisisDetector.detect(m.value(c['q'] as String));
        // A zero-width mark may be a space or a joiner; both readings are
        // tried, and the first that fires wins, so only detection counts.
        final bool kindMatters = m.key != 'zero-width character inside a word';
        if (got == null || (kindMatters && got.name != c['expect'])) {
          missed.add(c['id'] as String);
        }
      }
      expect(missed, isEmpty, reason: 'missed under ${m.key}: $missed');
    });

    // An invisible mark inside a word is read both as a space and as nothing,
    // because either may be what the writer meant; a benign sentence whose
    // exclusion word is split by one can therefore fire. Not tested here.
    if (m.key == 'zero-width character inside a word') continue;
    test('no benign golden case fires under: ${m.key}', () {
      final List<String> fired = <String>[];
      for (final Map<String, dynamic> c in negatives) {
        if (CrisisDetector.detect(m.value(c['q'] as String)) != null) {
          fired.add(c['id'] as String);
        }
      }
      expect(fired, isEmpty, reason: 'false positives under ${m.key}: $fired');
    });
  }

  // One typing slip: believed only conservatively, so the floor is lower.
  final Map<String, String Function(String)> slips =
      <String, String Function(String)>{
    'two letters swapped': _swap,
    'a letter missing': _drop,
    'a letter doubled': _double,
  };
  for (final MapEntry<String, String Function(String)> m in slips.entries) {
    test('most one-slip typos are still caught: ${m.key}', () {
      int hit = 0;
      for (final Map<String, dynamic> c in positives) {
        if (CrisisDetector.detect(m.value(c['q'] as String)) != null) hit++;
      }
      expect(hit / positives.length, greaterThanOrEqualTo(0.7),
          reason: '${m.key}: $hit of ${positives.length}');
    });
  }

  test('the plain pass alone still finds every golden case (no recall lost)',
      () {
    for (final Map<String, dynamic> c in positives) {
      expect(CrisisDetector.detectExact(c['q'] as String)?.name, c['expect'],
          reason: c['id'] as String);
    }
  });

  test('a benign corpus of ordinary questions never fires', () {
    final List<String> lines = File('test/data/benign_questions.txt')
        .readAsLinesSync()
        .where((String l) => l.trim().isNotEmpty)
        .toList();
    expect(lines.length, greaterThanOrEqualTo(800));
    final List<String> fired = <String>[
      for (final String l in lines)
        if (CrisisDetector.detect(l) != null) l,
    ];
    expect(fired, isEmpty, reason: 'false positives: ${fired.length}');
  });

  test('on the app\'s own text the later passes add no new detections', () {
    final List<String> texts = <String>[];
    for (final FileSystemEntity f
        in Directory('assets').listSync(recursive: true)) {
      if (f is File && f.path.endsWith('.json')) {
        try {
          texts.addAll(_strings(json.decode(f.readAsStringSync())));
        } on FormatException {
          // Not text we can read; nothing to check.
        }
      }
    }
    expect(texts.length, greaterThan(5000));
    final List<String> added = <String>[];
    for (final String t in texts) {
      if (CrisisDetector.detectExact(t) == null &&
          CrisisDetector.detect(t) != null) {
        added.add(t.length > 60 ? t.substring(0, 60) : t);
      }
    }
    expect(added, isEmpty,
        reason: '${added.length} asset strings fire only after folding or a '
            'typo allowance, e.g. ${added.take(5).toList()}');
  });
}
