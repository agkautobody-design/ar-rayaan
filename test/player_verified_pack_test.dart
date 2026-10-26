// Contract lock for the verified-links pack (official-channel nasheeds and
// naats). Every entry is a checked video on an official channel; nothing is
// hosted or downloadable; the checksum gates every byte.
import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/features/academy/data/player_verified_pack.dart';
import 'package:ar_rayaan/features/academy/domain/player.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final String raw =
      File('assets/academy/player_catalog_verified.json').readAsStringSync();

  test('file matches its checksum', () {
    expect(sha256.convert(utf8.encode(raw)).toString(),
        kVerifiedCatalogSha256);
  });

  test('every entry is a well-formed official-channel link', () {
    final List<Track> tracks = PlayerVerifiedPack.parse(raw);
    final List<dynamic> rows =
        (jsonDecode(raw) as Map<String, dynamic>)['tracks'] as List<dynamic>;
    expect(tracks.length, rows.length, reason: 'no entry may be dropped');
    expect(tracks.length, greaterThanOrEqualTo(200));
    final Set<String> ids = <String>{};
    final Set<String> videos = <String>{};
    for (int i = 0; i < tracks.length; i++) {
      final Track t = tracks[i];
      final Map<String, dynamic> j = rows[i] as Map<String, dynamic>;
      expect(ids.add(t.id), isTrue, reason: 'duplicate id ${t.id}');
      expect(videos.add(t.youtubeId!), isTrue, reason: 'duplicate video');
      expect(t.audioUrl, isEmpty, reason: 'no audio files in the repo');
      expect(t.hasAudio, isFalse);
      expect(t.officialUrl,
          'https://www.youtube.com/watch?v=${t.youtubeId}');
      expect(t.licenseLine, contains('Official upload'));
      expect(t.licenseLine, contains('not downloadable'));
      expect((j['channel'] as String).isNotEmpty, isTrue);
      expect(<String>['vocals', 'duff', 'music', 'unknown']
          .contains(t.audioStyle), isTrue);
      expect(t.title.isNotEmpty && t.artist.isNotEmpty, isTrue);
    }
  });

  test('sources map gives each verified track an in-app YouTube source', () {
    final List<Track> tracks = PlayerVerifiedPack.parse(raw);
    final sources = PlayerVerifiedPack.sourcesOf(tracks);
    expect(sources.length, tracks.length);
    expect(sources[tracks.first.id]!.preferred, isNotNull);
  });

  test('a bad video id is dropped', () {
    final List<Track> t = PlayerVerifiedPack.parse(jsonEncode(<String, dynamic>{
      'tracks': <dynamic>[
        <String, dynamic>{
          'id': 'x', 'title': 't', 'artist': 'a', 'language': 'Urdu',
          'theme': 'naat', 'mood': 'devotion', 'audioUrl': '',
          'youtube': 'bad',
        },
      ],
    }));
    expect(t, isEmpty);
  });
}
