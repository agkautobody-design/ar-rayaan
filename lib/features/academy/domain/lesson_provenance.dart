/// Provenance and review status for every manifest lesson.
///
/// Religious-content standard (Abdul, 20 Oct 2026): a lesson may be labelled
/// "scholar-reviewed" only when a NAMED reviewer and a date are recorded.
/// None exists yet, so every lesson carries [LessonReviewStatus
/// .notYetScholarReviewed] and the fixed label "Not yet scholar-reviewed".
/// `test/lesson_provenance_test.dart` fails the build when a manifest lesson
/// has no entry here, when an entry claims review without a reviewer, or when
/// a lesson cites a Qur'an reference that does not exist.
///
/// The cited sources shown next to a lesson are NOT stored here: they are
/// read from the lesson's own text every time ([extractSources]), so they can
/// never drift from what the lesson says.
library;

import 'hifz_planner.dart' show ayatInSurah;

enum LessonReviewStatus { notYetScholarReviewed, scholarReviewed }

/// The label shown to the learner. Fixed wording: never "scholar-reviewed"
/// on its own.
const String kNotYetReviewedLabel = 'Not yet scholar-reviewed';

class LessonProvenance {
  const LessonProvenance({
    required this.origin,
    this.status = LessonReviewStatus.notYetScholarReviewed,
    this.reviewer,
    this.reviewedOn,
    this.version = 1,
  });

  /// Where the lesson text comes from.
  final String origin;
  final LessonReviewStatus status;

  /// Named scholar. Required when [status] is scholarReviewed.
  final String? reviewer;

  /// ISO date (yyyy-mm-dd) of the review. Required with a reviewer.
  final String? reviewedOn;

  /// Bumped when the lesson text changes after a review.
  final int version;

  String get label => status == LessonReviewStatus.scholarReviewed
      ? 'Reviewed by $reviewer on $reviewedOn'
      : kNotYetReviewedLabel;
}

/// One thing a lesson cites.
class LessonSource {
  const LessonSource({required this.kind, required this.ref});

  /// 'quran' or 'hadith'.
  final String kind;

  /// '2:183', '9:60-61', 'Bukhari 1903'.
  final String ref;

  @override
  String toString() => kind == 'quran' ? "Qur'an $ref" : ref;

  @override
  bool operator ==(Object other) =>
      other is LessonSource && other.kind == kind && other.ref == ref;

  @override
  int get hashCode => Object.hash(kind, ref);
}

// No look-behind (older Safari lacks it): group 1 is the character before.
final RegExp _quranRef = RegExp(
    r'(^|[^\d.:])(\d{1,3}):(\d{1,3})(?:\s*[-\u2013]\s*(\d{1,3}))?(?!\d)');
final RegExp _hadithRef = RegExp(
    r"\b(Bukhari|Muslim|Tirmidhi|Abu Dawud|An-Nasa.i|Nasa.i|Ibn Majah|Ahmad)\s+(\d{1,5})\b");

/// True when surah:ayah exists (surah 1..114, ayah within its count).
bool quranRefExists(int surah, int ayah) =>
    ayah >= 1 && ayah <= ayatInSurah(surah);

/// The Qur'an and hadith references written in [text], in order, once each.
/// Qur'an references that do not exist are returned too (kind 'quran' with
/// the raw text) so that a test can fail on them; use [quranRefExists].
List<LessonSource> extractSources(String text) {
  final List<LessonSource> out = <LessonSource>[];
  void add(LessonSource s) {
    if (!out.contains(s)) out.add(s);
  }

  for (final RegExpMatch m in _quranRef.allMatches(text)) {
    final String? to = m.group(4);
    add(LessonSource(
      kind: 'quran',
      ref: '${m.group(2)}:${m.group(3)}${to == null ? '' : '-$to'}',
    ));
  }
  for (final RegExpMatch m in _hadithRef.allMatches(text)) {
    add(LessonSource(kind: 'hadith', ref: '${m.group(1)} ${m.group(2)}'));
  }
  return out;
}

/// Parses '2:183' or '9:60-61'; null when malformed.
({int surah, int from, int to})? parseQuranRef(String ref) {
  final RegExpMatch? m =
      RegExp(r'^(\d{1,3}):(\d{1,3})(?:[-\u2013](\d{1,3}))?$').firstMatch(ref);
  if (m == null) return null;
  final int surah = int.parse(m.group(1)!);
  final int from = int.parse(m.group(2)!);
  final int to = m.group(3) == null ? from : int.parse(m.group(3)!);
  return (surah: surah, from: from, to: to);
}

/// True when every ayah in the reference exists.
bool quranRefValid(String ref) {
  final ({int surah, int from, int to})? p = parseQuranRef(ref);
  if (p == null) return false;
  return p.to >= p.from &&
      quranRefExists(p.surah, p.from) &&
      quranRefExists(p.surah, p.to);
}

const String _originPath =
    'Academy-authored text (The Path). Qur’an and hadith are quoted in '
    'paraphrase; the bundled Qur’an text is the authority for any ayah.';
const String _originSchool =
    'Academy-authored text (school course). Qur’an and hadith are '
    'quoted in paraphrase; the bundled Qur’an text is the authority '
    'for any ayah.';

/// One entry per manifest lesson, in manifest order.
const Map<String, LessonProvenance> kLessonProvenance =
    <String, LessonProvenance>{
  'path.u0.l1': LessonProvenance(origin: _originPath),
  'path.u1.l1': LessonProvenance(origin: _originPath),
  'path.u2.l1': LessonProvenance(origin: _originPath),
  'path.u3.l1': LessonProvenance(origin: _originPath),
  'path.u4.l1': LessonProvenance(origin: _originPath),
  'path.u4.l2': LessonProvenance(origin: _originPath),
  'path.u4.l3': LessonProvenance(origin: _originPath),
  'path.u4.l4': LessonProvenance(origin: _originPath),
  'path.u5.l1': LessonProvenance(origin: _originPath),
  'path.u5.l2': LessonProvenance(origin: _originPath),
  'path.u5.l3': LessonProvenance(origin: _originPath),
  'path.u5.l4': LessonProvenance(origin: _originPath),
  'path.u6.l1': LessonProvenance(origin: _originPath),
  'path.u6.l2': LessonProvenance(origin: _originPath),
  'path.u6.l3': LessonProvenance(origin: _originPath),
  'path.u7.l1': LessonProvenance(origin: _originPath),
  'path.u7.l2': LessonProvenance(origin: _originPath),
  'path.u7.l3': LessonProvenance(origin: _originPath),
  'path.u7.l4': LessonProvenance(origin: _originPath),
  'path.u8.l1': LessonProvenance(origin: _originPath),
  'path.u8.l2': LessonProvenance(origin: _originPath),
  'path.u8.l3': LessonProvenance(origin: _originPath),
  'path.u8.l4': LessonProvenance(origin: _originPath),
  'path.u9.l1': LessonProvenance(origin: _originPath),
  'path.u9.l2': LessonProvenance(origin: _originPath),
  'path.u9.l3': LessonProvenance(origin: _originPath),
  'path.u9.l4': LessonProvenance(origin: _originPath),
  'arabic.u1.l1': LessonProvenance(origin: _originSchool),
  'arabic.u1.l2': LessonProvenance(origin: _originSchool),
  'arabic.u1.l3': LessonProvenance(origin: _originSchool),
  'arabic.u1.l4': LessonProvenance(origin: _originSchool),
  'arabic.u2.l1': LessonProvenance(origin: _originSchool),
  'arabic.u2.l2': LessonProvenance(origin: _originSchool),
  'arabic.u2.l3': LessonProvenance(origin: _originSchool),
  'aqid.u1.l1': LessonProvenance(origin: _originSchool),
  'aqid.u1.l2': LessonProvenance(origin: _originSchool),
  'aqid.u1.l3': LessonProvenance(origin: _originSchool),
  'aqid.u1.l4': LessonProvenance(origin: _originSchool),
  'aqid.u2.l1': LessonProvenance(origin: _originSchool),
  'aqid.u2.l2': LessonProvenance(origin: _originSchool),
  'aqid.u2.l3': LessonProvenance(origin: _originSchool),
  'aqid.u3.l1': LessonProvenance(origin: _originSchool),
  'aqid.u3.l2': LessonProvenance(origin: _originSchool),
  'aqid.u3.l3': LessonProvenance(origin: _originSchool),
  'char.u1.l1': LessonProvenance(origin: _originSchool),
  'char.u1.l2': LessonProvenance(origin: _originSchool),
  'char.u1.l3': LessonProvenance(origin: _originSchool),
  'char.u1.l4': LessonProvenance(origin: _originSchool),
  'char.u2.l1': LessonProvenance(origin: _originSchool),
  'char.u2.l2': LessonProvenance(origin: _originSchool),
  'char.u2.l3': LessonProvenance(origin: _originSchool),
  'char.u2.l4': LessonProvenance(origin: _originSchool),
  'char.u3.l1': LessonProvenance(origin: _originSchool),
  'char.u3.l2': LessonProvenance(origin: _originSchool),
  'char.u3.l3': LessonProvenance(origin: _originSchool),
  'char.u3.l4': LessonProvenance(origin: _originSchool),
  'fam.u1.l1': LessonProvenance(origin: _originSchool),
  'fam.u1.l2': LessonProvenance(origin: _originSchool),
  'fam.u1.l3': LessonProvenance(origin: _originSchool),
  'fam.u2.l1': LessonProvenance(origin: _originSchool),
  'fam.u2.l2': LessonProvenance(origin: _originSchool),
  'fam.u2.l3': LessonProvenance(origin: _originSchool),
  'fam.u2.l4': LessonProvenance(origin: _originSchool),
  'fam.u3.l1': LessonProvenance(origin: _originSchool),
  'fam.u3.l2': LessonProvenance(origin: _originSchool),
  'fam.u3.l3': LessonProvenance(origin: _originSchool),
  'yth.u1.l1': LessonProvenance(origin: _originSchool),
  'yth.u1.l2': LessonProvenance(origin: _originSchool),
  'yth.u1.l3': LessonProvenance(origin: _originSchool),
  'yth.u2.l1': LessonProvenance(origin: _originSchool),
  'yth.u2.l2': LessonProvenance(origin: _originSchool),
  'yth.u2.l3': LessonProvenance(origin: _originSchool),
  'yth.u3.l1': LessonProvenance(origin: _originSchool),
  'yth.u3.l2': LessonProvenance(origin: _originSchool),
  'yth.u3.l3': LessonProvenance(origin: _originSchool),
  'wmns.u1.l1': LessonProvenance(origin: _originSchool),
  'wmns.u1.l2': LessonProvenance(origin: _originSchool),
  'wmns.u1.l3': LessonProvenance(origin: _originSchool),
  'wmns.u1.l4': LessonProvenance(origin: _originSchool),
  'wmns.u2.l1': LessonProvenance(origin: _originSchool),
  'wmns.u2.l2': LessonProvenance(origin: _originSchool),
  'wmns.u2.l3': LessonProvenance(origin: _originSchool),
  'wmns.u2.l4': LessonProvenance(origin: _originSchool),
  'wmns.u3.l1': LessonProvenance(origin: _originSchool),
  'wmns.u3.l2': LessonProvenance(origin: _originSchool),
  'wmns.u3.l3': LessonProvenance(origin: _originSchool),
  'wmns.u3.l4': LessonProvenance(origin: _originSchool),
  'wmns.u3.l5': LessonProvenance(origin: _originSchool),
  'wmns.u4.l1': LessonProvenance(origin: _originSchool),
  'wmns.u4.l2': LessonProvenance(origin: _originSchool),
  'wmns.u4.l3': LessonProvenance(origin: _originSchool),
  'wmns.u4.l4': LessonProvenance(origin: _originSchool),
  'trx.u1.l1': LessonProvenance(origin: _originSchool),
  'trx.u1.l2': LessonProvenance(origin: _originSchool),
  'trx.u1.l3': LessonProvenance(origin: _originSchool),
  'trx.u1.l4': LessonProvenance(origin: _originSchool),
  'trx.u2.l1': LessonProvenance(origin: _originSchool),
  'trx.u2.l2': LessonProvenance(origin: _originSchool),
  'trx.u2.l3': LessonProvenance(origin: _originSchool),
  'trx.u3.l1': LessonProvenance(origin: _originSchool),
  'trx.u3.l2': LessonProvenance(origin: _originSchool),
  'trx.u3.l3': LessonProvenance(origin: _originSchool),
  'eol.u1.l1': LessonProvenance(origin: _originSchool),
  'eol.u1.l2': LessonProvenance(origin: _originSchool),
  'eol.u1.l3': LessonProvenance(origin: _originSchool),
  'eol.u1.l4': LessonProvenance(origin: _originSchool),
  'eol.u2.l1': LessonProvenance(origin: _originSchool),
  'eol.u2.l2': LessonProvenance(origin: _originSchool),
  'eol.u2.l3': LessonProvenance(origin: _originSchool),
  'eol.u3.l1': LessonProvenance(origin: _originSchool),
  'eol.u3.l2': LessonProvenance(origin: _originSchool),
  'daw.u1.l1': LessonProvenance(origin: _originSchool),
  'daw.u1.l2': LessonProvenance(origin: _originSchool),
  'daw.u1.l3': LessonProvenance(origin: _originSchool),
  'daw.u1.l4': LessonProvenance(origin: _originSchool),
  'daw.u2.l1': LessonProvenance(origin: _originSchool),
  'daw.u2.l2': LessonProvenance(origin: _originSchool),
  'daw.u2.l3': LessonProvenance(origin: _originSchool),
  'daw.u2.l4': LessonProvenance(origin: _originSchool),
  'daw.u3.l1': LessonProvenance(origin: _originSchool),
  'daw.u3.l2': LessonProvenance(origin: _originSchool),
  'daw.u3.l3': LessonProvenance(origin: _originSchool),
  'hlth.u1.l1': LessonProvenance(origin: _originSchool),
  'hlth.u1.l2': LessonProvenance(origin: _originSchool),
  'hlth.u1.l3': LessonProvenance(origin: _originSchool),
  'hlth.u1.l4': LessonProvenance(origin: _originSchool),
  'hlth.u2.l1': LessonProvenance(origin: _originSchool),
  'hlth.u2.l2': LessonProvenance(origin: _originSchool),
  'hlth.u2.l3': LessonProvenance(origin: _originSchool),
  'hlth.u3.l1': LessonProvenance(origin: _originSchool),
  'hlth.u3.l2': LessonProvenance(origin: _originSchool),
  'und.u1.l1': LessonProvenance(origin: _originSchool),
  'und.u1.l2': LessonProvenance(origin: _originSchool),
  'und.u1.l3': LessonProvenance(origin: _originSchool),
  'und.u2.l1': LessonProvenance(origin: _originSchool),
  'und.u2.l2': LessonProvenance(origin: _originSchool),
  'und.u2.l3': LessonProvenance(origin: _originSchool),
  'und.u3.l1': LessonProvenance(origin: _originSchool),
  'und.u3.l2': LessonProvenance(origin: _originSchool),
  'und.u3.l3': LessonProvenance(origin: _originSchool),
  'hfz.u1.l1': LessonProvenance(origin: _originSchool),
  'hfz.u1.l2': LessonProvenance(origin: _originSchool),
  'hfz.u1.l3': LessonProvenance(origin: _originSchool),
  'hfz.u2.l1': LessonProvenance(origin: _originSchool),
  'hfz.u2.l2': LessonProvenance(origin: _originSchool),
  'hfz.u2.l3': LessonProvenance(origin: _originSchool),
};

/// The provenance of [lessonId], or null when the lesson has no entry (a
/// test makes that impossible for manifest lessons).
LessonProvenance? provenanceOf(String lessonId) => kLessonProvenance[lessonId];
