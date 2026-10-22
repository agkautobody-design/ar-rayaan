/// My Playlists repository — on-device only, prefs-backed JSON. A corrupt or
/// hand-edited value loads as an empty list instead of crashing the screen.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/user_playlist.dart';

abstract final class UserPlaylistRepository {
  static const String _key = 'ar.player.playlists.v1';

  static List<UserPlaylist> load(SharedPreferences prefs) {
    final String? raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <UserPlaylist>[];
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) return <UserPlaylist>[];
      final List<UserPlaylist> out = <UserPlaylist>[
        for (final Object? e in decoded)
          if (UserPlaylist.fromJson(e) case final UserPlaylist p) p,
      ];
      return out.length > kMaxPlaylists ? out.sublist(0, kMaxPlaylists) : out;
    } catch (_) {
      return <UserPlaylist>[];
    }
  }

  static Future<void> save(
      SharedPreferences prefs, List<UserPlaylist> playlists) async {
    await prefs.setString(_key,
        jsonEncode(playlists.map((UserPlaylist p) => p.toJson()).toList()));
  }
}
