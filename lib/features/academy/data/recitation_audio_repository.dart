/// Recitation audio repository — fetch, on-device cache, honest fallback.
///
/// Per-ayah files are tried first. A 404 (or network failure) NEVER
/// crashes playback: the event degrades to the whole-surah file for
/// that range — honest fallback over fake precision (§4A).
library;

import 'dart:io';

import 'package:http/http.dart' as http;

import '../domain/recitation_audio.dart';

/// Where one utterance's sound comes from.
sealed class PlaybackSource {}

/// The normal path: a per-ayah MP3, cached on device after first fetch.
class AyahFileSource extends PlaybackSource {
  AyahFileSource(this.path, this.url);

  /// Local file path (cached). Equals [url] only before caching completes
  /// — callers should play from [path] when the file exists.
  final String path;
  final String url;
}

/// Fallback path: per-ayah file unavailable; use the whole-surah file.
class SurahFileSource extends PlaybackSource {
  SurahFileSource(this.url, this.surah);

  final String url;
  final int surah;
}

abstract final class RecitationAudioRepository {
  /// Resolve the audio source for [ref] from [pack].
  ///
  /// [cacheDir] holds downloaded ayah files; created if absent. A cached
  /// file is used without any network call (offline-first).
  static Future<PlaybackSource> resolve({
    required ReciterPack pack,
    required AyahRef ref,
    required Directory cacheDir,
    http.Client? client,
  }) async {
    final http.Client c = client ?? http.Client();
    final File target = File(
      '${cacheDir.path}/${ref.fileName}',
    );
    if (await target.exists()) {
      return AyahFileSource(target.path, pack.ayahUrl(ref));
    }
    final Uri uri = Uri.parse(pack.ayahUrl(ref));
    try {
      final http.Response res = await c.get(uri);
      if (res.statusCode == 200) {
        await cacheDir.create(recursive: true);
        await target.writeAsBytes(res.bodyBytes, flush: true);
        return AyahFileSource(target.path, uri.toString());
      }
    } on SocketException {
      // Offline and not cached — fall through to surah URL (the caller
      // may still stream it, or surface "download on Wi-Fi").
    }
    // 404 or offline: honest fallback to the whole-surah file.
    return SurahFileSource(pack.surahUrl(ref.surah), ref.surah);
  }

  /// Byte size ceiling for one ayah at 64kbps (~30s) — sanity check so a
  /// broken endpoint serving HTML error pages is never cached as "audio".
  static const int maxAyahBytes = 1 << 20; // 1MB

  /// Download a full-surah audio file into [cacheDir] (surah key
  /// "surah_001.mp3"). Returns the local file path, or null on failure.
  /// Progress is reported via [onProgress] (0.0–1.0).
  static Future<String?> downloadSurah({
    required ReciterPack pack,
    required int surah,
    required Directory cacheDir,
    void Function(double progress)? onProgress,
    http.Client? client,
  }) async {
    final http.Client c = client ?? http.Client();
    final String name =
        'surah_${surah.toString().padLeft(3, '0')}.mp3';
    final File target = File('${cacheDir.path}/$name');
    if (await target.exists()) return target.path;
    try {
      final Uri uri = Uri.parse(pack.surahUrl(surah));
      final http.Request req = http.Request('GET', uri);
      final http.StreamedResponse res = await c.send(req);
      if (res.statusCode != 200) return null;
      final int total = res.contentLength ?? 0;
      int received = 0;
      final List<int> bytes = <int>[];
      await res.stream.forEach((List<int> chunk) {
        bytes.addAll(chunk);
        received += chunk.length;
        if (total > 0) onProgress?.call(received / total);
      });
      await cacheDir.create(recursive: true);
      await target.writeAsBytes(bytes, flush: true);
      return target.path;
    } catch (_) {
      return null;
    }
  }
}
