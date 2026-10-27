import 'package:ar_rayaan/features/notes/domain/notes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime now = DateTime.utc(2026, 10, 27, 9, 30);

  group('buildNote', () {
    test('a note with a title and a body keeps both', () {
      final NoteItem n =
          buildNote(title: ' Sabr ', body: ' be patient ', now: now)!;
      expect(n.title, 'Sabr');
      expect(n.body, 'be patient');
      expect(n.at, now.toIso8601String());
    });

    test('a note with ONLY a body is saved, titled from its first line', () {
      final NoteItem? n = buildNote(
        title: '',
        body: 'Call my mother after Asr\nand ask about the visit',
        now: now,
      );
      expect(n, isNotNull);
      expect(n!.title, 'Call my mother after Asr');
      expect(n.body, contains('ask about the visit'));
    });

    test('a note with ONLY a title is saved', () {
      final NoteItem? n = buildNote(title: 'Dua for exams', body: '', now: now);
      expect(n, isNotNull);
      expect(n!.body, '');
    });

    test('only an empty note (nothing but spaces) is refused', () {
      expect(buildNote(title: '', body: '', now: now), isNull);
      expect(buildNote(title: '  ', body: ' \n ', now: now), isNull);
    });

    test('editing keeps the note\'s id', () {
      final NoteItem n =
          buildNote(title: 'a', body: 'b', now: now, at: 'old-id')!;
      expect(n.at, 'old-id');
    });
  });

  group('autoTitle', () {
    test('a long first line is cut at a word edge with an ellipsis', () {
      final String t = autoTitle(
        'Remember to thank Allah for every small mercy that came to me today',
      );
      expect(t.length, lessThanOrEqualTo(kNoteAutoTitleChars + 1));
      expect(t.endsWith('…'), isTrue);
    });

    test('blank lines are skipped', () {
      expect(autoTitle('\n\n  hello \nworld'), 'hello');
    });

    test('empty gives empty', () {
      expect(autoTitle(''), '');
    });
  });

  group('storage', () {
    test('notes written by the old screen still load', () {
      const String old =
          '[{"title":"Dua","body":"rabbi zidni ilma","at":"2026-01-02T03:04:05.000"}]';
      final List<NoteItem> notes = decodeNotes(old);
      expect(notes.length, 1);
      expect(notes.first.title, 'Dua');
    });

    test('encode then decode gives the same notes', () {
      final List<NoteItem> notes = <NoteItem>[
        buildNote(title: 'a', body: 'b', now: now)!,
        buildNote(title: '', body: 'only body', now: now.add(const Duration(seconds: 1)))!,
      ];
      expect(decodeNotes(encodeNotes(notes)), notes);
    });

    test('garbage gives an empty list, and one bad entry loses nothing else',
        () {
      expect(decodeNotes(null), isEmpty);
      expect(decodeNotes(''), isEmpty);
      expect(decodeNotes('not json'), isEmpty);
      expect(decodeNotes('{"a":1}'), isEmpty);
      final List<NoteItem> some = decodeNotes(
        '[1,{"title":"ok","body":"","at":"x"},{"title":5}]',
      );
      expect(some.length, 1);
      expect(some.first.title, 'ok');
    });
  });
}

