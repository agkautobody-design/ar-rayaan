/// The person's own notes. Pure data (no Flutter), stored on the device only;
/// nothing here is sent anywhere.
///
/// The stored shape is the one the Notes screen has always used, a JSON list
/// of `{title, body, at}`, so notes written by earlier versions still load.
library;

import 'dart:convert';

/// The longest title made up from a note that has only a body.
const int kNoteAutoTitleChars = 48;

class NoteItem {
  const NoteItem({required this.at, required this.title, required this.body});

  /// When the note was first written (ISO 8601). It is also the note's id.
  final String at;
  final String title;
  final String body;

  NoteItem copyWith({String? title, String? body}) => NoteItem(
        at: at,
        title: title ?? this.title,
        body: body ?? this.body,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        'body': body,
        'at': at,
      };

  @override
  bool operator ==(Object other) =>
      other is NoteItem &&
      other.at == at &&
      other.title == title &&
      other.body == body;

  @override
  int get hashCode => Object.hash(at, title, body);
}

/// The title for a note written with an empty title box: the first line of
/// the body, cut at a word edge when it is long. Empty when [body] is empty.
String autoTitle(String body) {
  final String first = body
      .split(RegExp(r'[\r\n]+'))
      .map((String l) => l.trim())
      .firstWhere((String l) => l.isNotEmpty, orElse: () => '');
  if (first.length <= kNoteAutoTitleChars) return first;
  final String cut = first.substring(0, kNoteAutoTitleChars);
  final int space = cut.lastIndexOf(' ');
  final String head =
      space >= kNoteAutoTitleChars ~/ 2 ? cut.substring(0, space) : cut;
  return '${head.trimRight()}…';
}

/// Builds the note to save from what was typed. A note with only a body is
/// kept (its title is made from the body); only a note with neither a title
/// nor a body is refused (null). [at] is the id of an existing note being
/// edited; a new note gets [now] as its id.
NoteItem? buildNote({
  required String title,
  required String body,
  required DateTime now,
  String? at,
}) {
  final String t = title.trim();
  final String b = body.trim();
  if (t.isEmpty && b.isEmpty) return null;
  return NoteItem(
    at: at ?? now.toIso8601String(),
    title: t.isEmpty ? autoTitle(b) : t,
    body: b,
  );
}

/// Reads the stored JSON. Anything unreadable gives an empty list, and one
/// malformed entry is skipped without losing the others.
List<NoteItem> decodeNotes(String? raw) {
  if (raw == null || raw.isEmpty) return const <NoteItem>[];
  try {
    final dynamic data = jsonDecode(raw);
    if (data is! List<dynamic>) return const <NoteItem>[];
    final List<NoteItem> out = <NoteItem>[];
    for (final dynamic e in data) {
      if (e is! Map) continue;
      final Object? title = e['title'];
      final Object? body = e['body'];
      final Object? at = e['at'];
      if (at is! String || at.isEmpty) continue;
      final String t = title is String ? title : '';
      final String b = body is String ? body : '';
      if (t.trim().isEmpty && b.trim().isEmpty) continue;
      out.add(NoteItem(at: at, title: t.isEmpty ? autoTitle(b) : t, body: b));
    }
    return out;
  } catch (_) {
    return const <NoteItem>[];
  }
}

String encodeNotes(List<NoteItem> notes) =>
    jsonEncode(<Map<String, dynamic>>[for (final NoteItem n in notes) n.toJson()]);
