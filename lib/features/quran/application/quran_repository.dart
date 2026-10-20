import '../domain/quran_models.dart';

/// Qur'an text contract. Bundled implementation serves all flavors today
/// (offline-first for immutable text); the seam allows future sources
/// (audio recitation, tafsir, additional translations) without UI changes.
abstract interface class QuranRepository {
  /// All 114 surahs' metadata, in order.
  Future<List<SurahMeta>> index();

  /// Full text of one surah (Arabic + English).
  Future<Surah> surah(int number);

  /// The whole Qur'an (all 114 surahs, in order) — for offline search.
  Future<List<Surah>> all();
}
