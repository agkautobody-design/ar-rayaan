/// Offline Qur'an search over the bundled text (Tanzil Uthmani Arabic +
/// Saheeh International). Pure functions — no I/O, no Flutter — so the
/// whole behaviour is unit-tested.
///
/// * "2:255" / "2.255" jumps straight to that ayah.
/// * Arabic queries are matched after folding diacritics, Qur'anic marks,
///   hamza/alef/ya/ta-marbuta variants (typing بسم الله finds the
///   fully-voweled text). A skeleton pass (alef/waw/ya dropped) also
///   bridges Uthmani spelling (الصلوة) and plain spelling (الصلاة).
/// * English queries match when every word occurs (word-prefix tolerant),
///   phrase matches first.
library;

import '../../quran/domain/quran_models.dart';
import 'search_text.dart' show normalizeSearchQuery;

/// One search result.
class QuranHit {
  const QuranHit({
    required this.surah,
    required this.ayah,
    required this.score,
    required this.arabic,
    required this.english,
    required this.surahName,
  });

  final int surah;
  final int ayah;

  /// Higher is better: 3 = exact verse key, 2 = phrase match, 1 = loose.
  final int score;
  final String arabic;
  final String english;
  final String surahName;

  String get key => '$surah:$ayah';
}

/// Fold Arabic text for matching: strip tashkeel, Qur'anic annotation
/// marks and tatweel; unify alef/hamza/ya/ta-marbuta forms; drop hamza.
String foldArabic(String input) {
  final StringBuffer out = StringBuffer();
  for (final int r in input.runes) {
    if ((r >= 0x064B && r <= 0x065F) ||
        r == 0x0670 ||
        (r >= 0x06D6 && r <= 0x06ED) ||
        (r >= 0x0610 && r <= 0x061A) ||
        r == 0x0640 ||
        r == 0x200C ||
        r == 0x200D ||
        r == 0x200F ||
        r == 0x200E) {
      continue;
    }
    switch (r) {
      case 0x0671: // ٱ
      case 0x0623: // أ
      case 0x0625: // إ
      case 0x0622: // آ
        out.writeCharCode(0x0627); // ا
      case 0x0649: // ى
        out.writeCharCode(0x064A); // ي
      case 0x0629: // ة
        out.writeCharCode(0x0647); // ه
      case 0x0624: // ؤ
        out.writeCharCode(0x0648); // و
      case 0x0626: // ئ
        out.writeCharCode(0x064A); // ي
      case 0x0621: // ء
        break;
      default:
        out.writeCharCode(r);
    }
  }
  return out.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
}

/// [foldArabic] with the long-vowel letters (alef, waw, ya) removed — the
/// "skeleton" that is identical for Uthmani and plain spellings.
String arabicSkeleton(String input) =>
    foldArabic(input).replaceAll(RegExp('[اوي]'), '');

bool containsArabicLetters(String s) =>
    s.runes.any((int r) => r >= 0x0600 && r <= 0x06FF);

/// Lower-case English with bracketed translator insertions unwrapped,
/// punctuation reduced to spaces.
String foldEnglish(String input) {
  return input
      .toLowerCase()
      .replaceAll(RegExp(r"[^a-z0-9' ]"), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Parses "2:255", "2.255", "2 : 255" into (surah, ayah) or null.
({int surah, int ayah})? parseVerseKey(String q) {
  final RegExpMatch? m =
      RegExp(r'^\s*(\d{1,3})\s*[:.]\s*(\d{1,3})\s*$').firstMatch(q);
  if (m == null) return null;
  return (surah: int.parse(m.group(1)!), ayah: int.parse(m.group(2)!));
}

// The Qur'an text never changes while the app runs, so each ayah is folded
// once and remembered. Without this every keystroke re-folded all 6,236 ayahs
// (three regex passes each), which is what froze the page on long input.
final Expando<String> _foldedEnglish = Expando<String>('foldedEnglish');
final Expando<String> _foldedArabic = Expando<String>('foldedArabic');
final Expando<String> _skeletonArabic = Expando<String>('skeletonArabic');

String _enOf(Ayah a) => _foldedEnglish[a] ??= foldEnglish(a.english);
String _arOf(Ayah a) => _foldedArabic[a] ??= foldArabic(a.arabic);
String _skOf(Ayah a) => _skeletonArabic[a] ??= arabicSkeleton(a.arabic);

/// Searches [surahs] (all 114, in order). Returns at most [limit] hits.
List<QuranHit> searchQuran(
  List<Surah> surahs,
  String query, {
  int limit = 30,
}) {
  final String q = normalizeSearchQuery(query);
  if (q.isEmpty || surahs.isEmpty) return const <QuranHit>[];

  final ({int surah, int ayah})? key = parseVerseKey(q);
  if (key != null) {
    if (key.surah < 1 || key.surah > surahs.length) return const <QuranHit>[];
    final Surah s = surahs[key.surah - 1];
    if (key.ayah < 1 || key.ayah > s.ayahs.length) return const <QuranHit>[];
    final Ayah a = s.ayahs[key.ayah - 1];
    return <QuranHit>[
      QuranHit(
        surah: s.meta.number,
        ayah: a.number,
        score: 3,
        arabic: a.arabic,
        english: a.english,
        surahName: s.meta.transliteration,
      ),
    ];
  }

  final List<QuranHit> hits = <QuranHit>[];
  if (containsArabicLetters(q)) {
    final String folded = foldArabic(q);
    final String skeleton = arabicSkeleton(q);
    if (skeleton.length < 2) return const <QuranHit>[];
    for (final Surah s in surahs) {
      for (final Ayah a in s.ayahs) {
        final String fa = _arOf(a);
        int score = 0;
        if (folded.isNotEmpty && fa.contains(folded)) {
          score = 2;
        } else if (_skOf(a).contains(skeleton)) {
          score = 1;
        }
        if (score > 0) {
          hits.add(
            QuranHit(
              surah: s.meta.number,
              ayah: a.number,
              score: score,
              arabic: a.arabic,
              english: a.english,
              surahName: s.meta.transliteration,
            ),
          );
        }
      }
    }
  } else {
    final String phrase = foldEnglish(q);
    if (phrase.length < 2) return const <QuranHit>[];
    final List<String> words = phrase.split(' ');
    for (final Surah s in surahs) {
      for (final Ayah a in s.ayahs) {
        final String en = _enOf(a);
        int score = 0;
        if (en.contains(phrase)) {
          score = 2;
        } else if (words.length > 1 && words.every((String w) => en.contains(w))) {
          score = 1;
        }
        if (score > 0) {
          hits.add(
            QuranHit(
              surah: s.meta.number,
              ayah: a.number,
              score: score,
              arabic: a.arabic,
              english: a.english,
              surahName: s.meta.transliteration,
            ),
          );
        }
      }
    }
  }
  // Stable: higher score first, then Qur'anic order (already in order).
  final List<QuranHit> exact =
      hits.where((QuranHit h) => h.score == 2).toList();
  final List<QuranHit> loose =
      hits.where((QuranHit h) => h.score == 1).toList();
  return <QuranHit>[...exact, ...loose].take(limit).toList();
}
