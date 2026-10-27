/// Path UX: the weekly rhythm and the placement quiz.
///
/// Dignity-first (Charter): there is no streak to lose, no red, no shame. The
/// rhythm only shows the days this week the learner showed up. The placement
/// quiz only suggests where to start; the learner can always start at the
/// beginning.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Days on which the learner did something in the Academy (finished a lesson
/// or answered a review). On-device only; dates only, no content.
abstract final class ActivityLog {
  static const String prefKey = 'ar.academy.activity.v1';

  /// Days kept (about ten years): they are tiny and totals must not shrink.
  static const int maxDays = 3650;

  /// 'yyyy-mm-dd' in the device's local time.
  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static Set<String> decode(String? raw) {
    if (raw == null || raw.isEmpty) return <String>{};
    try {
      final List<dynamic> l = jsonDecode(raw) as List<dynamic>;
      return <String>{for (final dynamic e in l) e as String};
    } catch (_) {
      return <String>{};
    }
  }

  /// [raw] with [now]'s day added, trimmed to [maxDays].
  static String add(String? raw, DateTime now) {
    final List<String> days = decode(raw).toList()..add(dayKey(now));
    final List<String> sorted = days.toSet().toList()..sort();
    final List<String> kept = sorted.length > maxDays
        ? sorted.sublist(sorted.length - maxDays)
        : sorted;
    return jsonEncode(kept);
  }

  /// Record today. Never throws: a blocked store must not stop learning.
  static void record(SharedPreferences prefs, [DateTime? now]) {
    try {
      prefs.setString(
          prefKey, add(prefs.getString(prefKey), now ?? DateTime.now()));
    } catch (_) {}
  }
}

/// The last seven days, oldest first, ending today.
class WeeklyRhythm {
  const WeeklyRhythm({required this.days, required this.active});

  /// 'yyyy-mm-dd' for each of the seven days, oldest first.
  final List<String> days;

  /// Same length: true when the learner was active that day.
  final List<bool> active;

  int get count => active.where((bool a) => a).length;

  factory WeeklyRhythm.of(Set<String> activeDays, DateTime today) {
    final DateTime t = DateTime(today.year, today.month, today.day);
    final List<String> days = <String>[
      for (int i = 6; i >= 0; i--)
        ActivityLog.dayKey(DateTime(t.year, t.month, t.day - i)),
    ];
    return WeeklyRhythm(
      days: days,
      active: <bool>[for (final String d in days) activeDays.contains(d)],
    );
  }

  /// One gentle line. Never a reproach.
  String get message {
    final int n = count;
    if (n == 0) {
      return 'A fresh week. One small lesson is enough to begin, in shaa Allah.';
    }
    if (n == 1) return 'You showed up once this week. That is a beginning.';
    if (n >= 7) return 'You showed up on all 7 days this week. Glad you are here.';
    return 'You showed up on $n of the last 7 days.';
  }
}

/// One placement question.
class PlacementQuestion {
  const PlacementQuestion({
    required this.level,
    required this.prompt,
    required this.options,
    required this.answer,
  });

  /// The unit this question checks (1..7).
  final int level;
  final String prompt;
  final List<String> options;

  /// Index into [options].
  final int answer;
}

/// A two-minute check that suggests where in the Letters school to start.
/// Two questions per unit, in unit order. It suggests the first unit the
/// learner did not fully get; getting everything right suggests the Word
/// Decks. Content is only letter names, vowel marks and reading rules.
abstract final class PlacementQuiz {
  static const List<PlacementQuestion> questions = <PlacementQuestion>[
    PlacementQuestion(level: 1, prompt: 'Which letter is Ba?',
        options: <String>['ب', 'ت', 'ج'], answer: 0),
    PlacementQuestion(level: 1, prompt: 'Which letter is Jeem?',
        options: <String>['ح', 'ج', 'خ'], answer: 1),
    PlacementQuestion(level: 2, prompt: 'Which letter is Seen?',
        options: <String>['س', 'ش', 'ص'], answer: 0),
    PlacementQuestion(level: 2, prompt: 'Which letter is Ra?',
        options: <String>['ز', 'د', 'ر'], answer: 2),
    PlacementQuestion(level: 3, prompt: 'Which letter is Ayn?',
        options: <String>['غ', 'ع', 'ف'], answer: 1),
    PlacementQuestion(level: 3, prompt: 'Which letter is Qaf?',
        options: <String>['ق', 'ف', 'ك'], answer: 0),
    PlacementQuestion(level: 4, prompt: 'Which letter is Noon?',
        options: <String>['ل', 'م', 'ن'], answer: 2),
    PlacementQuestion(level: 4, prompt: 'Which letter is Waw?',
        options: <String>['و', 'ي', 'ه'], answer: 0),
    PlacementQuestion(level: 5, prompt: 'How do you read بِ ?',
        options: <String>['ba', 'bi', 'bu'], answer: 1),
    PlacementQuestion(level: 5, prompt: 'Which letter stretches a fatha into a long aa?',
        options: <String>['ا', 'و', 'ي'], answer: 0),
    PlacementQuestion(level: 6, prompt: 'What does a shaddah mean?',
        options: <String>['The letter is doubled', 'The letter is silent', 'The vowel is long'],
        answer: 0),
    PlacementQuestion(level: 6, prompt: 'Two dammas at the end of a word give which ending?',
        options: <String>['an', 'in', 'un'], answer: 2),
    PlacementQuestion(level: 7, prompt: 'Which letter does NOT join to the letter after it?',
        options: <String>['ب', 'د', 'ن'], answer: 1),
    PlacementQuestion(level: 7, prompt: 'Arabic is read:',
        options: <String>['Left to right', 'Right to left', 'Top to bottom'],
        answer: 1),
  ];

  /// First lesson id of each unit, index 0 = unit 1.
  static const List<String> unitStart = <String>[
    'letters-01', 'letters-08', 'letters-15', 'letters-22',
    'letters-29', 'letters-33', 'letters-37',
  ];

  /// [correct] holds, per question index, whether it was answered correctly.
  /// Returns the lesson id to start from, or null when everything was right
  /// (the learner is ready for the Word Decks).
  static String? recommend(List<bool> correct) {
    for (int level = 1; level <= unitStart.length; level++) {
      bool all = true;
      for (int i = 0; i < questions.length; i++) {
        if (questions[i].level != level) continue;
        if (i >= correct.length || !correct[i]) all = false;
      }
      if (!all) return unitStart[level - 1];
    }
    return null;
  }
}
