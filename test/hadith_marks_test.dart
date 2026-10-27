import 'package:ar_rayaan/features/hadith/domain/hadith_marks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nothing saved: empty, no bookmarks, no notes', () {
    const HadithMarks m = HadithMarks();
    expect(m.list(), isEmpty);
    expect(m.isBookmarked(1), isFalse);
    expect(m.noteOf(1), '');
    expect(m.bookmarkCount, 0);
    expect(m.noteCount, 0);
  });

  test('bookmark and note survive encode and decode', () {
    final HadithMarks m = HadithMarks(
      marks: <int, HadithMark>{
        7: const HadithMark(number: 7, bookmarked: true, updatedMs: 5),
        1: const HadithMark(number: 1, note: 'intentions', updatedMs: 9),
        30: const HadithMark(
          number: 30,
          bookmarked: true,
          note: 'limits',
          updatedMs: 11,
        ),
      },
    );
    final HadithMarks back = HadithMarks.decode(m.encode());
    expect(back.list().map((HadithMark x) => x.number).toList(), <int>[1, 7, 30]);
    expect(back.isBookmarked(7), isTrue);
    expect(back.isBookmarked(1), isFalse);
    expect(back.noteOf(1), 'intentions');
    expect(back.noteOf(30), 'limits');
    expect(back.bookmarkCount, 2);
    expect(back.noteCount, 2);
  });

  test('a note without a bookmark is still listed (never hidden)', () {
    final HadithMarks m = HadithMarks(
      marks: <int, HadithMark>{
        4: const HadithMark(number: 4, note: 'mother, three times'),
      },
    );
    expect(m.list().length, 1);
    expect(m.bookmarkCount, 0);
  });

  test('a mark holding neither a bookmark nor a note is dropped on load', () {
    final HadithMarks m = HadithMarks.decode(
      '{"v":1,"marks":[{"h":3,"b":false,"n":"  ","t":1},{"h":5,"b":true,"n":"","t":2}]}',
    );
    expect(m.list().map((HadithMark x) => x.number).toList(), <int>[5]);
  });

  test('unreadable storage gives an empty set, not an error', () {
    expect(HadithMarks.decode(null).list(), isEmpty);
    expect(HadithMarks.decode('').list(), isEmpty);
    expect(HadithMarks.decode('nonsense').list(), isEmpty);
    expect(HadithMarks.decode('{"marks":5}').list(), isEmpty);
  });
}
