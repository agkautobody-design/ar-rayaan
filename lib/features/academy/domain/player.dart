/// The Ar-Rayaan Player — domain: tracks, catalog, queue, mixes.
/// Official RHW catalog: vocals-only by law; checksum-gated pack like
/// every other content pack (kCatalogSha256 recorded when Pack 1 ships).
library;

class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    this.poet,
    required this.language,
    required this.theme,
    required this.mood,
    required this.audioUrl,
    this.lyricsLines = const <String>[],
    this.licenseLine,
    this.officialUrl,
  });

  final String id;
  final String title;
  final String artist;
  final String? poet;
  final String language;
  final String theme;
  final String mood;
  final String audioUrl;
  final List<String> lyricsLines;
  final String? licenseLine;
  final String? officialUrl;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id, 'title': title, 'artist': artist,
        if (poet != null) 'poet': poet,
        'language': language, 'theme': theme, 'mood': mood,
        'audioUrl': audioUrl,
        if (lyricsLines.isNotEmpty) 'lyrics': lyricsLines,
        if (licenseLine != null) 'licenseLine': licenseLine,
        if (officialUrl != null) 'officialUrl': officialUrl,
      };

  factory Track.fromJson(Map<String, dynamic> j) => Track(
        id: j['id'] as String,
        title: j['title'] as String,
        artist: j['artist'] as String,
        poet: j['poet'] as String?,
        language: j['language'] as String,
        theme: j['theme'] as String,
        mood: j['mood'] as String,
        audioUrl: j['audioUrl'] as String,
        lyricsLines: (j['lyrics'] as List<dynamic>? ?? const <dynamic>[])
            .map((dynamic e) => e.toString()).toList(),
        licenseLine: j['licenseLine'] as String?,
        officialUrl: j['officialUrl'] as String?,
      );
}

class Catalog {
  const Catalog(this.tracks);
  final List<Track> tracks;

  List<Track> byLanguage(String lang) =>
      tracks.where((Track t) => t.language == lang).toList();
  List<Track> byTheme(String theme) =>
      tracks.where((Track t) => t.theme == theme).toList();
  List<String> get languages =>
      tracks.map((Track t) => t.language).toSet().toList()..sort();
  List<String> get artists =>
      tracks.map((Track t) => t.artist).toSet().toList()..sort();
  List<String> get poets =>
      tracks.where((Track t) => t.poet != null).map((Track t) => t.poet!).toSet().toList()..sort();
  List<String> get themes =>
      tracks.map((Track t) => t.theme).toSet().toList()..sort();
}

/// Queue state machine: play-next, reorder, save-as-playlist data.
class PlayerQueue {
  const PlayerQueue({
    this.tracks = const <Track>[],
    this.index = -1,
    this.playlistName,
  });

  final List<Track> tracks;
  final int index;
  final String? playlistName;

  Track? get current => index >= 0 && index < tracks.length ? tracks[index] : null;
  bool get isEmpty => tracks.isEmpty;

  PlayerQueue enqueue(Track t) => PlayerQueue(
        tracks: <Track>[...tracks, t],
        index: index < 0 ? 0 : index,
        playlistName: playlistName,
      );

  PlayerQueue playNext(Track t) {
    final int at = index < 0 ? 0 : index + 1;
    final List<Track> next = <Track>[...tracks]..insert(at, t);
    return PlayerQueue(tracks: next, index: index < 0 ? 0 : index, playlistName: playlistName);
  }

  PlayerQueue reorder(int from, int to) {
    if (from < 0 || from >= tracks.length || to < 0 || to >= tracks.length) return this;
    final List<Track> next = <Track>[...tracks];
    final Track t = next.removeAt(from);
    next.insert(to, t);
    int idx = index;
    if (from == index) idx = to;
    return PlayerQueue(tracks: next, index: idx, playlistName: playlistName);
  }

  PlayerQueue next() => index + 1 < tracks.length
      ? PlayerQueue(tracks: tracks, index: index + 1, playlistName: playlistName)
      : this;

  PlayerQueue previous() => index > 0
      ? PlayerQueue(tracks: tracks, index: index - 1, playlistName: playlistName)
      : this;

  PlayerQueue named(String name) =>
      PlayerQueue(tracks: tracks, index: index, playlistName: name);
}

abstract final class Mixes {
  /// Mood-seeded endless queue from the official catalog (all lawful by
  /// construction — the catalog gate enforces vocals-only at intake).
  static List<Track> seed(String mood, Catalog catalog, {int count = 25}) {
    final List<Track> pool = catalog.tracks.where((Track t) => t.mood == mood).toList();
    if (pool.isEmpty) return const <Track>[];
    final List<Track> out = <Track>[];
    for (var i = 0; i < count; i++) {
      out.add(pool[i % pool.length]);
    }
    return out;
  }

  static const List<String> kMoods = <String>[
    'morning', 'night', 'study', 'travel', 'ramadan',
  ];
}
