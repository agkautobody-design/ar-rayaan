/// A YouTube or Spotify link, parsed and validated.
///
/// The Player never plays a user-pasted address directly. A pasted link is
/// parsed into a service, a kind and an ID; only an ID that passes the
/// strict shape check is kept, and the embed and open addresses are built
/// from it with fixed hosts. A link that does not parse is refused, so
/// nothing a user types can become an iframe source or an outside page.
library;

enum StreamService { youtube, spotify }

class StreamLink {
  const StreamLink({
    required this.service,
    required this.kind,
    required this.id,
  });

  final StreamService service;

  /// youtube: `video` or `playlist`. spotify: `track`, `album`, `playlist`,
  /// `artist`, `episode` or `show`.
  final String kind;
  final String id;

  String get serviceLabel =>
      service == StreamService.youtube ? 'YouTube' : 'Spotify';

  /// Stable identity for de-duplication.
  String get key => '${service.name}:$kind:$id';

  /// The address of the in-app player. Fixed hosts only.
  Uri get embedUri {
    if (service == StreamService.youtube) {
      if (kind == 'playlist') {
        return Uri.https('www.youtube-nocookie.com', '/embed/videoseries',
            <String, String>{'list': id, 'rel': '0', 'playsinline': '1'});
      }
      return Uri.https('www.youtube-nocookie.com', '/embed/$id',
          <String, String>{'rel': '0', 'playsinline': '1'});
    }
    return Uri.https('open.spotify.com', '/embed/$kind/$id');
  }

  /// The public page, which opens the YouTube or Spotify app on a phone.
  Uri get openUri {
    if (service == StreamService.youtube) {
      return kind == 'playlist'
          ? Uri.https('www.youtube.com', '/playlist',
              <String, String>{'list': id})
          : Uri.https('www.youtube.com', '/watch', <String, String>{'v': id});
    }
    return Uri.https('open.spotify.com', '/$kind/$id');
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'service': service.name,
        'kind': kind,
        'id': id,
      };

  /// Null when the stored form is not a valid link (a corrupt or edited
  /// entry is dropped, never trusted).
  static StreamLink? fromJson(Object? j) {
    if (j is! Map<String, dynamic>) return null;
    final Object? service = j['service'];
    final Object? kind = j['kind'];
    final Object? id = j['id'];
    if (service is! String || kind is! String || id is! String) return null;
    final StreamService? s = service == 'youtube'
        ? StreamService.youtube
        : service == 'spotify'
            ? StreamService.spotify
            : null;
    if (s == null) return null;
    return _build(s, kind, id);
  }

  @override
  bool operator ==(Object other) => other is StreamLink && other.key == key;

  @override
  int get hashCode => key.hashCode;

  static final RegExp _ytVideo = RegExp(r'^[A-Za-z0-9_-]{11}$');
  static final RegExp _ytList = RegExp(r'^[A-Za-z0-9_-]{10,64}$');
  static final RegExp _spId = RegExp(r'^[A-Za-z0-9]{22}$');
  static const Set<String> _spKinds = <String>{
    'track',
    'album',
    'playlist',
    'artist',
    'episode',
    'show',
  };

  static StreamLink? _build(StreamService s, String kind, String id) {
    if (s == StreamService.youtube) {
      if (kind == 'video' && _ytVideo.hasMatch(id)) {
        return StreamLink(service: s, kind: kind, id: id);
      }
      if (kind == 'playlist' && _ytList.hasMatch(id)) {
        return StreamLink(service: s, kind: kind, id: id);
      }
      return null;
    }
    if (_spKinds.contains(kind) && _spId.hasMatch(id)) {
      return StreamLink(service: s, kind: kind, id: id);
    }
    return null;
  }

  /// Parse text a person pasted: a YouTube or Spotify address, or a
  /// `spotify:track:ID` URI. Null when it is neither, or malformed.
  static StreamLink? parse(String? raw) {
    if (raw == null) return null;
    final String t = raw.trim();
    if (t.isEmpty || t.length > 2048) return null;
    for (final int c in t.runes) {
      if (c <= 0x20 || c == 0x7f) return null;
    }

    final RegExpMatch? uri =
        RegExp(r'^spotify:([a-z]+):([A-Za-z0-9]+)$').firstMatch(t);
    if (uri != null) {
      return _build(StreamService.spotify, uri.group(1)!, uri.group(2)!);
    }

    final String candidate = t.contains('://') ? t : 'https://$t';
    final Uri? u = Uri.tryParse(candidate);
    if (u == null) return null;
    final String scheme = u.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') return null;
    String host = u.host.toLowerCase();
    if (host.isEmpty) return null;
    for (final String prefix in <String>['www.', 'm.', 'music.']) {
      if (host.startsWith(prefix)) host = host.substring(prefix.length);
    }
    final List<String> seg =
        u.pathSegments.where((String s) => s.isNotEmpty).toList();

    if (host == 'youtu.be') {
      if (seg.isEmpty) return null;
      return _build(StreamService.youtube, 'video', seg.first);
    }
    if (host == 'youtube.com' || host == 'youtube-nocookie.com') {
      if (seg.isEmpty) return null;
      final String head = seg.first;
      if (head == 'watch') {
        final String? v = u.queryParameters['v'];
        if (v != null) return _build(StreamService.youtube, 'video', v);
        final String? list = u.queryParameters['list'];
        if (list != null) {
          return _build(StreamService.youtube, 'playlist', list);
        }
        return null;
      }
      if (head == 'playlist') {
        final String? list = u.queryParameters['list'];
        return list == null
            ? null
            : _build(StreamService.youtube, 'playlist', list);
      }
      if (<String>{'shorts', 'embed', 'live', 'v'}.contains(head) &&
          seg.length >= 2) {
        if (head == 'embed' && seg[1] == 'videoseries') {
          final String? list = u.queryParameters['list'];
          return list == null
              ? null
              : _build(StreamService.youtube, 'playlist', list);
        }
        return _build(StreamService.youtube, 'video', seg[1]);
      }
      return null;
    }
    if (host == 'open.spotify.com' || host == 'spotify.com') {
      final List<String> s = <String>[...seg];
      if (s.isNotEmpty && RegExp(r'^intl-[a-z]{2}(-[a-z]+)?$').hasMatch(s[0])) {
        s.removeAt(0);
      }
      if (s.isNotEmpty && s[0] == 'embed') s.removeAt(0);
      if (s.length < 2) return null;
      return _build(StreamService.spotify, s[0], s[1]);
    }
    return null;
  }
}
