import 'dart:convert';

import '../../../app/core/content_loader.dart';
import '../application/quran_repository.dart';
import '../domain/quran_index.dart';
import '../domain/quran_models.dart';

/// Serves the complete Qur'an from the bundled asset (Tanzil Uthmani
/// Arabic + Saheeh International). Parsed once, held in memory.
class BundledQuranRepository implements QuranRepository {
  List<Surah>? _cache;

  /// The download in progress, shared: the index, the reader and search all
  /// ask at once on first open, and the file must be fetched only once.
  Future<List<Surah>>? _inFlight;

  Future<List<Surah>> _load() {
    final List<Surah>? cached = _cache;
    if (cached != null) return Future<List<Surah>>.value(cached);
    return _inFlight ??= _fetch().whenComplete(() => _inFlight = null);
  }

  Future<List<Surah>> _fetch() async {
    final String raw = await ContentLoader.loadString(kQuranAsset);
    final List<dynamic> data = jsonDecode(raw) as List<dynamic>;
    final List<Surah> surahs = <Surah>[
      for (final Map<String, dynamic> s in data.cast<Map<String, dynamic>>())
        Surah(
          meta: SurahMeta(
            number: s['n'] as int,
            arabicName: s['ar'] as String,
            transliteration: s['tl'] as String,
            englishMeaning: s['en'] as String,
            revelationType: s['ty'] as String,
            ayahCount: s['c'] as int,
          ),
          ayahs: <Ayah>[
            for (final List<dynamic> v
                in (s['v'] as List<dynamic>).cast<List<dynamic>>())
              Ayah(
                number: v[0] as int,
                arabic: v[1] as String,
                english: v[2] as String,
              ),
          ],
        ),
    ];
    _cache = surahs;
    return surahs;
  }

  @override
  Future<List<Surah>> all() => _load();

  /// Answered from the names bundled in the code, not from the 2 MB text:
  /// the surah list must show at once, even on a slow connection or offline.
  @override
  Future<List<SurahMeta>> index() async => kSurahIndex;

  @override
  Future<Surah> surah(int number) async {
    final List<Surah> all = await _load();
    if (number < 1 || number > all.length) {
      throw ArgumentError.value(number, 'number', 'Surah must be 1–114');
    }
    return all[number - 1];
  }
}
