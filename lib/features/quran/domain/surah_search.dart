/// Pure helpers for finding a surah in the index and jumping to an ayah.
/// No Flutter, no storage: easy to test.
library;

import 'quran_models.dart';

/// Surah and ayah of Ayat al-Kursi, for the list shortcut.
const int kAyatAlKursiSurah = 2;
const int kAyatAlKursiAyah = 255;

/// Lower-cases, folds common Arabic letter variants, and drops Arabic marks,
/// spaces and punctuation, so "Ya-Sin", "ya sin" and "yasin" all match and
/// "البقرة" matches however it is written.
String normaliseForSearch(String input) {
  final StringBuffer b = StringBuffer();
  for (final int r in input.toLowerCase().runes) {
    // Arabic marks (harakat, shadda, dagger alif) and tatweel.
    if ((r >= 0x064B && r <= 0x065F) || r == 0x0670 || r == 0x0640) continue;
    // Alef variants -> bare alef; alef maksura -> yeh; teh marbuta -> heh.
    if (r == 0x0622 || r == 0x0623 || r == 0x0625 || r == 0x0671) {
      b.writeCharCode(0x0627);
      continue;
    }
    if (r == 0x0649) {
      b.writeCharCode(0x064A);
      continue;
    }
    if (r == 0x0629) {
      b.writeCharCode(0x0647);
      continue;
    }
    final bool isDigit = r >= 0x30 && r <= 0x39;
    final bool isLatin = r >= 0x61 && r <= 0x7A;
    final bool isArabic = r >= 0x0621 && r <= 0x064A;
    if (isDigit || isLatin || isArabic) b.writeCharCode(r);
  }
  return b.toString();
}

/// Folds the common English spellings of the same sound onto one form, so
/// "Yaseen" and "Ya-Sin" (all "yasin" once folded) meet, and so do
/// "Noor" and "Nur", "Yousuf" and "Yusuf", "Ikhlaas" and "Ikhlas". Applied to
/// the typed text and to every name alike, so only spellings that SOUND the
/// same ever meet. Expects the output of [normaliseForSearch].
String foldSpelling(String normalised) {
  String s = normalised;
  // Long vowels written doubled.
  s = s.replaceAll('ee', 'i').replaceAll('ii', 'i');
  s = s.replaceAll('oo', 'u').replaceAll('uu', 'u').replaceAll('ou', 'u');
  s = s.replaceAll('aa', 'a');
  // "Yaseen" is often typed "Ya Seen" / "Yassin": a doubled s is one s.
  s = s.replaceAll('ss', 's');
  return s;
}

/// The surahs that match [query], in their original order. An empty query
/// returns everything. A number matches that surah number exactly; text
/// matches the transliteration, Arabic name or English meaning anywhere in
/// the name.
List<SurahMeta> filterSurahs(List<SurahMeta> all, String query) {
  final String q = normaliseForSearch(query);
  if (q.isEmpty) return all;
  final int? number = int.tryParse(q);
  if (number != null) {
    return <SurahMeta>[
      for (final SurahMeta s in all)
        if (s.number == number) s,
    ];
  }
  final String folded = foldSpelling(q);
  bool hits(String name) {
    final String n = normaliseForSearch(name);
    return n.contains(q) || foldSpelling(n).contains(folded);
  }

  return <SurahMeta>[
    for (final SurahMeta s in all)
      if (hits(s.transliteration) ||
          hits(s.arabicName) ||
          hits(s.englishMeaning))
        s,
  ];
}

/// Reads what the person typed into "Jump to ayah". Returns the ayah number
/// when it is a whole number from 1 to [ayahCount]; otherwise null.
int? parseAyahJump(String input, int ayahCount) {
  final int? n = int.tryParse(input.trim());
  if (n == null || n < 1 || n > ayahCount) return null;
  return n;
}
