/// A poem or naat the person added themselves: their own words, on their own
/// device only. It is tagged as theirs, never joins the library others see,
/// never reaches kids mode, and the app does not check or vouch for it.
library;

import 'dart:convert';

/// Languages the person can say a poem or its meaning is in. `xx` is "another
/// language": it can be read but the app has no voice to read it aloud.
const Map<String, String> kUserPoemLanguages = <String, String>{
  'ar': 'العربية',
  'ur': 'اردو',
  'en': 'English',
  'bn': 'বাংলা',
  'hi': 'हिन्दी',
  'xx': 'Other',
};

/// Languages the app can read aloud on a phone, if the phone has the voice.
const Set<String> kRecitalLanguages = <String>{'ar', 'ur', 'en', 'bn', 'hi'};

/// One non-empty trimmed line per row of [text].
List<String> parsePoemLines(String text) => <String>[
  for (final String l in text.split(RegExp(r'\r?\n')))
    if (l.trim().isNotEmpty) l.trim(),
];

class UserPoem {
  const UserPoem({
    required this.id,
    required this.title,
    required this.lang,
    required this.lines,
    this.meaningLang,
    this.meanings = const <String>[],
    this.audioUrl,
  });

  /// Always starts with `mine-`.
  final String id;
  final String title;

  /// Language of [lines]: a key of [kUserPoemLanguages].
  final String lang;
  final List<String> lines;

  /// Language of [meanings], when the person wrote them.
  final String? meaningLang;

  /// Meaning of line `i` at index `i`; may be shorter than [lines].
  final List<String> meanings;

  /// A direct audio link the person chose to play with the words.
  final String? audioUrl;

  bool get hasAudio => audioUrl != null && audioUrl!.isNotEmpty;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'title': title,
    'lang': lang,
    'lines': lines,
    'meaningLang': meaningLang,
    'meanings': meanings,
    'audioUrl': audioUrl,
  };

  /// Null for anything that is not a well-formed poem (kept safe: a damaged
  /// saved entry is skipped, never a crash).
  static UserPoem? tryFromJson(Object? j) {
    if (j is! Map) return null;
    final Object? id = j['id'];
    final Object? title = j['title'];
    final Object? lang = j['lang'];
    final Object? lines = j['lines'];
    if (id is! String || !id.startsWith('mine-')) return null;
    if (title is! String || title.trim().isEmpty) return null;
    if (lang is! String || !kUserPoemLanguages.containsKey(lang)) return null;
    if (lines is! List || lines.isEmpty) return null;
    final Object? ml = j['meaningLang'];
    final Object? ms = j['meanings'];
    final Object? au = j['audioUrl'];
    return UserPoem(
      id: id,
      title: title,
      lang: lang,
      lines: <String>[for (final Object? l in lines) l.toString()],
      meaningLang:
          ml is String && kUserPoemLanguages.containsKey(ml) ? ml : null,
      meanings: ms is List
          ? <String>[for (final Object? m in ms) m.toString()]
          : const <String>[],
      audioUrl: au is String && au.startsWith('http') ? au : null,
    );
  }
}

List<UserPoem> decodeUserPoems(String? raw) {
  if (raw == null || raw.isEmpty) return <UserPoem>[];
  try {
    final Object? d = jsonDecode(raw);
    if (d is! List) return <UserPoem>[];
    return <UserPoem>[
      for (final Object? e in d)
        if (UserPoem.tryFromJson(e) != null) UserPoem.tryFromJson(e)!,
    ];
  } catch (_) {
    return <UserPoem>[];
  }
}

String encodeUserPoems(List<UserPoem> poems) =>
    jsonEncode(<Map<String, dynamic>>[for (final UserPoem p in poems) p.toJson()]);
