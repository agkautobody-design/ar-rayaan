/// Qur'an domain models. Text is bundled (immutable, offline-first) —
/// Arabic (Tanzil Uthmani) + Saheeh International translation.
class SurahMeta {
  const SurahMeta({
    required this.number,
    required this.arabicName,
    required this.transliteration,
    required this.englishMeaning,
    required this.revelationType,
    required this.ayahCount,
  });

  final int number;
  final String arabicName;
  final String transliteration;
  final String englishMeaning;

  /// "meccan" | "medinan"
  final String revelationType;
  final int ayahCount;

  bool get isMeccan => revelationType == 'meccan';
}

class Ayah {
  const Ayah({
    required this.number,
    required this.arabic,
    required this.english,
  });

  final int number;
  final String arabic;
  final String english;
}

class Surah {
  const Surah({required this.meta, required this.ayahs});

  final SurahMeta meta;
  final List<Ayah> ayahs;
}

/// The user's saved reading position (Continue Reading).
class ReadingPosition {
  const ReadingPosition({required this.surah, required this.ayah});

  final int surah;
  final int ayah;
}
