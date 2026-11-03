import 'package:firebase_analytics/firebase_analytics.dart';

/// Centralized analytics for Ar-Rayaan.
/// Call these methods from screens and controllers to track user behavior.
class AppAnalytics {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // ── Navigation ───────────────────────────────────────────────────────

  static void logScreenView(String screenName) {
    _analytics.logScreenView(screenName: screenName);
  }

  // ── Auth ─────────────────────────────────────────────────────────────

  static void logLogin(String method) {
    _analytics.logLogin(loginMethod: method);
  }

  static void logSignUp(String method) {
    _analytics.logSignUp(signUpMethod: method);
  }

  static void logPasswordReset() {
    _analytics.logEvent(name: 'password_reset_requested');
  }

  static void logEmailVerified() {
    _analytics.logEvent(name: 'email_verified');
  }

  // ── Quran ────────────────────────────────────────────────────────────

  static void logQuranBookmark(String surah, int ayah) {
    _analytics.logEvent(
      name: 'quran_bookmark_added',
      parameters: {'surah': surah, 'ayah': ayah},
    );
  }

  static void logQuranAudioPlayed(String surah, String reciter) {
    _analytics.logEvent(
      name: 'quran_audio_played',
      parameters: {'surah': surah, 'reciter': reciter},
    );
  }

  // ── Academy ──────────────────────────────────────────────────────────

  static void logAcademyLessonStarted(String school, String lessonId) {
    _analytics.logEvent(
      name: 'academy_lesson_started',
      parameters: {'school': school, 'lesson_id': lessonId},
    );
  }

  static void logAcademyLessonCompleted(String school, String lessonId, int? score) {
    _analytics.logEvent(
      name: 'academy_lesson_completed',
      parameters: {
        'school': school,
        'lesson_id': lessonId,
        if (score != null) 'score': score,
      },
    );
  }

  static void logAcademyTestSubmitted(String school, String lessonId, int score) {
    _analytics.logEvent(
      name: 'academy_test_submitted',
      parameters: {'school': school, 'lesson_id': lessonId, 'score': score},
    );
  }

  // ── Family ───────────────────────────────────────────────────────────

  static void logFamilyCreated() {
    _analytics.logEvent(name: 'family_created');
  }

  static void logFamilyChildAdded(int childCount) {
    _analytics.logEvent(
      name: 'family_child_added',
      parameters: {'child_count': childCount},
    );
  }

  static void logFamilyParentInvited() {
    _analytics.logEvent(name: 'family_parent_invited');
  }

  static void logFamilyTeacherInvited() {
    _analytics.logEvent(name: 'family_teacher_invited');
  }

  static void logFamilyChildCredentialsShared() {
    _analytics.logEvent(name: 'family_child_credentials_shared');
  }

  // ── Hadi / Wasia ─────────────────────────────────────────────────────

  static void logHadiQuestionAsked(String category) {
    _analytics.logEvent(
      name: 'hadi_question_asked',
      parameters: {'category': category},
    );
  }

  static void logWasiaParentChatOpened(String childId) {
    _analytics.logEvent(
      name: 'wasia_parent_chat_opened',
      parameters: {'child_id': childId},
    );
  }

  // ── Prayer ───────────────────────────────────────────────────────────

  static void logPrayerTimeViewed(String prayerName) {
    _analytics.logEvent(
      name: 'prayer_time_viewed',
      parameters: {'prayer': prayerName},
    );
  }

  static void logQiblaOpened() {
    _analytics.logEvent(name: 'qibla_opened');
  }

  // ── Daily Content ────────────────────────────────────────────────────

  static void logDailyHadithViewed(String hadithId) {
    _analytics.logEvent(
      name: 'daily_hadith_viewed',
      parameters: {'hadith_id': hadithId},
    );
  }

  static void logDailyDuaViewed(String duaId) {
    _analytics.logEvent(
      name: 'daily_dua_viewed',
      parameters: {'dua_id': duaId},
    );
  }

  // ── Engagement ───────────────────────────────────────────────────────

  static void logSessionDuration(int seconds) {
    _analytics.logEvent(
      name: 'session_duration',
      parameters: {'duration_seconds': seconds},
    );
  }

  static void logAppRatingPromptShown() {
    _analytics.logEvent(name: 'app_rating_prompt_shown');
  }

  static void logAppRatingSubmitted(int stars) {
    _analytics.logEvent(
      name: 'app_rating_submitted',
      parameters: {'stars': stars},
    );
  }
}
