import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../application/quran_repository.dart';
import '../domain/quran_models.dart';

/// Serves the complete Qur'an from the bundled asset (Tanzil Uthmani
/// Arabic + Saheeh International). Parsed once, held in memory.
class BundledQuranRepository implements QuranRepository {
  List<Surah>? _cache;

  Future<List<Surah>> _load() async {
    final List<Surah>? cached = _cache;
    if (cached != null) return cached;
    final String raw = await rootBundle.loadString('assets/quran/quran.json');
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
  Future<List<SurahMeta>> index() async {
    return (await _load()).map((Surah s) => s.meta).toList(growable: false);
  }

  @override
  Future<Surah> surah(int number) async {
    final List<Surah> all = await _load();
    if (number < 1 || number > all.length) {
      throw ArgumentError.value(number, 'number', 'Surah must be 1–114');
    }
    return all[number - 1];
  }
}
