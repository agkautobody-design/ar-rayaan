/// Story model — Stories module (Master Blueprint row 8).
/// Every story carries its source label and references per the
/// Content Integrity law.

/// The honesty labels a story (or one chapter of it) may carry.
const kLabelEstablished = 'Established';
const kLabelInterpretive = 'Interpretive';
const kLabelReflection = 'Reflection';

/// A Seerah report whose named book was opened and the passage read for the
/// story audit (docs/story_audit.md records the book, volume and page).
const kLabelSeerah = 'Seerah report';
const kLabelSeerahUnchecked = 'Seerah report (source not checked)';
const kLabelHadithUnchecked = 'Hadith report (reference not checked)';

/// Every legal value of [Story.sourceLabel] and [StoryChapter.label].
const kStoryLabels = <String>[
  kLabelEstablished,
  kLabelInterpretive,
  kLabelReflection,
  kLabelSeerah,
  kLabelSeerahUnchecked,
  kLabelHadithUnchecked,
];

/// One plain sentence saying what a label means, shown beside the label.
String storyLabelMeaning(String label) {
  switch (label) {
    case kLabelEstablished:
      return 'Rests on the Qur\u2019an or on a hadith whose reference was checked.';
    case kLabelInterpretive:
      return 'Told from the sources with interpretation; read it as a reading, not a ruling.';
    case kLabelReflection:
      return 'A reflection written for this app. It adds no new fact about the past.';
    case kLabelSeerah:
      return 'Comes from the biographies of the Prophet. The passage was read in the named book for this audit, but a biography records reports, not revelation. Not yet scholar-reviewed.';
    case kLabelSeerahUnchecked:
      return 'Comes from the biographies of the Prophet. The book it comes from was not opened to check it. Treat the details as reports, not as established facts.';
    case kLabelHadithUnchecked:
      return 'Comes from a hadith report whose collection and number were not checked. Treat the details as reports, not as established facts.';
    default:
      return '';
  }
}

class StoryChapter {
  final String heading;
  final String body;
  final String? arabic;
  final String? dua;

  /// Optional honesty label for this chapter alone, used where the chapter
  /// is weaker than the story as a whole (one of [kStoryLabels]).
  final String? label;
  const StoryChapter({
    required this.heading,
    required this.body,
    this.arabic,
    this.dua,
    this.label,
  });

  factory StoryChapter.fromJson(Map<String, dynamic> j) => StoryChapter(
        heading: j['heading'] as String,
        body: j['body'] as String,
        arabic: j['arabic'] as String?,
        dua: j['dua'] as String?,
        label: j['label'] as String?,
      );
}

class Story {
  final String id;
  final String collection;
  final String title;
  final String kicker;
  final String subtitle;
  final String sourceLabel; // one of kStoryLabels
  final List<String> sources;
  final List<StoryChapter> chapters;
  final String familyQuestion;

  /// Hisn al-Muslim gate this dua belongs to (dailyduas only; explicit in
  /// the JSON so every dua is reachable).
  final String? hisnCategory;

  /// Id of the story this one repeats (identical dua listed twice); the
  /// Hisn screen shows only the original.
  final String? duplicateOf;

  const Story({
    required this.id,
    required this.collection,
    required this.title,
    required this.kicker,
    required this.subtitle,
    required this.sourceLabel,
    required this.sources,
    required this.chapters,
    required this.familyQuestion,
    this.hisnCategory,
    this.duplicateOf,
  });

  factory Story.fromJson(Map<String, dynamic> j) => Story(
        id: j['id'] as String,
        collection: j['collection'] as String,
        title: j['title'] as String,
        kicker: j['kicker'] as String,
        subtitle: j['subtitle'] as String,
        sourceLabel: j['sourceLabel'] as String,
        sources: (j['sources'] as List<dynamic>).cast<String>(),
        chapters: (j['chapters'] as List<dynamic>)
            .map((e) => StoryChapter.fromJson(e as Map<String, dynamic>))
            .toList(),
        familyQuestion: j['familyQuestion'] as String,
        hisnCategory: j['hisnCategory'] as String?,
        duplicateOf: j['duplicateOf'] as String?,
      );
}
