/// The in-app YouTube / Spotify queue — what is playing in the embedded
/// player, and the pure rule that decides which playlist items can play.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/player_sources_pack.dart';
import '../domain/stream_link.dart';
import '../domain/user_playlist.dart';

class StreamEntry {
  const StreamEntry({
    required this.title,
    required this.artist,
    required this.link,
    this.personal = false,
  });

  final String title;
  final String artist;
  final StreamLink link;

  /// A link the person pasted (tagged "Personal — added by you").
  final bool personal;
}

class StreamQueue {
  const StreamQueue({this.entries = const <StreamEntry>[], this.index = 0});

  final List<StreamEntry> entries;
  final int index;

  bool get isEmpty => entries.isEmpty;
  StreamEntry? get current =>
      index >= 0 && index < entries.length ? entries[index] : null;
  bool get hasNext => index + 1 < entries.length;
  bool get hasPrevious => index > 0;
}

class StreamQueueNotifier extends StateNotifier<StreamQueue> {
  StreamQueueNotifier() : super(const StreamQueue());

  void play(List<StreamEntry> entries, int index) {
    if (entries.isEmpty) return;
    final int i = index < 0
        ? 0
        : index >= entries.length
            ? entries.length - 1
            : index;
    state = StreamQueue(entries: entries, index: i);
  }

  void next() {
    if (state.hasNext) {
      state = StreamQueue(entries: state.entries, index: state.index + 1);
    }
  }

  void previous() {
    if (state.hasPrevious) {
      state = StreamQueue(entries: state.entries, index: state.index - 1);
    }
  }

  /// Removes the player, which stops the embedded video or audio.
  void stop() => state = const StreamQueue();
}

final streamQueueProvider =
    StateNotifierProvider<StreamQueueNotifier, StreamQueue>(
        (Ref ref) => StreamQueueNotifier());

/// What an item plays from, or null when it has no approved in-app source.
/// A catalogue item plays only from the approved sources list; a pasted
/// link plays only when personal items are not hidden.
StreamEntry? entryForItem(
  PlaylistItem item,
  Map<String, TrackSources> sources, {
  required bool personalHidden,
}) {
  final StreamLink? own = item.link;
  if (own != null) {
    if (personalHidden) return null;
    return StreamEntry(
        title: item.title, artist: item.artist, link: own, personal: true);
  }
  final String? cid = item.catalogId;
  final StreamLink? approved = cid == null ? null : sources[cid]?.preferred;
  if (approved == null) return null;
  return StreamEntry(
      title: item.title, artist: item.artist, link: approved);
}
