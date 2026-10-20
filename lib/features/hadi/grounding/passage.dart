/// A piece of scripture Hādi is allowed to show, identified by an ID.
///
/// The model never types scripture. It points at an ID (`[[src:q:94:5-6]]`);
/// the app prints the Arabic and translation from its own library, with the
/// label, grade and who gave the grade. See [HadiCorpus] and [AnswerVerifier].
library;

enum PassageKind { quran, hadith }

class Passage {
  const Passage({
    required this.id,
    required this.kind,
    required this.reference,
    required this.english,
    this.arabic,
    this.collection,
    this.number,
    this.grade,
    this.grader,
    this.textKind,
    this.verifiedOn,
    this.verifiedAt,
  });

  /// `q:94:5-6` for the Qur'an, `h:muslim-2749` for the corpus hadith.
  final String id;
  final PassageKind kind;

  /// What the screen shows as the citation, for example `Qur’an 94:5–6` or
  /// `Sahih Muslim 2749`.
  final String reference;
  final String english;
  final String? arabic;

  /// Hadith only.
  final String? collection;
  final String? number;
  final String? grade;
  final String? grader;

  /// `summary` or `excerpt`: the hadith English is written for this app, it
  /// is not a copy of a published translation.
  final String? textKind;
  final String? verifiedOn;
  final String? verifiedAt;

  /// `Qur’an` or `Hadith`.
  String get label => kind == PassageKind.quran ? 'Qur’an' : 'Hadith';

  /// One line under a hadith: its grade and who gave it. Null for the
  /// Qur'an.
  String? get gradeLine {
    final String? g = grade;
    if (kind == PassageKind.quran || g == null) return null;
    final String? who = grader;
    return who == null ? g : '$g · $who';
  }
}
