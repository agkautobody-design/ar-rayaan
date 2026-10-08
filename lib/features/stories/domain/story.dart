/// Story model — Stories module (Master Blueprint row 8).
/// Every story carries its source label and references per the
/// Content Integrity law: Established (Qur'an / Sahih) or Interpretive.
class StoryChapter {
  final String heading;
  final String body;
  final String? arabic;
  final String? dua;
  const StoryChapter({required this.heading, required this.body, this.arabic, this.dua});

  factory StoryChapter.fromJson(Map<String, dynamic> j) => StoryChapter(
        heading: j['heading'] as String,
        body: j['body'] as String,
        arabic: j['arabic'] as String?,
        dua: j['dua'] as String?,
      );
}

class Story {
  final String id;
  final String collection;
  final String title;
  final String kicker;
  final String subtitle;
  final String sourceLabel; // Established | Interpretive
  final List<String> sources;
  final List<StoryChapter> chapters;
  final String familyQuestion;

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
      );
}
