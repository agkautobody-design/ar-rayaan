/// Hadith domain models.
///
/// v1 bundled content: The Forty Hadith of Imam an-Nawawi (Arabic +
/// English, fawazahmed0 verified editions). See Build Sheet v1.6:
/// Riyad as-Salihin (O-5) could not be sourced from this environment
/// (dataset paths 404, sunnah.com Cloudflare-blocked); an-Nawawi is the
/// same author and Riyad opens with this same first hadith. Swap is a
/// data-file change only — screens/providers untouched.
///
/// Grading standard (Ar-Rayaan religious-content rules): every hadith we
/// show carries its source, and every report from Abu Dawud, at-Tirmidhi,
/// an-Nasa'i or Ibn Majah is shown WITH its grade and WHO graded it. A
/// grade without a named grader is not a grade, so [HadithGrade] cannot be
/// built without one.
library;

/// A hadith grade together with the person or work that gave it.
class HadithGrade {
  const HadithGrade({required this.grade, required this.grader, this.note});

  /// e.g. `sahih`, `hasan`, `hasan sahih`, `daif`.
  final String grade;

  /// Who gave the grade, e.g. `al-Albani`, `at-Tirmidhi`, `Imam an-Nawawi`,
  /// or `Included in Sahih Muslim`.
  final String grader;

  /// Optional short caveat, e.g. that another grader differs.
  final String? note;

  /// Human label: `Hasan sahih — at-Tirmidhi`.
  String get label => '${_capitalise(grade)} — $grader';

  /// Reads `grade` + `grader` (+ optional `gradeNote`) from a JSON map.
  /// Returns null unless BOTH a grade and a named grader are present.
  static HadithGrade? fromJson(Map<String, dynamic> json) {
    final Object? grade = json['grade'];
    final Object? grader = json['grader'];
    if (grade is String &&
        grade.trim().isNotEmpty &&
        grader is String &&
        grader.trim().isNotEmpty) {
      final Object? note = json['gradeNote'];
      return HadithGrade(
        grade: grade.trim(),
        grader: grader.trim(),
        note: note is String && note.trim().isNotEmpty ? note.trim() : null,
      );
    }
    return null;
  }

  static String _capitalise(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

/// True when [source] names a collection whose reports must be shown with a
/// grade and a grader (Abu Dawud, at-Tirmidhi, an-Nasa'i, Ibn Majah, and
/// anything outside the six books such as Ahmad, al-Hakim or at-Tabarani).
/// Sahih al-Bukhari and Sahih Muslim are the top tier and need no separate
/// grade.
bool hadithSourceNeedsGrade(String source) {
  final String s = source.toLowerCase();
  return s.contains('dawud') ||
      s.contains('dawood') ||
      s.contains('tirmidhi') ||
      s.contains('nasa') ||
      s.contains('majah') ||
      s.contains('ahmad') ||
      s.contains('hakim') ||
      s.contains('tabarani') ||
      s.contains('mustadrak') ||
      s.contains("mu'jam") ||
      s.contains('mu\u2019jam');
}

class Hadith {
  const Hadith({
    required this.number,
    required this.arabic,
    required this.english,
    this.source,
    this.grade,
  });

  final int number;
  final String arabic;
  final String english;

  /// Who collected it, as an-Nawawi attributes it (e.g. `Bukhari & Muslim`).
  final String? source;

  /// Grade and grader, when the bundled data carries them.
  final HadithGrade? grade;

  /// One line for the UI: `Bukhari & Muslim · Sahih — Included in …`.
  String? get sourceLine {
    final String? s = source;
    final HadithGrade? g = grade;
    if (s == null && g == null) return null;
    if (g == null) return s;
    if (s == null) return g.label;
    return '$s · ${g.label}';
  }
}
