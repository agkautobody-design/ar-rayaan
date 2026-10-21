// Qur'an reference gate (mirrors tool/quran_ref_check.py).
//
// 1. Every explicit Qur'an reference in lib/**/*.dart and assets/**/*.json
//    ("Qur'an 2:255", "(94:5-6)", "(Al-Baqarah 255)") must exist in the
//    bundled text (assets/quran/quran.json).
// 2. EVERYWHERE in the repo (not only the Hadi knowledge base) every quotation
//    placed next to a reference must be inside the cited ayah(s), word for
//    word in the bundled Saheeh International text (case, punctuation and the
//    translator's [brackets] ignored): scripture is never quoted from memory
//    and a paraphrase is never put inside quotation marks. The only exceptions
//    are listed, each with a reason, in tool/quran_quote_allowlist.json.
// 3. Qur'an "cards" (JSON {arabic, text|body, source: "Qur'an 94:5-6"} and
//    Dart FeelingResponse(kind: 'Quran', text:, source:)) must carry the
//    bundled wording.
// 4. The bundled-ayah entries in assets/noor/noor.json must match the bundled
//    Arabic and English, and the Hadi corpus may only name ayat that exist.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

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

// Quotations are read from decoded string values, so any quotation mark may
// delimit them; an apostrophe inside a word (Qur'an, Prophet's) does not.
final RegExp _quote = RegExp(
  r'''(?<![A-Za-z0-9])[‘'“"]([^‘“"”]{10,}?)['’”"](?![A-Za-z0-9])''',
);
final RegExp _hadith = RegExp(
  r'bukhari|muslim|tirmidhi|da[wu]*[ou]*d|nasa|majah|ahmad',
  caseSensitive: false,
);
final RegExp _word3 = RegExp(r'[A-Za-z]{3}.*[A-Za-z]{3}');
final RegExp _gap = RegExp(r'^[\s:—–\-,]*$');
final RegExp _split = RegExp(r'\.\.\.|…|\[\.\.\.\]');

// A card's source: "Qur'an 94:5-6", "Quran 2:286 — excerpt", "Qur'an 71:28 (..)".
final RegExp _recSource = RegExp(
  r"^\s*(?:Qur['’]?an|Quran)\s*(\d{1,3}):(\d{1,3})(?:\s*[-–]\s*(\d{1,3}))?(?:\s*[(—·].*)?$",
);
final RegExp _dartRec = RegExp(
  r"kind:\s*'Quran',\s*text:\s*'((?:[^'\\]|\\.)*)',\s*source:\s*'((?:[^'\\]|\\.)*)'",
);
final RegExp _firstSentence = RegExp(r'^(.*?[.?!])(?:\s|$)', dotAll: true);
final RegExp _uEsc = RegExp(r'u\{([0-9a-fA-F]+)\}|u([0-9a-fA-F]{4})');
final RegExp _alnum = RegExp(r'[A-Za-z0-9]');

const Map<String, String> _escapes = <String, String>{
  'n': '\n',
  't': '\t',
  'r': '\r',
  'b': '\b',
  'f': '\f',
  'v': '\v',
};

class _Ref {
  const _Ref(this.start, this.end, this.surah, this.from, this.to, this.label);
  final int start;
  final int end;
  final int surah;
  final int from;
  final int to;
  final String label;
}

class _Unit {
  const _Unit(this.text, this.line);
  final String text;
  final int line;
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
    RegExp(r'[ؐ-ًؚ-ٰٟۖ-ۭ࣓-ࣿـ]'),
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

/// Decoded Dart string literals. Adjacent literals (only whitespace between
/// them) are one unit, as at runtime. Comments are skipped and ${...}
/// interpolations dropped (same reading as tool/quran_ref_check.py).
List<_Unit> _dartUnits(String raw) {
  final List<_Unit> out = <_Unit>[];
  StringBuffer? cur;
  int curLine = 0;
  int lastEnd = -1;
  int i = 0;
  int line = 1;
  final int n = raw.length;
  while (i < n) {
    final String c = raw[i];
    if (c == '\n') {
      line++;
      i++;
    } else if (raw.startsWith('//', i)) {
      while (i < n && raw[i] != '\n') {
        i++;
      }
    } else if (raw.startsWith('/*', i)) {
      int j = raw.indexOf('*/', i + 2);
      j = j < 0 ? n : j + 2;
      line += '\n'.allMatches(raw.substring(i, j)).length;
      i = j;
    } else if (c == "'" || c == '"') {
      final bool isRaw =
          i > 0 && raw[i - 1] == 'r' && (i < 2 || !_alnum.hasMatch(raw[i - 2]));
      final bool triple = raw.startsWith(c * 3, i);
      final String delim = triple ? c * 3 : c;
      int j = i + delim.length;
      final StringBuffer buf = StringBuffer();
      final int startLine = line;
      while (j < n && !raw.startsWith(delim, j)) {
        final String ch = raw[j];
        if (ch == '\n') line++;
        if (ch == r'\' && !isRaw && j + 1 < n) {
          final String nx = raw[j + 1];
          if (nx == 'u') {
            final Match? m = _uEsc.matchAsPrefix(raw, j + 1);
            if (m != null) {
              buf.writeCharCode(
                int.parse((m.group(1) ?? m.group(2))!, radix: 16),
              );
              j = m.end;
              continue;
            }
          }
          buf.write(_escapes[nx] ?? nx);
          if (nx == '\n') line++;
          j += 2;
          continue;
        }
        if (ch == r'$' && !isRaw && raw.startsWith(r'${', j)) {
          int depth = 1;
          j += 2;
          while (j < n && depth > 0) {
            if (raw[j] == '{') depth++;
            if (raw[j] == '}') depth--;
            j++;
          }
          continue;
        }
        buf.write(ch);
        j++;
      }
      j = j + delim.length > n ? n : j + delim.length;
      if (cur != null && raw.substring(lastEnd, i).trim().isEmpty) {
        cur.write(buf.toString());
      } else {
        if (cur != null) out.add(_Unit(cur.toString(), curLine));
        cur = StringBuffer(buf.toString());
        curLine = startLine;
      }
      lastEnd = j;
      i = j;
    } else {
      i++;
    }
  }
  if (cur != null) out.add(_Unit(cur.toString(), curLine));
  return out;
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

List<_Unit> _units(File f) {
  final String raw = f.readAsStringSync();
  if (f.path.endsWith('.dart')) return _dartUnits(raw);
  final List<String> strings = <String>[];
  try {
    _walk(jsonDecode(raw), strings);
  } on FormatException {
    return <_Unit>[];
  }
  return <_Unit>[for (final String s in strings) _Unit(s, 0)];
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
List<({String quote, _Ref ref})> _pairQuotes(String text, List<_Ref> refs) {
  final List<({String quote, _Ref ref})> out = <({String quote, _Ref ref})>[];
  for (final RegExpMatch qm in _quote.allMatches(text)) {
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

/// Qur'an cards: (text, ref) from JSON records with an "arabic" key and a
/// Qur'an "source", and from Dart FeelingResponse(kind: 'Quran', ...).
List<({String text, _Ref ref})> _cards(File f, _Quran q) {
  final List<({String text, _Ref ref})> out = <({String text, _Ref ref})>[];
  _Ref? refOf(String source) {
    final RegExpMatch? m = _recSource.firstMatch(source);
    if (m == null) return null;
    final int s = int.parse(m.group(1)!);
    final int a = int.parse(m.group(2)!);
    final int b = m.group(3) == null ? a : int.parse(m.group(3)!);
    return _Ref(0, 0, s, a, b, source);
  }

  void walk(Object? o) {
    if (o is Map<String, dynamic>) {
      final Object? src = o['source'];
      final _Ref? r = src is String ? refOf(src) : null;
      if (r != null && o.containsKey('arabic')) {
        for (final String key in <String>['text', 'body']) {
          final Object? t = o[key];
          if (t is String) {
            String text = t;
            if (key == 'body') {
              final RegExpMatch? fm = _firstSentence.firstMatch(t);
              if (fm != null) text = fm.group(1)!;
            }
            out.add((text: text, ref: r));
          }
        }
      }
      for (final Object? v in o.values) {
        walk(v);
      }
    } else if (o is List<dynamic>) {
      for (final Object? v in o) {
        walk(v);
      }
    }
  }

  final String raw = f.readAsStringSync();
  if (f.path.endsWith('.dart')) {
    for (final RegExpMatch m in _dartRec.allMatches(raw)) {
      final _Ref? r = refOf(_unescape(m.group(2)!));
      if (r != null) out.add((text: _unescape(m.group(1)!), ref: r));
    }
  } else {
    try {
      walk(jsonDecode(raw));
    } on FormatException {
      return out;
    }
  }
  return out.where((({String text, _Ref ref}) c) => q.valid(c.ref.surah, c.ref.from, c.ref.to)).toList();
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

final RegExp _refId = RegExp(r'^(\d+):(\d+)(?:-(\d+))?$');

/// tool/quran_quote_allowlist.json: [{file, quote, reason}] keyed by
/// "file|normalised quote".
Map<String, Map<String, dynamic>> _allowlist() {
  final File f = File('tool/quran_quote_allowlist.json');
  final Map<String, Map<String, dynamic>> out =
      <String, Map<String, dynamic>>{};
  if (!f.existsSync()) return out;
  for (final dynamic e in jsonDecode(f.readAsStringSync()) as List<dynamic>) {
    final Map<String, dynamic> m = e as Map<String, dynamic>;
    out['${m['file']}|${_normEn(m['quote'] as String, false)}'] = m;
  }
  return out;
}

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
      for (final _Unit u in _units(f)) {
        for (final _Ref r in _findRefs(u.text, q)) {
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

  test('every quotation next to a Qur\'an reference is word for word in the '
      'cited ayah (whole repo, allowlist aside)', () {
    final Map<String, Map<String, dynamic>> allow = _allowlist();
    final Set<String> used = <String>{};
    final List<String> bad = <String>[];
    for (final MapEntry<String, Map<String, dynamic>> e in allow.entries) {
      if ((e.value['reason'] as String? ?? '').trim().isEmpty) {
        bad.add('allowlist entry without a reason: ${e.key}');
      }
    }
    int checked = 0;
    for (final File f in _files()) {
      final String rel = f.path.replaceAll('\\', '/');
      for (final _Unit u in _units(f)) {
        final List<_Ref> refs = _findRefs(u.text, q)
            .where((_Ref r) => q.valid(r.surah, r.from, r.to))
            .toList();
        for (final ({String quote, _Ref ref}) p in _pairQuotes(u.text, refs)) {
          checked++;
          if (_quoteOk(p.quote, p.ref, q)) continue;
          final String key = '$rel|${_normEn(p.quote, false)}';
          if (allow.containsKey(key)) {
            used.add(key);
            continue;
          }
          final String shown =
              p.quote.length > 90 ? p.quote.substring(0, 90) : p.quote;
          bad.add('$rel:${u.line}: "$shown" is not word for word in '
              '${p.ref.label}');
        }
      }
    }
    for (final String key in allow.keys) {
      if (!used.contains(key)) {
        bad.add('allowlist entry matches nothing (remove it): $key');
      }
    }
    expect(checked, greaterThan(400), reason: 'the scan found the quotations');
    expect(bad, isEmpty, reason: bad.join('\n'));
  });

  test('Qur\'an cards carry the bundled wording', () {
    final Map<String, Map<String, dynamic>> allow = _allowlist();
    final List<String> bad = <String>[];
    int cards = 0;
    for (final File f in _files()) {
      final String rel = f.path.replaceAll('\\', '/');
      for (final ({String text, _Ref ref}) c in _cards(f, q)) {
        cards++;
        if (_quoteOk(c.text, c.ref, q)) continue;
        if (allow.containsKey('$rel|${_normEn(c.text, false)}')) continue;
        final String shown =
            c.text.length > 90 ? c.text.substring(0, 90) : c.text;
        bad.add('$rel: card text "$shown" is not word for word in '
            '${c.ref.label}');
      }
    }
    expect(cards, greaterThan(15), reason: 'the scan found the cards');
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
    final List<({String quote, _Ref ref})> p1 =
        _pairQuotes(good, _findRefs(good, q));
    expect(p1, hasLength(1));
    expect(_quoteOk(p1.single.quote, p1.single.ref, q), isTrue);

    const String bad =
        'Allah says: “Indeed, hardship never ends for anyone.” (Qur\'an 94:5).';
    final List<({String quote, _Ref ref})> p2 =
        _pairQuotes(bad, _findRefs(bad, q));
    expect(p2, hasLength(1));
    expect(_quoteOk(p2.single.quote, p2.single.ref, q), isFalse);

    // A paraphrase inside plain single quotes is a quotation too.
    const String para =
        "Recite: 'Verily, in the remembrance of Allah do hearts find rest' (13:28).";
    final List<({String quote, _Ref ref})> p3 =
        _pairQuotes(para, _findRefs(para, q));
    expect(p3, hasLength(1));
    expect(_quoteOk(p3.single.quote, p3.single.ref, q), isFalse);

    // A quotation followed by a hadith citation is not a Qur'an quote.
    const String had =
        'He said: “Seek it in the last ten nights.” (Sahih al-Bukhari 2017). See (97:1).';
    expect(_pairQuotes(had, _findRefs(had, q)), isEmpty);

    // Adjacent Dart literals are one string; escaped quotes are quotation marks.
    final List<_Unit> units = _dartUnits(
      "const a = 'Allah says: \\'Indeed, with hardship '\n    '[will be] ease.\\' (Qur\\'an 94:5)';\n"
      "const b = 'x';\n// 'Indeed, nothing at all like this' (94:5)\n",
    );
    expect(units, hasLength(2));
    expect(
      units.first.text,
      "Allah says: 'Indeed, with hardship [will be] ease.' (Qur'an 94:5)",
    );
    final List<({String quote, _Ref ref})> p4 =
        _pairQuotes(units.first.text, _findRefs(units.first.text, q));
    expect(p4, hasLength(1));
    expect(_quoteOk(p4.single.quote, p4.single.ref, q), isTrue);

    // Card records: only a verbatim first sentence passes.
    final _Ref card = _Ref(0, 0, 94, 5, 6, 'Qur\'an 94:5-6');
    expect(_quoteOk('For indeed, with hardship [will be] ease.', card, q), isTrue);
    expect(_quoteOk('Indeed, with hardship comes ease.', card, q), isFalse);
  });
}
