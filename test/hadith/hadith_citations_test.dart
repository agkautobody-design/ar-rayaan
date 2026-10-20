// Citation gate for the Kutub al-Sittah references in the bundled content.
//
// Mirrors tool/hadith_check.py (the CI step runs both): every
// "<book> <number>" reference found in the enforced paths must have an `ok`
// verdict in tool/hadith_verdicts/*.json, must not be recorded `wrong`, and a
// citation from Abu Dawud / Tirmidhi / Nasa'i / Ibn Majah must name who graded
// it. Verdicts record outcomes only (never hadith text from sunnah.com).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const List<String> _books = <String>[
  'bukhari',
  'muslim',
  'abudawud',
  'tirmidhi',
  'nasai',
  'ibnmajah',
  'ahmad',
];
const Set<String> _graded = <String>{
  'abudawud',
  'tirmidhi',
  'nasai',
  'ibnmajah',
};

final RegExp _cite = RegExp(
  r"(?:(bukhari)|(muslim)(?![a-z])|((?:abu|abi)\s+dawu?o?d)|(tirmidhi)|(nasa['’ʿʼ]?i)|(ibn\s+maja?h?)|((?:musnad\s+)?ahmad))"
  r"(?:\s*\)?\s*[:#]?\s*(?:no\.?\s*|hadith\s+)?)"
  r"(\d{1,5}(?:\s*(?:,|&|/|and|;)\s*\d{1,5}(?![\d:]))*)"
  r"(?![\d:]|\s*(?:days?|times|years|minutes|rak))",
  caseSensitive: false,
);
final RegExp _num = RegExp(r'\d+');
final RegExp _grader = RegExp(
  r'al-?albani|darussalam|zubair|al-?tirmidhi|tirmidhi himself|ungraded|not graded',
  caseSensitive: false,
);

class _Cite {
  const _Cite(this.key, this.file, this.line, this.tail);
  final String key;
  final String file;
  final int line;
  final String tail;
  String get where => '$file:$line';
}

List<File> _files() {
  final List<File> out = <File>[];
  for (final FileSystemEntity e
      in Directory('assets').listSync(recursive: true)) {
    if (e is File &&
        e.path.endsWith('.json') &&
        !e.path.endsWith('content_manifest.json')) {
      out.add(e);
    }
  }
  for (final FileSystemEntity e in Directory('lib').listSync(recursive: true)) {
    if (e is File && e.path.endsWith('.dart')) out.add(e);
  }
  out.sort((File a, File b) => a.path.compareTo(b.path));
  return out;
}

List<_Cite> _extract() {
  final List<_Cite> res = <_Cite>[];
  for (final File f in _files()) {
    final bool dart = f.path.endsWith('.dart');
    final String rel = f.path.replaceAll('\\', '/');
    final List<String> lines = f.readAsLinesSync();
    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i];
      if (dart && line.trimLeft().startsWith('//')) continue;
      for (final RegExpMatch m in _cite.allMatches(line)) {
        int book = -1;
        for (int g = 1; g <= 7; g++) {
          if (m.group(g) != null) {
            book = g - 1;
            break;
          }
        }
        if (book < 0) continue;
        final int end = m.end;
        final int tailEnd = end + 140 > line.length ? line.length : end + 140;
        for (final RegExpMatch n in _num.allMatches(m.group(8)!)) {
          res.add(_Cite(
            '${_books[book]}:${int.parse(n.group(0)!)}',
            rel,
            i + 1,
            line.substring(end, tailEnd),
          ));
        }
      }
    }
  }
  return res;
}

int _rank(Object? verdict) =>
    verdict == 'ok' ? 3 : (verdict == 'wrong' ? 2 : 1);

Map<String, Map<String, dynamic>> _verdicts() {
  final Map<String, Map<String, dynamic>> out =
      <String, Map<String, dynamic>>{};
  for (final FileSystemEntity e in Directory('tool/hadith_verdicts').listSync()) {
    if (e is! File || !e.path.endsWith('.json')) continue;
    final String name = e.path.split('/').last;
    if (name == 'allowlist.json' || name == 'scope.json') continue;
    final Map<String, dynamic> d =
        jsonDecode(e.readAsStringSync()) as Map<String, dynamic>;
    d.forEach((String k, dynamic v) {
      final Map<String, dynamic> val = v as Map<String, dynamic>;
      final Map<String, dynamic>? prev = out[k];
      // Same ranking as tool/hadith_check.py: ok > wrong > unverifiable.
      if (prev == null || _rank(val['verdict']) > _rank(prev['verdict'])) {
        out[k] = val;
      }
    });
  }
  return out;
}

Map<String, dynamic> _json(String path) {
  final File f = File(path);
  if (!f.existsSync()) return <String, dynamic>{};
  return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
}

void main() {
  final Map<String, Map<String, dynamic>> verdicts = _verdicts();

  test('verdict files follow the schema', () {
    final RegExp keyRe = RegExp('^(${_books.join('|')}):\\d+\$');
    final RegExp dateRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    final List<String> bad = <String>[];
    verdicts.forEach((String k, Map<String, dynamic> v) {
      if (!keyRe.hasMatch(k)) bad.add('$k: bad key');
      final Object? verdict = v['verdict'];
      if (verdict != 'ok' && verdict != 'wrong' && verdict != 'unverifiable') {
        bad.add('$k: bad verdict $verdict');
      }
      if (!dateRe.hasMatch((v['checked'] as String?) ?? '')) {
        bad.add('$k: missing checked date');
      }
      if (verdict == 'wrong') {
        final String c = (v['correct'] as String?) ?? '';
        if (c != 'none' && !keyRe.hasMatch(c)) {
          bad.add('$k: wrong needs correct (book:n or none)');
        }
      }
      if (verdict == 'ok' &&
          _graded.contains(k.split(':').first) &&
          (((v['grade'] as String?) ?? '').isEmpty ||
              ((v['grader'] as String?) ?? '').isEmpty)) {
        bad.add('$k: needs grade and grader');
      }
    });
    expect(verdicts, isNotEmpty);
    expect(bad, isEmpty, reason: bad.join('\n'));
  });

  test('every enforced citation has an ok verdict and, outside the Sahihs, a grader',
      () {
    final Map<String, dynamic> scopeFile = _json('tool/hadith_verdicts/scope.json');
    final List<String>? scope = scopeFile.containsKey('enforced')
        ? (scopeFile['enforced'] as List<dynamic>).cast<String>()
        : null;
    final Map<String, dynamic> allow =
        _json('tool/hadith_verdicts/allowlist.json');
    final List<_Cite> cites = _extract();
    expect(cites.length, greaterThan(300), reason: 'the extractor found the packs');

    final List<String> bad = <String>[];
    int enforced = 0;
    for (final _Cite c in cites) {
      if (scope != null && !scope.any((String p) => c.file.contains(p))) {
        continue;
      }
      enforced++;
      if (allow.containsKey('${c.key}@${c.file}')) continue;
      final Map<String, dynamic>? v = verdicts[c.key];
      if (v == null) {
        bad.add('${c.key} has no verdict at ${c.where}');
      } else if (v['verdict'] == 'wrong') {
        bad.add('${c.key} is WRONG (correct: ${v['correct']}) at ${c.where}');
      } else if (v['verdict'] != 'ok') {
        bad.add('${c.key} is ${v['verdict']} at ${c.where}');
      } else if (_graded.contains(c.key.split(':').first) &&
          !_grader.hasMatch(c.tail)) {
        bad.add('${c.key} names no grader at ${c.where}');
      }
    }
    expect(enforced, greaterThan(100), reason: 'the enforced scope is not empty');
    expect(bad, isEmpty, reason: bad.join('\n'));
  });

  test('the extractor reads the usual citation shapes', () {
    String keysOf(String s) {
      final List<String> out = <String>[];
      for (final RegExpMatch m in _cite.allMatches(s)) {
        int book = 0;
        for (int g = 1; g <= 7; g++) {
          if (m.group(g) != null) {
            book = g - 1;
            break;
          }
        }
        for (final RegExpMatch n in _num.allMatches(m.group(8)!)) {
          out.add('${_books[book]}:${n.group(0)}');
        }
      }
      return out.join(' ');
    }

    expect(keysOf('Sahih al-Bukhari 3436'), 'bukhari:3436');
    expect(keysOf('(Muslim 2542).'), 'muslim:2542');
    expect(keysOf('Sunan Abi Dawud 5096 — daʿif'), 'abudawud:5096');
    expect(keysOf("Sunan an-Nasa'i 1745"), 'nasai:1745');
    expect(keysOf('Sunan Ibn Majah 1753'), 'ibnmajah:1753');
    expect(keysOf('Jami at-Tirmidhi 3563'), 'tirmidhi:3563');
    expect(keysOf('Sahih al-Bukhari 52, 3734; Sahih Muslim 55'),
        'bukhari:52 bukhari:3734 muslim:55');
    expect(keysOf('MUSLIM PATH · DAY 3 OF 30'), '');
    expect(keysOf('Muslim Belal 2 days'), '');
    expect(keysOf('Musnad Ahmad 15493'), 'ahmad:15493');
  });
}
