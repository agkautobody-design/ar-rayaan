/// Verified-links pack: nasheeds and naats whose video was checked against
/// the artist's or label's official YouTube channel (see
/// docs/content_needed/NASHEED_VERIFICATION_LOG.md). Same contract as the
/// other packs: checksum gate, nothing unverified. Regenerate with
/// tool/build_verified_catalogue.py, which prints the new digest.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../domain/player.dart';
import '../domain/stream_link.dart';
import 'player_sources_pack.dart';

const String kVerifiedCatalogSha256 =
    '38121d92689cb2a35158e0aa9732fe1580deeed9317c4937df2ab6c3dd08b9b2';

abstract final class PlayerVerifiedPack {
  static const String assetPath = 'assets/academy/player_catalog_verified.json';

  /// Pure parser (also used by tests). Entries without a valid 11-character
  /// video ID are dropped.
  static List<Track> parse(String raw) {
    final Object? doc = jsonDecode(raw);
    if (doc is! Map<String, dynamic>) return const <Track>[];
    final Object? list = doc['tracks'];
    if (list is! List<dynamic>) return const <Track>[];
    final List<Track> out = <Track>[];
    for (final Object? j in list) {
      if (j is! Map<String, dynamic>) continue;
      try {
        final Track t = Track.fromJson(j);
        final String? id = t.youtubeId;
        if (id == null) continue;
        if (StreamLink.parse('https://www.youtube.com/watch?v=$id') == null) {
          continue;
        }
        out.add(t);
      } catch (_) {
        continue;
      }
    }
    return out;
  }

  /// Sources map for the verified tracks, keyed by track id.
  static Map<String, TrackSources> sourcesOf(List<Track> tracks) {
    final Map<String, TrackSources> out = <String, TrackSources>{};
    for (final Track t in tracks) {
      final StreamLink? l =
          StreamLink.parse('https://www.youtube.com/watch?v=${t.youtubeId}');
      if (l != null) out[t.id] = TrackSources(youtube: l);
    }
    return out;
  }

  static Future<List<Track>> load() async {
    String raw;
    try {
      raw = await rootBundle.loadString(assetPath);
    } catch (_) {
      return const <Track>[];
    }
    if (sha256.convert(utf8.encode(raw)).toString() != kVerifiedCatalogSha256) {
      return const <Track>[];
    }
    return parse(raw);
  }
}
