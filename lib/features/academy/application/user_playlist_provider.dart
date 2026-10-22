/// My Playlists state.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';
import '../data/user_playlist_repository.dart';
import '../domain/stream_link.dart';
import '../domain/user_playlist.dart';

final userPlaylistsProvider =
    StateNotifierProvider<UserPlaylistsNotifier, List<UserPlaylist>>(
        (Ref ref) {
  return UserPlaylistsNotifier(ref.watch(sharedPreferencesProvider));
});

class UserPlaylistsNotifier extends StateNotifier<List<UserPlaylist>> {
  UserPlaylistsNotifier(this._prefs)
      : super(UserPlaylistRepository.load(_prefs));

  final SharedPreferences _prefs;
  int _seq = 0;

  String _newId(String prefix) {
    _seq++;
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$_seq';
  }

  Future<void> _commit(List<UserPlaylist> next) async {
    state = next;
    await UserPlaylistRepository.save(_prefs, next);
  }

  /// Creates a playlist and returns its id, or null for a blank name or a
  /// full shelf.
  Future<String?> create(String name) async {
    final String n = clipText(name, kMaxNameLength);
    if (n.isEmpty || state.length >= kMaxPlaylists) return null;
    final String id = _newId('pl');
    await _commit(<UserPlaylist>[...state, UserPlaylist(id: id, name: n)]);
    return id;
  }

  Future<void> rename(String id, String name) async {
    final String n = clipText(name, kMaxNameLength);
    if (n.isEmpty) return;
    await _commit(<UserPlaylist>[
      for (final UserPlaylist p in state) p.id == id ? p.renamed(n) : p,
    ]);
  }

  Future<void> delete(String id) async {
    await _commit(state.where((UserPlaylist p) => p.id != id).toList());
  }

  /// Adds a catalogue track. Returns false when the playlist is full or the
  /// track is already in it.
  Future<bool> addCatalogTrack(
    String playlistId, {
    required String catalogId,
    required String title,
    required String artist,
  }) =>
      _add(
        playlistId,
        PlaylistItem(
          id: _newId('it'),
          title: clipText(title, kMaxTitleLength),
          artist: clipText(artist, kMaxTitleLength),
          catalogId: catalogId,
        ),
      );

  /// Adds a pasted link (personal). Returns false when full or a duplicate.
  Future<bool> addLink(
    String playlistId, {
    required String title,
    required StreamLink link,
  }) =>
      _add(
        playlistId,
        PlaylistItem(
          id: _newId('it'),
          title: clipText(title, kMaxTitleLength),
          link: link,
        ),
      );

  Future<bool> _add(String playlistId, PlaylistItem item) async {
    bool added = false;
    final List<UserPlaylist> next = <UserPlaylist>[];
    for (final UserPlaylist p in state) {
      if (p.id == playlistId) {
        final UserPlaylist q = p.withItem(item);
        added = q.items.length != p.items.length;
        next.add(q);
      } else {
        next.add(p);
      }
    }
    if (added) await _commit(next);
    return added;
  }

  Future<void> removeItem(String playlistId, String itemId) async {
    await _commit(<UserPlaylist>[
      for (final UserPlaylist p in state)
        p.id == playlistId ? p.withoutItem(itemId) : p,
    ]);
  }
}
