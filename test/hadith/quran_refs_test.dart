// Qur'an reference gate (mirrors tool/quran_ref_check.py).
//
// 1. Every explicit Qur'an reference in lib/**/*.dart and assets/**/*.json
//    ("Qur'an 2:255", "(94:5-6)", "(Al-Baqarah 255)") must exist in the
//    bundled text (assets/quran/quran.json).
// 2. In the Hadi offline knowledge base (lib/features/hadi/**, assets/noor/**)
//    every quotation placed next to a reference must be inside the cited
//    ayah(s), word for word (case, punctuation and the translator's [brackets]
//    ignored): scripture is never quoted from memory. The bundled-ayah entries
//    in assets/noor/noor.json must match the bundled Arabic and English, and
//    the Hadi corpus may only name ayat that exist.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const List<String> _strictPrefixes = <String>[
  'lib/features/hadi/',
  'assets/noor/',
];

// "Qur'an 2:255", "Quran 94:5-6", "Surah 2:255" or "(2:255)".
final RegExp _numRef = RegExp(
  r"(?:(?:Qur['’]?an|Quran|Surah|Sura)\s*\(?\s*|\()"
  r"(\d{1,3}):(\d{1,3})(?:\s*[-–]\s*(\d{1,3}))?(?![\d:])",
);

// "(Al-Baqarah 255)", "Al-Imran 35-37", "An-Nisa 11-12".
final RegExp _namedRef = RegExp(
  r"(?<![A-Za-z'’\-])((?:Al|An|Ar|As|Ash|At|Az|Ad|Adh|Ath)[- ][A-Za-z'’]+|[A-Z][a-z'’]+)"
  r"\s+(\d{1,3})(?:\s*[-–]\s*(\d{1,3}))?(?![\d:])",
);

// JSON strings may quote with any mark; Dart source uses ' for the literal
// itself, so only double and curly double quotes delimit a quotation there.
final RegExp _quoteAny = RegExp(
  r'''(?<![A-Za-z0-9])[‘'“"]([^‘“"”]{10,}?)['’”"](?![A-Za-z0-9])''',
);
final RegExp _quoteDart = RegExp(
  r'''(?<![A-Za-z0-9])[“"]([^“"”]{10,}?)[”"](?![A-Za-z0-9])''',
);
final RegExp _hadith = RegExp(
  r'bukhari|muslim|tirmidhi|da[wu]*[ou]*d|nasa|majah|ahmad',
  caseSensitive: false,
);
final RegExp _word3 = RegExp(r'[A-Za-z]{3}.*[A-Za-z]{3}');
final RegExp _gap = RegExp(r'^[\s:—–\-,]*$');
final RegExp _split = RegExp(r'\.\.\.|…|\[\.\.\.\]');

// Adjacent Dart string literals are one string at runtime: join them.
final RegExp _join = RegExp('(["\'])[ \\t]*\\n?[ \\t\\r\\n]*(["\'])');

class _Ref {
  const _Ref(this.start, this.end, this.surah, this.from, this.to, this.label);
  final int start;
  final int end;
  final int surah;
  final int from;
  final int to;
  final String label;
}

class _Quran {
  _Quran(List<dynamic> doc) {
    for (final dynamic s in doc) {
      final Map<String, dynamic> m = s as Map<String, dynamic>;
      final int n = m['n'] as int;
      count[n] = m['c'] as int;
      names[_key(m['tl'] as String)] = n;
      for (final dynamic v in m['v'] as List<dynamic>) {
        final List<dynamic> row = v as List<dynamic>;
        arabic['$n:${row[0]}'] = row[1] as String;
        english['$n:${row[0]}'] = row[2] as String;
      }
    }
    for (final String alias in <String>[
      'alimran',
      'aalimran',
      'imran',
      'aliimran',
    ]) {
      names[alias] = 3;
    }
  }

  final Map<int, int> count = <int, int>{};
  final Map<String, int> names = <String, int>{};
  final Map<String, String> arabic = <String, String>{};
  final Map<String, String> english = <String, String>{};

  bool valid(int s, int a, int b) {
    final int? c = count[s];
    return c != null && a >= 1 && a <= b && b <= c;
  }

  List<String> englishRange(int s, int a, int b) =>
      <String>[for (int k = a; k <= b; k++) english['$s:$k'] ?? ''];

  List<String> arabicRange(int s, int a, int b) =>
      <String>[for (int k = a; k <= b; k++) arabic['$s:$k'] ?? ''];
}

String _key(String name) =>
    name.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

String _normEn(String t, bool keepBrackets) {
  String x = t.toLowerCase().replaceAll('’', "'");
  if (keepBrackets) {
    x = x.replaceAll('[', '').replaceAll(']', '');
  } else {
    x = x.replaceAll(RegExp(r'\[[^\]]*\]'), '');
  }
  return x.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}

String _normAr(String t) {
  String x = t.replaceAll(
    RegExp(r'[ؐ-ًؚ-ٰٟۖ-ۭ࣓-ࣿـ]'),
    '',
  );
  x = x.replaceAll(RegExp('[إأآٱ]'), 'ا').replaceAll('ى', 'ي');
  return x.replaceAll(RegExp(r'[^ء-ي]+'), ' ').trim();
}

String _unescape(String t) {
  final String u = t.replaceAllMapped(
    RegExp(r'\\u([0-9a-fA-F]{4})'),
    (Match m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)),
  );
  return u.replaceAll("\\'", "'").replaceAll('\\"', '"').replaceAll('\\n', '\n');
}

/// Comment lines blanked, adjacent literals joined (see tool/hadith_check.py).
String _dartLogical(String raw) {
  final String text = raw
      .split('\n')
      .map((String l) => l.trimLeft().startsWith('//') ? ' ' * l.length : l)
      .join('\n');
  final StringBuffer out = StringBuffer();
  int pos = 0;
  for (final RegExpMatch m in _join.allMatches(text)) {
    if (m.end - m.start == 2) continue;
    out.write(text.substring(pos, m.start));
    pos = m.end;
  }
  out.write(text.substring(pos));
  return _unescape(out.toString());
}

void _walk(Object? o, List<String> out) {
  if (o is String) {
    out.add(o);
  } else if (o is List<dynamic>) {
    for (final dynamic x in o) {
      _walk(x, out);
    }
  } else if (o is Map<String, dynamic>) {
    for (final dynamic x in o.values) {
      _walk(x, out);
    }
  }
}

List<String> _units(File f) {
  final String raw = f.readAsStringSync();
  if (f.path.endsWith('.dart')) return <String>[_dartLogical(raw)];
  final List<String> out = <String>[];
  try {
    _walk(jsonDecode(raw), out);
  } on FormatException {
    return <String>[];
  }
  return out;
}

List<_Ref> _findRefs(String text, _Quran q) {
  final List<_Ref> out = <_Ref>[];
  for (final RegExpMatch m in _numRef.allMatches(text)) {
    final int s = int.parse(m.group(1)!);
    final int a = int.parse(m.group(2)!);
    final int b = m.group(3) == null ? a : int.parse(m.group(3)!);
    out.add(_Ref(m.start, m.end, s, a, b, m.group(0)!.trim()));
  }
  for (final RegExpMatch m in _namedRef.allMatches(text)) {
    final int? n = q.names[_key(m.group(1)!)];
    if (n == null) continue;
    final int a = int.parse(m.group(2)!);
    final int b = m.group(3) == null ? a : int.parse(m.group(3)!);
    out.add(_Ref(m.start, m.end, n, a, b, m.group(0)!.trim()));
  }
  return out;
}

bool _quoteOk(String quote, _Ref r, _Quran q) {
  final List<String> pieces = quote
      .split(_split)
      .where((String p) => _normEn(p, false).split(' ').length >= 2)
      .toList();
  if (pieces.isEmpty) return true;
  final List<String> ayat = q.englishRange(r.surah, r.from, r.to);
  for (final bool keep in <bool>[true, false]) {
    final String hay = ayat.map((String x) => _normEn(x, keep)).join(' ');
    if (pieces.every(
      (String p) => hay.contains(_normEn(p, false)) || hay.contains(_normEn(p, true)),
    )) {
      return true;
    }
  }
  return false;
}

/// Quotations placed next to a valid reference: (quote, ref).
List<({String quote, _Ref ref})> _pairQuotes(
  String text,
  List<_Ref> refs,
  bool dart,
) {
  final List<({String quote, _Ref ref})> out = <({String quote, _Ref ref})>[];
  for (final RegExpMatch qm in (dart ? _quoteDart : _quoteAny).allMatches(text)) {
    final String qt = qm.group(1)!;
    if (!_word3.hasMatch(qt)) continue;
    final List<_Ref> after = refs
        .where((_Ref r) => r.start - qm.end >= 0 && r.start - qm.end <= 45)
        .toList();
    final _Ref ref;
    if (after.isNotEmpty) {
      ref = after.reduce((_Ref a, _Ref b) => b.start < a.start ? b : a);
      if (_hadith.hasMatch(text.substring(qm.end, ref.start))) continue;
    } else {
      final List<_Ref> before = refs
          .where((_Ref r) =>
              qm.start - r.end >= 0 &&
              qm.start - r.end <= 8 &&
              _gap.hasMatch(text.substring(r.end, qm.start)))
          .toList();
      if (before.isEmpty) continue;
      ref = before.reduce((_Ref a, _Ref b) => b.end > a.end ? b : a);
    }
    out.add((quote: qt, ref: ref));
  }
  return out;
}

List<File> _files() {
  final List<File> out = <File>[];
  for (final FileSystemEntity e
      in Directory('assets').listSync(recursive: true)) {
    final String p = e.path.replaceAll('\\', '/');
    if (e is File &&
        p.endsWith('.json') &&
        !p.startsWith('assets/quran/') &&
        !p.endsWith('content_manifest.json')) {
      out.add(e);
    }
  }
  for (final FileSystemEntity e in Directory('lib').listSync(recursive: true)) {
    if (e is File && e.path.endsWith('.dart')) out.add(e);
  }
  out.sort((File a, File b) => a.path.compareTo(b.path));
  return out;
}

bool _strict(String rel) => _strictPrefixes.any(rel.startsWith);

final RegExp _refId = RegExp(r'^(\d+):(\d+)(?:-(\d+))?$');

void main() {
  final _Quran q = _Quran(
    jsonDecode(File('assets/quran/quran.json').readAsStringSync())
        as List<dynamic>,
  );

  test('every Qur\'an reference in lib and assets exists in the bundled text',
      () {
    final List<String> bad = <String>[];
    int refs = 0;
    for (final File f in _files()) {
      final String rel = f.path.replaceAll('\\', '/');
      for (final String text in _units(f)) {
        for (final _Ref r in _findRefs(text, q)) {
          refs++;
          if (!q.valid(r.surah, r.from, r.to)) {
            bad.add('$rel: "${r.label}" does not exist in the bundled Qur\'an');
          }
        }
      }
    }
    expect(refs, greaterThan(1000), reason: 'the scan found the references');
    expect(bad, isEmpty, reason: bad.join('\n'));
  });

  test('Hadi quotes next to a reference are word for word in the cited ayah',
      () {
    final List<String> bad = <String>[];
    int checked = 0;
    for (final File f in _files()) {
      final String rel = f.path.replaceAll('\\', '/');
      if (!_strict(rel)) continue;
      for (final String text in _units(f)) {
        final List<_Ref> refs = _findRefs(text, q)
            .where((_Ref r) => q.valid(r.surah, r.from, r.to))
            .toList();
        for (final ({String quote, _Ref ref}) p
            in _pairQuotes(text, refs, f.path.endsWith('.dart'))) {
          checked++;
          if (!_quoteOk(p.quote, p.ref, q)) {
            final String shown = p.quote.length > 90
                ? p.quote.substring(0, 90)
                : p.quote;
            bad.add('$rel: "$shown" is not word for word in ${p.ref.label}');
          }
        }
      }
    }
    expect(checked, greaterThan(40), reason: 'the scan found the quotations');
    expect(bad, isEmpty, reason: bad.join('\n'));
  });

  test('noor.json Qur\'an entries and the Hadi corpus match the bundled text',
      () {
    final List<String> bad = <String>[];
    final Map<String, dynamic> noor = jsonDecode(
      File('assets/noor/noor.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    int quran = 0;
    for (final dynamic e in noor['entries'] as List<dynamic>) {
      final Map<String, dynamic> m = e as Map<String, dynamic>;
      if (m['k'] != 'quran') continue;
      quran++;
      final String ref = m['ref'] as String;
      final RegExpMatch? id = _refId.firstMatch(ref);
      if (id == null) {
        bad.add('noor.json: bad ref $ref');
        continue;
      }
      final int s = int.parse(id.group(1)!);
      final int a = int.parse(id.group(2)!);
      final int b = id.group(3) == null ? a : int.parse(id.group(3)!);
      if (!q.valid(s, a, b)) {
        bad.add('noor.json: $ref does not exist');
        continue;
      }
      final String ar =
          q.arabicRange(s, a, b).map(_normAr).join(' ');
      if (!ar.contains(_normAr(m['ar'] as String))) {
        bad.add('noor.json: Arabic of $ref is not in the bundled ayah');
      }
      final _Ref r = _Ref(0, 0, s, a, b, ref);
      if (!_quoteOk(m['en'] as String, r, q)) {
        bad.add('noor.json: English of $ref is not in the bundled ayah');
      }
    }
    expect(quran, greaterThan(10));
    final Map<String, dynamic> corpus = jsonDecode(
      File('assets/noor/hadi_corpus.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final List<dynamic> verses = corpus['quran'] as List<dynamic>;
    expect(verses, isNotEmpty);
    for (final dynamic v in verses) {
      final String ref = (v as Map<String, dynamic>)['ref'] as String;
      final RegExpMatch? id = _refId.firstMatch(ref);
      if (id == null) {
        bad.add('hadi_corpus.json: bad ref $ref');
        continue;
      }
      final int s = int.parse(id.group(1)!);
      final int a = int.parse(id.group(2)!);
      final int b = id.group(3) == null ? a : int.parse(id.group(3)!);
      if (!q.valid(s, a, b)) bad.add('hadi_corpus.json: $ref does not exist');
    }
    expect(bad, isEmpty, reason: bad.join('\n'));
  });

  test('the reference and quotation readers work on the usual shapes', () {
    List<String> labels(String s) =>
        _findRefs(s, q).map((_Ref r) => '${r.surah}:${r.from}-${r.to}').toList();

    expect(labels("(Qur'an 2:255)"), <String>['2:255-255']);
    expect(labels('Quran 94:5-6'), <String>['94:5-6']);
    expect(labels('(Al-Baqarah 255)'), <String>['2:255-255']);
    expect(labels('Al-Imran 35-37'), <String>['3:35-37']);
    expect(labels('at 5:30 pm'), isEmpty);
    expect(q.valid(2, 255, 255), isTrue);
    expect(q.valid(2, 287, 287), isFalse);
    expect(q.valid(115, 1, 1), isFalse);
    expect(q.valid(94, 6, 5), isFalse);

    const String good =
        'Allah says: “Indeed, with hardship [will be] ease.” (Qur\'an 94:5).';
    final List<_Ref> r1 = _findRefs(good, q);
    final List<({String quote, _Ref ref})> p1 = _pairQuotes(good, r1, true);
    expect(p1, hasLength(1));
    expect(_quoteOk(p1.single.quote, p1.single.ref, q), isTrue);

    const String bad =
        'Allah says: “Indeed, hardship never ends for anyone.” (Qur\'an 94:5).';
    final List<({String quote, _Ref ref})> p2 =
        _pairQuotes(bad, _findRefs(bad, q), true);
    expect(p2, hasLength(1));
    expect(_quoteOk(p2.single.quote, p2.single.ref, q), isFalse);

    // A quotation followed by a hadith citation is not a Qur'an quote.
    const String had =
        'He said: “Seek it in the last ten nights.” (Sahih al-Bukhari 2017). See (97:1).';
    expect(_pairQuotes(had, _findRefs(had, q), true), isEmpty);

    // Adjacent Dart literals are joined before reading.
    final String joined = _dartLogical(
      "const a = 'Allah says: “Indeed, with hardship '\n    '[will be] ease.” (Qur\\'an 94:5)';",
    );
    expect(_pairQuotes(joined, _findRefs(joined, q), true), hasLength(1));
  });
}
