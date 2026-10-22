/// "My Playlists" — a person's own playlists inside the Player.
///
/// On-device only (the same Amanah law as My Additions: the app is a player,
/// never a distributor). An item is either a catalogue track (played only
/// from the approved sources list) or a link the person pasted, which stays
/// personal: tagged "Personal — added by you", hidden by the household
/// filter, and never in mixes or the share catalogue.
library;

import 'stream_link.dart';

const int kMaxPlaylists = 50;
const int kMaxPlaylistItems = 200;
const int kMaxNameLength = 60;
const int kMaxTitleLength = 120;

class PlaylistItem {
  const PlaylistItem({
    required this.id,
    required this.title,
    this.artist = '',
    this.catalogId,
    this.link,
  });

  final String id;
  final String title;
  final String artist;

  /// Set for a catalogue track; resolved against the approved sources list
  /// when played.
  final String? catalogId;

  /// Set for a pasted link (a personal item).
  final StreamLink? link;

  bool get isPersonal => link != null;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        if (artist.isNotEmpty) 'artist': artist,
        if (catalogId != null) 'catalogId': catalogId,
        if (link != null) 'link': link!.toJson(),
      };

  /// Null when the stored entry is unusable; it is dropped, never trusted.
  static PlaylistItem? fromJson(Object? j) {
    if (j is! Map<String, dynamic>) return null;
    final Object? id = j['id'];
    final Object? title = j['title'];
    if (id is! String || id.isEmpty || title is! String || title.isEmpty) {
      return null;
    }
    final Object? artist = j['artist'];
    final Object? catalogId = j['catalogId'];
    final StreamLink? link = StreamLink.fromJson(j['link']);
    final String? cid =
        catalogId is String && catalogId.isNotEmpty ? catalogId : null;
    // An item with neither a catalogue id nor a valid link plays nothing.
    if (cid == null && link == null) return null;
    return PlaylistItem(
      id: id,
      title: clipText(title, kMaxTitleLength),
      artist: artist is String ? clipText(artist, kMaxTitleLength) : '',
      catalogId: cid,
      link: link,
    );
  }
}

class UserPlaylist {
  const UserPlaylist({
    required this.id,
    required this.name,
    this.items = const <PlaylistItem>[],
  });

  final String id;
  final String name;
  final List<PlaylistItem> items;

  UserPlaylist renamed(String next) =>
      UserPlaylist(id: id, name: clipText(next, kMaxNameLength), items: items);

  /// Adds [item]; false-safe: a full playlist or a duplicate is unchanged.
  UserPlaylist withItem(PlaylistItem item) {
    if (items.length >= kMaxPlaylistItems) return this;
    if (items.any((PlaylistItem x) => x.id == item.id)) return this;
    final String? cid = item.catalogId;
    if (cid != null && items.any((PlaylistItem x) => x.catalogId == cid)) {
      return this;
    }
    final StreamLink? link = item.link;
    if (link != null && items.any((PlaylistItem x) => x.link == link)) {
      return this;
    }
    return UserPlaylist(
        id: id, name: name, items: <PlaylistItem>[...items, item]);
  }

  UserPlaylist withoutItem(String itemId) => UserPlaylist(
        id: id,
        name: name,
        items:
            items.where((PlaylistItem x) => x.id != itemId).toList(),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'items': items.map((PlaylistItem x) => x.toJson()).toList(),
      };

  static UserPlaylist? fromJson(Object? j) {
    if (j is! Map<String, dynamic>) return null;
    final Object? id = j['id'];
    final Object? name = j['name'];
    if (id is! String || id.isEmpty || name is! String || name.trim().isEmpty) {
      return null;
    }
    final Object? raw = j['items'];
    final List<PlaylistItem> items = <PlaylistItem>[
      if (raw is List<dynamic>)
        for (final Object? e in raw)
          if (PlaylistItem.fromJson(e) case final PlaylistItem it) it,
    ];
    return UserPlaylist(
      id: id,
      name: clipText(name.trim(), kMaxNameLength),
      items: items.length > kMaxPlaylistItems
          ? items.sublist(0, kMaxPlaylistItems)
          : items,
    );
  }
}

/// Trim and cap a user-typed string.
String clipText(String s, int max) {
  final String t = s.trim();
  return t.length <= max ? t : t.substring(0, max);
}
