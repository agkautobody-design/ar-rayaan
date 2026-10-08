/// The Ar-Rayaan Player — domain (M1b.1).
/// Tracks, queues, repeat modes. Content catalogs arrive as packs; the
/// shell plays whatever catalog it's given.
library;

import 'dart:math';

import 'recitation_audio.dart';

enum RepeatMode { off, one, all }

enum NasheedSource { officialCatalog, personalImport, directUrl, youtubeStream }

class NasheedTrack {
  const NasheedTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.language,
    this.poet,
    this.theme = 'praise',
    this.collection,
    required this.durationSec,
    required this.source,
    required this.playableRef,
    this.licenseLine = '',
  });

  final String id;
  final String title;
  final String artist;
  final String language;
  final String? poet;
  final String theme;
  final String? collection;
  final int durationSec;
  final NasheedSource source;

  /// Local path or stream URL, resolved by the catalog/provider.
  final String playableRef;

  final String licenseLine;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'artist': artist,
        'language': language,
        if (poet != null) 'poet': poet,
        'theme': theme,
        if (collection != null) 'collection': collection,
        'durationSec': durationSec,
        'source': source.name,
        'playableRef': playableRef,
        'licenseLine': licenseLine,
      };

  factory NasheedTrack.fromJson(Map<String, dynamic> j) => NasheedTrack(
        id: j['id'] as String,
        title: j['title'] as String,
        artist: j['artist'] as String,
        language: j['language'] as String,
        poet: j['poet'] as String?,
        theme: j['theme'] as String? ?? 'praise',
        collection: j['collection'] as String?,
        durationSec: j['durationSec'] as int? ?? 0,
        source: NasheedSource.values.asNameMap()[j['source'] as String?] ??
            NasheedSource.officialCatalog,
        playableRef: j['playableRef'] as String,
        licenseLine: j['licenseLine'] as String? ?? '',
      );
}

abstract final class QueueEngine {
  /// Next index given repeat mode; returns null when the queue ends.
  static int? next(int current, int length, RepeatMode mode) {
    if (length == 0) return null;
    if (mode == RepeatMode.one) return current;
    if (current + 1 < length) return current + 1;
    return mode == RepeatMode.all ? 0 : null;
  }

  /// Previous index; at the start, repeats the first track (music-player
  /// convention: back at start = replay current).
  static int prev(int current, int length) {
    if (length == 0) return 0;
    return current > 0 ? current - 1 : 0;
  }

  /// A mood mix: theme/language-filtered, shuffled deterministically by
  /// [seed] (same seed, same mix — testable, shareable).
  static List<NasheedTrack> buildMix({
    required List<NasheedTrack> catalog,
    String? theme,
    String? language,
    int seed = 7,
    int maxTracks = 25,
  }) {
    // Mixes are official-catalog only by founder law: "Personal — added
    // by you" tracks never enter a mix even if a caller passes them in.
    final List<NasheedTrack> pool = catalog
        .where((NasheedTrack t) =>
            t.source != NasheedSource.personalImport &&
            (theme == null || t.theme == theme) &&
            (language == null || t.language == language))
        .toList();
    // Seeded Fisher-Yates: same seed -> same mix on every device
    // (dart:math Random(seed) is platform-stable), different seeds differ.
    final Random rng = Random(seed);
    for (int i = pool.length - 1; i > 0; i--) {
      final int j = rng.nextInt(i + 1);
      final NasheedTrack tmp = pool[i];
      pool[i] = pool[j];
      pool[j] = tmp;
    }
    return pool.length > maxTracks ? pool.sublist(0, maxTracks) : pool;
  }
}
