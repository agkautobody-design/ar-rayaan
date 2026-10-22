/// Approved in-app sources (YouTube / Spotify) for catalogue tracks.
///
/// A track plays inside the app only when it has an entry here. Entries are
/// checked against the artist's official channel by a person before they are
/// added; anything malformed is dropped on load.
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../domain/stream_link.dart';

class TrackSources {
  const TrackSources({this.youtube, this.spotify});

  final StreamLink? youtube;
  final StreamLink? spotify;

  /// YouTube first (a full track for everyone); Spotify otherwise.
  StreamLink? get preferred => youtube ?? spotify;
  bool get isEmpty => youtube == null && spotify == null;
}

abstract final class PlayerSourcesPack {
  static const String assetPath = 'assets/academy/player_sources.json';

  /// Pure parser (also used by tests). Bad entries are skipped.
  static Map<String, TrackSources> parse(String raw) {
    final Object? doc = jsonDecode(raw);
    if (doc is! Map<String, dynamic>) return const <String, TrackSources>{};
    final Object? sources = doc['sources'];
    if (sources is! Map<String, dynamic>) {
      return const <String, TrackSources>{};
    }
    final Map<String, TrackSources> out = <String, TrackSources>{};
    sources.forEach((String trackId, Object? v) {
      if (v is! Map<String, dynamic>) return;
      final Object? y = v['youtube'];
      final Object? s = v['spotify'];
      final StreamLink? yt = y is String
          ? StreamLink.parse('https://www.youtube.com/watch?v=$y')
          : null;
      final StreamLink? sp =
          s is String ? StreamLink.parse('https://open.spotify.com/$s') : null;
      final TrackSources t = TrackSources(
        youtube: yt?.service == StreamService.youtube ? yt : null,
        spotify: sp?.service == StreamService.spotify ? sp : null,
      );
      if (!t.isEmpty) out[trackId] = t;
    });
    return out;
  }

  static Future<Map<String, TrackSources>> load() async {
    try {
      return parse(await rootBundle.loadString(assetPath));
    } catch (_) {
      return const <String, TrackSources>{};
    }
  }
}
