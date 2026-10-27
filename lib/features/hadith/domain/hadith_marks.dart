/// Hadith bookmarks and notes, the same idea as the Qur'an's ayah marks
/// (see `quran_marks.dart`): pure data, kept on this device only, nothing
/// here is sent anywhere. A mark holds a bookmark, a private note, or both;
/// a mark that holds neither is dropped.
library;

import 'dart:convert';

/// What the person saved about one of the Forty Hadith.
class HadithMark {
  const HadithMark({
    required this.number,
    this.bookmarked = false,
    this.note = '',
    this.updatedMs = 0,
  });

  factory HadithMark.fromJson(Map<String, dynamic> j) => HadithMark(
        number: j['h'] as int,
        bookmarked: j['b'] as bool? ?? false,
        note: j['n'] as String? ?? '',
        updatedMs: j['t'] as int? ?? 0,
      );

  /// The hadith number inside The Forty Hadith (1 to 42).
  final int number;
  final bool bookmarked;
  final String note;
  final int updatedMs;

  bool get isEmpty => !bookmarked && note.trim().isEmpty;

  HadithMark copyWith({bool? bookmarked, String? note, int? updatedMs}) =>
      HadithMark(
        number: number,
        bookmarked: bookmarked ?? this.bookmarked,
        note: note ?? this.note,
        updatedMs: updatedMs ?? this.updatedMs,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'h': number,
        'b': bookmarked,
        'n': note,
        't': updatedMs,
      };

  @override
  bool operator ==(Object other) =>
      other is HadithMark &&
      other.number == number &&
      other.bookmarked == bookmarked &&
      other.note == note &&
      other.updatedMs == updatedMs;

  @override
  int get hashCode => Object.hash(number, bookmarked, note, updatedMs);
}

/// Everything saved about the hadith, as one immutable value.
class HadithMarks {
  const HadithMarks({this.marks = const <int, HadithMark>{}});

  /// Reads the stored JSON; anything unreadable gives an empty set rather
  /// than an error (the Hadith screen must always open).
  factory HadithMarks.decode(String? raw) {
    if (raw == null || raw.isEmpty) return const HadithMarks();
    try {
      final Map<String, dynamic> j = jsonDecode(raw) as Map<String, dynamic>;
      final Map<int, HadithMark> marks = <int, HadithMark>{};
      for (final dynamic m in (j['marks'] as List<dynamic>? ?? <dynamic>[])) {
        final HadithMark mark = HadithMark.fromJson(m as Map<String, dynamic>);
        if (!mark.isEmpty) marks[mark.number] = mark;
      }
      return HadithMarks(marks: marks);
    } catch (_) {
      return const HadithMarks();
    }
  }

  final Map<int, HadithMark> marks;

  String encode() => jsonEncode(<String, dynamic>{
        'v': 1,
        'marks': <Map<String, dynamic>>[
          for (final HadithMark m in list()) m.toJson(),
        ],
      });

  HadithMark? of(int number) => marks[number];

  bool isBookmarked(int number) => marks[number]?.bookmarked ?? false;

  String noteOf(int number) => marks[number]?.note ?? '';

  /// Saved hadith in the order of the book. A mark with only a note (not
  /// bookmarked) is listed too, so no note is ever hidden from the person who
  /// wrote it.
  List<HadithMark> list() {
    final List<HadithMark> out = marks.values.toList();
    out.sort((HadithMark a, HadithMark b) => a.number.compareTo(b.number));
    return out;
  }

  /// How many hadith are bookmarked (notes alone do not count).
  int get bookmarkCount =>
      marks.values.where((HadithMark m) => m.bookmarked).length;

  /// How many hadith carry a note.
  int get noteCount =>
      marks.values.where((HadithMark m) => m.note.trim().isNotEmpty).length;
}
