/// Request-a-nasheed channel (1b.4).
/// The Player's official catalog grows by request, never by scraping:
/// a user asks for a track, the founder reviews it, only then may it
/// enter the catalog. No backend — the request is composed as honest
/// text the user sends through any channel (email when the founder's
/// address is set, copy otherwise). Design: locked glass-card grammar.
library;

enum NasheedRequestStatus { pending }

class NasheedRequest {
  const NasheedRequest({
    required this.id,
    required this.title,
    required this.createdAt,
    this.artist,
    this.url,
    this.note,
    this.status = NasheedRequestStatus.pending,
  });

  final String id;
  final String title;
  final String? artist;
  final String? url;
  final String? note;
  final DateTime createdAt;
  final NasheedRequestStatus status;

  /// The pre-composed message the user sends to the founder.
  String get shareText {
    final StringBuffer b = StringBuffer()
      ..writeln('Assalamu alaikum — requesting a nasheed for Ar-Rayaan:')
      ..writeln('Title: $title');
    if (artist != null && artist!.isNotEmpty) b.writeln('Artist: $artist');
    if (url != null && url!.isNotEmpty) b.writeln('Link: $url');
    if (note != null && note!.isNotEmpty) b.writeln('Note: $note');
    return b.toString().trimRight();
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'title': title,
        'artist': artist,
        'url': url,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
      };

  static NasheedRequest fromJson(Map<String, Object?> j) => NasheedRequest(
        id: (j['id'] ?? '') as String,
        title: (j['title'] ?? '') as String,
        artist: j['artist'] as String?,
        url: j['url'] as String?,
        note: j['note'] as String?,
        createdAt: DateTime.tryParse((j['createdAt'] ?? '') as String) ??
            DateTime.fromMillisecondsSinceEpoch(0),
        status: NasheedRequestStatus.values.asNameMap()[(j['status'] ?? '') as String] ??
            NasheedRequestStatus.pending,
      );
}

/// The founder's request inbox. Empty until the founder sets a real
/// address — until then the channel is copy-and-send, honestly labeled.
const String kRequestChannelEmail = '';
