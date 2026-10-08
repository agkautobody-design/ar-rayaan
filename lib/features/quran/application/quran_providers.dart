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

/// Continue-Reading position, persisted locally (syncs to the profile
/// record when Firestore lands with O-4).
class ReadingPositionController extends Notifier<ReadingPosition?> {
  static const String _key = 'ar.quran.lastRead';

  @override
  ReadingPosition? build() {
    try {
      final SharedPreferences prefs = ref.watch(sharedPreferencesProvider);
      final String? raw = prefs.getString(_key);
      if (raw != null) {
        final Map<String, dynamic> j = jsonDecode(raw) as Map<String, dynamic>;
        return ReadingPosition(
          surah: j['surah'] as int,
          ayah: j['ayah'] as int,
        );
      }
    } catch (_) {
      // No persistence in this context — position lives in memory only.
    }
    return null;
  }

  Future<void> save(ReadingPosition position) async {
    state = position;
    try {
      final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
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
