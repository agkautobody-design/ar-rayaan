/// Ayah bookmarks, collections and notes. Pure data (no Flutter), stored on
/// the device only; nothing here is sent anywhere.
library;

import 'dart:convert';

/// What the person saved about one ayah: a bookmark, a private note and the
/// collections it sits in. An entry that holds none of these is dropped.
class AyahMark {
  const AyahMark({
    required this.surah,
    required this.ayah,
    this.bookmarked = false,
    this.note = '',
    this.collections = const <String>[],
    this.updatedMs = 0,
  });

  factory AyahMark.fromJson(Map<String, dynamic> j) => AyahMark(
        surah: j['s'] as int,
        ayah: j['a'] as int,
        bookmarked: j['b'] as bool? ?? false,
        note: j['n'] as String? ?? '',
        collections: <String>[
          for (final dynamic c in (j['c'] as List<dynamic>? ?? <dynamic>[]))
            if (c is String) c,
        ],
        updatedMs: j['t'] as int? ?? 0,
      );

  final int surah;
  final int ayah;
  final bool bookmarked;
  final String note;
  final List<String> collections;
  final int updatedMs;

  String get key => '$surah:$ayah';

  bool get isEmpty =>
      !bookmarked && note.trim().isEmpty && collections.isEmpty;

  AyahMark copyWith({
    bool? bookmarked,
    String? note,
    List<String>? collections,
    int? updatedMs,
  }) =>
      AyahMark(
        surah: surah,
        ayah: ayah,
        bookmarked: bookmarked ?? this.bookmarked,
        note: note ?? this.note,
        collections: collections ?? this.collections,
        updatedMs: updatedMs ?? this.updatedMs,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        's': surah,
        'a': ayah,
        'b': bookmarked,
        'n': note,
        'c': collections,
        't': updatedMs,
      };

  @override
  bool operator ==(Object other) =>
      other is AyahMark &&
      other.surah == surah &&
      other.ayah == ayah &&
      other.bookmarked == bookmarked &&
      other.note == note &&
      other.updatedMs == updatedMs &&
      _sameList(other.collections, collections);

  @override
  int get hashCode =>
      Object.hash(surah, ayah, bookmarked, note, updatedMs, collections.length);

  static bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class QuranCollection {
  const QuranCollection({required this.id, required this.name});

  factory QuranCollection.fromJson(Map<String, dynamic> j) =>
      QuranCollection(id: j['id'] as String, name: j['name'] as String);

  final String id;
  final String name;

  Map<String, dynamic> toJson() => <String, dynamic>{'id': id, 'name': name};
}

/// Everything saved, as one immutable value.
class QuranMarks {
  const QuranMarks({
    this.marks = const <String, AyahMark>{},
    this.collections = const <QuranCollection>[],
  });

  /// Reads the stored JSON; anything unreadable gives an empty set rather
  /// than an error (the Qur'an reader must always open).
  factory QuranMarks.decode(String? raw) {
    if (raw == null || raw.isEmpty) return const QuranMarks();
    try {
      final Map<String, dynamic> j = jsonDecode(raw) as Map<String, dynamic>;
      final Map<String, AyahMark> marks = <String, AyahMark>{};
      for (final dynamic m in (j['marks'] as List<dynamic>? ?? <dynamic>[])) {
        final AyahMark mark = AyahMark.fromJson(m as Map<String, dynamic>);
        if (!mark.isEmpty) marks[mark.key] = mark;
      }
      return QuranMarks(
        marks: marks,
        collections: <QuranCollection>[
          for (final dynamic c
              in (j['collections'] as List<dynamic>? ?? <dynamic>[]))
            QuranCollection.fromJson(c as Map<String, dynamic>),
        ],
      );
    } catch (_) {
      return const QuranMarks();
    }
  }

  final Map<String, AyahMark> marks;
  final List<QuranCollection> collections;

  String encode() => jsonEncode(<String, dynamic>{
        'v': 1,
        'collections': <Map<String, dynamic>>[
          for (final QuranCollection c in collections) c.toJson(),
        ],
        'marks': <Map<String, dynamic>>[
          for (final AyahMark m in marks.values) m.toJson(),
        ],
      });

  AyahMark? of(int surah, int ayah) => marks['$surah:$ayah'];

  QuranCollection? collection(String id) {
    for (final QuranCollection c in collections) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Saved ayahs in reading order, optionally only those in [collectionId].
  /// A mark with only a note (not bookmarked) is listed too, so no note is
  /// ever hidden from the person who wrote it.
  List<AyahMark> list({String? collectionId}) {
    final List<AyahMark> out = <AyahMark>[
      for (final AyahMark m in marks.values)
        if (collectionId == null || m.collections.contains(collectionId)) m,
    ];
    out.sort((AyahMark a, AyahMark b) => a.surah != b.surah
        ? a.surah.compareTo(b.surah)
        : a.ayah.compareTo(b.ayah));
    return out;
  }
}

/// Plain-text export of saved ayahs (for copying or sharing). Qur'an text is
/// taken from the bundled text through [lookup]; notes are the person's own.
String exportMarks(
  QuranMarks marks, {
  required ({String arabic, String english, String surahName})? Function(
    int surah,
    int ayah,
  ) lookup,
  String? collectionId,
}) {
  final StringBuffer b = StringBuffer();
  final String? title = collectionId == null
      ? null
      : marks.collection(collectionId)?.name;
  b.writeln(title == null ? 'My Qur’an bookmarks' : 'Qur’an collection: $title');
  b.writeln();
  for (final AyahMark m in marks.list(collectionId: collectionId)) {
    final ({String arabic, String english, String surahName})? t =
        lookup(m.surah, m.ayah);
    b.writeln('${t?.surahName ?? 'Surah ${m.surah}'} ${m.surah}:${m.ayah}');
    if (t != null) {
      b.writeln(t.arabic);
      b.writeln(t.english);
    }
    if (m.note.trim().isNotEmpty) b.writeln('Note: ${m.note.trim()}');
    b.writeln();
  }
  b.writeln(
    'Arabic: Tanzil Uthmani (tanzil.net). Translation: Saheeh International, '
    'via Tanzil. Exported from Ar-Rayaan.',
  );
  return b.toString();
}
