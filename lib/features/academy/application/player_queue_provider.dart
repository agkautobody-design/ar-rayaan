/// Player queue provider — reuses the production audio backend.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/audioplayers_ayah_player.dart';
import '../data/player_sources_pack.dart';
import '../domain/player.dart';
import 'package:ar_rayaan/features/academy/data/player_catalog_pack.dart';

final playerCatalogProvider = FutureProvider<Catalog?>((Ref ref) {
  return PlayerCatalogPack.load();
});

/// Approved YouTube / Spotify sources, by catalogue track id.
final playerSourcesProvider =
    FutureProvider<Map<String, TrackSources>>((Ref ref) {
  return PlayerSourcesPack.load();
});

class PlayerQueueNotifier extends StateNotifier<PlayerQueue> {
  PlayerQueueNotifier(this._audio) : super(const PlayerQueue());

  final AudioplayersAyahPlayer _audio;

  Future<void> playQueue(List<Track> tracks, {String? name}) async {
    // Never queue entries with no audio file: they would play silence.
    final List<Track> playable =
        tracks.where((Track t) => t.hasAudio).toList();
    if (playable.isEmpty) return;
    state = PlayerQueue(tracks: playable, index: 0, playlistName: name);
    await _playCurrent();
  }

  Future<void> enqueue(Track t) async {
    if (!t.hasAudio) return;
    state = state.enqueue(t);
    if (state.index == state.tracks.length - 1 && state.tracks.length == 1) {
      await _playCurrent();
    }
  }

  Future<void> playNext(Track t) async {
    if (!t.hasAudio) return;
    state = state.playNext(t);
  }

  Future<void> reorder(int from, int to) async {
    state = state.reorder(from, to);
  }

  Future<void> skipNext() async {
    final PlayerQueue n = state.next();
    if (!identical(n, state)) {
      state = n;
      await _playCurrent();
    }
  }

  Future<void> skipPrevious() async {
    final PlayerQueue p = state.previous();
    if (!identical(p, state)) {
      state = p;
      await _playCurrent();
    }
  }

  /// Pause keeps the queue position; resume re-plays the current track.
  Future<void> pause() async {
    await _audio.stop();
  }

  Future<void> resume() async {
    await _playCurrent();
  }

  Future<void> _playCurrent() async {
    final Track? t = state.current;
    if (t == null || !t.hasAudio) return;
    await _audio.play(t.audioUrl);
  }
}

final playerQueueProvider =
    StateNotifierProvider<PlayerQueueNotifier, PlayerQueue>((Ref ref) {
  return PlayerQueueNotifier(AudioplayersAyahPlayer());
});
