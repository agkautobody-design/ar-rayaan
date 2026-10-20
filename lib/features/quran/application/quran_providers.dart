import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';
import '../data/bundled_quran_repository.dart';
import '../domain/quran_models.dart';
import 'quran_repository.dart';

final Provider<QuranRepository> quranRepositoryProvider =
    Provider<QuranRepository>((ref) => BundledQuranRepository());

/// All 114 surahs' metadata.
final FutureProvider<List<SurahMeta>> quranIndexProvider =
    FutureProvider<List<SurahMeta>>((ref) {
      return ref.watch(quranRepositoryProvider).index();
    });

/// Full text of one surah.
final FutureProviderFamily<Surah, int> surahProvider =
    FutureProvider.family<Surah, int>((ref, int number) {
      return ref.watch(quranRepositoryProvider).surah(number);
    });

/// The whole Qur'an, for offline search (parsed once, held in memory).
final FutureProvider<List<Surah>> quranAllProvider =
    FutureProvider<List<Surah>>((ref) {
      return ref.watch(quranRepositoryProvider).all();
    });

/// Continue-Reading position, persisted locally (syncs to the profile
/// record when Firestore lands with O-4).
class ReadingPositionController extends Notifier<ReadingPosition?> {
  static const String _key = 'ar.quran.lastRead';
  static const String _perSurahKey = 'ar.quran.positions';

  /// Last saved ayah for each surah, so opening another surah never wipes
  /// your place in this one.
  Map<int, int> _perSurah = <int, int>{};

  /// The ayah last saved inside [surah], or 1 if it was never opened.
  int ayahFor(int surah) => _perSurah[surah] ?? 1;

  @override
  ReadingPosition? build() {
    _perSurah = <int, int>{};
    try {
      final SharedPreferences p = ref.watch(sharedPreferencesProvider);
      final String? rawMap = p.getString(_perSurahKey);
      if (rawMap != null) {
        final Map<String, dynamic> m =
            jsonDecode(rawMap) as Map<String, dynamic>;
        m.forEach((String k, dynamic v) {
          final int? s = int.tryParse(k);
          if (s != null && v is int) _perSurah[s] = v;
        });
      }
    } catch (_) {
      // Unreadable positions map — start empty.
    }
    try {
      final SharedPreferences prefs = ref.watch(sharedPreferencesProvider);
      final String? raw = prefs.getString(_key);
      if (raw != null) {
        final Map<String, dynamic> j = jsonDecode(raw) as Map<String, dynamic>;
        final int surah = j['surah'] as int;
        final int ayah = j['ayah'] as int;
        _perSurah.putIfAbsent(surah, () => ayah);
        return ReadingPosition(surah: surah, ayah: ayah);
      }
    } catch (_) {
      // No persistence in this context — position lives in memory only.
    }
    return null;
  }

  Future<void> save(ReadingPosition position) async {
    state = position;
    _perSurah[position.surah] = position.ayah;
    try {
      final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(
        _perSurahKey,
        jsonEncode(<String, int>{
          for (final MapEntry<int, int> e in _perSurah.entries)
            '${e.key}': e.value,
        }),
      );
      await prefs.setString(
        _key,
        jsonEncode(<String, dynamic>{
          'surah': position.surah,
          'ayah': position.ayah,
        }),
      );
    } catch (_) {
      // In-memory only.
    }
  }
}

final NotifierProvider<ReadingPositionController, ReadingPosition?>
readingPositionProvider =
    NotifierProvider<ReadingPositionController, ReadingPosition?>(
      ReadingPositionController.new,
    );
