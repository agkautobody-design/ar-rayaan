/// Academy providers — feature flag (kill switch), progress persistence,
/// and the "continue where you left off" resolver.
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/core/providers.dart';
import '../domain/academy_models.dart';
import '../domain/course_manifest.dart';
import '../domain/mushaf_layout.dart';
import '../domain/spaced_repetition.dart';
import '../data/mushaf_layout_pack.dart';

/// Feature flag. Default ON for the beta preview; flipping the stored
/// value to false hides every Academy entry point instantly (kill switch).
final academyFlagProvider = FutureProvider<bool>((Ref ref) async {
  try {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('ar.flag.academy') ?? true;
  } catch (_) {
    // Channels unavailable (test harness, cold start): the flag defaults ON.
    return true;
  }
});

/// The course manifest (static in Wave 1; content packs land in Wave 2+).
final academyCoursesProvider = Provider<List<AcademyCourse>>(
  (Ref ref) => kAcademyCourses,
);

/// Resolve the lesson to feature in the "Continue" hero: the first
/// in-manifest lesson that isn't completed (manifest order = Path order).
final continueLessonProvider = Provider<AcademyLesson?>((Ref ref) {
  final List<AcademyCourse> courses = ref.watch(academyCoursesProvider);
  final Map<String, LessonProgress> progress = ref.watch(
    academyProgressProvider,
  );
  for (final AcademyCourse c in courses) {
    for (final AcademyUnit u in c.units) {
      for (final AcademyLesson l in u.lessons) {
        if (!(progress[l.id]?.completed ?? false)) return l;
      }
    }
  }
  return null;
});

/// Completed-lesson count for the Today strip.
final lessonsDoneProvider = Provider<int>((Ref ref) {
  final Map<String, LessonProgress> progress = ref.watch(
    academyProgressProvider,
  );
  return progress.values.where((LessonProgress p) => p.completed).length;
});

class AcademyProgressNotifier
    extends StateNotifier<Map<String, LessonProgress>> {
  AcademyProgressNotifier(this._prefs) : super(<String, LessonProgress>{}) {
    _load();
  }

  static const String _key = 'ar.academy.progress.v1';
  final SharedPreferences _prefs;

  void _load() {
    final String? raw = _prefs.getString(_key);
    if (raw == null) return;
    final Map<String, dynamic> decoded =
        jsonDecode(raw) as Map<String, dynamic>;
    state = decoded.map(
      (String k, dynamic v) =>
          MapEntry<String, LessonProgress>(k, LessonProgress.fromJson(v as Map<String, dynamic>)),
    );
  }

  Future<void> _save() async {
    final Map<String, dynamic> encoded = state.map(
      (String k, LessonProgress v) => MapEntry<String, dynamic>(k, v.toJson()),
    );
    await _prefs.setString(_key, jsonEncode(encoded));
  }

  LessonProgress of(String lessonId) =>
      state[lessonId] ?? const LessonProgress();

  /// Advance the resume pointer to [stepIndex] (never backwards mid-lesson
  /// except on explicit restart).
  Future<void> advance(String lessonId, int stepIndex) async {
    final LessonProgress current = of(lessonId);
    if (stepIndex <= current.lastStep && !current.completed) return;
    state = <String, LessonProgress>{
      ...state,
      lessonId: current.copyWith(lastStep: stepIndex),
    };
    await _save();
  }

  Future<void> complete(String lessonId) async {
    final LessonProgress current = of(lessonId);
    state = <String, LessonProgress>{
      ...state,
      lessonId: current.copyWith(completed: true),
    };
    await _save();
  }

  /// Direct write (used by the Review Queue for mastery marks).
  Future<void> update(String lessonId, LessonProgress value) async {
    state = <String, LessonProgress>{...state, lessonId: value};
    await _save();
  }

  Future<void> restart(String lessonId) async {
    state = <String, LessonProgress>{
      ...state,
      lessonId: const LessonProgress(lastStep: 0),
    };
    await _save();
  }
}

/// The Review Queue — "Today's amana". One SM-2 card per completed lesson,
/// any school. Completing a lesson enqueues it; grading a review reschedules
/// it and (on good/easy) marks the lesson MASTERED in device progress.
/// Interleaving is free: due cards sort by date across all schools.
class ReviewQueueNotifier extends StateNotifier<Map<String, ReviewCard>> {
  ReviewQueueNotifier(this._ref) : super(<String, ReviewCard>{}) {
    _load();
  }

  final Ref _ref;
  static const String _pref = 'ar.academy.review.v1';
  static const int dailyCap = 10;

  void _load() {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      final raw = prefs.getString(_pref);
      if (raw == null || raw.isEmpty) return;
      final List<dynamic> list = json.decode(raw) as List<dynamic>;
      state = <String, ReviewCard>{
        for (final dynamic e in list)
          (e as Map)['wordKey'] as String:
              ReviewCard.fromJson(Map<String, dynamic>.from(e)),
      };
    } catch (_) {}
  }

  void _save() {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      prefs.setString(
          _pref, json.encode(state.values.map((c) => c.toJson()).toList()));
    } catch (_) {}
  }

  void _update(String lessonId, ReviewCard card) {
    state = <String, ReviewCard>{...state, lessonId: card};
    _save();
  }

  /// Enqueue (or reset) a lesson when it is completed.
  void addLesson(String lessonId) {
    _update(
      lessonId,
      ReviewCard(
        wordKey: lessonId,
        dueDate: DateTime.now().add(const Duration(days: 1)),
      ),
    );
  }

  /// Today's queue, oldest first, capped so review never becomes a chore.
  List<ReviewCard> get due => Sm2Engine.dueQueue(
        state.values.toList(),
        DateTime.now(),
      ).take(dailyCap).toList();

  int get dueCount => due.length;

  /// Grade a review. good/easy -> mastered at device level; again -> the
  /// lesson comes back tomorrow. Never a fail state.
  Future<void> grade(String lessonId, ReviewGrade grade) async {
    final card = state[lessonId];
    if (card == null) return;
    _update(lessonId, Sm2Engine.schedule(card, grade, DateTime.now()));
    if (grade != ReviewGrade.again) {
      final progress = _ref.read(academyProgressProvider.notifier);
      final current = progress.of(lessonId);
      if (current.completed) {
        progress.update(lessonId, current.copyWith(mastered: true));
      }
    }
  }
}

/// Learning track — one door per learner, same schools behind each.
/// 'child' (avatar-led, play-heavy) · 'teen'/'adult' (why-first, direct) ·
/// 'parent' (teaching notes + Family Wing). Switchable anytime; stored
/// per device.
class AcademyTrackNotifier extends StateNotifier<String> {
  AcademyTrackNotifier(this._ref) : super('teen') {
    _load();
  }

  final Ref _ref;
  static const String _pref = 'ar.academy.track';

  void _load() {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      final String? t = prefs.getString(_pref);
      if (t != null && (t == 'child' || t == 'teen' || t == 'parent')) {
        state = t;
      }
    } catch (_) {}
  }

  Future<void> set(String track) async {
    if (track != 'child' && track != 'teen' && track != 'parent') return;
    state = track;
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      await prefs.setString(_pref, track);
    } catch (_) {}
  }
}

final academyTrackProvider =
    StateNotifierProvider<AcademyTrackNotifier, String>(
        (ref) => AcademyTrackNotifier(ref));

final reviewQueueProvider =
    StateNotifierProvider<ReviewQueueNotifier, Map<String, ReviewCard>>(
        (ref) => ReviewQueueNotifier(ref));

final academyProgressProvider = StateNotifierProvider<
    AcademyProgressNotifier, Map<String, LessonProgress>>((Ref ref) {
  // SharedPreferences is set up before app boot (same pattern as the
  // habits/sakina providers); unsynchronized access in tests uses
  // SharedPreferences.setMockInitialValues.
  return AcademyProgressNotifier(
    ref.watch(sharedPreferencesProvider),
  );
});


/// The checksum-verified Madinah layout pack. Null until the authentic
/// 604-page mapping ships — Madinah mode stays hidden (never unverified).
final mushafLayoutProvider = FutureProvider<List<MushafPage>?>((Ref ref) {
  return MushafLayoutPack.load();
});
