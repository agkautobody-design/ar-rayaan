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
import '../data/mushaf_layout_pack.dart';

/// Feature flag. Default ON for the beta preview; flipping the stored
/// value to false hides every Academy entry point instantly (kill switch).
final academyFlagProvider = FutureProvider<bool>((Ref ref) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool('ar.flag.academy') ?? true;
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

  Future<void> restart(String lessonId) async {
    state = <String, LessonProgress>{
      ...state,
      lessonId: const LessonProgress(lastStep: 0),
    };
    await _save();
  }
}

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
