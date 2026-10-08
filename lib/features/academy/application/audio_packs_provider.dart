/// Audio packs state — which surahs are downloaded, download progress.
library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';
import '../domain/recitation_audio.dart';
import '../data/recitation_audio_repository.dart';

final audioPacksProvider =
    StateNotifierProvider<AudioPacksNotifier, Set<int>>((Ref ref) {
  return AudioPacksNotifier(ref.watch(sharedPreferencesProvider));
});

class AudioPacksNotifier extends StateNotifier<Set<int>> {
  AudioPacksNotifier(this._prefs) : super(<int>{}) {
    _load();
  }

  final SharedPreferences _prefs;
  static const String _key = 'ar.audio.packs.v1';

  Future<Directory> _dir() async {
    final Directory base = await getApplicationSupportDirectory();
    final Directory dir = Directory('${base.path}/recitation/husary');
    await dir.create(recursive: true);
    return dir;
  }

  void _load() {
    final String? raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return;
    state = raw.split(',').map((String s) => int.tryParse(s) ?? 0)
        .where((int n) => n > 0).toSet();
  }

  Future<void> _save() async {
    final List<int> sorted = state.toList()..sort();
    await _prefs.setString(_key, sorted.join(','));
  }

  static final List<int> kAllSurahs = List<int>.generate(114, (int i) => i + 1);

  bool has(int surah) => state.contains(surah);

  /// Progress stream per surah via a simple listener map (UI reads
  /// [progressOf] during download).
  final Map<int, double> _progress = <int, double>{};
  double progressOf(int surah) => _progress[surah] ?? 0;
  final List<void Function()> _listeners = <void Function()>[];
  void addProgressListener(void Function() l) => _listeners.add(l);
  void _notify() {
    for (final void Function() l in _listeners) {
      l();
    }
  }

  Future<String?> download(int surah) async {
    if (state.contains(surah)) return null;
    final Directory dir = await _dir();
    final String? path = await RecitationAudioRepository.downloadSurah(
      pack: ReciterPack.alHusary,
      surah: surah,
      cacheDir: dir,
      onProgress: (double p) {
        _progress[surah] = p;
        _notify();
      },
    );
    _progress.remove(surah);
    if (path != null) {
      state = <int>{...state, surah};
      await _save();
    }
    _notify();
    return path;
  }

  /// Mark a surah as downloaded without network (test seam + import flows).
  Future<void> markDownloaded(int surah) async {
    if (state.contains(surah)) return;
    state = <int>{...state, surah};
    await _save();
  }

  Future<void> remove(int surah) async {
    // File deletion is best-effort: on platforms/tests without a support
    // directory (MissingPlugin), the state update must still succeed.
    try {
      final Directory dir = await _dir();
      final File f = File(
          '${dir.path}/surah_${surah.toString().padLeft(3, '0')}.mp3');
      if (await f.exists()) await f.delete();
    } catch (_) {}
    state = state.where((int n) => n != surah).toSet();
    await _save();
    _notify();
  }

  /// Prune to the most recent [keep] surahs (storage pressure repair).
  Future<void> pruneTo(int keep) async {
    final List<int> sorted = state.toList()..sort();
    while (sorted.length > keep) {
      await remove(sorted.removeAt(0));
    }
  }
}
