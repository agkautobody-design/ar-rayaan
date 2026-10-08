/// "My Additions" — the user's personal library (founder law 2026-10-06):
/// their own audio, on their device, playable through the Player. Tagged
/// "Personal — added by you"; excluded from official mixes, kids mode,
/// and the share catalog. Household filter hides them on shared devices.
library;

import 'nasheed_player.dart';

class PersonalTrack {
  const PersonalTrack({
    required this.id,
    required this.title,
    required this.source,
    required this.addedAt,
  });

  final String id;
  final String title;

  /// Local file path OR direct URL the user provided.
  final String source;
  final DateTime addedAt;

  bool get isUrl => source.startsWith('http');

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'source': source,
        'addedAt': addedAt.toIso8601String(),
      };

  factory PersonalTrack.fromJson(Map<String, dynamic> j) => PersonalTrack(
        id: j['id'] as String,
        title: j['title'] as String,
        source: j['source'] as String,
        addedAt: DateTime.parse(j['addedAt'] as String),
      );
}

extension PersonalTrackPlayable on PersonalTrack {
  /// The founder-law tag shown everywhere a personal track appears.
  static const String personalBadge = 'Personal — added by you';

  /// Play a personal track through the Player: the user's own path/URL
  /// becomes the playable ref, tagged personalImport so every official
  /// surface (mixes, kids mode, share catalog) can exclude it by rule.
  NasheedTrack toPlayable() => NasheedTrack(
        id: id,
        title: title,
        artist: '',
        language: 'personal',
        theme: 'personal',
        durationSec: 0,
        source: NasheedSource.personalImport,
        playableRef: source,
        licenseLine: personalBadge,
      );
}

/// Household filter ("hide personal tracks" on shared devices):
/// hidden -> the personal library is not surfaced at all.
List<PersonalTrack> visiblePersonal(List<PersonalTrack> tracks, bool hidden) =>
    hidden ? const <PersonalTrack>[] : tracks;
