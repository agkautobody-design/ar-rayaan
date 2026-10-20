/// Size of the Letters school and how its two asset files combine.
///
/// Units 1-4 (the 28 letters) live in assets/academy/letters_curriculum.json,
/// a versioned content pack. Units 5-7 (vowels, sukun, shaddah, tanween,
/// joining) live in assets/academy/letters_v2_curriculum.json so the pack and
/// its manifest entry are untouched. [mergeLettersCurriculum] joins them.
/// test/letters_v2_test.dart fails when these constants drift from the files.
library;

/// Lessons in the Letters school: 28 letters (units 1-4) plus units 5-7.
const int kLettersLessonCount = 40;

/// Units in the Letters school.
const int kLettersUnitCount = 7;

/// [base] (units 1-4) followed by [v2] (units 5-7): units and exams
/// concatenated, everything else taken from [base]. Units or exams in [v2]
/// whose id already exists in [base] are ignored.
Map<String, dynamic> mergeLettersCurriculum(
    Map<String, dynamic> base, Map<String, dynamic>? v2) {
  if (v2 == null) return base;
  List<dynamic> join(String key) {
    final List<dynamic> out =
        List<dynamic>.of(base[key] as List<dynamic>? ?? <dynamic>[]);
    final Set<Object?> ids = <Object?>{
      for (final dynamic e in out) (e as Map<dynamic, dynamic>)['id'],
    };
    for (final dynamic e in v2[key] as List<dynamic>? ?? <dynamic>[]) {
      if (ids.add((e as Map<dynamic, dynamic>)['id'])) out.add(e);
    }
    return out;
  }

  return <String, dynamic>{
    ...base,
    'units': join('units'),
    'exams': join('exams'),
  };
}
