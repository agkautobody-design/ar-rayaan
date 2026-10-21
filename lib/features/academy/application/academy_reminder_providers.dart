import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/notifications/prayer_notification_scheduler.dart';
import '../../../app/core/providers.dart';
import '../../prayer/application/prayer_providers.dart';
import '../domain/academy_reminders.dart';
import 'academy_providers.dart';

/// The parent's Academy reminder choices. Everything starts off: nothing is
/// scheduled, and no permission is asked, until a parent switches one on.
class AcademyReminderController extends Notifier<AcademyReminderSettings> {
  @override
  AcademyReminderSettings build() {
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      return AcademyReminderSettings.decode(
        prefs.getString(kAcademyRemindPref),
      );
    } catch (_) {
      return const AcademyReminderSettings();
    }
  }

  /// Returns false when a reminder was turned on but the phone refused
  /// notifications (the switch stays on; the reminder simply cannot show).
  Future<bool> setLesson(bool on) => _set(state.copyWith(lesson: on), on);

  Future<bool> setReviews(bool on) => _set(state.copyWith(reviews: on), on);

  Future<void> setTime(int hour, int minute) async {
    await _set(state.copyWith(hour: hour, minute: minute), false);
  }

  Future<bool> _set(AcademyReminderSettings next, bool askPermission) async {
    state = next;
    try {
      await ref
          .read(sharedPreferencesProvider)
          .setString(kAcademyRemindPref, next.encode());
    } catch (_) {}
    if (!askPermission) return true;
    final PrayerNotificationScheduler s = ref.read(
      prayerNotificationSchedulerProvider,
    );
    if (!s.supported) return false;
    return s.requestPermission();
  }
}

final NotifierProvider<AcademyReminderController, AcademyReminderSettings>
    academyReminderProvider =
    NotifierProvider<AcademyReminderController, AcademyReminderSettings>(
  AcademyReminderController.new,
);

/// Keeps the OS reminders equal to the plan. A no-op where notifications are
/// unsupported; kept alive by the app shell like the prayer and zakat plans.
final Provider<void> academyReminderSyncProvider = Provider<void>((ref) {
  final PrayerNotificationScheduler scheduler = ref.watch(
    prayerNotificationSchedulerProvider,
  );
  if (!scheduler.supported) return;
  final AcademyReminderSettings settings = ref.watch(academyReminderProvider);
  final bool waiting = ref.watch(lessonReviewsDueProvider).isNotEmpty;
  ref.watch(prayerDayKeyProvider);
  final List<AcademyReminder> plan = planAcademyReminders(
    now: DateTime.now(),
    settings: settings,
    reviewsWaiting: waiting,
  );
  unawaited(
    scheduler.replaceAcademyReminders(<PlannedReminder>[
      for (final AcademyReminder r in plan)
        PlannedReminder(
          id: kAcademyReminderIdBase + r.dayOffset,
          at: r.at.toUtc(),
          title: r.title,
          body: r.body,
        ),
    ]),
  );
});
