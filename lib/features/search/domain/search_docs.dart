/// How each shelf's items are cut into fields for [scoreDoc]. Pure Dart, so
/// the real data files can be searched in tests. The screen uses the same
/// functions, so a test of these is a test of what people get.
library;

import '../../hadith/domain/hadith_models.dart';
import '../../notes/domain/notes.dart';
import '../../stories/domain/story.dart';
import 'search_engine.dart';

/// A hadith: its number is the title; the source, grade and who graded it
/// (and any caveat) are searchable, so "sahih" or "Tirmidhi" find hadith.
SearchDoc hadithDoc(Hadith h) => SearchDoc(
      title: 'Hadith ${h.number}',
      subtitle: 'an-Nawawi Forty Hadith ${h.sourceLine ?? ''} '
          '${h.grade?.note ?? ''}',
      body: h.english,
    );

/// A story: every chapter is searched, not only the first.
SearchDoc storyDoc(Story s) => SearchDoc(
      title: s.title,
      subtitle: '${s.subtitle} ${s.kicker}',
      body: s.chapters
          .map((StoryChapter c) => '${c.heading} ${c.body} ${c.dua ?? ''}')
          .join(' '),
    );

/// The Arabic of every chapter of [s] that has any (empty when none).
String storyArabic(Story s) => s.chapters
    .map((StoryChapter c) => c.arabic ?? '')
    .where((String a) => a.isNotEmpty)
    .join(' ');

/// A Q&A entry: the question is the title, the answer the body.
SearchDoc qaDoc(String question, String answer) =>
    SearchDoc(title: question, body: answer);

/// A note of the person's own.
SearchDoc noteDoc(NoteItem n) => SearchDoc(title: n.title, body: n.body);

/// A dhikr: the set's name is the title, the transliteration the subtitle.
SearchDoc dhikrDoc({
  required String setTitle,
  String? transliteration,
  String? translation,
}) =>
    SearchDoc(
      title: setTitle,
      subtitle: transliteration ?? '',
      body: translation ?? '',
    );
