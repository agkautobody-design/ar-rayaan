/// A read-only view of the bundled Qur'an text for Academy v3 lessons.
///
/// A v3 lesson never carries Qur'anic Arabic of its own: it names an ayah as
/// `q:<surah>:<ayah>` (or a range `q:<surah>:<from>-<to>`) and the Arabic, the
/// English and, where the app has one, the transliteration are read from
/// `assets/quran/quran.json` and `assets/quran/transliteration.json`. Pure
/// Dart (no Flutter), so the same code runs in the app and in the tests.
library;

import 'dart:convert';

/// One ayah as stored in quran.json (Tanzil Uthmani Arabic, Saheeh
/// International English).
class Verse {
  const Verse({required this.arabic, required this.english});

  final String arabic;
  final String english;
}

/// A parsed `q:` reference: one ayah, or a run of ayat within one surah.
class QuranRef {
  const QuranRef(this.surah, this.from, this.to);

  final int surah;
  final int from;
  final int to;

  bool get isRange => to != from;

  static final RegExp _pattern = RegExp(r'^q:(\d{1,3}):(\d{1,3})(?:-(\d{1,3}))?$');

  /// True when [ref] is written as a Qur'an reference (it may still not
  /// resolve; see [QuranVerses.has]).
  static bool looksLikeOne(String ref) => ref.startsWith('q:');

  static QuranRef? tryParse(String ref) {
    final RegExpMatch? m = _pattern.firstMatch(ref);
    if (m == null) return null;
    final int s = int.parse(m.group(1)!);
    final int a = int.parse(m.group(2)!);
    final int b = m.group(3) == null ? a : int.parse(m.group(3)!);
    if (b < a) return null;
    return QuranRef(s, a, b);
  }

  @override
  String toString() => isRange ? '$surah:$from-$to' : '$surah:$from';
}

class QuranVerses {
  QuranVerses._(this._verses, this._translit, [this._generated = const <String>{}]);

  /// [quranJson] is the content of assets/quran/quran.json;
  /// [transliterationJson] the content of assets/quran/transliteration.json
  /// (optional: an ayah without one simply shows none).
  factory QuranVerses.parse(
    String quranJson, {
    String? transliterationJson,
    String? fallbackTransliterationJson,
  }) {
    final List<dynamic> data = jsonDecode(quranJson) as List<dynamic>;
    final Map<int, List<Verse>> verses = <int, List<Verse>>{};
    for (final dynamic raw in data) {
      final Map<String, dynamic> s = raw as Map<String, dynamic>;
      final int n = s['n'] as int;
      final List<dynamic> vs = s['v'] as List<dynamic>;
      verses[n] = <Verse>[
        for (final dynamic v in vs)
          Verse(
            arabic: (v as List<dynamic>)[1] as String,
            english: v[2] as String,
          ),
      ];
    }
    final Map<String, String> tr = <String, String>{};
    if (transliterationJson != null) {
      final Map<String, dynamic> t =
          jsonDecode(transliterationJson) as Map<String, dynamic>;
      final Map<String, dynamic> map = t['map'] as Map<String, dynamic>;
      map.forEach((String k, dynamic v) => tr[k] = v as String);
    }
    // The program-made transliteration of every ayah fills what the curated
    // list does not have; those ayat are marked so screens say "Scholar review needed".
    final Set<String> generated = <String>{};
    if (fallbackTransliterationJson != null) {
      try {
        final Map<String, dynamic> t =
            jsonDecode(fallbackTransliterationJson) as Map<String, dynamic>;
        final Map<String, dynamic> map = t['map'] as Map<String, dynamic>;
        map.forEach((String k, dynamic v) {
          if (!tr.containsKey(k) && v is String && v.trim().isNotEmpty) {
            tr[k] = v;
            generated.add(k);
          }
        });
      } catch (_) {
        // Unreadable: those ayat simply have no transliteration.
      }
    }
    return QuranVerses._(verses, tr, generated);
  }

  final Map<int, List<Verse>> _verses;
  final Map<String, String> _translit;
  final Set<String> _generated;

  int get surahCount => _verses.length;

  int ayahCount(int surah) => _verses[surah]?.length ?? 0;

  /// The ayah, or null when [surah]:[ayah] does not exist.
  Verse? verse(int surah, int ayah) {
    final List<Verse>? list = _verses[surah];
    if (list == null || ayah < 1 || ayah > list.length) return null;
    return list[ayah - 1];
  }

  /// The app's transliteration of the ayah, or null when it has none.
  String? transliteration(int surah, int ayah) => _translit['$surah:$ayah'];

  /// True when the ayah's transliteration was made by a program (not curated).
  bool transliterationIsGenerated(int surah, int ayah) =>
      _generated.contains('$surah:$ayah');

  /// True when every ayah of [ref] exists.
  bool has(QuranRef ref) {
    for (int a = ref.from; a <= ref.to; a++) {
      if (verse(ref.surah, a) == null) return false;
    }
    return true;
  }
}
